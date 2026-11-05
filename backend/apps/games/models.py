from decimal import Decimal
from django.conf import settings
from django.db import models


class Game(models.Model):
    CATEGORY_CHOICES = [
        ("sports", "Sports"),
        ("board", "Board"),
        ("casual", "Casual"),
    ]

    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=120, unique=True)
    description = models.TextField(blank=True)
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        default="casual",
    )
    icon_name = models.CharField(
        max_length=50,
        default="sports_esports",
    )
    is_active = models.BooleanField(default=True)
    sort_order = models.PositiveIntegerField(default=0)
    entry_fee = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal("10.00"),
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["sort_order", "name"]

    def __str__(self):
        return self.name


class MinesGameSession(models.Model):
    STATUS_CHOICES = [
        ("in_progress", "In Progress"),
        ("cashed_out", "Cashed Out"),
        ("busted", "Busted"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="mines_sessions",
    )
    bet_amount = models.DecimalField(max_digits=10, decimal_places=2)
    mine_count = models.PositiveSmallIntegerField(default=3)
    grid_size = models.PositiveSmallIntegerField(default=25)
    mine_locations = models.JSONField(default=list)  # Hidden list of mine indices e.g. [2, 7, 18]
    revealed_tiles = models.JSONField(default=list)  # Safe indices user clicked
    current_multiplier = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=Decimal("1.00"),
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default="in_progress",
    )
    payout = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal("0.00"),
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Mines Session #{self.id} - {self.user.email} - Bet ₹{self.bet_amount} ({self.status})"


class GamePlayRecord(models.Model):
    RESULT_CHOICES = [
        ("win", "Win"),
        ("loss", "Loss"),
        ("draw", "Draw"),
        ("cashed_out", "Cashed Out"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="game_records",
    )
    game_name = models.CharField(max_length=100)
    game_slug = models.CharField(max_length=120)
    bet_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("0.00"))
    payout_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal("0.00"))
    balance_before = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    balance_after = models.DecimalField(max_digits=12, decimal_places=2, default=Decimal("0.00"))
    result = models.CharField(max_length=20, choices=RESULT_CHOICES)
    score_details = models.JSONField(default=dict, blank=True)
    reference_id = models.CharField(max_length=64, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} - {self.game_name} ({self.result.upper()}) Bet: ₹{self.bet_amount} Payout: ₹{self.payout_amount}"

