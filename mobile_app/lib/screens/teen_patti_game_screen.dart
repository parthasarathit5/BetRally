import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

class TeenPattiGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const TeenPattiGameScreen({
    super.key,
    required this.userBalance,
    this.entryFee = 20.0,
    this.onGameFinished,
  });

  @override
  State<TeenPattiGameScreen> createState() => _TeenPattiGameScreenState();
}

class _TeenPattiGameScreenState extends State<TeenPattiGameScreen> {
  List<Map<String, dynamic>> playerHand = [];
  List<Map<String, dynamic>> opponentHand = [];
  bool hasSeenCards = false;
  double pot = 40.0;
  double currentChaal = 20.0;

  bool isGameOver = false;
  String? matchRef;
  String? whatsappUrl;
  String message = 'Cards dealt! Play Blind or See Cards.';

  final List<String> suits = ['♠', '♥', '♦', '♣'];

  @override
  void initState() {
    super.initState();
    dealHands();
  }

  void dealHands() {
    final rand = Random();
    playerHand = [
      {'suit': suits[rand.nextInt(4)], 'val': rand.nextInt(13) + 2},
      {'suit': suits[rand.nextInt(4)], 'val': rand.nextInt(13) + 2},
      {'suit': suits[rand.nextInt(4)], 'val': rand.nextInt(13) + 2},
    ];
    opponentHand = [
      {'suit': suits[rand.nextInt(4)], 'val': rand.nextInt(13) + 2},
      {'suit': suits[rand.nextInt(4)], 'val': rand.nextInt(13) + 2},
      {'suit': suits[rand.nextInt(4)], 'val': rand.nextInt(13) + 2},
    ];
    pot = widget.entryFee * 2;
  }

  int evaluateScore(List<Map<String, dynamic>> hand) {
    hand.sort((a, b) => (b['val'] as int).compareTo(a['val'] as int));
    final v0 = hand[0]['val'] as int;
    final v1 = hand[1]['val'] as int;
    final v2 = hand[2]['val'] as int;
    final s0 = hand[0]['suit'];
    final s1 = hand[1]['suit'];
    final s2 = hand[2]['suit'];

    final isFlush = (s0 == s1 && s1 == s2);
    final isStraight = (v0 == v1 + 1 && v1 == v2 + 1);

    if (v0 == v1 && v1 == v2) return 60000 + v0; // Trail (Three of a kind)
    if (isFlush && isStraight) return 50000 + v0; // Pure Sequence
    if (isStraight) return 40000 + v0; // Sequence
    if (isFlush) return 30000 + v0; // Color
    if (v0 == v1 || v1 == v2) return 20000 + (v0 == v1 ? v0 : v1); // Pair
    return v0 * 100 + v1 * 10 + v2; // High Card
  }

  void makeChaal() {
    if (isGameOver) return;
    setState(() {
      pot += currentChaal;
      message = 'Chaal placed (+₹$currentChaal). Opponent matches...';
    });

    // Opponent matches after 1s
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || isGameOver) return;
      setState(() {
        pot += currentChaal;
        message = 'Opponent called! Pot is now ₹${pot.toStringAsFixed(0)}.';
      });
    });
  }

  void showdown() {
    if (isGameOver) return;
    hasSeenCards = true;

    final pScore = evaluateScore(playerHand);
    final oScore = evaluateScore(opponentHand);

    if (pScore >= oScore) {
      endGame('win', 'SHOWDOWN WIN! Your hand beats opponent hand!');
    } else {
      endGame('loss', 'SHOWDOWN DEFEAT! Opponent held higher cards.');
    }
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? pot : 0.0;

    try {
      final res = await ApiService.recordMatch(
        gameName: 'Teen Patti',
        gameSlug: 'teen-patti',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {'reason': reason, 'pot': pot},
      );
      if (!mounted) return;
      setState(() {
        matchRef = res['reference_id']?.toString();
        whatsappUrl = res['whatsapp_admin_url']?.toString();
      });
      widget.onGameFinished?.call();
    } catch (_) {}

    _showResultDialog(outcome, reason, payout);
  }

  void _showResultDialog(String outcome, String reason, double payout) {
    final isWin = outcome == 'win';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied, color: isWin ? gold : pink, size: 28),
            const SizedBox(width: 10),
            Text(isWin ? 'POT WON!' : 'PACK / LOST', style: TextStyle(color: isWin ? gold : pink, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isWin ? teal.withValues(alpha: 0.15) : pink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isWin ? 'Total Pot Won:' : 'Match Fee:', style: const TextStyle(color: Colors.white70)),
                  Text(
                    isWin ? '+₹${payout.toStringAsFixed(2)}' : '-₹${widget.entryFee.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isWin ? teal : pink),
                  ),
                ],
              ),
            ),
            if (matchRef != null) ...[
              const SizedBox(height: 10),
              Text('Match Ref: $matchRef', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ],
        ),
        actions: [
          if (whatsappUrl != null)
            TextButton.icon(
              icon: const Icon(Icons.chat, color: green, size: 18),
              label: const Text('REPORT TO ADMIN', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final uri = Uri.parse(whatsappUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('BACK TO GAMES'),
          ),
        ],
      ),
    );
  }

  String formatCard(Map<String, dynamic> c) {
    final v = c['val'] as int;
    String name = '$v';
    if (v == 14) {
      name = 'A';
    } else if (v == 11) {
      name = 'J';
    } else if (v == 12) {
      name = 'Q';
    } else if (v == 13) {
      name = 'K';
    }
    return '$name${c['suit']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teen Patti (3 Cards)'),
        backgroundColor: bg,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: gold, size: 16),
                const SizedBox(width: 4),
                Text('Entry ₹${widget.entryFee.toStringAsFixed(0)}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Opponent Area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('OPPONENT BOT', style: TextStyle(color: pink, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: opponentHand.map((c) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 50,
                          height: 75,
                          decoration: BoxDecoration(
                            color: isGameOver ? Colors.white : const Color(0xFF1E3799),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Center(
                            child: isGameOver
                                ? Text(formatCard(c), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                                : const Icon(Icons.lock, color: Colors.white54, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              // Center Pot Pool
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF000000)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gold.withValues(alpha: 0.4), width: 1.5),
                  boxShadow: [BoxShadow(color: gold.withValues(alpha: 0.15), blurRadius: 16)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: gold, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TABLE POT', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('₹${pot.toStringAsFixed(0)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: gold)),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(message, style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 12)),
              ),

              const Spacer(),

              // Player Hand
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('YOUR CARDS', style: TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 10),
                      if (!hasSeenCards && !isGameOver)
                        TextButton(
                          onPressed: () => setState(() => hasSeenCards = true),
                          child: const Text('SEE CARDS (CHAAL x2)', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: playerHand.map((c) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 70,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                        ),
                        child: Center(
                          child: hasSeenCards
                              ? Text(
                                  formatCard(c),
                                  style: TextStyle(
                                    color: (c['suit'] == '♥' || c['suit'] == '♦') ? Colors.red : Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Icon(Icons.style, color: Colors.black38, size: 28),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: pink,
                          side: const BorderSide(color: pink),
                        ),
                        onPressed: isGameOver ? null : () => endGame('loss', 'You packed your hand.'),
                        child: const Text('PACK (FOLD)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: isGameOver ? null : makeChaal,
                        child: Text(hasSeenCards ? 'CHAAL ₹$currentChaal' : 'BLIND ₹${currentChaal / 2}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: isGameOver ? null : showdown,
                        child: const Text('SHOWDOWN', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
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
}
