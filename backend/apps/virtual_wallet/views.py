import urllib.parse
import uuid
from decimal import Decimal

from django.conf import settings
from django.db import transaction
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Wallet
from apps.transactions.models import Transaction
from .serializers import (
    WalletSerializer,
    TransactionSerializer,
    DepositRequestSerializer,
    WithdrawRequestSerializer,
)


class TransactionPagination(PageNumberPagination):
    page_size = 15
    page_size_query_param = "page_size"
    max_page_size = 50


class WalletDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        wallet, _ = Wallet.objects.get_or_create(
            user=request.user,
            defaults={"balance": Decimal("100.00")},
        )
        serializer = WalletSerializer(wallet)
        data = serializer.data
        data["admin_whatsapp"] = getattr(settings, "ADMIN_WHATSAPP_NUMBER", "+917780383832")
        return Response(data)


class WalletDepositView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = DepositRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        amount = Decimal(str(serializer.validated_data["amount"]))
        payment_method = serializer.validated_data.get("payment_method", "UPI")

        wallet, _ = Wallet.objects.get_or_create(
            user=request.user,
            defaults={"balance": Decimal("100.00")},
        )

        ref_id = f"DEP-{uuid.uuid4().hex[:10].upper()}"
        try:
            wallet.credit(
                amount=amount,
                description=f"Deposit via {payment_method}",
                reference_id=ref_id,
                transaction_type="deposit",
            )
        except ValueError as err:
            return Response({"error": str(err)}, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            "message": f"Successfully deposited ₹{amount:.2f}",
            "balance": str(wallet.balance),
            "reference_id": ref_id,
        }, status=status.HTTP_200_OK)


class WhatsAppDepositRequestView(APIView):
    """
    Player creates a pending deposit request and receives a direct WhatsApp link
    to authenticate & submit payment screenshot directly to Admin WhatsApp.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            amount = Decimal(str(request.data.get("amount", "100")))
        except Exception:
            return Response({"error": "Invalid deposit amount."}, status=status.HTTP_400_BAD_REQUEST)

        if amount < Decimal("1.00"):
            return Response({"error": "Minimum deposit amount is ₹1.00."}, status=status.HTTP_400_BAD_REQUEST)

        wallet, _ = Wallet.objects.get_or_create(
            user=request.user,
            defaults={"balance": Decimal("100.00")},
        )

        ref_id = f"WA-DEP-{uuid.uuid4().hex[:8].upper()}"
        admin_phone = getattr(settings, "ADMIN_WHATSAPP_NUMBER", "+917780383832").strip()
        clean_phone = "".join(ch for ch in admin_phone if ch.isdigit())

        # Create a pending transaction record
        txn = Transaction.objects.create(
            user=request.user,
            wallet=wallet,
            amount=amount,
            balance_after=wallet.balance,
            transaction_type="deposit",
            status="pending",
            description=f"Pending WhatsApp Deposit (Ref: {ref_id})",
            reference_id=ref_id,
        )

        # Prefilled message for player to send to admin
        wa_text = (
            f"Hello Admin, I want to add money to my BetRally / WinPlay wallet.\n\n"
            f"👤 Player: {request.user.username}\n"
            f"📧 Email: {request.user.email}\n"
            f"💰 Amount: ₹{amount:.2f}\n"
            f"🔖 Deposit Ref: {ref_id}\n\n"
            f"I have transferred the amount. Please verify and credit my wallet balance. Thank you!"
        )

        encoded_text = urllib.parse.quote(wa_text)
        whatsapp_url = f"https://wa.me/{clean_phone}?text={encoded_text}"

        return Response({
            "message": "Deposit request created. Please message Admin on WhatsApp to complete payment.",
            "transaction_id": txn.id,
            "reference_id": ref_id,
            "amount": str(amount),
            "status": "pending",
            "admin_phone": admin_phone,
            "whatsapp_url": whatsapp_url,
            "prefilled_message": wa_text,
        }, status=status.HTTP_201_CREATED)


class WalletWithdrawView(APIView):
    """
    Player creates a withdrawal request (Minimum ₹500).
    Funds are held in pending escrow and a direct WhatsApp request is generated
    for Admin verification (+91 7780383832).
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = WithdrawRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        amount = Decimal(str(serializer.validated_data["amount"]))
        account_info = serializer.validated_data.get("account_info", "UPI")

        if amount < Decimal("500.00"):
            return Response({
                "error": "Minimum withdrawal amount is ₹500.00. Please enter ₹500 or more."
            }, status=status.HTTP_400_BAD_REQUEST)

        wallet, _ = Wallet.objects.get_or_create(
            user=request.user,
            defaults={"balance": Decimal("0.00")},
        )

        if wallet.balance < amount:
            return Response({
                "error": f"Insufficient wallet balance. You have ₹{wallet.balance:.2f} but requested ₹{amount:.2f}."
            }, status=status.HTTP_400_BAD_REQUEST)

        ref_id = f"WA-WTH-{uuid.uuid4().hex[:8].upper()}"
        admin_phone = getattr(settings, "ADMIN_WHATSAPP_NUMBER", "+917780383832").strip()
        clean_phone = "".join(ch for ch in admin_phone if ch.isdigit())

        # Atomically deduct from wallet and hold in pending withdrawal escrow
        with transaction.atomic():
            wallet = Wallet.objects.select_for_update().get(id=wallet.id)
            if wallet.balance < amount:
                return Response({"error": "Insufficient balance."}, status=status.HTTP_400_BAD_REQUEST)
            wallet.balance -= amount
            wallet.save(update_fields=["balance", "updated_at"])

            txn = Transaction.objects.create(
                user=request.user,
                wallet=wallet,
                amount=amount,
                balance_after=wallet.balance,
                transaction_type="withdrawal",
                status="pending",
                description=f"Pending Withdrawal to {account_info} (Ref: {ref_id})",
                reference_id=ref_id,
            )

        # Prefilled message for player to send to Admin
        wa_text = (
            f"Hello Admin, I have requested a withdrawal from my BetRally / WinPlay wallet.\n\n"
            f"👤 Player: {request.user.username} (ID: #{request.user.id})\n"
            f"📧 Email: {request.user.email}\n"
            f"💰 Withdrawal Amount: ₹{amount:.2f}\n"
            f"🏦 UPI / Account: {account_info}\n"
            f"🔖 Withdrawal Ref: {ref_id}\n\n"
            f"Please verify and transfer to my account. Thank you!"
        )

        encoded_text = urllib.parse.quote(wa_text)
        whatsapp_url = f"https://wa.me/{clean_phone}?text={encoded_text}"

        return Response({
            "message": f"Withdrawal request for ₹{amount:.2f} submitted. Contact Admin on WhatsApp to expedite payout.",
            "transaction_id": txn.id,
            "reference_id": ref_id,
            "amount": str(amount),
            "status": "pending",
            "balance": str(wallet.balance),
            "admin_phone": admin_phone,
            "whatsapp_url": whatsapp_url,
            "prefilled_message": wa_text,
        }, status=status.HTTP_201_CREATED)


