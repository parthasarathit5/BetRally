import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/betting_match_dialog.dart';
import 'chess_game_screen.dart';
import 'fruit_blade_ninja_screen.dart';
import 'cricket_game_screen.dart';
import 'carrom_game_screen.dart';
import 'football_game_screen.dart';
import 'moto_rush_screen.dart';
import 'galaxy_strike_screen.dart';
import 'zombie_survival_screen.dart';
import 'tower_defense_screen.dart';
import 'puzzle_2048_screen.dart';
import 'indian_betting_screens.dart';
import 'more_betting_screens.dart';
import 'mines_game_screen.dart';
import 'aviator_game_screen.dart';
import 'card_games_screens.dart' hide AndarBaharScreen;
import 'arcade_games_screens.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const surfaceLight = Color(0xFF222649);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const blue = Color(0xFF398BFF);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

class GamesScreen extends StatefulWidget {
  final VoidCallback? onWalletChanged;
  const GamesScreen({super.key, this.onWalletChanged});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String selectedCategory = 'all';
  String searchQuery = '';
  List<dynamic> gamesList = [];
  bool isLoading = true;
  double userBalance = 0.0;
  String adminWhatsApp = '+917780383832';

  final categories = [
    {'id': 'all', 'label': 'All Games (20+)'},
    {'id': 'board', 'label': 'Chess & Board'},
    {'id': 'cards', 'label': 'Rummy & Cards'},
    {'id': 'sports', 'label': 'Cricket & Sports'},
    {'id': 'action', 'label': 'Arcade & Action'},
    {'id': 'casual', 'label': 'Live Betting'},
  ];

