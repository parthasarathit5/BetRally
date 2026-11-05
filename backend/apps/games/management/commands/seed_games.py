from decimal import Decimal
from django.core.management.base import BaseCommand
from apps.games.models import Game
from apps.virtual_wallet.models import Wallet


class Command(BaseCommand):
    help = "Seed 20 premier real-money betting games into WinPlay / BetRally catalog"

    def handle(self, *args, **options):
        # 1. Clear old games to replace with premier betting catalog
        Game.objects.all().delete()
        self.stdout.write(self.style.WARNING("Cleared existing catalog to install premier betting games."))

        # 2. 20 High-Stakes Premier Real-Money Betting Games (RajBet, Rummy, WinZO, Zupee style)
        games = [
            {
                "name": "Blitz Chess Pro",
                "slug": "chess",
                "description": "Tactical 10-minute real chess battle! Checkmate king to claim victory pot!",
                "category": "board",
                "icon_name": "grid_on",
                "entry_fee": Decimal("50.00"),
                "sort_order": 1,
            },
            {
                "name": "RajBet Aviator",
                "slug": "aviator",
                "description": "The #1 Crash game! Watch rocket multiplier rise up to 100x+. Cash out before the crash to win big!",
                "category": "casual",
                "icon_name": "rocket_launch",
                "entry_fee": Decimal("50.00"),
                "sort_order": 2,
            },
            {
                "name": "Points Rummy (13 Card)",
                "slug": "rummy",
                "description": "Authentic Indian 13-Card Rummy! Form pure sequence, sets, discard cards and declare to beat opponent!",
                "category": "board",
                "icon_name": "style",
                "entry_fee": Decimal("50.00"),
                "sort_order": 2,
            },
            {
                "name": "Dragon vs Tiger Live",
                "slug": "dragon-tiger",
                "description": "High-stakes live casino showdown! Bet on Dragon, Tiger or Tie. Highest card takes the pot!",
                "category": "casual",
                "icon_name": "casino",
                "entry_fee": Decimal("50.00"),
                "sort_order": 3,
            },
            {
                "name": "Teen Patti Cash Pro",
                "slug": "teen-patti",
                "description": "Pure Indian 3-Patti poker! Blind, Chaal, Pack, Showdown. Form Trail, Pure Sequence or Color to win!",
                "category": "board",
                "icon_name": "style",
                "entry_fee": Decimal("50.00"),
                "sort_order": 4,
            },
            {
                "name": "Fruit Blade Ninja",
                "slug": "fruit-cutter",
                "description": "Play Store style fruit slicing battle! Swipe blade across flying fruits, trigger combos, avoid bombs and beat opponent score!",
                "category": "casual",
                "icon_name": "local_florist",
                "entry_fee": Decimal("25.00"),
                "sort_order": 5,
            },
            {
                "name": "Speed Ludo Clash",
                "slug": "speed-ludo",
                "description": "Zupee-style 2-player rapid token race! Roll dice, capture opponent tokens (+50 bonus), score maximum points to win!",
                "category": "board",
                "icon_name": "casino",
                "entry_fee": Decimal("30.00"),
                "sort_order": 6,
            },
            {
                "name": "7 Up 7 Down Royale",
                "slug": "seven-up-down",
                "description": "Premier Indian 2-dice betting! Bet on 7 Down (2-6), Lucky 7 (pays 3x!), or 7 Up (8-12). Dice roll determines payout!",
                "category": "casual",
                "icon_name": "casino",
                "entry_fee": Decimal("40.00"),
                "sort_order": 7,
            },
            {
                "name": "Andar Bahar Deluxe",
                "slug": "andar-bahar",
                "description": "Traditional Indian card betting! Dealer opens Joker card; bet whether matching card lands on Andar or Bahar!",
                "category": "board",
                "icon_name": "style",
                "entry_fee": Decimal("40.00"),
                "sort_order": 8,
            },
            {
                "name": "Cricket Super Over",
                "slug": "cricket-over",
                "description": "High-pressure 1-Over (6 balls) cricket betting! Time your shots, smash 4s & 6s, and chase opponent target!",
                "category": "sports",
                "icon_name": "sports_cricket",
                "entry_fee": Decimal("50.00"),
                "sort_order": 9,
            },
            {
                "name": "Jhandi Munda King",
                "slug": "jhandi-munda",
                "description": "Iconic 6-symbol street betting game! Bet on Spade, Heart, Club, Diamond, Flag or Face; win up to 6x matching symbols!",
                "category": "casual",
                "icon_name": "casino",
                "entry_fee": Decimal("30.00"),
                "sort_order": 10,
            },
            {
                "name": "Mines High Roller",
                "slug": "mines",
                "description": "5x5 minefield betting! Reveal hidden gems to multiply your stake. Cash out anytime before hitting a mine!",
                "category": "casual",
                "icon_name": "diamond",
                "entry_fee": Decimal("50.00"),
                "sort_order": 11,
            },
            {
                "name": "Roulette Royale 36",
                "slug": "roulette-royale",
                "description": "European 37-pocket roulette wheel! Bet on Red/Black, Even/Odd, Columns, or single straight-up numbers for 35:1 payout!",
                "category": "casual",
                "icon_name": "trip_origin",
                "entry_fee": Decimal("50.00"),
                "sort_order": 12,
            },
            {
                "name": "Blackjack 21 VIP",
                "slug": "blackjack-vip",
                "description": "Vegas VIP 21 against the Dealer! Hit, Stand, Double Down, Insurance. Beat dealer without going over 21!",
                "category": "board",
                "icon_name": "style",
                "entry_fee": Decimal("50.00"),
                "sort_order": 13,
            },
            {
                "name": "Carrom Clash Pro",
                "slug": "carrom-clash",
                "description": "Realistic 2-player carrom board physics! Strike white & black pucks, pocket the Red Queen, beat opponent score!",
                "category": "board",
                "icon_name": "circle_outlined",
                "entry_fee": Decimal("40.00"),
                "sort_order": 14,
            },
            {
                "name": "Mega Spin Wheel",
                "slug": "spin-win",
                "description": "Spin the cash multiplier wheel! Land on 2x, 5x, 10x, 25x or the Mega 50x Jackpot segment!",
                "category": "casual",
                "icon_name": "trip_origin",
                "entry_fee": Decimal("25.00"),
                "sort_order": 15,
            },
            {
                "name": "Penalty Shootout Cup",
                "slug": "penalty-kick",
                "description": "5-kick soccer penalty shootout! Aim corners, curve past the goalkeeper, stop opponent kicks to take the trophy!",
                "category": "sports",
                "icon_name": "sports_soccer",
                "entry_fee": Decimal("30.00"),
                "sort_order": 16,
            },
            {
                "name": "8-Ball Pool Showdown",
                "slug": "pool-clash",
                "description": "Premier cue billiards! Aim cue stick, set power spin, sink solids or stripes, pocket 8-ball to win!",
                "category": "sports",
                "icon_name": "sports_baseball",
                "entry_fee": Decimal("50.00"),
                "sort_order": 17,
            },
            {
                "name": "Knife Master Bounty",
                "slug": "knife-master",
                "description": "Precision knife target throwing! Throw blades into spinning wood block, avoid colliding with knives, slice bonus apples!",
                "category": "casual",
                "icon_name": "flash_on",
                "entry_fee": Decimal("25.00"),
                "sort_order": 19,
            },
            {
                "name": "Call Break Spades Pro",
                "slug": "call-break-pro",
                "description": "Strategic 4-hand trick taking card battle! Bid your hand count, lead trump spades, win required tricks for the pot!",
                "category": "board",
                "icon_name": "style",
                "entry_fee": Decimal("40.00"),
                "sort_order": 20,
            },
        ]

        created_count = 0
        for g_data in games:
            game = Game.objects.create(
                name=g_data["name"],
                slug=g_data["slug"],
                description=g_data["description"],
                category=g_data["category"],
                icon_name=g_data["icon_name"],
                entry_fee=g_data["entry_fee"],
                sort_order=g_data["sort_order"],
                is_active=True,
            )
            created_count += 1
            self.stdout.write(f"  [+] #{created_count}: {game.name} ({game.slug}) - Fee: INR {game.entry_fee}")

        self.stdout.write(self.style.SUCCESS(f"\nSuccessfully seeded {created_count} premier betting games into database!"))
