import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'mines_game_screen.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
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
  List<dynamic> gamesList = [];
  bool isLoading = true;

  final categories = [
    {'id': 'all', 'label': 'All Games'},
    {'id': 'casual', 'label': 'Casual / Arcade'},
    {'id': 'sports', 'label': 'Sports'},
    {'id': 'board', 'label': 'Board'},
  ];

  @override
  void initState() {
    super.initState();
    loadGames();
  }

  Future<void> loadGames() async {
    setState(() => isLoading = true);
    try {
      final games = await ApiService.getGames();
      if (!mounted) return;
      setState(() {
        gamesList = games;
        isLoading = false;
      });
    } catch (_) {
      // Fallback default games if backend is offline
      if (!mounted) return;
      setState(() {
        gamesList = [
          {
            'name': 'Mines',
            'slug': 'mines',
            'category': 'casual',
            'description': 'Uncover gems & avoid mines. Cash out anytime!',
            'icon_name': 'diamond',
          },
          {
            'name': 'Cricket Clash',
            'slug': 'cricket',
            'category': 'sports',
            'description': 'Real-time batting & timing showdown.',
            'icon_name': 'sports_cricket',
          },
          {
            'name': 'Speed Football',
            'slug': 'football',
            'category': 'sports',
            'description': 'Score penalties for high multipliers.',
            'icon_name': 'sports_soccer',
          },
          {
            'name': 'Blitz Chess',
            'slug': 'chess',
            'category': 'board',
            'description': 'Tactical speed chess duels.',
            'icon_name': 'grid_on',
          },
          {
            'name': 'Carrom King',
            'slug': 'carrom',
            'category': 'board',
            'description': 'Pocket coins and cover the queen.',
            'icon_name': 'circle_outlined',
          },
        ];
        isLoading = false;
      });
    }
  }

  IconData getIcon(String? iconName) {
    switch (iconName) {
      case 'diamond':
        return Icons.diamond_outlined;
      case 'sports_cricket':
        return Icons.sports_cricket;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'grid_on':
        return Icons.grid_on;
      case 'circle_outlined':
        return Icons.circle_outlined;
      default:
        return Icons.sports_esports;
    }
  }

  Color getCategoryColor(String? cat) {
    switch (cat) {
      case 'casual':
        return pink;
      case 'sports':
        return teal;
      case 'board':
        return purple;
      default:
        return blue;
    }
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
          'EXPLORE GAMES',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: teal),
            onPressed: loadGames,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search games (Mines, Cricket, Chess)...',
                prefixIcon: const Icon(Icons.search, color: purple),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: categories.map((cat) {
                final isSel = selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat['label']!),
                    selected: isSel,
                    selectedColor: purple.withValues(alpha: 0.35),
                    labelStyle: TextStyle(
                      color: isSel ? purple : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => selectedCategory = cat['id']!),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Games Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: teal))
                : filteredGames.isEmpty
                    ? const Center(child: Text('No games match your criteria.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: filteredGames.length,
                        itemBuilder: (context, index) {
                          final game = filteredGames[index];
                          final name = game['name']?.toString() ?? 'Game';
                          final slug = game['slug']?.toString() ?? '';
                          final cat = game['category']?.toString() ?? 'casual';
                          final desc = game['description']?.toString() ?? '';
                          final color = getCategoryColor(cat);
                          final icon = getIcon(game['icon_name']?.toString());
                          final isMines = slug == 'mines';

                          return InkWell(
                            onTap: () {
                              if (isMines) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MinesGameScreen(
                                      onWalletChanged: widget.onWalletChanged,
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name tournament rooms are opening soon! Play Mines now.'),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isMines ? teal : color.withValues(alpha: 0.4),
                                  width: isMines ? 1.8 : 1,
                                ),
                                boxShadow: isMines
                                    ? [
                                        BoxShadow(
                                          color: teal.withValues(alpha: 0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isMines)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        '🔥 HOT • PLAYABLE',
                                        style: TextStyle(
                                          color: gold,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: color, size: 36),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isMines ? teal : surface.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isMines ? 'PLAY NOW ➔' : 'COMING SOON',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isMines ? Colors.black : Colors.white38,
                                        fontSize: 12,
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

