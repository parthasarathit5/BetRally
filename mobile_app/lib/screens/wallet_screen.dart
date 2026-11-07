import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const surfaceLight = Color(0xFF222649);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

class WalletScreen extends StatefulWidget {
  final VoidCallback? onBalanceUpdated;
  const WalletScreen({super.key, this.onBalanceUpdated});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 0.0;
  String adminWhatsApp = '+917780383832';
  bool isLoading = true;
  List<dynamic> transactions = [];
  String? errorMessage;

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
        balance = double.tryParse(walletData['balance']?.toString() ?? '0') ?? 0.0;
        adminWhatsApp = walletData['admin_whatsapp']?.toString() ?? adminWhatsApp;
        transactions = (txnData['results'] as List?) ?? [];
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

  void _showDepositDialog() {
    final amountController = TextEditingController(text: '500');
    final amounts = [100, 200, 500, 1000, 2000, 5000];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.add_circle, color: green, size: 24),
                            SizedBox(width: 8),
                            Text('Deposit to Wallet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [green.withValues(alpha: 0.18), teal.withValues(alpha: 0.12)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: green.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: green,
                                radius: 14,
                                child: Icon(Icons.chat, size: 16, color: Colors.black),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Admin WhatsApp: $adminWhatsApp',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select deposit amount below to send request directly to Admin. Admin verifies your UPI/Payment and immediately credits your wallet balance!',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text('SELECT AMOUNT (₹)', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amounts.map((amt) {
                        final isSelected = amountController.text == amt.toString();
                        return ChoiceChip(
                          label: Text('₹$amt'),
                          selected: isSelected,
                          selectedColor: green.withValues(alpha: 0.3),
                          labelStyle: TextStyle(color: isSelected ? green : Colors.white70, fontWeight: FontWeight.bold),
                          onSelected: (_) {
                            setModalState(() => amountController.text = amt.toString());
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Deposit Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee, color: green),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: isSubmitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Icon(Icons.chat, color: Colors.black),
                        label: const Text('PROCEED VIA WHATSAPP (+91 7780383832)', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                                if (amt < 50) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Minimum deposit is ₹50'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);
                                try {
                                  await ApiService.requestWhatsAppDeposit(
                                    amount: amt,
                                  );
                                } catch (_) {}

                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);

                                final msg = 'Hello Admin, I have requested to deposit ₹${amt.toStringAsFixed(0)} into my Nexlyn wallet. Please share payment QR / UPI and credit my wallet.';
                                final url = 'https://wa.me/${adminWhatsApp.replaceAll('+', '').replaceAll(' ', '')}?text=${Uri.encodeComponent(msg)}';
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

                                loadWalletData();
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWithdrawDialog() {
    final amountCtrl = TextEditingController();
    final upiCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.account_balance_wallet, color: gold, size: 24),
                        SizedBox(width: 10),
                        Text('Withdraw Winnings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Available Balance: ₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Withdrawal Amount (Min ₹500)',
                        prefixIcon: Icon(Icons.currency_rupee, color: gold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: upiCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'UPI ID (e.g. name@okhdfcbank)',
                        prefixIcon: Icon(Icons.payment, color: teal),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Account Holder Name',
                        prefixIcon: Icon(Icons.person, color: purple),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                                if (amt < 500) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Minimum withdrawal is ₹500'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }
                                if (amt > balance) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.red),
                                  );
                                  return;
                                }

                                final messenger = ScaffoldMessenger.of(context);
                                setModalState(() => isSubmitting = true);
                                try {
                                  final accountDetails = 'UPI: ${upiCtrl.text.trim()} | Name: ${nameCtrl.text.trim()}';
                                  await ApiService.withdraw(
                                    amount: amt,
                                    accountInfo: accountDetails,
                                  );
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Withdrawal request submitted for Admin approval!'), backgroundColor: green),
                                  );
                                  loadWalletData();
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text('SUBMIT WITHDRAWAL REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: const Text('WALLET & WINNINGS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Balance',
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
                        // Balance Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7137D5), Color(0xFFCB438F), Color(0xFF2855A5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(color: purple.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL WALLET BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                              const SizedBox(height: 12),
                              Text(
                                '₹${balance.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              const Text('Play games online and win real money credited automatically to this wallet.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: green,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 13),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      icon: const Icon(Icons.add_circle, color: Colors.black, size: 20),
                                      label: const Text('ADD MONEY', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: _showDepositDialog,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: surfaceLight,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 13),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      icon: const Icon(Icons.arrow_circle_up, color: gold, size: 20),
                                      label: const Text('WITHDRAW', style: TextStyle(fontWeight: FontWeight.bold)),
                                      onPressed: _showWithdrawDialog,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Text('Transaction & Match History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        if (transactions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
                            child: const Center(
                              child: Text('No transaction records found. Play games to see wins!', style: TextStyle(color: Colors.white70)),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder: (context, i) => const SizedBox(height: 10),
                            itemBuilder: (ctx, index) {
                              final item = transactions[index];
                              final isCredit = item['transaction_type'] == 'deposit' || item['transaction_type'] == 'game_win';
                              final desc = item['description'] ?? 'Game Session';
                              final amt = item['amount'] ?? '0.00';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isCredit ? green.withValues(alpha: 0.15) : pink.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? green : pink, size: 20),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(desc, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 2),
                                          Text('${item['transaction_type']?.toString().toUpperCase()} • ${item['status']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isCredit ? '+' : '-'}₹$amt',
                                      style: TextStyle(color: isCredit ? green : pink, fontWeight: FontWeight.bold, fontSize: 15),
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
