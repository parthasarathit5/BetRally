
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class User(AbstractUser):

    email = models.EmailField(
        unique=True,
        db_index=True
    )

    phone_number = models.CharField(
        max_length=20,
        blank=True
    )

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    def __str__(self):
        return self.email
class PasswordResetOTP(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="password_reset_otps",
    )

    otp_hash = models.CharField(max_length=256)

    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    attempts = models.PositiveSmallIntegerField(default=0)
    is_used = models.BooleanField(default=False)

    reset_token_hash = models.CharField(
        max_length=256,
        blank=True,
    )

    reset_token_expires_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    def is_expired(self):
        return timezone.now() >= self.expires_at

    def __str__(self):
        return f"Password reset for {self.user.email}"
