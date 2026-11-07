import 'package:flutter/material.dart';
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

class GamesScreen extends StatefulWidget {
  final VoidCallback? onWalletChanged;
  const GamesScreen({super.key, this.onWalletChanged});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  String selectedCategory = 'all';
  String searchQuery = '';
  double userCredits = 1000.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserCredits();
  }

  Future<void> _loadUserCredits() async {
    setState(() => isLoading = true);
    try {
      final wallet = await ApiService.getWallet();
      if (!mounted) return;
      setState(() {
        userCredits = double.tryParse(wallet['balance']?.toString() ?? '1000') ?? 1000.0;
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
      case 'filter_2': return Icons.filter_2;
      case 'filter_1': return Icons.filter_1;
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

  void _onGameSelected(ProviderGame game) {
    // If it's the preserved chess game, open the chess engine
    if (game.id == 'nexlyn-chess-master') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChessGameScreen(
            userBalance: userCredits,
            entryFee: 0.0,
            onGameFinished: () {
              _loadUserCredits();
              widget.onWalletChanged?.call();
            },
          ),
        ),
      );
      return;
    }

    // Launch provider engine
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderGameLauncherScreen(
          game: game,
          userCredits: userCredits,
          onSessionCompleted: () {
            _loadUserCredits();
            widget.onWalletChanged?.call();
          },
        ),
      ),
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
            // Top App Banner & Credits display
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEXLYN GAMING LOBBY',
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
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: teal, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Third-Party Provider Network • 10 Categories',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [purple.withValues(alpha: 0.3), pink.withValues(alpha: 0.3)]),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: purple.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: gold, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${userCredits.toInt()} XP',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
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
                  hintText: 'Search games, providers (Pragmatic, Famobi, Spribe)...',
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
                        gradient: isSelected
                            ? const LinearGradient(colors: [purple, pink])
                            : null,
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
                                        color: game.isOfficiallyAuthorized
                                            ? teal.withValues(alpha: 0.4)
                                            : Colors.white10,
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
                                          // Top Visual & Provider Badge
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
                                                        color: game.isOfficiallyAuthorized
                                                            ? teal.withValues(alpha: 0.2)
                                                            : gold.withValues(alpha: 0.2),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(
                                                          color: game.isOfficiallyAuthorized ? teal : gold,
                                                          width: 0.8,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        game.isOfficiallyAuthorized ? 'PLAYABLE' : 'SHOWCASE',
                                                        style: TextStyle(
                                                          color: game.isOfficiallyAuthorized ? teal : gold,
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
                                                        'RTP: ${game.rtp}',
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 10,
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