  // Default fallback games in case backend/network is slow
  final List<Map<String, dynamic>> fallbackGames = [
    {
      'name': 'Blitz Chess Pro',
      'slug': 'chess',
      'category': 'board',
      'icon_name': 'circle_outlined',
      'entry_fee': 50.0,
      'description': '3-Min Blitz timer FIDE Chess match against opponent AI. Checkmate to win!',
    },
    {
      'name': 'Cricket Clash Champions',
      'slug': 'cricket',
      'category': 'sports',
      'icon_name': 'sports_cricket',
      'entry_fee': 50.0,
      'description': 'Chase down the target score against opponent bowling before 6 balls run out.',
    },
    {
      'name': 'Fruit Blade Ninja',
      'slug': 'fruit-cutter',
      'category': 'action',
      'icon_name': 'local_florist',
      'entry_fee': 25.0,
      'description': 'Slice flying fruits, dodge bombs, beat opponent score before 60s timer expires.',
    },
    {
      'name': 'Points Rummy (13 Card)',
      'slug': 'rummy',
      'category': 'cards',
      'icon_name': 'style',
      'entry_fee': 50.0,
      'description': 'Real-time 13 card meld and show against opponent. Declare first to win.',
    },
    {
      'name': 'Carrom Clash Pro',
      'slug': 'carrom',
      'category': 'board',
      'icon_name': 'sports_baseball',
      'entry_fee': 40.0,
      'description': 'Pocket white coins and cover the queen before opponent wins the board.',
    },
    {
      'name': 'Teen Patti Cash Pro',
      'slug': 'teen-patti',
      'category': 'cards',
      'icon_name': 'style',
      'entry_fee': 50.0,
      'description': 'Classic 3-card Indian poker showdown against opponent.',
    },
    {
      'name': 'Dragon vs Tiger Live',
      'slug': 'dragon-tiger',
      'category': 'casual',
      'icon_name': 'shield',
      'entry_fee': 50.0,
      'description': 'Fast-paced two-card battle. High card wins the pot.',
    },
    {
      'name': 'Andar Bahar Deluxe',
      'slug': 'andar-bahar',
      'category': 'cards',
      'icon_name': 'casino',
      'entry_fee': 40.0,
      'description': 'Bet on Andar or Bahar for matching card spot wins.',
    },
    {
      'name': 'RajBet Aviator',
      'slug': 'aviator',
      'category': 'casual',
      'icon_name': 'flight_takeoff',
      'entry_fee': 50.0,
      'description': 'Multiplier curve crash. Cash out before plane flies away!',
    },
    {
      'name': 'Mines High Roller',
      'slug': 'mines',
      'category': 'casual',
      'icon_name': 'grid_on',
      'entry_fee': 50.0,
      'description': 'Uncover gems in 5x5 minefield. Multipliers grow with each gem.',
    },
    {
      'name': 'Penalty Shootout Cup',
      'slug': 'football',
      'category': 'sports',
      'icon_name': 'sports_soccer',
      'entry_fee': 30.0,
      'description': 'Interactive penalty kicks against goalkeeper to score winning goals.',
    },
    {
      'name': 'Moto Rush Highway',
      'slug': 'moto-rush',
      'category': 'action',
      'icon_name': 'rocket_launch',
      'entry_fee': 40.0,
      'description': 'Dodge traffic at 200 km/h and reach 10 km finish line to cash out.',
    },
    {
      'name': 'Galaxy Strike Space',
      'slug': 'galaxy-strike',
      'category': 'action',
      'icon_name': 'rocket_launch',
      'entry_fee': 50.0,
      'description': 'Destroy enemy alien fleet waves before ship shields deplete.',
    },
    {
      'name': 'Zombie Arena Survival',
      'slug': 'zombie-survival',
      'category': 'action',
      'icon_name': 'whatshot',
      'entry_fee': 50.0,
      'description': 'Survive intense zombie waves to claim the jackpot bounty.',
    },
    {
      'name': 'Kingdom Tower Defense',
      'slug': 'tower-defense',
      'category': 'action',
      'icon_name': 'lock',
      'entry_fee': 50.0,
      'description': 'Tactical defense strategy to defeat incoming invader waves.',
    },
    {
      'name': 'Speed Ludo Clash',
      'slug': 'speed-ludo',
      'category': 'board',
      'icon_name': 'casino',
      'entry_fee': 30.0,
      'description': 'Fast-paced Ludo pawn race against opponent with timer.',
    },
    {
      'name': 'Blackjack 21 VIP',
      'slug': 'blackjack',
      'category': 'cards',
      'icon_name': 'style',
      'entry_fee': 50.0,
      'description': 'Beat the dealer hand to 21 without busting.',
    },
    {
      'name': 'Roulette Royale 36',
      'slug': 'roulette',
      'category': 'casual',
      'icon_name': 'album',
      'entry_fee': 50.0,
      'description': 'Spin European 3D roulette wheel with inside and outside bets.',
    },
    {
      'name': '8-Ball Pool Showdown',
      'slug': 'pool-clash',
      'category': 'sports',
      'icon_name': 'sports_baseball',
      'entry_fee': 50.0,
      'description': 'Pocket solids or stripes and sink the 8-ball before opponent.',
    },
    {
      'name': 'Archery Target Duel',
      'slug': 'archery',
      'category': 'sports',
      'icon_name': 'track_changes',
      'entry_fee': 30.0,
      'description': 'Compete in bullseye archery accuracy against opponent score.',
    },
    {
      'name': 'Knife Hit Master',
      'slug': 'knife-hit',
      'category': 'action',
      'icon_name': 'colorize',
      'entry_fee': 25.0,
      'description': 'Pin blades onto spinning timber without hitting other knives.',
    },
  ];

  @override
  void initState() {
    super.initState();
    loadGamesAndWallet();
  }

  Future<void> loadGamesAndWallet() async {
    setState(() => isLoading = true);
    try {
      final games = await ApiService.getGames();
      final wallet = await ApiService.getWallet();

      if (!mounted) return;
      setState(() {
        if (games.isNotEmpty) {
          gamesList = games;
        } else {
          gamesList = fallbackGames;
        }
        userBalance = double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
        adminWhatsApp = wallet['admin_whatsapp']?.toString() ?? adminWhatsApp;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        gamesList = fallbackGames;
        isLoading = false;
      });
    }
  }

