import 'package:flutter/material.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

class AdminDepositsScreen extends StatefulWidget {
  const AdminDepositsScreen({super.key});

  @override
  State<AdminDepositsScreen> createState() => _AdminDepositsScreenState();
}

class _AdminDepositsScreenState extends State<AdminDepositsScreen> {
  final searchController = TextEditingController();
  String selectedFilter = 'pending'; // 'pending', 'success', 'failed', ''
  List<dynamic> deposits = [];
  bool isLoading = true;
  String? errorMessage;
  int page = 1;
  int totalCount = 0;
  bool hasNext = false;
  bool hasPrev = false;

  @override
  void initState() {
    super.initState();
    loadDeposits();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadDeposits() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final res = await ApiService.getAdminDeposits(
        status: selectedFilter,
        search: searchController.text.trim(),
        page: page,
      );

      if (!mounted) return;
      setState(() {
        totalCount = res['count'] as int? ?? 0;
        hasNext = res['next'] != null;
        hasPrev = res['previous'] != null;
        deposits = (res['results'] as List?) ?? [];
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

  Future<void> approveDeposit(int txnId, String username, String amount) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await ApiService.approveAdminDeposit(transactionId: txnId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Deposit approved & wallet credited!'),
          backgroundColor: teal,
        ),
      );
      loadDeposits();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Approval failed: $e'), backgroundColor: pink),
      );
    }
  }

  Future<void> rejectDeposit(int txnId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await ApiService.rejectAdminDeposit(transactionId: txnId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Deposit rejected.'),
          backgroundColor: pink,
        ),
      );
      loadDeposits();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Action failed: $e'), backgroundColor: pink),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DEPOSIT REQUESTS & APPROVALS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: teal),
            onPressed: loadDeposits,
          ),
          const SizedBox(width: 8),
        ],
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
                  onSubmitted: (_) {
                    page = 1;
                    loadDeposits();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search player email, username or Ref ID...',
                    prefixIcon: const Icon(Icons.search, color: purple),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        page = 1;
                        loadDeposits();
                      },
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('pending', 'Pending Approval ⏳'),
                    _buildFilterChip('success', 'Approved ✅'),
                    _buildFilterChip('failed', 'Rejected ❌'),
                    _buildFilterChip('', 'All Deposits'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Content List
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
                                FilledButton(onPressed: loadDeposits, child: const Text('Retry')),
                              ],
                            ),
                          )
                        : deposits.isEmpty
                            ? Center(
                                child: Text(
                                  selectedFilter == 'pending'
                                      ? 'No pending deposits to approve! 🎉'
                                      : 'No deposit requests found.',
                                  style: const TextStyle(color: Colors.white60),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: deposits.length,
                                itemBuilder: (context, index) {
                                  final item = Map<String, dynamic>.from(deposits[index] as Map);
                                  final id = item['id'] as int;
                                  final email = item['user_email']?.toString() ?? 'Player';
                                  final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                                  final status = item['status']?.toString() ?? 'pending';
                                  final refId = item['reference_id']?.toString() ?? '-';
                                  final date = item['created_at']?.toString() ?? '';
                                  final isPending = status == 'pending';

                                  return Card(
                                    color: surface,
                                    margin: const EdgeInsets.only(bottom: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(
                                        color: isPending ? gold.withValues(alpha: 0.5) : Colors.white12,
                                        width: isPending ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      email,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Ref: $refId',
                                                      style: const TextStyle(color: gold, fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '₹${amt.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  color: teal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isPending
                                                      ? gold.withValues(alpha: 0.2)
                                                      : (status == 'success'
                                                          ? teal.withValues(alpha: 0.2)
                                                          : pink.withValues(alpha: 0.2)),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: isPending
                                                        ? gold
                                                        : (status == 'success' ? teal : pink),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                date.length > 19 ? date.substring(0, 19).replaceAll('T', ' ') : date,
                                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          if (isPending) ...[
                                            const SizedBox(height: 14),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: teal,
                                                      foregroundColor: Colors.black,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    icon: const Icon(Icons.check, size: 18),
                                                    label: const Text(
                                                      'APPROVE & CREDIT',
                                                      style: TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    onPressed: () => approveDeposit(id, email, amt.toString()),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                OutlinedButton(
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: pink,
                                                    side: const BorderSide(color: pink),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  onPressed: () => rejectDeposit(id),
                                                  child: const Text('REJECT'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),

              // Pagination
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: hasPrev && !isLoading
                          ? () {
                              page--;
                              loadDeposits();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),
                    Text(
                      'Page $page ($totalCount deposits)',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    OutlinedButton.icon(
                      onPressed: hasNext && !isLoading
                          ? () {
                              page++;
                              loadDeposits();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: purple.withValues(alpha: 0.35),
        labelStyle: TextStyle(
          color: isSelected ? purple : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        onSelected: (_) {
          setState(() {
            selectedFilter = value;
            page = 1;
          });
          loadDeposits();
        },
      ),
    );
  }
}
