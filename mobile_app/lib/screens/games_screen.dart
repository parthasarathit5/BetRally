import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/betting_match_dialog.dart';
import 'fruit_blade_ninja_screen.dart';
import 'indian_betting_screens.dart';
import 'more_betting_screens.dart';
import 'mines_game_screen.dart';
import 'aviator_game_screen.dart';
import 'card_games_screens.dart' hide AndarBaharScreen;
import 'arcade_games_screens.dart';
import 'carrom_game_screen.dart';
import 'football_game_screen.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
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
    {'id': 'all', 'label': 'All Games (20)'},
    {'id': 'board', 'label': 'Cards & Rummy'},
    {'id': 'sports', 'label': 'Cricket & Sports'},
    {'id': 'casual', 'label': 'Live Betting'},
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
        gamesList = games;
        userBalance = double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
        adminWhatsApp = wallet['admin_whatsapp']?.toString() ?? adminWhatsApp;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
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
      default: return Icons.sports_esports;
    }
  }

  Color getCategoryColor(String? cat) {
    switch (cat) {
      case 'casual': return pink;
      case 'sports': return teal;
      case 'board': return purple;
      default: return blue;
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
      case 'cricket-over':
      case 'cricket':
        screen = CricketSuperOverScreen(
          userBalance: userBalance,
          betAmount: betAmount,
          opponent: opponent,
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
      case 'roulette-royale':
      case 'roulette':
      case 'spin-win':
        screen = RouletteScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;
      case 'blackjack-vip':
      case 'blackjack':
        screen = BlackjackGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;
      case 'carrom-clash':
      case 'carrom':
      case 'pool-clash':
        screen = CarromGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;
      case 'call-break-pro':
      case 'call-break':
        screen = CallBreakScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;
      case 'penalty-kick':
      case 'football':
        screen = FootballGameScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;
      case 'knife-master':
      case 'knife-hit':
        screen = KnifeHitScreen(
          userBalance: userBalance,
          entryFee: betAmount,
          onGameFinished: onGameReturned,
        );
        break;
      case 'archery-duel':
      case 'archery':
        screen = ArcheryScreen(
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
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: const Text(
          'BETRALLY CASINO (20)',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: gold, size: 16),
                const SizedBox(width: 6),
                Text('₹${userBalance.toStringAsFixed(2)}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: teal),
            onPressed: loadGamesAndWallet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Live Ticker Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: purple.withValues(alpha: 0.15),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Real-Money Stakes • 2-Player Matchmaking • Forfeit on Exit • 100% Instant Escrow',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search 20 real betting games...',
                prefixIcon: const Icon(Icons.search, color: teal),
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Categories Tabs
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, i) {
                final cat = categories[i];
                final isSelected = selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSelected,
                    selectedColor: gold.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: isSelected ? gold : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => selectedCategory = cat['id']!),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Games Grid (20 Real Betting Games)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: gold))
                : filteredGames.isEmpty
                    ? const Center(child: Text('No games found.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.86,
                        ),
                        itemCount: filteredGames.length,
                        itemBuilder: (context, index) {
                          final game = Map<String, dynamic>.from(filteredGames[index] as Map);
                          final name = game['name']?.toString() ?? 'Game';
                          final cat = game['category']?.toString() ?? 'casual';
                          final desc = game['description']?.toString() ?? '';
                          final color = getCategoryColor(cat);
                          final icon = getIcon(game['icon_name']?.toString());
                          final fee = getEntryFee(game);

                          return InkWell(
                            onTap: () => openBettingDialog(game),
                            borderRadius: BorderRadius.circular(20),
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
                                      'SELECT BET ➔',
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
                      ),
          ),
        ],
      ),
    );
  }
}