  IconData getIcon(String? iconName) {
    switch (iconName) {
      case 'diamond': return Icons.diamond_outlined;
      case 'sports_cricket': return Icons.sports_cricket;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'grid_on': return Icons.grid_on;
      case 'circle_outlined': return Icons.circle_outlined;
      case 'style': return Icons.style;
      case 'casino': return Icons.casino;
      case 'sports_baseball': return Icons.sports_baseball;
      case 'rocket_launch': return Icons.rocket_launch;
      case 'trip_origin': return Icons.trip_origin;
      case 'local_florist': return Icons.local_florist;
      case 'flash_on': return Icons.flash_on;
      case 'track_changes': return Icons.track_changes;
      case 'flight_takeoff': return Icons.flight_takeoff;
      case 'album': return Icons.album;
      case 'shield': return Icons.shield;
      case 'whatshot': return Icons.whatshot;
      case 'lock': return Icons.lock;
      case 'colorize': return Icons.colorize;
      default: return Icons.sports_esports;
    }
  }

  Color getCategoryColor(String? cat) {
    switch (cat) {
      case 'casual': return pink;
      case 'sports': return teal;
      case 'board': return purple;
      case 'cards': return blue;
      case 'action': return gold;
      default: return purple;
    }
  }

  double getEntryFee(dynamic game) {
    return double.tryParse(game['entry_fee']?.toString() ?? '50') ?? 50.0;
  }

