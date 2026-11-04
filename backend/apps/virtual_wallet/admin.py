from django.contrib import admin
from .models import Wallet


@admin.register(Wallet)
class WalletAdmin(admin.ModelAdmin):
    list_display = ("user", "balance", "currency", "is_locked", "created_at", "updated_at")
    search_fields = ("user__email", "user__username")
    list_filter = ("is_locked", "currency")
