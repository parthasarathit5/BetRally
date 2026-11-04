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

class CarromCoin {
  double x; // -1.0 to 1.0 (relative board coords)
  double y;
  double vx;
  double vy;
  final String type; // 'white', 'black', 'queen', 'striker'
  bool isPocketed;

  CarromCoin({
    required this.x,
    required this.y,
    this.vx = 0.0,
    this.vy = 0.0,
    required this.type,
    this.isPocketed = false,
  });
}

class CarromGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const CarromGameScreen({
    super.key,
    required this.userBalance,
    this.entryFee = 20.0,
    this.onGameFinished,
  });

  @override
  State<CarromGameScreen> createState() => _CarromGameScreenState();
}

class _CarromGameScreenState extends State<CarromGameScreen> {
  int playerScore = 0;
  int opponentScore = 0;
  final int targetScore = 25;

  bool isPlayerTurn = true;
  bool isAiming = false;
  double strikerBaseX = 0.0; // -0.7 to 0.7 on baseline
  double aimAngle = -pi / 2; // radians (-pi to 0)
  double shotPower = 0.7; // 0.1 to 1.0

  List<CarromCoin> coins = [];
  Timer? physicsTimer;
  bool isSimulationRunning = false;
  bool isGameOver = false;
  String? matchRef;
  String? whatsappUrl;
  String statusMessage = 'Aim striker and release shot!';

  @override
  void initState() {
    super.initState();
    resetBoard();
  }

  @override
  void dispose() {
    physicsTimer?.cancel();
    super.dispose();
  }

  void resetBoard() {
    coins = [
      // Red Queen in center
      CarromCoin(x: 0, y: 0, type: 'queen'),
      // Ring of white & black coins
      CarromCoin(x: 0.15, y: 0, type: 'white'),
      CarromCoin(x: -0.15, y: 0, type: 'white'),
      CarromCoin(x: 0, y: 0.15, type: 'white'),
      CarromCoin(x: 0, y: -0.15, type: 'white'),
      CarromCoin(x: 0.11, y: 0.11, type: 'black'),
      CarromCoin(x: -0.11, y: 0.11, type: 'black'),
      CarromCoin(x: 0.11, y: -0.11, type: 'black'),
      CarromCoin(x: -0.11, y: -0.11, type: 'black'),
      // Striker at player baseline
      CarromCoin(x: strikerBaseX, y: 0.75, type: 'striker'),
    ];
  }

  void fireStriker() {
    if (isSimulationRunning || isGameOver) return;

    final striker = coins.firstWhere((c) => c.type == 'striker');
    striker.x = strikerBaseX;
    striker.y = isPlayerTurn ? 0.75 : -0.75;
    striker.vx = cos(aimAngle) * (shotPower * 0.08);
    striker.vy = sin(aimAngle) * (shotPower * 0.08);

    setState(() {
      isSimulationRunning = true;
      statusMessage = isPlayerTurn ? 'Shot in motion!' : 'Opponent shot fired!';
    });

    physicsTimer?.cancel();
    int ticks = 0;
    physicsTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      ticks++;
      bool anyMoving = false;

      // Update positions & friction
      for (final coin in coins) {
        if (coin.isPocketed) continue;

        coin.x += coin.vx;
        coin.y += coin.vy;

        // Friction
        coin.vx *= 0.96;
        coin.vy *= 0.96;

        if (coin.vx.abs() > 0.001 || coin.vy.abs() > 0.001) {
          anyMoving = true;
        }

        // Cushion bounce
        if (coin.x < -0.85) { coin.x = -0.85; coin.vx = -coin.vx * 0.8; }
        if (coin.x > 0.85) { coin.x = 0.85; coin.vx = -coin.vx * 0.8; }
        if (coin.y < -0.85) { coin.y = -0.85; coin.vy = -coin.vy * 0.8; }
        if (coin.y > 0.85) { coin.y = 0.85; coin.vy = -coin.vy * 0.8; }

        // Check 4 corner pockets: (+/- 0.82, +/- 0.82)
        for (final px in [-0.85, 0.85]) {
          for (final py in [-0.85, 0.85]) {
            final dist = sqrt(pow(coin.x - px, 2) + pow(coin.y - py, 2));
            if (dist < 0.14 && !coin.isPocketed) {
              coin.isPocketed = true;
              coin.vx = 0;
              coin.vy = 0;
              onCoinPocketed(coin);
            }
          }
        }
      }

      // Coin-to-coin elastic collisions
      for (int i = 0; i < coins.length; i++) {
        for (int j = i + 1; j < coins.length; j++) {
          final c1 = coins[i];
          final c2 = coins[j];
          if (c1.isPocketed || c2.isPocketed) continue;

          final dx = c2.x - c1.x;
          final dy = c2.y - c1.y;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < 0.12 && dist > 0.0001) {
            // Collision resolution
            final nx = dx / dist;
            final ny = dy / dist;
            final kx = c1.vx - c2.vx;
            final ky = c1.vy - c2.vy;
            final p = 2 * (nx * kx + ny * ky) / 2;
            c1.vx -= p * nx;
            c1.vy -= p * ny;
            c2.vx += p * nx;
            c2.vy += p * ny;
          }
        }
      }

