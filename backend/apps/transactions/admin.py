from django.contrib import admin
from .models import Transaction


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "amount",
        "balance_after",
        "transaction_type",
        "status",
        "reference_id",
        "created_at",
    )
    list_filter = ("transaction_type", "status", "created_at")
    search_fields = ("user__email", "reference_id", "description")
    readonly_fields = ("created_at",)
