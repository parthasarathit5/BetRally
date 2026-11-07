import 'package:flutter/material.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const surfaceLight = Color(0xFF222649);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const gold = Color(0xFFFFC857);

class WalletScreen extends StatefulWidget {
  final VoidCallback? onBalanceUpdated;
  const WalletScreen({super.key, this.onBalanceUpdated});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double credits = 1000.0;
  bool isLoading = true;
  List<dynamic> activities = [];
  String? errorMessage;
  bool isClaimingDaily = false;

  @override
  void initState() {
    super.initState();
    loadWalletData();
  }

  Future<void> loadWalletData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final walletData = await ApiService.getWallet();
      final txnData = await ApiService.getTransactions(page: 1);

      if (!mounted) return;
      setState(() {
        credits = double.tryParse(walletData['balance']?.toString() ?? '1000') ?? 1000.0;
        activities = (txnData['results'] as List?) ?? [];
        isLoading = false;
      });
      widget.onBalanceUpdated?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> claimDailyBonus() async {
    setState(() => isClaimingDaily = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      credits += 500.0;
      isClaimingDaily = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Daily Social Bonus Claimed: +500 Entertainment Credits!'),
        backgroundColor: teal,
      ),
    );
    widget.onBalanceUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: const Text(
          'ENTERTAINMENT CREDITS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Credits',
            onPressed: loadWalletData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: teal))
          : RefreshIndicator(
              color: teal,
              onRefresh: loadWalletData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Credits Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [purple, pink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: purple.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'NEXLYN SOCIAL POINTS',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.verified, color: teal, size: 14),
                                        SizedBox(width: 4),
                                        Text(
                                          'Free-Play Only',
                                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    credits.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'XP',
                                    style: TextStyle(
                                      color: gold,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Non-redeemable virtual credits for social play and leaderboards.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: isClaimingDaily
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                        )
                                      : const Icon(Icons.card_giftcard, color: Colors.black),
                                  label: const Text(
                                    'CLAIM DAILY BONUS (+500 XP)',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: isClaimingDaily ? null : claimDailyBonus,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Social Gaming Compliance Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: teal.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield_outlined, color: teal, size: 24),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lawful Social Gaming Platform',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Nexlyn operates exclusively as an entertainment platform. There is no real-money gambling, cash wagering, stake deposit, or payout redemption.',
                                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Recent Play Activity
                        const Text(
                          'Recent Game Play Activity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (activities.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: const Center(
                              child: Column(
                                children: [
                                  Icon(Icons.history_toggle_off, color: Colors.white38, size: 40),
                                  SizedBox(height: 12),
                                  Text(
                                    'No recent sessions recorded yet.',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Launch any game in the lobby to earn XP!',
                                    style: TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activities.length,
                            separatorBuilder: (context, i) => const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final item = activities[index];
                              final gameName = item['description']?.toString() ?? item['game_name']?.toString() ?? 'Social Engagement';
                              final result = item['transaction_type']?.toString() ?? 'Play Session';
                              final payout = item['amount']?.toString() ?? '10.00';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: purple.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.sports_esports, color: purple, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            gameName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Result: ${result.toUpperCase()} • Social Play',
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '+$payout XP',
                                      style: const TextStyle(
                                        color: teal,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
