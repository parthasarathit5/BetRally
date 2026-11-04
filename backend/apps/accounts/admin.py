from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as DjangoUserAdmin

from .models import PasswordResetOTP, User


@admin.register(User)
class UserAdmin(DjangoUserAdmin):
    list_display = (
        "username",
        "email",
        "phone_number",
        "is_staff",
        "is_active",
        "date_joined",
    )
    list_filter = ("is_staff", "is_superuser", "is_active")
    search_fields = ("username", "email", "phone_number")
    ordering = ("-date_joined",)


@admin.register(PasswordResetOTP)
class PasswordResetOTPAdmin(admin.ModelAdmin):
    list_display = ("user", "created_at", "expires_at", "attempts", "is_used")
    list_filter = ("is_used", "created_at")
    search_fields = ("user__email",)
    readonly_fields = (
        "user",
        "otp_hash",
        "expires_at",
        "created_at",
        "attempts",
        "is_used",
        "reset_token_hash",
        "reset_token_expires_at",
    )

    def has_add_permission(self, request):
        return False
