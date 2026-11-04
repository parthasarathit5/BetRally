import 'dart:async';
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

class CricketGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const CricketGameScreen({
    super.key,
    required this.userBalance,
    this.entryFee = 25.0,
    this.onGameFinished,
  });

  @override
  State<CricketGameScreen> createState() => _CricketGameScreenState();
}

class _CricketGameScreenState extends State<CricketGameScreen> {
  final int totalBalls = 6;
  int ballsBowled = 0;
  int score = 0;
  int wickets = 0;
  final int targetScore = 20;

  bool isBowling = false;
  String currentBallType = 'Yorker (145 km/h)';
  String ballOutcomeText = 'Tap a shot when bowler delivers!';
  double timingIndicator = 0.5; // 0.0 to 1.0 (0.4-0.6 is perfect timing!)
  Timer? swingTimer;

  bool isGameOver = false;
  String? matchRef;
  String? whatsappUrl;
  List<String> overTimeline = [];

  final List<String> deliveryTypes = [
    'Fast Yorker (148 km/h)',
    'In-swinger (142 km/h)',
    'Sharp Bouncer (140 km/h)',
    'Off-Cutter (128 km/h)',
    'Googly / Spin (105 km/h)',
  ];

  @override
  void initState() {
    super.initState();
    startDeliveryCycle();
  }

  @override
  void dispose() {
    swingTimer?.cancel();
    super.dispose();
  }

  void startDeliveryCycle() {
    if (isGameOver) return;
    setState(() {
      isBowling = true;
      currentBallType = deliveryTypes[Random().nextInt(deliveryTypes.length)];
      ballOutcomeText = 'Bowler running in... Select shot!';
    });

    // Oscillate timing indicator
    double dir = 0.05;
    swingTimer?.cancel();
    swingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || isGameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        timingIndicator += dir;
        if (timingIndicator >= 1.0) {
          timingIndicator = 1.0;
          dir = -0.05;
        } else if (timingIndicator <= 0.0) {
          timingIndicator = 0.0;
          dir = 0.05;
        }
      });
    });
  }

  void playShot(String shotType) {
    if (!isBowling || isGameOver) return;
    swingTimer?.cancel();

    // Timing precision: distance from 0.5
    final diff = (timingIndicator - 0.5).abs();
    int runs = 0;
    String comment = '';
    bool out = false;

    if (diff < 0.08) {
      // Perfect timing!
      runs = (shotType == 'Loft' || shotType == 'Pull') ? 6 : 4;
      comment = runs == 6 ? 'MASSIVE SIX! Out of the ground!' : 'CRACKING FOUR! Beautiful timing!';
    } else if (diff < 0.20) {
      // Good timing
      runs = (shotType == 'Drive' || shotType == 'Cut') ? 4 : 2;
      comment = runs == 4 ? 'FOUR RUNS! Pierced the gap!' : 'Well placed, two runs taken.';
    } else if (diff < 0.35) {
      // Early or late
      runs = Random().nextBool() ? 1 : 0;
      comment = runs == 1 ? 'Quick single taken.' : 'Dot ball! Beaten by pace.';
    } else {
      // Poor timing: Wicket chance
      out = true;
      comment = 'OUT! Caught by deep fielder!';
    }

    setState(() {
      isBowling = false;
      ballsBowled++;
      if (out) {
        wickets++;
        overTimeline.add('W');
      } else {
        score += runs;
        overTimeline.add('$runs');
      }
      ballOutcomeText = '$shotType: $comment';
    });

    // Check match completion
    if (score >= targetScore) {
      finishMatch('win', 'Target chased down in $ballsBowled balls! Outstanding batting!');
    } else if (wickets >= 2 || ballsBowled >= totalBalls) {
      if (score >= targetScore) {
        finishMatch('win', 'Victory! Chased target successfully!');
      } else {
        finishMatch('loss', 'Defeat! Scored $score/$wickets. Needed $targetScore runs.');
      }
    } else {
      // Next ball in 1.8s
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted || isGameOver) return;
        startDeliveryCycle();
      });
    }
  }

  Future<void> finishMatch(String outcome, String reason) async {
    swingTimer?.cancel();
    setState(() => isGameOver = true);

    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.85) : 0.0;

    try {
      final res = await ApiService.recordMatch(
        gameName: 'Cricket Clash',
        gameSlug: 'cricket',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {
          'score': '$score/$wickets',
          'balls': ballsBowled,
          'target': targetScore,
          'over': overTimeline,
        },
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
            Text(isWin ? 'MATCH WON!' : 'MATCH LOST', style: TextStyle(color: isWin ? gold : pink, fontWeight: FontWeight.bold)),
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
    final ballsLeft = totalBalls - ballsBowled;
    final runsNeeded = max(0, targetScore - score);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cricket Clash T20'),
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
              // Scoreboard Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E284A), Color(0xFF12182B)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: teal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('YOUR SCORE', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('$score / $wickets', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: teal)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('TARGET TO WIN', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('$targetScore runs', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: gold)),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Need $runsNeeded runs in $ballsLeft balls', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('RRR: ${(runsNeeded / max(1, ballsLeft) * 6).toStringAsFixed(1)}', style: const TextStyle(color: purple, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Over ball dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalBalls, (i) {
                        final val = i < overTimeline.length ? overTimeline[i] : null;
                        Color dotColor = Colors.white12;
                        if (val == '4') {
                          dotColor = teal;
                        } else if (val == '6') {
                          dotColor = gold;
                        } else if (val == 'W') {
                          dotColor = pink;
                        } else if (val != null) {
                          dotColor = purple;
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Center(
                            child: Text(
                              val ?? '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Pitch & Delivery Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF163223), // Cricket turf green
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pitch strip
                      Container(
                        width: 80,
                        color: const Color(0xFF8B7355).withValues(alpha: 0.35),
                      ),
                      // Bowler indicator
                      Positioned(
                        top: 20,
                        child: Column(
                          children: [
                            const Icon(Icons.sports_cricket, color: gold, size: 28),
                            const SizedBox(height: 4),
                            Text(currentBallType, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      // Stumps at bottom
                      const Positioned(
                        bottom: 30,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fence, color: gold, size: 36),
                          ],
                        ),
                      ),
                      // Ball outcome message
                      Positioned(
                        bottom: 75,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: teal.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            ballOutcomeText,
                            style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Timing Gauge Meter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  children: [
                    const Text('TIMING SWEET SPOT (Hit when in Center!)', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 16,
                        color: surface,
                        child: Stack(
                          children: [
                            // Center sweet spot
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: 50,
                                color: teal.withValues(alpha: 0.45),
                              ),
                            ),
                            // Moving needle
                            Align(
                              alignment: Alignment(timingIndicator * 2 - 1, 0),
                              child: Container(
                                width: 8,
                                height: 16,
                                color: gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Shot Control Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _shotButton('Cover Drive', 'Drive', Icons.north_east),
                    _shotButton('Straight Loft', 'Loft', Icons.arrow_upward),
                    _shotButton('Pull Shot', 'Pull', Icons.west),
                    _shotButton('Late Cut', 'Cut', Icons.east),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shotButton(String label, String code, IconData icon) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: surface,
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: teal, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      onPressed: (!isBowling || isGameOver) ? null : () => playShot(code),
    );
  }
}
