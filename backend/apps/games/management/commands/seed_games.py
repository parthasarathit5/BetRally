from decimal import Decimal
from django.core.management.base import BaseCommand
from apps.games.models import Game
from apps.accounts.models import User
from apps.virtual_wallet.models import Wallet


class Command(BaseCommand):
    help = "Seed initial WinPlay games and ensure all users have wallets"

    def handle(self, *args, **options):
        initial_games = [
            {
                "name": "Mines",
                "slug": "mines",
                "description": "Uncover gems and avoid mines to multiply your coins. Cash out anytime!",
                "category": "casual",
                "icon_name": "diamond",
                "sort_order": 1,
            },
            {
                "name": "Cricket Clash",
                "slug": "cricket",
                "description": "Fast-paced cricket batting & timing showdown. Score maximum runs!",
                "category": "sports",
                "icon_name": "sports_cricket",
                "sort_order": 2,
            },
            {
                "name": "Speed Football",
                "slug": "football",
                "description": "Score penalties and outsmart the keeper for huge multipliers.",
                "category": "sports",
                "icon_name": "sports_soccer",
                "sort_order": 3,
            },
            {
                "name": "Blitz Chess",
                "slug": "chess",
                "description": "Real-time tactical chess puzzles and competitive 1v1 duels.",
                "category": "board",
                "icon_name": "grid_on",
                "sort_order": 4,
            },
            {
                "name": "Carrom King",
                "slug": "carrom",
                "description": "Classic carrom board action. Pocket coins and cover the queen!",
                "category": "board",
                "icon_name": "circle_outlined",
                "sort_order": 5,
            },
        ]

        created_count = 0
        for g_data in initial_games:
            game, created = Game.objects.get_or_create(
                slug=g_data["slug"],
                defaults=g_data,
            )
            if created:
                created_count += 1
                self.stdout.write(self.style.SUCCESS(f"Created game: {game.name}"))
            else:
                self.stdout.write(f"Game already exists: {game.name}")

        # Ensure all existing users have a wallet with welcome bonus
        wallet_count = 0
        for user in User.objects.all():
            wallet, created = Wallet.objects.get_or_create(
                user=user,
                defaults={"balance": Decimal("100.00")},
            )
            if created:
                wallet_count += 1
                self.stdout.write(self.style.SUCCESS(f"Created INR 100 wallet for: {user.email}"))

        self.stdout.write(self.style.SUCCESS(f"Seeding complete! {created_count} games added, {wallet_count} wallets created."))