      setState(() {});

      if (!anyMoving || ticks > 120) {
        timer.cancel();
        isSimulationRunning = false;
        onShotFinished();
      }
    });
  }

  void onCoinPocketed(CarromCoin coin) {
    if (coin.type == 'striker') return; // Foul

    int pts = 0;
    if (coin.type == 'white') {
      pts = 10;
    } else if (coin.type == 'black') {
      pts = 5;
    } else if (coin.type == 'queen') {
      pts = 25;
    }

    if (isPlayerTurn) {
      playerScore += pts;
      statusMessage = 'POCKETED ${coin.type.toUpperCase()}! +$pts points!';
    } else {
      opponentScore += pts;
      statusMessage = 'Opponent pocketed ${coin.type.toUpperCase()}! +$pts points.';
    }
  }

  void onShotFinished() {
    // Reset striker
    final striker = coins.firstWhere((c) => c.type == 'striker');
    striker.isPocketed = false;
    striker.vx = 0;
    striker.vy = 0;

    // Check game over
    if (playerScore >= targetScore || opponentScore >= targetScore) {
      final isWin = playerScore >= targetScore;
      endGame(isWin ? 'win' : 'loss', isWin ? 'Victory! You reached $playerScore points!' : 'Defeat! Opponent reached $opponentScore points.');
      return;
    }

    // Toggle turn
    setState(() {
      isPlayerTurn = !isPlayerTurn;
      if (isPlayerTurn) {
        striker.x = strikerBaseX;
        striker.y = 0.75;
        aimAngle = -pi / 2;
        statusMessage = 'Your turn! Aim and release.';
      } else {
        striker.x = 0.0;
        striker.y = -0.75;
        statusMessage = 'Opponent aiming striker...';
      }
    });

    if (!isPlayerTurn && !isGameOver) {
      // Opponent AI takes shot
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted || isGameOver) return;
        aimAngle = pi / 2 + (Random().nextDouble() * 0.8 - 0.4);
        shotPower = 0.6 + Random().nextDouble() * 0.35;
        fireStriker();
      });
    }
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.85) : 0.0;

    try {
      final res = await ApiService.recordMatch(
        gameName: 'Carrom King',
        gameSlug: 'carrom',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {
          'player_score': playerScore,
          'opponent_score': opponentScore,
          'target': targetScore,
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
            Text(isWin ? 'CARROM CHAMPION!' : 'MATCH LOST', style: TextStyle(color: isWin ? gold : pink, fontWeight: FontWeight.bold)),
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
        title: const Text('Carrom King (Board)'),
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
              // Scores Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('YOU (WHITE/QUEEN)', style: TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$playerScore pts', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('First to $targetScore', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('OPPONENT AI', style: TextStyle(color: pink, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('$opponentScore pts', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isPlayerTurn ? teal.withValues(alpha: 0.15) : purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    statusMessage,
                    style: TextStyle(
                      color: isPlayerTurn ? teal : purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              // Carrom Board Container
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5B782), // Polished plywood wooden board
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF5C3317), width: 14), // Dark mahogany frame
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 15),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;

                            return Stack(
                              children: [
                                // Center circle ring
                                Center(
                                  child: Container(
                                    width: w * 0.35,
                                    height: h * 0.35,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFC0392B), width: 2),
                                    ),
                                  ),
                                ),
                                // Baselines
                                Positioned(
                                  bottom: h * 0.12,
                                  left: w * 0.15,
                                  right: w * 0.15,
                                  child: Container(
                                    height: 3,
                                    color: const Color(0xFFC0392B).withValues(alpha: 0.7),
                                  ),
                                ),
                                // 4 Corner Pockets
                                Positioned(left: 4, top: 4, child: _pocketCircle()),
                                Positioned(right: 4, top: 4, child: _pocketCircle()),
                                Positioned(left: 4, bottom: 4, child: _pocketCircle()),
                                Positioned(right: 4, bottom: 4, child: _pocketCircle()),

                                // Coins
                                for (final coin in coins)
                                  if (!coin.isPocketed)
                                    Positioned(
                                      left: (coin.x + 1) / 2 * w - (coin.type == 'striker' ? 16 : 12),
                                      top: (coin.y + 1) / 2 * h - (coin.type == 'striker' ? 16 : 12),
                                      child: _buildCoinWidget(coin),
                                    ),

                                // Aiming ray when player's turn
                                if (isPlayerTurn && !isSimulationRunning)
                                  CustomPaint(
                                    size: Size(w, h),
                                    painter: _AimPainter(
                                      originX: (strikerBaseX + 1) / 2 * w,
                                      originY: 0.75 * h + h * 0.12,
                                      angle: aimAngle,
                                      power: shotPower,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Player Controls (Striker Position & Aim Angle)
              if (isPlayerTurn && !isSimulationRunning && !isGameOver)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Aim Angle', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Expanded(
                            child: Slider(
                              value: aimAngle,
                              min: -pi * 0.95,
                              max: -pi * 0.05,
                              activeColor: teal,
                              onChanged: (val) => setState(() => aimAngle = val),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Shot Power', style: TextStyle(fontSize: 12, color: Colors.white70)),
                          Expanded(
                            child: Slider(
                              value: shotPower,
                              min: 0.2,
                              max: 1.0,
                              activeColor: gold,
                              onChanged: (val) => setState(() => shotPower = val),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.flash_on),
                          label: const Text('STRIKE COIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: fireStriker,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pocketCircle() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCoinWidget(CarromCoin coin) {
    final isStriker = coin.type == 'striker';
    final isQueen = coin.type == 'queen';
    final isWhite = coin.type == 'white';

    Color c = isStriker ? Colors.white : (isQueen ? const Color(0xFFE74C3C) : (isWhite ? const Color(0xFFF7F9F9) : const Color(0xFF2C3E50)));

    return Container(
      width: isStriker ? 32 : 24,
      height: isStriker ? 32 : 24,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(
          color: isStriker ? teal : (isQueen ? gold : Colors.black45),
          width: isStriker ? 3 : 1.5,
        ),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2))],
      ),
      child: isQueen ? const Center(child: Icon(Icons.star, size: 12, color: gold)) : null,
    );
  }
}

class _AimPainter extends CustomPainter {
  final double originX;
  final double originY;
  final double angle;
  final double power;

  _AimPainter({
    required this.originX,
    required this.originY,
    required this.angle,
    required this.power,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = teal.withValues(alpha: 0.7)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final length = 60.0 + power * 90.0;
    final endX = originX + cos(angle) * length;
    final endY = originY + sin(angle) * length;

    canvas.drawLine(Offset(originX, originY), Offset(endX, endY), paint);
    canvas.drawCircle(Offset(endX, endY), 4, Paint()..color = gold);
  }

  @override
  bool shouldRepaint(covariant _AimPainter oldDelegate) =>
      oldDelegate.originX != originX ||
      oldDelegate.originY != originY ||
      oldDelegate.angle != angle ||
      oldDelegate.power != power;
}
