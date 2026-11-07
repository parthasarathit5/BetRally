import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/provider_games_service.dart';
import '../widgets/provider_game_launcher.dart';
import 'chess_game_screen.dart';

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
  double userBalance = 0.0;
  bool isLoading = true;
  String adminWhatsApp = '+917780383832';

  @override
  void initState() {
    super.initState();
    _loadUserBalance();
  }

  Future<void> _loadUserBalance() async {
    setState(() => isLoading = true);
    try {
      final wallet = await ApiService.getWallet();
      if (!mounted) return;
      setState(() {
        userBalance = double.tryParse(wallet['balance']?.toString() ?? '0') ?? 0.0;
        adminWhatsApp = wallet['admin_whatsapp']?.toString() ?? adminWhatsApp;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'flash_on': return Icons.flash_on;
      case 'local_florist': return Icons.local_florist;
      case 'cake': return Icons.cake;
      case 'lock': return Icons.lock;
      case 'pets': return Icons.pets;
      case 'grid_view': return Icons.grid_view;
      case 'radio_button_checked': return Icons.radio_button_checked;
      case 'album': return Icons.album;
      case 'trip_origin': return Icons.trip_origin;
      case 'stars': return Icons.stars;
      case 'sailing': return Icons.sailing;
      case 'water': return Icons.water;
      case 'waves': return Icons.waves;
      case 'style': return Icons.style;
      case 'casino': return Icons.casino;
      case 'credit_card': return Icons.credit_card;
      case 'tag': return Icons.tag;
      case 'apps': return Icons.apps;
      case 'sports_baseball': return Icons.sports_baseball;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports_tennis': return Icons.sports_tennis;
      case 'sports_cricket': return Icons.sports_cricket;
      case 'track_changes': return Icons.track_changes;
      case 'flight_takeoff': return Icons.flight_takeoff;
      case 'rocket_launch': return Icons.rocket_launch;
      case 'trending_up': return Icons.trending_up;
      case 'whatshot': return Icons.whatshot;
      case 'compare_arrows': return Icons.compare_arrows;
      case 'shield': return Icons.shield;
      case 'grid_on': return Icons.grid_on;
      case 'blur_on': return Icons.blur_on;
      case 'colorize': return Icons.colorize;
      case 'view_carousel': return Icons.view_carousel;
      case 'view_agenda': return Icons.view_agenda;
      case 'circle_outlined': return Icons.circle_outlined;
      default: return Icons.sports_esports;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'slots': return purple;
      case 'live': return pink;
      case 'fishing': return teal;
      case 'poker': return gold;
      case 'lottery': return blue;
      case 'sports': return teal;
      case 'crash': return pink;
      case 'prediction': return purple;
      case 'mini': return gold;
      case 'cards': return blue;
      default: return purple;
    }
  }

  void _showDepositModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, color: gold, size: 28),
            SizedBox(width: 10),
            Text('Low Wallet Balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Current Balance: ₹${userBalance.toStringAsFixed(2)}', style: const TextStyle(color: pink, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'To play online games and win real cash into your wallet, contact Admin on WhatsApp to deposit funds.',
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
            label: const Text('Message Admin on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final msg = 'Hello Admin, I want to add cash to my Nexlyn wallet to play games. Please credit my wallet.';
              final url = 'https://wa.me/${adminWhatsApp.replaceAll('+', '').replaceAll(' ', '')}?text=${Uri.encodeComponent(msg)}';
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  void _onGameSelected(ProviderGame game) {
    final entryFee = game.entryFee;

    // Check balance
    if (userBalance < entryFee) {
      _showDepositModal();
      return;
    }

    // Show quick confirmation
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [purple, pink]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_getIconData(game.iconName), color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(game.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${game.provider} • RTP: ${game.rtp}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Entry Fee', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('₹${entryFee.toStringAsFixed(0)}', style: const TextStyle(color: pink, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(height: 35, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        const Text('Potential Win', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('₹${(entryFee * 1.9).toStringAsFixed(0)}', style: const TextStyle(color: green, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '⚡ When you win, your prize money is automatically credited to your wallet in database!',
                style: TextStyle(color: teal, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.play_arrow, color: Colors.black),
                  label: const Text('CONFIRM & PLAY NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (game.id == 'nexlyn-chess-master') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChessGameScreen(
                            userBalance: userBalance,
                            entryFee: entryFee,
                            onGameFinished: () {
                              _loadUserBalance();
                              widget.onWalletChanged?.call();
                            },
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderGameLauncherScreen(
                            game: game,
                            userBalance: userBalance,
                            entryFee: entryFee,
                            onSessionCompleted: () {
                              _loadUserBalance();
                              widget.onWalletChanged?.call();
                            },
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredGames = ProviderGamesService.catalog.where((g) {
      final matchesCategory = (selectedCategory == 'all' || g.category == selectedCategory);
      final q = searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          g.title.toLowerCase().contains(q) ||
          g.provider.toLowerCase().contains(q) ||
          g.engineIdentifier.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Banner & Balance
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEXLYN LIVE LOBBY',
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
                            'Real-Time Games • Auto Wallet Credit On Win',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showDepositModal,
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
                  hintText: 'Search 30+ games (Cricket, Rummy, 8-Ball, Roulette)...',
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

            // 10 Horizontal Category Tabs
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: ProviderGamesService.categories.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (ctx, index) {
                  final cat = ProviderGamesService.categories[index];
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
                                'No titles found in "$selectedCategory"',
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
                                final catColor = _getCategoryColor(game.category);

                                return GestureDetector(
                                  onTap: () => _onGameSelected(game),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: teal.withValues(alpha: 0.4),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Top Visual
                                          Expanded(
                                            flex: 3,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    catColor.withValues(alpha: 0.25),
                                                    surfaceLight,
                                                  ],
                                                ),
                                              ),
                                              child: Stack(
                                                children: [
                                                  Center(
                                                    child: Icon(
                                                      _getIconData(game.iconName),
                                                      size: 44,
                                                      color: catColor,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    left: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black.withValues(alpha: 0.6),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        game.provider,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: green.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: green, width: 0.8),
                                                      ),
                                                      child: const Text(
                                                        'PLAY ONLINE',
                                                        style: TextStyle(
                                                          color: green,
                                                          fontSize: 8,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // Bottom Details
                                          Expanded(
                                            flex: 2,
                                            child: Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    game.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Fee: ₹${game.entryFee.toInt()}',
                                                        style: const TextStyle(
                                                          color: gold,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: purple.withValues(alpha: 0.2),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          game.category.toUpperCase(),
                                                          style: const TextStyle(
                                                            color: purple,
                                                            fontSize: 8,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
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
