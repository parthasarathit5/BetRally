import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const surfaceLight = Color(0xFF222649);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const blue = Color(0xFF398BFF);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366); // WhatsApp Green

class WalletScreen extends StatefulWidget {
  final VoidCallback? onBalanceUpdated;
  const WalletScreen({super.key, this.onBalanceUpdated});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double balance = 0.0;
  String currency = 'INR';
  String adminWhatsApp = '+919876543210';
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
        currency = walletData['currency']?.toString() ?? 'INR';
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

  void showDepositDialog() {
    final amountController = TextEditingController(text: '200');
    final amounts = [100, 200, 500, 1000, 2000, 5000];
    bool isSubmitting = false;
    int selectedTab = 0; // 0 = WhatsApp Deposit, 1 = Instant Demo

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
                        const Text(
                          'Add Cash to Wallet',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Payment Method Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedTab == 0 ? green : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.chat,
                                      size: 16,
                                      color: selectedTab == 0 ? Colors.black : Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Admin WhatsApp',
                                      style: TextStyle(
                                        color: selectedTab == 0 ? Colors.black : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setModalState(() => selectedTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedTab == 1 ? teal : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.flash_on,
                                      size: 16,
                                      color: selectedTab == 1 ? Colors.black : Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Instant Demo',
                                      style: TextStyle(
                                        color: selectedTab == 1 ? Colors.black : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Instruction note
                    if (selectedTab == 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user, color: green, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Submit request to open WhatsApp with Admin ($adminWhatsApp). Transfer via UPI/GPay and get credited immediately.',
                                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: teal.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: teal, size: 22),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Instant Demo: Simulates successful payment and credits wallet immediately.',
                                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 18),
                    const Text(
                      'SELECT AMOUNT (₹)',
                      style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amounts.map((amt) {
                        final isSelected = amountController.text == amt.toString();
                        return ChoiceChip(
                          label: Text('₹$amt'),
                          selected: isSelected,
                          selectedColor: (selectedTab == 0 ? green : teal).withValues(alpha: 0.3),
                          labelStyle: TextStyle(
                            color: isSelected ? (selectedTab == 0 ? green : teal) : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (_) {
                            setModalState(() {
                              amountController.text = amt.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Custom Amount (₹)',
                        prefixIcon: Icon(
                          Icons.currency_rupee,
                          color: selectedTab == 0 ? green : teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedTab == 0 ? green : teal,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: Icon(selectedTab == 0 ? Icons.chat : Icons.check_circle, color: Colors.black),
                        label: isSubmitting
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                                selectedTab == 0 ? 'PAY & AUTHENTICATE VIA WHATSAPP' : 'CONFIRM INSTANT DEPOSIT',
                                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                                final messenger = ScaffoldMessenger.of(this.context);
                                final modalNavigator = Navigator.of(context);

                                if (amt < 1.0) {
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('Minimum deposit is ₹1.00')),
                                  );
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                if (selectedTab == 0) {
                                  // WhatsApp Deposit Flow
                                  try {
                                    final res = await ApiService.requestWhatsAppDeposit(amount: amt);
                                    modalNavigator.pop();

                                    final waUrl = res['whatsapp_url']?.toString() ?? '';
                                    final refId = res['reference_id']?.toString() ?? '';

                                    // Open confirmation dialog with direct button
                                    if (mounted) {
                                      showWhatsAppConfirmationDialog(
                                        amount: amt,
                                        refId: refId,
                                        waUrl: waUrl,
                                        adminPhone: res['admin_phone']?.toString() ?? adminWhatsApp,
                                      );
                                    }
                                    loadWalletData();
                                  } catch (err) {
                                    setModalState(() => isSubmitting = false);
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Could not create deposit request: $err')),
                                    );
                                  }
                                } else {
                                  // Instant Demo Deposit Flow
                                  try {
                                    final res = await ApiService.deposit(amount: amt);
                                    modalNavigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(res['message']?.toString() ?? 'Deposit successful!'),
                                        backgroundColor: teal,
                                      ),
                                    );
                                    loadWalletData();
                                  } catch (err) {
                                    setModalState(() => isSubmitting = false);
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Deposit failed: $err')),
                                    );
                                  }
                                }
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

  void showWhatsAppConfirmationDialog({
    required double amount,
    required String refId,
    required String waUrl,
    required String adminPhone,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.chat, color: green, size: 28),
            SizedBox(width: 10),
            Text('Deposit Request Created', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: teal),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Reference ID: ', style: TextStyle(color: Colors.white60)),
                SelectableText(
                  refId,
                  style: const TextStyle(color: gold, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: refId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reference ID copied!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Admin WhatsApp: $adminPhone\n\nTap below to open WhatsApp with the prefilled payment verification message. Once Admin confirms receipt, your wallet will be credited instantly!',
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Later', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.black),
            icon: const Icon(Icons.open_in_new, size: 18, color: Colors.black),
            label: const Text('OPEN WHATSAPP NOW', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.parse(waUrl);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open WhatsApp automatically. Contact: $adminPhone')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void showWithdrawDialog() {
    final amountController = TextEditingController(text: '50');
    final upiController = TextEditingController(text: 'user@upi');
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Withdraw to Bank / UPI',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Available for withdrawal: ₹${balance.toStringAsFixed(2)}',
                    style: const TextStyle(color: teal, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Withdraw Amount (₹)',
                      prefixIcon: Icon(Icons.currency_rupee, color: pink),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: upiController,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID / VPA',
                      hintText: 'e.g. mobile@okhdfcbank',
                      prefixIcon: Icon(Icons.account_balance, color: purple),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                              final messenger = ScaffoldMessenger.of(this.context);
                              final modalNavigator = Navigator.of(context);

                              if (amt < 10.0) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Minimum withdrawal is ₹10.00')),
                                );
                                return;
                              }
                              if (amt > balance) {
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('Insufficient wallet balance')),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                final res = await ApiService.withdraw(
                                  amount: amt,
                                  accountInfo: upiController.text.trim(),
                                );
                                modalNavigator.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message']?.toString() ?? 'Withdrawal processed!'),
                                    backgroundColor: purple,
                                  ),
                                );
                                loadWalletData();
                              } catch (err) {
                                setModalState(() => isSubmitting = false);
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Withdrawal failed: $err')),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CONFIRM WITHDRAWAL',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                    ),
                  ),
                ],
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
      appBar: AppBar(
        title: const Text(
          'VIRTUAL WALLET',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: teal),
            onPressed: loadWalletData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadWalletData,
        color: teal,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Wallet Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5E27C5), Color(0xFFC02D7F), Color(0xFF1E438D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: purple.withValues(alpha: 0.35),
                    blurRadius: 25,
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
                        'TOTAL BALANCE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          currency,
                          style: const TextStyle(
                            color: teal,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  isLoading
                      ? const SizedBox(
                          height: 48,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        )
                      : Text(
                          '₹${balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                  const SizedBox(height: 6),
                  const Text(
                    '₹100 Welcome Bonus Included 🎉',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text(
                            'ADD CASH',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: showDepositDialog,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white60, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_upward, size: 20),
                          label: const Text(
                            'WITHDRAW',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: showWithdrawDialog,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Transactions Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Recent',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (isLoading && transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: teal),
                ),
              )
            else if (errorMessage != null && transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: pink, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: loadWalletData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: Colors.white38, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'No transactions yet.',
                      style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Play games or deposit funds to see your activity.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final txn = Map<String, dynamic>.from(transactions[index] as Map);
                  final amt = double.tryParse(txn['amount']?.toString() ?? '0') ?? 0.0;
                  final isPositive = amt >= 0;
                  final type = txn['transaction_type']?.toString() ?? 'deposit';
                  final txnStatus = txn['status']?.toString() ?? 'success';
                  final desc = txn['description']?.toString() ?? type;
                  final date = txn['created_at']?.toString() ?? '';
                  final isPending = txnStatus == 'pending';

                  IconData icon;
                  Color iconColor;

                  switch (type) {
                    case 'deposit':
                      icon = isPending ? Icons.hourglass_top : Icons.add_circle;
                      iconColor = isPending ? gold : teal;
                      break;
                    case 'withdrawal':
                      icon = Icons.arrow_outward;
                      iconColor = pink;
                      break;
                    case 'game_win':
                      icon = Icons.emoji_events;
                      iconColor = gold;
                      break;
                    case 'game_bet':
                      icon = Icons.sports_esports;
                      iconColor = purple;
                      break;
                    default:
                      icon = Icons.swap_horiz;
                      iconColor = blue;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isPending ? gold.withValues(alpha: 0.4) : Colors.white10,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                desc,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    date.length > 10 ? date.substring(0, 10) : date,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (isPending) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: gold.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'PENDING APPROVAL',
                                        style: TextStyle(
                                          color: gold,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isPositive ? '+' : ''}₹${amt.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isPending ? gold : (isPositive ? teal : pink),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bal: ₹${txn['balance_after'] ?? '0.00'}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
