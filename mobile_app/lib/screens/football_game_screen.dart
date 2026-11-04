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

class FootballGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const FootballGameScreen({
    super.key,
    required this.userBalance,
    this.entryFee = 20.0,
    this.onGameFinished,
  });

  @override
  State<FootballGameScreen> createState() => _FootballGameScreenState();
}

class _FootballGameScreenState extends State<FootballGameScreen> {
  final int totalKicks = 5;
  int kicksTaken = 0;
  int playerGoals = 0;
  int opponentGoals = 0;

  String? lastKeeperDive;
  String? lastPlayerTarget;
  String commentary = 'Tap a goal corner to strike the penalty kick!';
  bool isKicking = false;
  bool isGameOver = false;

  String? matchRef;
  String? whatsappUrl;
  List<bool?> playerKickHistory = [null, null, null, null, null];

  final List<String> targets = ['Top Left', 'Top Right', 'Bottom Left', 'Bottom Right', 'Center'];

  void takeKick(String target) {
    if (isKicking || isGameOver) return;

    final rand = Random();
    final keeperDive = targets[rand.nextInt(targets.length)];

    setState(() {
      isKicking = true;
      lastPlayerTarget = target;
      lastKeeperDive = keeperDive;
      commentary = 'Shooting towards $target...';
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;

      final isGoal = target != keeperDive;
      final opponentScored = rand.nextDouble() > 0.4; // Opponent bot kick

      setState(() {
        isKicking = false;
        kicksTaken++;
        playerKickHistory[kicksTaken - 1] = isGoal;
        if (isGoal) {
          playerGoals++;
          commentary = 'GOOOAAAL! Superb placement into $target!';
        } else {
          commentary = 'SAVED! Goalkeeper guessed $keeperDive and made the stop!';
        }
        if (opponentScored) opponentGoals++;
      });

      // Check match end
      if (kicksTaken >= totalKicks) {
        if (playerGoals > opponentGoals) {
          finishMatch('win', 'Penalty Shootout Won ($playerGoals - $opponentGoals)!');
        } else if (playerGoals < opponentGoals) {
          finishMatch('loss', 'Shootout Defeat ($playerGoals - $opponentGoals).');
        } else {
          finishMatch('win', 'Sudden Death Victory ($playerGoals - $opponentGoals)!');
        }
      }
    });
  }

  Future<void> finishMatch(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.85) : 0.0;

    try {
      final res = await ApiService.recordMatch(
        gameName: 'Speed Football',
        gameSlug: 'football',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {'score': '$playerGoals-$opponentGoals', 'reason': reason},
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
            Text(isWin ? 'SHOOTOUT VICTORY!' : 'SHOOTOUT DEFEAT', style: TextStyle(color: isWin ? gold : pink, fontWeight: FontWeight.bold)),
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
                  Text(isWin ? 'Prize Payout:' : 'Match Fee:', style: const TextStyle(color: Colors.white70)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Football (Penalties)'),
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
              // Scoreboard
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: teal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('YOU', style: TextStyle(color: teal, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$playerGoals', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        const Text('PENALTIES', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                        Column(
                          children: [
                            const Text('BOT', style: TextStyle(color: pink, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('$opponentGoals', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Kicks history dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalKicks, (i) {
                        final res = playerKickHistory[i];
                        Color dotColor = Colors.white12;
                        IconData icon = Icons.circle;
                        if (res == true) { dotColor = teal; icon = Icons.check; }
                        else if (res == false) { dotColor = pink; icon = Icons.close; }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                          child: Icon(icon, color: Colors.white, size: 14),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Commentary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: purple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(commentary, textAlign: TextAlign.center, style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 13)),
              ),

              const SizedBox(height: 16),

              // Goal Post Area with 5 target zones
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20), // Pitch green
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white70, width: 4), // Goal posts
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Goalkeeper representation
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 400),
                        alignment: _getKeeperAlignment(lastKeeperDive),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 18, backgroundColor: gold, child: Icon(Icons.sports_handball, color: Colors.black, size: 20)),
                            SizedBox(height: 2),
                            Text('Keeper', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // Target Zones Grid (Top Left, Top Right, Bottom Left, Bottom Right, Center)
                      Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _targetZone('Top Left', Alignment.topLeft),
                                _targetZone('Top Right', Alignment.topRight),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                _targetZone('Center', Alignment.center),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                _targetZone('Bottom Left', Alignment.bottomLeft),
                                _targetZone('Bottom Right', Alignment.bottomRight),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text('TAP ANY TARGET ZONE IN THE GOAL POST TO SHOOT', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Alignment _getKeeperAlignment(String? dive) {
    if (dive == 'Top Left') return const Alignment(-0.7, -0.6);
    if (dive == 'Top Right') return const Alignment(0.7, -0.6);
    if (dive == 'Bottom Left') return const Alignment(-0.7, 0.6);
    if (dive == 'Bottom Right') return const Alignment(0.7, 0.6);
    return Alignment.center;
  }

  Widget _targetZone(String label, Alignment align) {
    return Expanded(
      child: GestureDetector(
        onTap: (isKicking || isGameOver) ? null : () => takeKick(label),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24, style: BorderStyle.solid),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
