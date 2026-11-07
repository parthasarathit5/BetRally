import 'package:flutter/material.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

class GameResultDialog extends StatefulWidget {
  final String gameName;
  final String gameSlug;
  final bool won;
  final double betAmount;
  final double payoutAmount; // 2x bet (e.g., 20 -> 40, 1000 -> 2000)
  final String reason;
  final Map<String, dynamic> scoreDetails;
  final VoidCallback? onFinished;

  static double calculatePayout(double bet) {
    if (bet >= 1000) return 1800.0;
    if (bet >= 500) return 950.0;
    if (bet >= 250) return 475.0;
    if (bet >= 100) return 200.0;
    if (bet >= 50) return 100.0;
    if (bet >= 25) return 50.0;
    if (bet >= 20) return 40.0;
    if (bet >= 10) return 20.0;
    return bet * 2.0;
  }

  const GameResultDialog({
    super.key,
    required this.gameName,
    required this.gameSlug,
    required this.won,
    required this.betAmount,
    required this.payoutAmount,
    required this.reason,
    this.scoreDetails = const {},
    this.onFinished,
  });

  static Future<void> show({
    required BuildContext context,
    required String gameName,
    required String gameSlug,
    required bool won,
    required double betAmount,
    required double payoutAmount,
    required String reason,
    Map<String, dynamic> scoreDetails = const {},
    VoidCallback? onFinished,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameResultDialog(
        gameName: gameName,
        gameSlug: gameSlug,
        won: won,
        betAmount: betAmount,
        payoutAmount: payoutAmount,
        reason: reason,
        scoreDetails: scoreDetails,
        onFinished: onFinished,
      ),
    );
  }

  @override
  State<GameResultDialog> createState() => _GameResultDialogState();
}

class _GameResultDialogState extends State<GameResultDialog> {
  bool isCollecting = false;
  bool isCollected = false;
  String? referenceId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // If the match is lost, record the loss immediately to deduct entry fee & audit in Supabase
    if (!widget.won) {
      _recordLoss();
    }
  }

  Future<void> _recordLoss() async {
    try {
      final res = await ApiService.recordMatch(
        gameName: widget.gameName,
        gameSlug: widget.gameSlug,
        result: 'loss',
        betAmount: widget.betAmount,
        payoutAmount: 0.0,
        scoreDetails: widget.scoreDetails,
      );
      if (mounted) {
        setState(() {
          referenceId = res['reference_id']?.toString();
        });
        widget.onFinished?.call();
      }
    } catch (_) {}
  }

  Future<void> _collectReward() async {
    if (isCollecting || isCollected) return;

    setState(() {
      isCollecting = true;
      errorMessage = null;
    });

    try {
      final res = await ApiService.recordMatch(
        gameName: widget.gameName,
        gameSlug: widget.gameSlug,
        result: 'win',
        betAmount: widget.betAmount,
        payoutAmount: widget.payoutAmount,
        scoreDetails: widget.scoreDetails,
      );

      if (!mounted) return;

      setState(() {
        isCollecting = false;
        isCollected = true;
        referenceId = res['reference_id']?.toString();
      });

      widget.onFinished?.call();

      // Show confirmation briefly and exit to lobby
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(context).pop(); // Exit game screen to lobby
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isCollecting = false;
        errorMessage = 'Failed to credit wallet. Please try again.';
      });
    }
  }

  void _exitWithoutCollecting() {
    // If player leaves without collecting won reward, they do NOT receive the money
    Navigator.of(context).pop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isWin = widget.won;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isWin ? gold : pink.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isWin ? gold.withValues(alpha: 0.25) : pink.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Trophy / Skull
              CircleAvatar(
                radius: 36,
                backgroundColor: isWin ? gold.withValues(alpha: 0.2) : pink.withValues(alpha: 0.2),
                child: Icon(
                  isWin ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                  color: isWin ? gold : pink,
                  size: 44,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                isWin ? 'VICTORY!' : 'MATCH DEFEAT',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isWin ? gold : pink,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),

              Text(
                widget.reason,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 18),

              // Prize / Loss Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: isWin ? green.withValues(alpha: 0.15) : pink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isWin ? green.withValues(alpha: 0.4) : pink.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isWin ? 'PRIZE TO COLLECT' : 'ENTRY DEDUCTED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isWin ? green : Colors.white60,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWin
                          ? '+₹${widget.payoutAmount.toStringAsFixed(0)}'
                          : '-₹${widget.betAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: isWin ? green : pink,
                      ),
                    ),
                    if (isWin) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Entry: ₹${widget.betAmount.toStringAsFixed(0)} ➔ Pot Won: ₹${widget.payoutAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),

              if (referenceId != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Supabase Ref: $referenceId',
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                ),
              ],

              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              if (isWin) ...[
                if (isCollected) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: green,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.black, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'ADDED TO YOUR WALLET!',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                      ),
                      onPressed: isCollecting ? null : _collectReward,
                      child: isCollecting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.card_giftcard, color: Colors.black, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'COLLECT REWARD ₹${widget.payoutAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: isCollecting ? null : _exitWithoutCollecting,
                    child: const Text(
                      'Forfeit & Exit (Will Not Credit)',
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                ],
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: surface,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'BACK TO LOBBY',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

