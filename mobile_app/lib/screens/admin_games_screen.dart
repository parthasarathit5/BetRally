import 'package:flutter/material.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const blue = Color(0xFF398BFF);
const gold = Color(0xFFFFC857);

class AdminGamesScreen extends StatefulWidget {
  const AdminGamesScreen({super.key});

  @override
  State<AdminGamesScreen> createState() => _AdminGamesScreenState();
}

class _AdminGamesScreenState extends State<AdminGamesScreen> {
  final searchController = TextEditingController();
  List<dynamic> games = [];
  bool isLoading = true;
  String? errorMessage;
  String selectedCategory = 'all';

  final availableIcons = [
    {'name': 'diamond', 'icon': Icons.diamond_outlined, 'label': 'Diamond (Mines)'},
    {'name': 'sports_cricket', 'icon': Icons.sports_cricket, 'label': 'Cricket'},
    {'name': 'sports_soccer', 'icon': Icons.sports_soccer, 'label': 'Football'},
    {'name': 'grid_on', 'icon': Icons.grid_on, 'label': 'Chess / Grid'},
    {'name': 'circle_outlined', 'icon': Icons.circle_outlined, 'label': 'Carrom'},
    {'name': 'sports_esports', 'icon': Icons.sports_esports, 'label': 'Arcade'},
    {'name': 'casino', 'icon': Icons.casino_outlined, 'label': 'Dice / Casino'},
    {'name': 'style', 'icon': Icons.style_outlined, 'label': 'Cards'},
  ];

