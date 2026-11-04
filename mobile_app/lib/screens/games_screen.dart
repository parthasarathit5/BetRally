import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'mines_game_screen.dart';
import 'chess_game_screen.dart';
import 'cricket_game_screen.dart';
import 'carrom_game_screen.dart';
import 'galaxy_strike_screen.dart';
import 'moto_rush_screen.dart';
import 'tower_defense_screen.dart';
import 'puzzle_2048_screen.dart';
import 'zombie_survival_screen.dart';
import 'football_game_screen.dart';
import 'aviator_game_screen.dart';
import 'card_games_screens.dart';
import 'arcade_games_screens.dart';

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
    {'id': 'board', 'label': 'Board & Cards'},
    {'id': 'sports', 'label': 'Sports'},
    {'id': 'casual', 'label': 'Arcade'},
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
      case 'stairs': return Icons.stairs;
      case 'local_florist': return Icons.local_florist;
      case 'flash_on': return Icons.flash_on;
      case 'my_location': return Icons.my_location;
      case 'track_changes': return Icons.track_changes;
      case 'two_wheeler': return Icons.two_wheeler;
      case 'shield': return Icons.shield;
      case 'grid_view': return Icons.grid_view;
      case 'security': return Icons.security;
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
    return double.tryParse(game['entry_fee']?.toString() ?? '20') ?? 20.0;
  }

  void launchGame(Map<String, dynamic> game) {
    final slug = game['slug']?.toString() ?? '';
    final name = game['name']?.toString() ?? 'Game';
    final entryFee = getEntryFee(game);

    // Rule: If wallet money < entry fee, player CANNOT play. Redirects to Admin WhatsApp!
    if (userBalance < entryFee) {
      showInsufficientBalanceDialog(name, entryFee);
      return;
    }

    Widget screen;
    switch (slug) {
      case 'mines':
        screen = MinesGameScreen(onWalletChanged: () {
          loadGamesAndWallet();
          widget.onWalletChanged?.call();
        });
        break;
      case 'chess':
        screen = ChessGameScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'cricket':
        screen = CricketGameScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'carrom':
        screen = CarromGameScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'galaxy-strike':
        screen = GalaxyStrikeScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'moto-rush':
        screen = MotoRushScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'tower-defense':
        screen = TowerDefenseScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'puzzle-2048':
        screen = Puzzle2048Screen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'zombie-survival':
        screen = ZombieSurvivalScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'football':
        screen = FootballGameScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'ludo':
        screen = SpeedLudoScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'aviator':
        screen = AviatorGameScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'blackjack':
        screen = BlackjackGameScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'roulette':
        screen = RouletteScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'call-break':
        screen = CallBreakScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'snakes-ladders':
        screen = SnakesLaddersScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'fruit-slice':
        screen = FruitSliceScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'knife-hit':
        screen = KnifeHitScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'archery':
        screen = ArcheryScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      case 'bottle-shoot':
        screen = BottleShootScreen(userBalance: userBalance, entryFee: entryFee, onGameFinished: onGameReturned);
        break;
      default:
        screen = MinesGameScreen(onWalletChanged: () {
          loadGamesAndWallet();
          widget.onWalletChanged?.call();
        });
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

  void showInsufficientBalanceDialog(String gameName, double requiredFee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: pink, size: 28),
            SizedBox(width: 10),
            Text('Insufficient Balance', style: TextStyle(color: pink, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need at least ₹${requiredFee.toStringAsFixed(2)} to play $gameName.',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Your current balance: ₹${userBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: green.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Player wallet credits are securely handled by Admin. Contact Admin on WhatsApp to deposit funds instantly.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.black),
            icon: const Icon(Icons.chat),
            label: const Text('ADD MONEY VIA WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final msg = Uri.encodeComponent(
                'Hello Admin (+91 7780383832), I need funds in my BetRally/WinPlay wallet to play $gameName. Please credit my wallet.',
              );
              final cleanPhone = adminWhatsApp.replaceAll('+', '').replaceAll(' ', '');
              final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
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
      appBar: AppBar(
        title: const Text(
          'BETRALLY GAMES (20)',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: teal.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: teal, size: 16),
                const SizedBox(width: 6),
                Text('₹${userBalance.toStringAsFixed(2)}', style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 13)),
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
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search 20 real games...',
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
                    selectedColor: teal.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      color: isSelected ? teal : Colors.white60,
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

          // Games Grid (20 Real Games)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: teal))
                : filteredGames.isEmpty
                    ? const Center(child: Text('No games found.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.88,
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
                            onTap: () => launchGame(game),
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
                                      Text(
                                        '₹${fee.toStringAsFixed(0)}',
                                        style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 11),
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
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                      color: teal,
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
                      ),
          ),
        ],
      ),
    );
  }
}