  void openBettingDialog(Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (ctx) => BettingMatchDialog(
        game: game,
        userBalance: userBalance,
        adminWhatsApp: adminWhatsApp,
        onMatchConfirmed: (betAmount, opponent) {
          launchMatchedGame(game, betAmount, opponent);
        },
      ),
    );
  }

  void launchMatchedGame(Map<String, dynamic> game, double betAmount, OpponentProfile opponent) {
    final slug = game['slug']?.toString() ?? '';

    Widget screen;
    switch (slug) {
      case 'chess':
        screen = ChessGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'cricket':
      case 'cricket-over':
        screen = CricketGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'fruit-cutter':
      case 'fruit-slice':
        screen = FruitBladeNinjaScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
          onGameFinished: onGameReturned,
        );
        break;

      case 'rummy':
        screen = PointsRummyScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
          onGameFinished: onGameReturned,
        );
        break;

      case 'carrom':
      case 'carrom-clash':
        screen = CarromGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'dragon-tiger':
        screen = DragonTigerScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
          onGameFinished: onGameReturned,
        );
        break;

      case 'teen-patti':
        screen = TeenPattiCashScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
          onGameFinished: onGameReturned,
        );
        break;

      case 'seven-up-down':
      case 'jhandi-munda':
        screen = SevenUpDownScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
          onGameFinished: onGameReturned,
        );
        break;

      case 'andar-bahar':
        screen = AndarBaharScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
          onGameFinished: onGameReturned,
        );
        break;

      case 'speed-ludo':
      case 'ludo':
        screen = SpeedLudoClashScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
          onGameFinished: onGameReturned,
        );
        break;

      case 'football':
      case 'penalty-kick':
        screen = FootballGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'moto-rush':
        screen = MotoRushScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'galaxy-strike':
        screen = GalaxyStrikeScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'zombie-survival':
        screen = ZombieSurvivalScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'tower-defense':
        screen = TowerDefenseScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case '2048':
      case 'puzzle-2048':
        screen = Puzzle2048Screen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'aviator':
        screen = AviatorGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'mines':
        screen = MinesGameScreen(
          onWalletChanged: onGameReturned,
        );
        break;

      case 'roulette':
      case 'roulette-royale':
      case 'spin-win':
        screen = RouletteScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'blackjack':
      case 'blackjack-vip':
        screen = BlackjackGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'pool-clash':
        screen = Pool8BallScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'call-break':
      case 'call-break-pro':
        screen = CallBreakScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'knife-hit':
      case 'knife-master':
        screen = KnifeHitScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'archery':
      case 'archery-duel':
        screen = ArcheryScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      case 'bottle-shoot':
        screen = BottleShootScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;

      default:
        screen = FruitBladeNinjaScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
          onGameFinished: onGameReturned,
        );
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((_) {
      loadGamesAndWallet();
      widget.onWalletChanged?.call();
    });
  }

  void onGameReturned() {
    loadGamesAndWallet();
    widget.onWalletChanged?.call();
  }

  void _showDepositDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: gold, size: 28),
            SizedBox(width: 10),
            Text('Deposit to Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Current Balance: ₹${userBalance.toStringAsFixed(2)}', style: const TextStyle(color: pink, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Add cash to your wallet to place bets and play matches against opponents.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat, color: green, size: 20),
                  const SizedBox(width: 8),
                  Text('Admin WhatsApp: $adminWhatsApp', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: green, foregroundColor: Colors.black),
            icon: const Icon(Icons.chat, color: Colors.black, size: 18),
            label: const Text('Add Cash on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final msg = 'Hello Admin, I want to add cash to my BetRally/Nexlyn wallet to play matches. Please credit my wallet.';
              final url = 'https://wa.me/${adminWhatsApp.replaceAll('+', '').replaceAll(' ', '')}?text=${Uri.encodeComponent(msg)}';
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = gamesList.where((g) {
      final matchCat = selectedCategory == 'all' || g['category'] == selectedCategory;
      final matchSearch = searchQuery.isEmpty ||
          (g['name']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      return matchCat && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Banner & Live Wallet Balance
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BETRALLY REAL MATCHES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: green, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text(
                            'Head-to-Head • Timed Matches • Win Cash in Wallet',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showDepositDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [purple, teal]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: purple.withValues(alpha: 0.3), blurRadius: 10),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '₹${userBalance.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.add_circle, color: gold, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search 20+ matches (Chess, Cricket, Rummy, Carrom, Fruit Ninja)...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 20),
                  filled: true,
                  fillColor: surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
            ),

            // Category Tabs
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  final isSelected = (cat['id'] == selectedCategory);

                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = cat['id']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected ? const LinearGradient(colors: [purple, pink]) : null,
                        color: isSelected ? null : surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white12,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat['label']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Games Grid
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: teal))
                  : filteredGames.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sports_esports_outlined, color: Colors.white30, size: 50),
                              const SizedBox(height: 12),
                              Text(
                                'No matches found in "$selectedCategory"',
                                style: const TextStyle(color: Colors.white60, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 900
                                ? 4
                                : (constraints.maxWidth > 600 ? 3 : 2);

                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: filteredGames.length,
                              itemBuilder: (ctx, index) {
                                final game = filteredGames[index];
                                final name = game['name'] ?? 'Game';
                                final cat = game['category'] ?? 'casual';
                                final icon = getIcon(game['icon_name']);
                                final color = getCategoryColor(cat);
                                final fee = getEntryFee(game);
                                final desc = game['description'] ?? 'Compete against an opponent in this timed match.';

                                return GestureDetector(
                                  onTap: () => openBettingDialog(game),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.12),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                cat.toUpperCase(),
                                                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: gold.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'STAKE ₹${fee.toStringAsFixed(0)}+',
                                                style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 9),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        CircleAvatar(
                                          backgroundColor: color.withValues(alpha: 0.15),
                                          radius: 22,
                                          child: Icon(icon, color: color, size: 24),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 2),
                                        Expanded(
                                          child: Text(
                                            desc,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          decoration: BoxDecoration(
                                            color: gold,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'PLAY MATCH ➔',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
