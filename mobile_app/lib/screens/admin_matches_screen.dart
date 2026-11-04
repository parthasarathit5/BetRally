import 'package:flutter/material.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);

class AdminMatchesScreen extends StatefulWidget {
  const AdminMatchesScreen({super.key});

  @override
  State<AdminMatchesScreen> createState() => _AdminMatchesScreenState();
}

class _AdminMatchesScreenState extends State<AdminMatchesScreen> {
  final search = TextEditingController();
  String selectedResultFilter = '';
  List<dynamic> matches = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadMatches();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> loadMatches() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.getAdminMatches(
        search: search.text.trim(),
        result: selectedResultFilter,
      );
      if (!mounted) return;
      setState(() {
        matches = (res['results'] as List?) ?? [];
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Match Activity & Records'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: loadMatches,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              // Search & Filter
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: search,
                        onSubmitted: (_) => loadMatches(),
                        decoration: InputDecoration(
                          hintText: 'Search by player or game...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: loadMatches,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: selectedResultFilter,
                      dropdownColor: surface,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('All Results')),
                        DropdownMenuItem(value: 'win', child: Text('Wins Only')),
                        DropdownMenuItem(value: 'loss', child: Text('Losses Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedResultFilter = val);
                          loadMatches();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Match List
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator(color: teal))
                    : error != null
                        ? Center(child: Text(error!, style: const TextStyle(color: pink)))
                        : matches.isEmpty
                            ? const Center(child: Text('No match records found in Supabase.'))
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: matches.length,
                                itemBuilder: (context, index) {
                                  final m = Map<String, dynamic>.from(matches[index] as Map);
                                  final isWin = m['result'] == 'win';
                                  final date = m['created_at']?.toString().split('T').first ?? '';

                                  return Card(
                                    color: surface,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isWin ? teal.withValues(alpha: 0.2) : pink.withValues(alpha: 0.2),
                                        child: Icon(
                                          isWin ? Icons.emoji_events : Icons.close,
                                          color: isWin ? teal : pink,
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${m['username']} • ${m['game_name']}',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: (isWin ? teal : pink).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              (m['result']?.toString() ?? '').toUpperCase(),
                                              style: TextStyle(
                                                color: isWin ? teal : pink,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        'Player ID: #${m['user_id']} • Bet: ₹${m['bet_amount']} • Payout: ₹${m['payout_amount']}\nDate: $date • Ref: ${m['reference_id']}',
                                        style: const TextStyle(fontSize: 12, color: Colors.white60),
                                      ),
                                      isThreeLine: true,
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
}