  @override
  void initState() {
    super.initState();
    loadGames();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadGames() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final res = await ApiService.getAdminGames();
      if (!mounted) return;
      setState(() {
        games = res;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> toggleGameActive(Map<String, dynamic> game) async {
    final int id = game['id'] as int;
    final bool current = game['is_active'] == true;
    final bool desired = !current;
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ApiService.updateGame(gameId: id, changes: {'is_active': desired});
      if (!mounted) return;
      setState(() {
        game['is_active'] = desired;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(desired ? '${game['name']} activated.' : '${game['name']} deactivated.'),
          backgroundColor: desired ? teal : pink,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: pink),
      );
    }
  }

  Future<void> deleteGame(Map<String, dynamic> game) async {
    final int id = game['id'] as int;
    final String name = game['name']?.toString() ?? 'Game';
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: const Text('Delete Game'),
        content: Text('Are you sure you want to permanently delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: pink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.deleteGame(gameId: id);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Game "$name" deleted.'), backgroundColor: teal),
      );
      loadGames();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: pink),
      );
    }
  }

  void showGameDialog({Map<String, dynamic>? existingGame}) {
    final isEditing = existingGame != null;
    final nameController = TextEditingController(text: existingGame?['name']?.toString() ?? '');
    final slugController = TextEditingController(text: existingGame?['slug']?.toString() ?? '');
    final descController = TextEditingController(text: existingGame?['description']?.toString() ?? '');
    final sortController = TextEditingController(text: existingGame?['sort_order']?.toString() ?? '0');
    String category = existingGame?['category']?.toString() ?? 'casual';
    String iconName = existingGame?['icon_name']?.toString() ?? 'sports_esports';
    bool isActive = existingGame?['is_active'] ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              title: Text(
                isEditing ? 'Edit Game: ${existingGame['name']}' : 'Add New Game',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        onChanged: (val) {
                          if (!isEditing) {
                            setDialogState(() {
                              slugController.text = val
                                  .toLowerCase()
                                  .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                                  .replaceAll(RegExp(r'^-+|-+$'), '');
                            });
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Game Name *'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: slugController,
                        decoration: const InputDecoration(labelText: 'URL Slug *'),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        dropdownColor: surface,
                        items: const [
                          DropdownMenuItem(value: 'casual', child: Text('Casual / Arcade')),
                          DropdownMenuItem(value: 'sports', child: Text('Sports')),
                          DropdownMenuItem(value: 'board', child: Text('Board Game')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => category = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text('Game Icon:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableIcons.map((item) {
                          final isSel = iconName == item['name'];
                          return InkWell(
                            onTap: () => setDialogState(() => iconName = item['name'] as String),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSel ? purple.withValues(alpha: 0.3) : Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: isSel ? purple : Colors.white12),
                              ),
                              child: Icon(item['icon'] as IconData, color: isSel ? purple : Colors.white70, size: 24),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sortController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sort Order (0, 1, 2...)'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: isActive,
                            activeColor: teal,
                            onChanged: (val) => setDialogState(() => isActive = val ?? true),
                          ),
                          const Text('Active & Visible to Players'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final slug = slugController.text.trim();
                          if (name.isEmpty || slug.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name and slug are required.')),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final sort = int.tryParse(sortController.text.trim()) ?? 0;
                          final messenger = ScaffoldMessenger.of(this.context);

                          try {
                            if (isEditing) {
                              await ApiService.updateGame(
                                gameId: existingGame['id'] as int,
                                changes: {
                                  'name': name,
                                  'slug': slug,
                                  'category': category,
                                  'icon_name': iconName,
                                  'description': descController.text.trim(),
                                  'sort_order': sort,
                                  'is_active': isActive,
                                },
                              );
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Game updated successfully!'), backgroundColor: teal),
                              );
                            } else {
                              await ApiService.createGame(
                                name: name,
                                slug: slug,
                                category: category,
                                iconName: iconName,
                                description: descController.text.trim(),
                                sortOrder: sort,
                                isActive: isActive,
                              );
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Game created successfully!'), backgroundColor: teal),
                              );
                            }

                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            loadGames();
                          } catch (err) {
                            setDialogState(() => isSaving = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Save failed: $err'), backgroundColor: pink),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Create Game', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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
      case 'casino':
        return Icons.casino_outlined;
      case 'style':
        return Icons.style_outlined;
      default:
        return Icons.sports_esports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final filteredGames = games.where((g) {
      final matchCat = selectedCategory == 'all' || g['category'] == selectedCategory;
      final matchSearch = query.isEmpty ||
          (g['name']?.toString().toLowerCase().contains(query) ?? false) ||
          (g['slug']?.toString().toLowerCase().contains(query) ?? false);
      return matchCat && matchSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GAME MANAGEMENT',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: teal),
            onPressed: loadGames,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: teal,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('NEW GAME', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => showGameDialog(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search games by name or slug...',
                    prefixIcon: Icon(Icons.search, color: purple),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildCategoryChip('all', 'All Games'),
                    _buildCategoryChip('casual', 'Casual / Arcade'),
                    _buildCategoryChip('sports', 'Sports'),
                    _buildCategoryChip('board', 'Board Games'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: teal))
                    : errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(errorMessage!, style: const TextStyle(color: pink)),
                                const SizedBox(height: 12),
                                FilledButton(onPressed: loadGames, child: const Text('Retry')),
                              ],
                            ),
                          )
                        : filteredGames.isEmpty
                            ? const Center(child: Text('No games found.'))
                            : ListView.builder(
                                padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
                                itemCount: filteredGames.length,
                                itemBuilder: (context, index) {
                                  final g = Map<String, dynamic>.from(filteredGames[index] as Map);
                                  final name = g['name']?.toString() ?? 'Game';
                                  final slug = g['slug']?.toString() ?? '';
                                  final cat = g['category']?.toString() ?? 'casual';
                                  final desc = g['description']?.toString() ?? '';
                                  final icon = getIcon(g['icon_name']?.toString());
                                  final isActive = g['is_active'] == true;
                                  final sortOrder = g['sort_order'] ?? 0;

                                  return Card(
                                    color: surface,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(
                                        color: isActive ? teal.withValues(alpha: 0.3) : Colors.white12,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: (isActive ? teal : Colors.grey).withValues(alpha: 0.15),
                                        child: Icon(icon, color: isActive ? teal : Colors.white38),
                                      ),
                                      title: Row(
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: purple.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(cat.toUpperCase(), style: const TextStyle(color: purple, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('Slug: $slug • Sort: $sortOrder', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                            value: isActive,
                                            activeThumbColor: teal,
                                            onChanged: (_) => toggleGameActive(g),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, color: blue, size: 20),
                                            onPressed: () => showGameDialog(existingGame: g),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: pink, size: 20),
                                            onPressed: () => deleteGame(g),
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
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String val, String label) {
    final isSel = selectedCategory == val;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSel,
        selectedColor: purple.withValues(alpha: 0.35),
        labelStyle: TextStyle(
          color: isSel ? purple : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => selectedCategory = val),
      ),
    );
  }
}
