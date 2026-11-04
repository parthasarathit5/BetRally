import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> {
  final searchController = TextEditingController();
  String selectedFilter = 'pending'; // 'pending', 'success', 'failed', ''
  List<dynamic> withdrawals = [];
  bool isLoading = true;
  String? errorMessage;
  int page = 1;
  int totalCount = 0;
  bool hasNext = false;
  bool hasPrev = false;

  @override
  void initState() {
    super.initState();
    loadWithdrawals();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadWithdrawals() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final res = await ApiService.getAdminWithdrawals(
        status: selectedFilter,
        search: searchController.text.trim(),
        page: page,
      );

      if (!mounted) return;
      setState(() {
        totalCount = res['count'] as int? ?? 0;
        hasNext = res['next'] != null;
        hasPrev = res['previous'] != null;
        withdrawals = (res['results'] as List?) ?? [];
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

  Future<void> approveWithdrawal(int txnId, String username, String amount) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await ApiService.approveAdminWithdrawal(transactionId: txnId);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Withdrawal marked paid & completed!'),
          backgroundColor: teal,
        ),
      );
      loadWithdrawals();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error approving payout: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void promptRejectWithdrawal(int txnId, String username, String amount) {
    final reasonController = TextEditingController(text: 'UPI ID invalid or name mismatch');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text('Reject & Refund ₹$amount', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Player: $username', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            const Text(
              'Rejecting this withdrawal will automatically refund the full amount back into the player\'s wallet balance.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Rejection Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('REJECT & REFUND'),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              try {
                final res = await ApiService.rejectAdminWithdrawal(
                  transactionId: txnId,
                  reason: reasonController.text.trim(),
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(res['message']?.toString() ?? 'Withdrawal rejected & refunded.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                loadWithdrawals();
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Rejection failed: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'success':
        return teal;
      case 'pending':
        return gold;
      case 'failed':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        title: const Text('Withdrawal Requests (Min ₹500)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadWithdrawals,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: surface.withValues(alpha: 0.6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Pending', 'pending', gold),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed / Paid', 'success', teal),
                  const SizedBox(width: 8),
                  _buildFilterChip('Rejected', 'failed', Colors.redAccent),
                  const SizedBox(width: 8),
                  _buildFilterChip('All Requests', '', purple),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search player username, email, or Ref ID...',
                prefixIcon: const Icon(Icons.search, color: pink),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          searchController.clear();
                          page = 1;
                          loadWithdrawals();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) {
                page = 1;
                loadWithdrawals();
              },
            ),
          ),

          // Content List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: pink))
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(errorMessage!, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: loadWithdrawals, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : withdrawals.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 54, color: Colors.white.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  selectedFilter == 'pending'
                                      ? 'No pending withdrawal requests!'
                                      : 'No withdrawals found',
                                  style: const TextStyle(color: Colors.white60, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: withdrawals.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final item = withdrawals[i];
                              final id = item['id'] as int? ?? 0;
                              final username = item['user_username']?.toString() ?? 'Player';
                              final amount = item['amount']?.toString() ?? '0.00';
                              final status = item['status']?.toString() ?? 'pending';
                              final refId = item['reference_id']?.toString() ?? '-';
                              final desc = item['description']?.toString() ?? '';
                              final date = item['created_at']?.toString().split('T').first ?? '';

                              final isPending = status == 'pending';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isPending ? gold.withValues(alpha: 0.5) : Colors.white10,
                                    width: isPending ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: pink.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Icons.arrow_upward, color: pink, size: 20),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  username,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                Text(date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '₹$amount',
                                              style: const TextStyle(
                                                color: pink,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 20,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: getStatusColor(status).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  color: getStatusColor(status),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: bg.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text('Ref ID:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                              Row(
                                                children: [
                                                  Text(refId, style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
                                                  const SizedBox(width: 4),
                                                  InkWell(
                                                    onTap: () {
                                                      Clipboard.setData(ClipboardData(text: refId));
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(content: Text('Ref ID copied!')),
                                                      );
                                                    },
                                                    child: const Icon(Icons.copy, size: 14, color: Colors.white54),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              desc,
                                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Action Buttons for Pending Requests
                                    if (isPending) ...[
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.redAccent,
                                                side: const BorderSide(color: Colors.redAccent),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              icon: const Icon(Icons.close, size: 16),
                                              label: const Text('REJECT & REFUND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              onPressed: () => promptRejectWithdrawal(id, username, amount),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: teal,
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              icon: const Icon(Icons.check, size: 16, color: Colors.black),
                                              label: const Text('APPROVE & PAID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              onPressed: () => approveWithdrawal(id, username, amount),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
          ),

          // Pagination Footer
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total: $totalCount requests', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: hasPrev
                            ? () {
                                setState(() => page--);
                                loadWithdrawals();
                              }
                            : null,
                      ),
                      Text('Page $page', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: hasNext
                            ? () {
                                setState(() => page++);
                                loadWithdrawals();
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.25),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.white60,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? color : Colors.transparent),
      onSelected: (_) {
        setState(() {
          selectedFilter = value;
          page = 1;
        });
        loadWithdrawals();
      },
    );
  }
}
