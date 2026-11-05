from decimal import Decimal
from django.conf import settings
from django.db import models, transaction


class Wallet(models.Model):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="wallet",
    )
    balance = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal("0.00"),
    )
    currency = models.CharField(max_length=10, default="INR")
    is_locked = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} Wallet - ₹{self.balance}"

    def can_afford(self, amount: Decimal) -> bool:
        return not self.is_locked and self.balance >= amount

    def credit(self, amount: Decimal, description: str = "", reference_id: str = "", transaction_type: str = "deposit"):
        from apps.transactions.models import Transaction

        if amount <= Decimal("0"):
            raise ValueError("Credit amount must be greater than zero.")

        with transaction.atomic():
            wallet = Wallet.objects.select_for_update().get(pk=self.pk)
            if wallet.is_locked:
                raise ValueError("Wallet is locked.")

            wallet.balance += amount
            wallet.save(update_fields=["balance", "updated_at"])
            self.balance = wallet.balance

            txn = Transaction.objects.create(
                user=wallet.user,
                wallet=wallet,
                amount=amount,
                balance_after=wallet.balance,
                transaction_type=transaction_type,
                status="success",
                description=description or f"Credited ₹{amount}",
                reference_id=reference_id,
            )
            return txn

    def debit(self, amount: Decimal, description: str = "", reference_id: str = "", transaction_type: str = "game_bet"):
        from apps.transactions.models import Transaction

        if amount <= Decimal("0"):
            raise ValueError("Debit amount must be greater than zero.")

        with transaction.atomic():
            wallet = Wallet.objects.select_for_update().get(pk=self.pk)
            if wallet.is_locked:
                raise ValueError("Wallet is locked.")

            if wallet.balance < amount:
                raise ValueError("Insufficient wallet balance.")

            wallet.balance -= amount
            wallet.save(update_fields=["balance", "updated_at"])
            self.balance = wallet.balance

            txn = Transaction.objects.create(
                user=wallet.user,
                wallet=wallet,
                amount=-amount,
                balance_after=wallet.balance,
                transaction_type=transaction_type,
                status="success",
                description=description or f"Debited ₹{amount}",
                reference_id=reference_id,
            )
            return txn
