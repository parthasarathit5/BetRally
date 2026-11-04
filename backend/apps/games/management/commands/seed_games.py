from decimal import Decimal
from django.core.management.base import BaseCommand
from apps.games.models import Game
from apps.accounts.models import User
from apps.virtual_wallet.models import Wallet


class Command(BaseCommand):
    help = "Seed 20 real playable games into WinPlay / BetRally and ensure wallets"

    def handle(self, *args, **options):
        # 1. Remove unwanted games per user requirement
        removed_slugs = ["rummy", "teen-patti", "poker", "pool", "andar-bahar"]
        deleted_count, _ = Game.objects.filter(slug__in=removed_slugs).delete()
        if deleted_count > 0:
            self.stdout.write(self.style.WARNING(f"Removed {deleted_count} unwanted card/pool games from catalog."))

        # 2. 20 High-Quality Real Games (Deep 10-Min Mechanics, Visual Dashboards, Strict Entry Fees)
        games = [
            {
                "name": "Mines Arcade",
                "slug": "mines",
                "description": "Uncover glowing gems and avoid hidden mines to multiply coins. Cash out anytime!",
                "category": "casual",
                "icon_name": "diamond",
                "entry_fee": Decimal("50.00"),
                "sort_order": 1,
            },
            {
                "name": "Blitz Chess",
                "slug": "chess",
                "description": "Tactical 10-minute chess battle against grandmaster AI. Checkmate king to claim victory!",
                "category": "board",
                "icon_name": "grid_on",
                "entry_fee": Decimal("50.00"),
                "sort_order": 2,
            },
            {
                "name": "Cricket Clash",
                "slug": "cricket",
                "description": "T20 batting championship. Time your shots, smash sixes and chase down the target!",
                "category": "sports",
                "icon_name": "sports_cricket",
                "entry_fee": Decimal("50.00"),
                "sort_order": 3,
            },
            {
                "name": "Carrom King",
                "slug": "carrom",
                "description": "Realistic carrom board physics. Aim striker, pot coins and cover the Red Queen!",
                "category": "board",
                "icon_name": "circle_outlined",
                "entry_fee": Decimal("40.00"),
                "sort_order": 4,
            },
            {
                "name": "Galaxy Strike",
                "slug": "galaxy-strike",
                "description": "Epic 10-minute space arcade shooter! Pilot fighter ship, blast alien fleets and destroy mothership bosses!",
                "category": "casual",
                "icon_name": "rocket_launch",
                "entry_fee": Decimal("50.00"),
                "sort_order": 5,
            },
            {
                "name": "Moto Rush",
                "slug": "moto-rush",
                "description": "High-octane highway superbike racer. Weave through traffic, activate nitro boost and survive 10 minutes!",
                "category": "sports",
                "icon_name": "two_wheeler",
                "entry_fee": Decimal("40.00"),
                "sort_order": 6,
            },
            {
                "name": "Kingdom Tower Defense",
                "slug": "tower-defense",
                "description": "Strategic 10-minute castle defense. Build Archer, Cannon & Magic towers to crush 10 enemy invasion waves!",
                "category": "board",
                "icon_name": "shield",
                "entry_fee": Decimal("50.00"),
                "sort_order": 7,
            },
            {
                "name": "Speed Football",
                "slug": "football",
                "description": "Penalty shootout showdown. Pick your corner, beat the keeper and score 5 penalties!",
                "category": "sports",
                "icon_name": "sports_soccer",
                "entry_fee": Decimal("40.00"),
                "sort_order": 8,
            },
            {
                "name": "Speed Ludo",
                "slug": "ludo",
                "description": "Rapid dice roll and token race. Capture opponent tokens and reach home first!",
                "category": "board",
                "icon_name": "casino",
                "entry_fee": Decimal("30.00"),
                "sort_order": 9,
            },
            {
                "name": "2048 Mega Blitz",
                "slug": "puzzle-2048",
                "description": "Mind-bending numerical strategy puzzle. Merge tiles (2->4->8...2048), trigger combos and beat high score!",
                "category": "casual",
                "icon_name": "grid_view",
                "entry_fee": Decimal("30.00"),
                "sort_order": 10,
            },
            {
                "name": "Aviator Crash",
                "slug": "aviator",
                "description": "Rocket climb multiplier. Watch multiplier rise and jump out before it crashes!",
                "category": "casual",
                "icon_name": "rocket",
                "entry_fee": Decimal("50.00"),
                "sort_order": 11,
            },
            {
                "name": "Zombie Outbreak",
                "slug": "zombie-survival",
                "description": "Intense 10-minute commando survival arena. Shoot undead hordes, scavenge ammo and survive to extract!",
                "category": "casual",
                "icon_name": "security",
                "entry_fee": Decimal("50.00"),
                "sort_order": 12,
            },
            {
                "name": "Blackjack 21",
                "slug": "blackjack",
                "description": "Beat dealer's hand without busting over 21. Hit, Stand, or Double down!",
                "category": "board",
                "icon_name": "style",
                "entry_fee": Decimal("50.00"),
                "sort_order": 13,
            },
            {
                "name": "European Roulette",
                "slug": "roulette",
                "description": "Spin the wheel. Place bets on Red/Black, Even/Odd, or single lucky numbers!",
                "category": "casual",
                "icon_name": "trip_origin",
                "entry_fee": Decimal("30.00"),
                "sort_order": 14,
            },
            {
                "name": "Call Break",
                "slug": "call-break",
                "description": "Strategic 4-player trick taking. Spades are trumps; bid your hand and win tricks!",
                "category": "board",
                "icon_name": "style",
                "entry_fee": Decimal("40.00"),
                "sort_order": 15,
            },
            {
                "name": "Snakes & Ladders",
                "slug": "snakes-ladders",
                "description": "Classic 100-tile race. Climb ladders, dodge snakes, and reach tile 100 first!",
                "category": "board",
                "icon_name": "stairs",
                "entry_fee": Decimal("30.00"),
                "sort_order": 16,
            },
            {
                "name": "Fruit Slice",
                "slug": "fruit-slice",
                "description": "Fast-paced arcade action. Slice watermelons, oranges and pineapples; avoid bombs!",
                "category": "casual",
                "icon_name": "local_florist",
                "entry_fee": Decimal("25.00"),
                "sort_order": 17,
            },
            {
                "name": "Knife Hit",
                "slug": "knife-hit",
                "description": "Throw knives into rotating target. Do not hit existing knives. Clear all stages!",
                "category": "casual",
                "icon_name": "flash_on",
                "entry_fee": Decimal("25.00"),
                "sort_order": 18,
            },
            {
                "name": "Archery Master",
                "slug": "archery",
                "description": "Olympic bow shooting. Account for wind speed and hit the yellow 10-ring bullseye!",
                "category": "sports",
                "icon_name": "my_location",
                "entry_fee": Decimal("30.00"),
                "sort_order": 19,
            },
            {
                "name": "Bottle Shoot",
                "slug": "bottle-shoot",
                "description": "Quick trigger target shooter. Shatter all moving bottles before the timer expires!",
                "category": "casual",
                "icon_name": "track_changes",
                "entry_fee": Decimal("30.00"),
                "sort_order": 20,
            },
        ]

        created_count = 0
        updated_count = 0
        for g_data in games:
            game, created = Game.objects.get_or_create(
                slug=g_data["slug"],
                defaults=g_data,
            )
            if created:
                created_count += 1
            else:
                for k, v in g_data.items():
                    setattr(game, k, v)
                game.is_active = True
                game.save()
                updated_count += 1

        wallet_count = 0
        for user in User.objects.all():
            w, c = Wallet.objects.get_or_create(
                user=user,
                defaults={"balance": Decimal("0.00")},
            )
            if c:
                wallet_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Seeding complete! {created_count} new games created, {updated_count} games updated, {wallet_count} new wallets verified in Supabase."
            )
        )
