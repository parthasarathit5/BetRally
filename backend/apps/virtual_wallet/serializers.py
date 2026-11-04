from decimal import Decimal
from rest_framework import serializers
from .models import Wallet
from apps.transactions.models import Transaction


class TransactionSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source="user.email", read_only=True)

    class Meta:
        model = Transaction
        fields = [
            "id",
            "user_email",
            "amount",
            "balance_after",
            "transaction_type",
            "status",
            "description",
            "reference_id",
            "created_at",
        ]


class WalletSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source="user.email", read_only=True)
    username = serializers.CharField(source="user.username", read_only=True)

    class Meta:
        model = Wallet
        fields = [
            "id",
            "user_email",
            "username",
            "balance",
            "currency",
            "is_locked",
            "created_at",
            "updated_at",
        ]


class DepositRequestSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal("1.00"))
    payment_method = serializers.CharField(max_length=50, default="UPI / Demo")


class WithdrawRequestSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=10, decimal_places=2, min_value=Decimal("10.00"))
    account_info = serializers.CharField(max_length=120, required=False, default="UPI")
