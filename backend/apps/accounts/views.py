import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.hashers import make_password, check_password
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.core.mail import send_mail
from django.db.models import Q
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt

from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import User, PasswordResetOTP
from .serializers import RegisterSerializer, AdminTokenObtainPairSerializer


def generic_response(note: str = ""):
    data = {
        "message": "If this email is registered, password reset instructions have been sent to your inbox."
    }
    if note:
        data["note"] = note
    return Response(data, status=status.HTTP_200_OK)


@csrf_exempt
@api_view(["POST"])
@permission_classes([AllowAny])
def request_password_reset(request):
    email = request.data.get("email", "").strip().lower()

    if not email:
        return Response(
            {"error": "Email is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user = User.objects.filter(email__iexact=email).first()

    # If the user doesn't exist, return clear info so users aren't left waiting for an email
    if not user:
        return Response({
            "message": "If this email is registered, password reset instructions have been sent.",
            "account_found": False,
        }, status=status.HTTP_200_OK)

    now = timezone.now()

    # Rate limiting: allow up to 10 requests per hour
    recent_requests = PasswordResetOTP.objects.filter(
        user=user,
        created_at__gte=now - timedelta(hours=1),
    ).count()

    if recent_requests >= 10:
        return Response(
            {"error": "Too many reset requests for this email. Please try again in an hour."},
            status=status.HTTP_429_TOO_MANY_REQUESTS,
        )

    # Invalidate older OTPs
    PasswordResetOTP.objects.filter(
        user=user,
        is_used=False,
    ).update(is_used=True)

    otp = f"{secrets.randbelow(1_000_000):06d}"

    reset_record = PasswordResetOTP.objects.create(
        user=user,
        otp_hash=make_password(otp),
        expires_at=now + timedelta(minutes=5),
    )

    # Rich HTML email template with WinPlay theme
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: #090B1A; color: #FFFFFF; margin: 0; padding: 24px; }}
        .card {{ max-width: 500px; margin: 0 auto; background: #171A31; border-radius: 18px; padding: 32px; border: 1px solid #2A2E50; text-align: center; }}
        .logo {{ font-size: 32px; font-weight: 900; letter-spacing: 5px; color: #9254FF; margin-bottom: 8px; }}
        .title {{ font-size: 22px; font-weight: 700; color: #FFFFFF; margin-top: 15px; }}
        .desc {{ font-size: 15px; color: #B0B5D0; line-height: 1.6; margin: 18px 0; }}
        .otp-box {{ background: #0C0E1E; border: 2px dashed #9254FF; border-radius: 12px; padding: 18px; font-size: 36px; letter-spacing: 12px; font-weight: 900; color: #21D6B5; margin: 24px 0; }}
        .badge {{ display: inline-block; background: rgba(255, 79, 163, 0.2); color: #FF4FA3; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 600; margin-bottom: 12px; }}
        .footer {{ font-size: 12px; color: #626785; margin-top: 30px; border-top: 1px solid #222644; padding-top: 20px; }}
      </style>
    </head>
    <body>
      <div class="card">
        <div class="logo">WINPLAY</div>
        <div class="badge">Password Reset Verification</div>
        <div class="title">Your WinPlay OTP Code</div>
        <div class="desc">
          Hello <strong>{user.username}</strong>,<br>
          We received a request to reset your password. Use the verification code below:
        </div>
        <div class="otp-box">{otp}</div>
        <div class="desc">
          This code is valid for <strong>5 minutes</strong>. Do not share it with anyone.<br>
          If you didn't request a password reset, you can safely ignore this email.
        </div>
        <div class="footer">
          &copy; WinPlay Gaming Platform. Play Fair &bull; Have Fun.
        </div>
      </div>
    </body>
    </html>
    """

    plain_message = (
        f"Hello {user.username},\n\n"
        f"Your WinPlay password reset code is: {otp}\n\n"
        "It expires in 5 minutes. Do not share this code with anyone.\n\n"
        "If you did not request this code, you can safely ignore this email."
    )

    try:
        send_mail(
            subject="WinPlay password reset OTP",
            message=plain_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            html_message=html_content,
            fail_silently=False,
        )
    except Exception as exc:
        reset_record.delete()
        if settings.DEBUG:
            return Response(
                {"error": f"Email delivery failed: {str(exc)}. Please check your SMTP settings in backend/.env."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
        return Response(
            {"error": "Email delivery is temporarily unavailable. Try again later."},
            status=status.HTTP_503_SERVICE_UNAVAILABLE,
        )

    res_data = {
        "message": f"A 6-digit reset code has been sent to {user.email}.",
        "email": user.email,
        "account_found": True,
    }

    # If backend is using console email backend during local testing, include debug_otp
    if settings.DEBUG and "console" in getattr(settings, "EMAIL_BACKEND", "").lower():
        res_data["debug_otp"] = otp
        res_data["note"] = "Local console email mode: OTP printed in terminal."

    return Response(res_data, status=status.HTTP_200_OK)


@csrf_exempt
@api_view(["POST"])
@permission_classes([AllowAny])
def verify_password_reset_otp(request):
    email = request.data.get("email", "").strip().lower()
    otp = request.data.get("otp", "").strip()

    if not email or len(otp) != 6 or not otp.isdigit():
        return Response(
            {"error": "Enter your email and six-digit OTP."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user = User.objects.filter(email__iexact=email).first()

    if not user:
        return Response(
            {"error": "Invalid or expired OTP."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    record = PasswordResetOTP.objects.filter(
        user=user,
        is_used=False,
        expires_at__gt=timezone.now(),
    ).order_by("-created_at").first()

    if not record or record.attempts >= 5:
        return Response(
            {"error": "Invalid or expired OTP."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    record.attempts += 1

    if not check_password(otp, record.otp_hash):
        record.save(update_fields=["attempts"])
        return Response(
            {"error": "Invalid OTP. Please check the code and try again."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    reset_token = secrets.token_urlsafe(32)

    record.is_used = True
    record.reset_token_hash = make_password(reset_token)
    record.reset_token_expires_at = timezone.now() + timedelta(minutes=10)
    record.save()

    return Response({
        "message": "OTP verified successfully.",
        "reset_token": reset_token,
    })


@csrf_exempt
@api_view(["POST"])
@permission_classes([AllowAny])
def confirm_password_reset(request):
    email = request.data.get("email", "").strip().lower()
    reset_token = request.data.get("reset_token", "")
    new_password = request.data.get("new_password", "")

    if not email or not reset_token or not new_password:
        return Response(
            {"error": "Email, reset token and new password are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user = User.objects.filter(email__iexact=email).first()

    if not user:
        return Response(
            {"error": "Invalid or expired reset session."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    record = PasswordResetOTP.objects.filter(
        user=user,
        is_used=True,
        reset_token_expires_at__gt=timezone.now(),
    ).exclude(
        reset_token_hash=""
    ).order_by("-created_at").first()

    if (
        not record
        or not check_password(reset_token, record.reset_token_hash)
    ):
        return Response(
            {"error": "Invalid or expired reset session."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        validate_password(new_password, user=user)
    except ValidationError as error:
        return Response(
            {"errors": error.messages},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user.set_password(new_password)
    user.save(update_fields=["password"])

    # Make the reset token unusable after a successful password change.
    record.reset_token_hash = ""
    record.reset_token_expires_at = None
    record.save(update_fields=[
        "reset_token_hash",
        "reset_token_expires_at",
    ])

    return Response({
        "message": "Password updated successfully. Please sign in again."
    })


class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]


class AdminLoginView(TokenObtainPairView):
    serializer_class = AdminTokenObtainPairSerializer


class AdminUserPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


class AdminUserListView(APIView):
    permission_classes = [IsAdminUser]

    def get(self, request):
        search = request.query_params.get("search", "").strip()
        users = User.objects.filter(is_staff=False, is_superuser=False).order_by("-date_joined")
        if search:
            users = users.filter(
                Q(username__icontains=search) |
                Q(email__icontains=search) |
                Q(phone_number__icontains=search)
            )
        paginator = AdminUserPagination()
        page = paginator.paginate_queryset(users, request, view=self)
        results = [{
            "id": user.id,
            "username": user.username,
            "email": user.email,
            "phone_number": user.phone_number,
            "is_active": user.is_active,
            "date_joined": user.date_joined.isoformat(),
        } for user in page]
        return paginator.get_paginated_response(results)


class AdminUserStatusView(APIView):
    permission_classes = [IsAdminUser]

    def patch(self, request, user_id):
        try:
            user = User.objects.get(pk=user_id, is_staff=False, is_superuser=False)
        except User.DoesNotExist:
            return Response({"detail": "Player not found."}, status=status.HTTP_404_NOT_FOUND)
        is_active = request.data.get("is_active")
        if not isinstance(is_active, bool):
            return Response({"detail": "is_active must be true or false."}, status=status.HTTP_400_BAD_REQUEST)
        user.is_active = is_active
        user.save(update_fields=["is_active"])
        return Response({"id": user.id, "is_active": user.is_active, "message": "Player status updated."})