class TransactionHistoryView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        transactions = Transaction.objects.filter(user=request.user).order_by("-created_at")
        paginator = TransactionPagination()
        page = paginator.paginate_queryset(transactions, request, view=self)
        serializer = TransactionSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


# ---------------- ADMIN WALLET & DEPOSIT CONTROLS ----------------


class AdminDepositListView(APIView):
    """Admin endpoint to view all deposit requests (especially pending WhatsApp deposits)."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        status_filter = request.query_params.get("status", "").strip()
        qs = Transaction.objects.filter(transaction_type="deposit")
        if status_filter:
            qs = qs.filter(status=status_filter)

        search = request.query_params.get("search", "").strip()
        if search:
            qs = qs.filter(
                user__email__icontains=search
            ) | qs.filter(
                user__username__icontains=search
            ) | qs.filter(
                reference_id__icontains=search
            )

        qs = qs.order_by("-created_at")
        paginator = TransactionPagination()
        page = paginator.paginate_queryset(qs, request, view=self)
        serializer = TransactionSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class AdminDepositApproveView(APIView):
    """Admin approves a pending deposit, crediting the player's wallet."""
    permission_classes = [IsAdminUser]

    def post(self, request, txn_id):
        try:
            txn = Transaction.objects.get(id=txn_id, transaction_type="deposit")
        except Transaction.DoesNotExist:
            return Response({"error": "Deposit transaction not found."}, status=status.HTTP_404_NOT_FOUND)

        if txn.status == "success":
            return Response({"error": "This deposit is already approved."}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            wallet = Wallet.objects.select_for_update().get(user=txn.user)
            wallet.balance += txn.amount
            wallet.save(update_fields=["balance", "updated_at"])

            txn.status = "success"
            txn.balance_after = wallet.balance
            txn.description = f"Approved Deposit (Ref: {txn.reference_id})"
            txn.save(update_fields=["status", "balance_after", "description"])

        return Response({
            "message": f"Successfully approved deposit of ₹{txn.amount:.2f} for {txn.user.username}.",
            "new_wallet_balance": str(wallet.balance),
            "status": "success",
        }, status=status.HTTP_200_OK)


class AdminDepositRejectView(APIView):
    """Admin rejects a pending deposit."""
    permission_classes = [IsAdminUser]

    def post(self, request, txn_id):
        try:
            txn = Transaction.objects.get(id=txn_id, transaction_type="deposit")
        except Transaction.DoesNotExist:
            return Response({"error": "Deposit transaction not found."}, status=status.HTTP_404_NOT_FOUND)

        if txn.status == "success":
            return Response({"error": "Cannot reject an already approved deposit."}, status=status.HTTP_400_BAD_REQUEST)

        reason = request.data.get("reason", "Payment verification unconfirmed")
        txn.status = "failed"
        txn.description = f"Rejected: {reason} (Ref: {txn.reference_id})"
        txn.save(update_fields=["status", "description"])

        return Response({
            "message": f"Deposit request #{txn.id} rejected.",
            "status": "failed",
        }, status=status.HTTP_200_OK)


class AdminWalletCreditDebitView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request, user_id):
        action = request.data.get("action")  # 'credit' or 'debit'
        try:
            amount = Decimal(str(request.data.get("amount", "0")))
        except Exception:
            return Response({"error": "Invalid amount"}, status=status.HTTP_400_BAD_REQUEST)

        if amount <= Decimal("0"):
            return Response({"error": "Amount must be positive"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            wallet = Wallet.objects.get(user_id=user_id)
        except Wallet.DoesNotExist:
            return Response({"error": "Wallet not found"}, status=status.HTTP_404_NOT_FOUND)

        reason = request.data.get("reason", "Admin adjustment")
        ref_id = f"ADM-{uuid.uuid4().hex[:8].upper()}"

        try:
            if action == "credit":
                wallet.credit(amount, description=f"Admin Credit: {reason}", reference_id=ref_id, transaction_type="bonus")
            elif action == "debit":
                wallet.debit(amount, description=f"Admin Debit: {reason}", reference_id=ref_id, transaction_type="withdrawal")
            else:
                return Response({"error": "action must be 'credit' or 'debit'"}, status=status.HTTP_400_BAD_REQUEST)
        except ValueError as err:
            return Response({"error": str(err)}, status=status.HTTP_400_BAD_REQUEST)

        return Response({
            "message": f"Wallet {action}ed ₹{amount:.2f}",
            "balance": str(wallet.balance),
            "new_balance": str(wallet.balance),
            "reference_id": ref_id,
        })


class AdminWithdrawalListView(APIView):
    """Admin endpoint to view all player withdrawal requests."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        status_filter = request.query_params.get("status", "").strip()
        qs = Transaction.objects.filter(transaction_type="withdrawal")
        if status_filter:
            qs = qs.filter(status=status_filter)

        search = request.query_params.get("search", "").strip()
        if search:
            qs = qs.filter(
                user__email__icontains=search
            ) | qs.filter(
                user__username__icontains=search
            ) | qs.filter(
                reference_id__icontains=search
            )

        qs = qs.order_by("-created_at")
        paginator = TransactionPagination()
        page = paginator.paginate_queryset(qs, request, view=self)
        serializer = TransactionSerializer(page, many=True)
        return paginator.get_paginated_response(serializer.data)


class AdminWithdrawalApproveView(APIView):
    """Admin approves a withdrawal request (payout sent via UPI/Bank)."""
    permission_classes = [IsAdminUser]

    def post(self, request, txn_id):
        try:
            txn = Transaction.objects.get(id=txn_id, transaction_type="withdrawal")
        except Transaction.DoesNotExist:
            return Response({"error": "Withdrawal transaction not found."}, status=status.HTTP_404_NOT_FOUND)

        if txn.status == "success":
            return Response({"error": "This withdrawal is already approved & completed."}, status=status.HTTP_400_BAD_REQUEST)

        txn.status = "success"
        txn.description = f"Completed Payout (Ref: {txn.reference_id})"
        txn.save(update_fields=["status", "description"])

        return Response({
            "message": f"Successfully marked withdrawal of ₹{txn.amount:.2f} for {txn.user.username} as completed.",
            "status": "success",
        }, status=status.HTTP_200_OK)


class AdminWithdrawalRejectView(APIView):
    """Admin rejects a withdrawal request and refunds amount back to player wallet."""
    permission_classes = [IsAdminUser]

    def post(self, request, txn_id):
        try:
            txn = Transaction.objects.get(id=txn_id, transaction_type="withdrawal")
        except Transaction.DoesNotExist:
            return Response({"error": "Withdrawal transaction not found."}, status=status.HTTP_404_NOT_FOUND)

        if txn.status == "success":
            return Response({"error": "Cannot reject an already completed withdrawal."}, status=status.HTTP_400_BAD_REQUEST)
        if txn.status == "failed":
            return Response({"error": "This withdrawal has already been rejected."}, status=status.HTTP_400_BAD_REQUEST)

        reason = request.data.get("reason", "UPI/Bank details invalid or rejected by Admin")

        with transaction.atomic():
            wallet = Wallet.objects.select_for_update().get(user=txn.user)
            wallet.balance += txn.amount
            wallet.save(update_fields=["balance", "updated_at"])

            txn.status = "failed"
            txn.balance_after = wallet.balance
            txn.description = f"Rejected & Refunded: {reason} (Ref: {txn.reference_id})"
            txn.save(update_fields=["status", "balance_after", "description"])

        return Response({
            "message": f"Withdrawal request #{txn.id} rejected. ₹{txn.amount:.2f} refunded to {txn.user.username}'s wallet.",
            "status": "failed",
            "refunded_balance": str(wallet.balance),
        }, status=status.HTTP_200_OK)
