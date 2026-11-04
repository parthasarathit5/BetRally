from django.contrib import admin
from .models import Game, MinesGameSession, GamePlayRecord


@admin.register(Game)
class GameAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "category", "entry_fee", "is_active", "sort_order", "created_at")
    list_filter = ("category", "is_active")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}


@admin.register(MinesGameSession)
class MinesGameSessionAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "bet_amount",
        "mine_count",
        "current_multiplier",
        "payout",
        "status",
        "created_at",
    )
    list_filter = ("status", "mine_count", "created_at")
    search_fields = ("user__email",)


@admin.register(GamePlayRecord)
class GamePlayRecordAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "user",
        "game_name",
        "result",
        "bet_amount",
        "payout_amount",
        "reference_id",
        "created_at",
    )
    list_filter = ("result", "game_slug", "created_at")
    search_fields = ("user__username", "user__email", "game_name", "reference_id")
