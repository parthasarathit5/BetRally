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

class AviatorGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const AviatorGameScreen({
    super.key,
    required this.userBalance,
    this.entryFee = 10.0,
    this.onGameFinished,
  });

  @override
  State<AviatorGameScreen> createState() => _AviatorGameScreenState();
}

class _AviatorGameScreenState extends State<AviatorGameScreen> {
  double currentMultiplier = 1.00;
  double crashPoint = 2.50;
  bool isFlying = false;
  bool hasCashedOut = false;
  bool hasCrashed = false;
  Timer? flightTimer;

  String? matchRef;
  String? whatsappUrl;
  double payout = 0.0;

  @override
  void initState() {
    super.initState();
    startFlight();
  }

  @override
  void dispose() {
    flightTimer?.cancel();
    super.dispose();
  }

  void startFlight() {
    // Generate crash point (between 1.10x and 12.00x)
    final rand = Random();
    crashPoint = 1.10 + (pow(rand.nextDouble(), 2) * 8.0);
    currentMultiplier = 1.00;
    isFlying = true;
    hasCashedOut = false;
    hasCrashed = false;

    flightTimer?.cancel();
    flightTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        currentMultiplier += 0.02 + (currentMultiplier * 0.005);
        if (currentMultiplier >= crashPoint) {
          timer.cancel();
          isFlying = false;
          hasCrashed = true;
          if (!hasCashedOut) {
            onGameEnded('loss', 'FLEW AWAY! Plane crashed at ${crashPoint.toStringAsFixed(2)}x.');
          }
        }
      });
    });
  }

  void cashOut() {
    if (!isFlying || hasCashedOut || hasCrashed) return;
    flightTimer?.cancel();
    setState(() {
      hasCashedOut = true;
      isFlying = false;
      payout = widget.entryFee * currentMultiplier;
    });

    onGameEnded('win', 'CASHED OUT AT ${currentMultiplier.toStringAsFixed(2)}x!');
  }

  Future<void> onGameEnded(String outcome, String reason) async {
    final isWin = outcome == 'win';
    final winPayout = isWin ? (widget.entryFee * currentMultiplier) : 0.0;

    try {
      final res = await ApiService.recordMatch(
        gameName: 'Aviator Crash',
        gameSlug: 'aviator',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: winPayout,
        scoreDetails: {
          'multiplier': currentMultiplier.toStringAsFixed(2),
          'crash_point': crashPoint.toStringAsFixed(2),
          'reason': reason,
        },
      );
      if (!mounted) return;
      setState(() {
        matchRef = res['reference_id']?.toString();
        whatsappUrl = res['whatsapp_admin_url']?.toString();
      });
      widget.onGameFinished?.call();
    } catch (_) {}

    _showResultDialog(outcome, reason, winPayout);
  }

  void _showResultDialog(String outcome, String reason, double payoutAmount) {
    final isWin = outcome == 'win';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isWin ? Icons.flight_takeoff : Icons.flight_land, color: isWin ? gold : pink, size: 28),
            const SizedBox(width: 10),
            Text(isWin ? 'BIG CASHOUT!' : 'CRASHED!', style: TextStyle(color: isWin ? gold : pink, fontWeight: FontWeight.bold)),
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
                    isWin ? '+₹${payoutAmount.toStringAsFixed(2)}' : '-₹${widget.entryFee.toStringAsFixed(2)}',
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
        title: const Text('Aviator Crash'),
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
              // Radar Screen Area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1226),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: hasCrashed ? pink : purple, width: 2),
                    boxShadow: [
                      BoxShadow(color: (hasCrashed ? pink : purple).withValues(alpha: 0.2), blurRadius: 20),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Grid lines
                      for (int i = 1; i <= 4; i++)
                        Positioned(
                          bottom: i * 60.0,
                          left: 0,
                          right: 0,
                          child: Container(height: 1, color: Colors.white10),
                        ),
                      // Multiplier display
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${currentMultiplier.toStringAsFixed(2)}x',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: hasCrashed ? pink : (hasCashedOut ? teal : Colors.white),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasCrashed ? 'FLEW AWAY!' : (hasCashedOut ? 'CASHED OUT!' : 'CURRENT MULTIPLIER'),
                              style: TextStyle(
                                color: hasCrashed ? pink : (hasCashedOut ? teal : gold),
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Animated rocket plane icon
                      Positioned(
                        bottom: min(240, 20 + (currentMultiplier - 1.0) * 80),
                        left: min(300, 20 + (currentMultiplier - 1.0) * 90),
                        child: Transform.rotate(
                          angle: -pi / 6,
                          child: Icon(
                            hasCrashed ? Icons.local_fire_department : Icons.rocket_launch,
                            size: 44,
                            color: hasCrashed ? pink : gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Cashout Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (isFlying && !hasCashedOut) ? gold : surface,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: (isFlying && !hasCashedOut) ? cashOut : null,
                    child: Text(
                      isFlying
                          ? 'CASHOUT ₹${(widget.entryFee * currentMultiplier).toStringAsFixed(2)}'
                          : (hasCrashed ? 'FLEW AWAY' : 'PLAYING...'),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

