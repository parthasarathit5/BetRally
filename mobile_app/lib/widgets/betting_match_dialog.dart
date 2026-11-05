import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);
const blue = Color(0xFF398BFF);

class OpponentProfile {
  final String name;
  final String city;
  final int rating;
  final String avatarUrl;

  const OpponentProfile({
    required this.name,
    required this.city,
    required this.rating,
    required this.avatarUrl,
  });
}

final List<OpponentProfile> mockOpponents = [
  const OpponentProfile(name: 'Rahul Sharma', city: 'Mumbai', rating: 1540, avatarUrl: '👨‍💼'),
  const OpponentProfile(name: 'Vikram Patel', city: 'Ahmedabad', rating: 1490, avatarUrl: '🧔'),
  const OpponentProfile(name: 'Pooja Verma', city: 'Bengaluru', rating: 1520, avatarUrl: '👩‍💼'),
  const OpponentProfile(name: 'Arjun Mehta', city: 'Delhi NCR', rating: 1610, avatarUrl: '👨‍🎓'),
  const OpponentProfile(name: 'Sneha Roy', city: 'Kolkata', rating: 1480, avatarUrl: '👩‍🎨'),
  const OpponentProfile(name: 'Karan Singhania', city: 'Chandigarh', rating: 1575, avatarUrl: '🧑‍💻'),
  const OpponentProfile(name: 'Deepak Joshi', city: 'Pune', rating: 1510, avatarUrl: '👨‍🔧'),
  const OpponentProfile(name: 'Ananya Gupta', city: 'Jaipur', rating: 1535, avatarUrl: '👩‍🔬'),
];

class BettingMatchDialog extends StatefulWidget {
  final Map<String, dynamic> game;
  final double userBalance;
  final String adminWhatsApp;
  final Function(double betAmount, OpponentProfile opponent) onMatchConfirmed;

  const BettingMatchDialog({
    super.key,
    required this.game,
    required this.userBalance,
    required this.adminWhatsApp,
    required this.onMatchConfirmed,
  });

  @override
  State<BettingMatchDialog> createState() => _BettingMatchDialogState();
}

class _BettingMatchDialogState extends State<BettingMatchDialog> {
  late double selectedBet;
  bool isSearchingOpponent = false;
  OpponentProfile? matchedOpponent;
  int countdownSeconds = 3;
  Timer? countdownTimer;

  final List<double> betPresets = [10.0, 25.0, 50.0, 100.0, 250.0, 500.0, 1000.0];

  @override
  void initState() {
    super.initState();
    final defaultFee = double.tryParse(widget.game['entry_fee']?.toString() ?? '50') ?? 50.0;
    selectedBet = betPresets.contains(defaultFee) ? defaultFee : 50.0;
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    super.dispose();
  }

  void startMatchmaking() {
    final opponent = mockOpponents[Random().nextInt(mockOpponents.length)];
    setState(() {
      isSearchingOpponent = true;
      matchedOpponent = opponent;
      countdownSeconds = 2;
    });

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdownSeconds > 1) {
        setState(() => countdownSeconds--);
      } else {
        timer.cancel();
        Navigator.pop(context);
        widget.onMatchConfirmed(selectedBet, opponent);
      }
    });
  }

  Future<void> openWhatsAppDeposit() async {
    final cleanPhone = widget.adminWhatsApp.replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = Uri.encodeComponent(
      'Hello Admin, I want to add funds to my BetRally wallet.\n'
      'Game: ${widget.game['name']}\n'
      'Required Stake: ₹${selectedBet.toStringAsFixed(2)}\n'
      'My Current Balance: ₹${widget.userBalance.toStringAsFixed(2)}',
    );
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameName = widget.game['name']?.toString() ?? 'Game';
    final hasEnoughBalance = widget.userBalance >= selectedBet;
    final totalPot = selectedBet * 2;
    final winPayout = (selectedBet * 1.9).toStringAsFixed(2);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: gold.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: isSearchingOpponent ? _buildMatchmakingView() : _buildBetSelectorView(gameName, hasEnoughBalance, totalPot, winPayout),
      ),
    );
  }

  Widget _buildBetSelectorView(String gameName, bool hasEnoughBalance, double totalPot, String winPayout) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Real-Money 2-Player Match',
                    style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white70),
            ),
          ],
        ),
        const Divider(color: Colors.white12, height: 24),

        // Wallet Balance Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: gold, size: 18),
                  SizedBox(width: 8),
                  Text('Your Wallet:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
              Text(
                '₹${widget.userBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: hasEnoughBalance ? green : pink,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Select Bet Stake
        const Text(
          'SELECT ENTRY BET (STAKE):',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: betPresets.map((bet) {
            final isSelected = selectedBet == bet;
            return ChoiceChip(
              label: Text(
                '₹${bet.toInt()}',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: gold,
              backgroundColor: bg,
              side: BorderSide(color: isSelected ? gold : Colors.white24),
              onSelected: (_) => setState(() => selectedBet = bet),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Pot & Prize Pool Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [purple.withValues(alpha: 0.2), blue.withValues(alpha: 0.15)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: purple.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('MATCH POT', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('₹${totalPot.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              Column(
                children: [
                  const Text('WINNER TAKES', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('₹$winPayout', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Forfeit Warning Notice
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fair Play Rule: Leaving or quitting mid-game will forfeit your stake immediately to the opponent.',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action Button
        if (hasEnoughBalance)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: startMatchmaking,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flash_on, size: 20),
                SizedBox(width: 8),
                Text('MATCH WITH REAL PLAYER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          )
        else
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: pink.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pink.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: pink, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Insufficient balance! You need ₹${selectedBet.toStringAsFixed(2)} to enter.',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: openWhatsAppDeposit,
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Add Funds via Admin WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMatchmakingView() {
    final opponent = matchedOpponent!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'MATCHMAKING IN PROGRESS',
          style: TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // User Card
            Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: green, width: 2),
                    color: bg,
                  ),
                  child: const Center(child: Text('👤', style: TextStyle(fontSize: 28))),
                ),
                const SizedBox(height: 6),
                const Text('YOU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Stake: ₹${selectedBet.toInt()}', style: const TextStyle(color: gold, fontSize: 11)),
              ],
            ),

            // VS Badge
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 4),
                Text('Pot: ₹${(selectedBet * 2).toInt()}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),

            // Opponent Card
            Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: pink, width: 2),
                    color: bg,
                  ),
                  child: Center(child: Text(opponent.avatarUrl, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(height: 6),
                Text(opponent.name.split(' ').first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${opponent.city} (🇮🇳)', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const CircularProgressIndicator(color: gold, strokeWidth: 2.5),
        const SizedBox(height: 12),
        Text(
          'Connecting match in $countdownSeconds...',
          style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

