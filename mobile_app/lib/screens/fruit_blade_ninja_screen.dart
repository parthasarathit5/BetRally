import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../widgets/betting_match_dialog.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

enum FruitType { watermelon, orange, pineapple, apple, strawberry, bomb }

class FlyingFruit {
  final int id;
  final FruitType type;
  double x;
  double y;
  double vx;
  double vy;
  double rotation;
  double rotationSpeed;
  bool isSliced;
  double sliceAngle;
  double half1X;
  double half1Y;
  double half2X;
  double half2Y;
  double size;

  FlyingFruit({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    this.isSliced = false,
    this.sliceAngle = 0.0,
    this.half1X = 0.0,
    this.half1Y = 0.0,
    this.half2X = 0.0,
    this.half2Y = 0.0,
    this.size = 54.0,
  });

  String get emoji {
    switch (type) {
      case FruitType.watermelon: return '🍉';
      case FruitType.orange: return '🍊';
      case FruitType.pineapple: return '🍍';
      case FruitType.apple: return '🍏';
      case FruitType.strawberry: return '🍓';
      case FruitType.bomb: return '💣';
    }
  }

  int get points {
    switch (type) {
      case FruitType.watermelon: return 15;
      case FruitType.orange: return 10;
      case FruitType.pineapple: return 20;
      case FruitType.apple: return 10;
      case FruitType.strawberry: return 12;
      case FruitType.bomb: return -40;
    }
  }
}

class SplashParticle {
  double x;
  double y;
  double vx;
  double vy;
  Color color;
  double opacity;

  SplashParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    this.opacity = 1.0,
  });
}

class FruitBladeNinjaScreen extends StatefulWidget {
  final double userBalance;
  final double betAmount;
  final OpponentProfile opponent;
  final VoidCallback? onGameFinished;

  const FruitBladeNinjaScreen({
    super.key,
    required this.userBalance,
    required this.betAmount,
    required this.opponent,
    this.onGameFinished,
  });

  @override
  State<FruitBladeNinjaScreen> createState() => _FruitBladeNinjaScreenState();
}

class _FruitBladeNinjaScreenState extends State<FruitBladeNinjaScreen> with SingleTickerProviderStateMixin {
  int playerScore = 0;
  int opponentScore = 0;
  int timeLeft = 45;
  int comboCount = 0;
  String? comboBanner;

  bool isGameOver = false;
  bool isForfeited = false;
  String? matchOutcome; // 'win' or 'loss'
  double payoutWon = 0.0;
  String? matchRef;
  String? adminWhatsApp;

  final List<FlyingFruit> activeFruits = [];
  final List<SplashParticle> particles = [];
  final List<Offset> bladeTrail = [];

  Timer? gameLoopTimer;
  Timer? matchTimer;
  Timer? fruitSpawnerTimer;
  Timer? opponentAiTimer;
  int fruitIdCounter = 0;
  final Random rng = Random();

  @override
  void initState() {
    super.initState();
    startMatch();
  }

  @override
  void dispose() {
    gameLoopTimer?.cancel();
    matchTimer?.cancel();
    fruitSpawnerTimer?.cancel();
    opponentAiTimer?.cancel();
    super.dispose();
  }

  void startMatch() {
    // 60 FPS physics tick
    gameLoopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) => updatePhysics());

    // 45s countdown timer
    matchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 1) {
        setState(() => timeLeft--);
      } else {
        timer.cancel();
        concludeMatch();
      }
    });

    // Spawns fruit waves every 1.1s
    fruitSpawnerTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) => spawnWave());

    // Real-time opponent competitive scoring AI
    opponentAiTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!isGameOver && mounted) {
        setState(() {
          opponentScore += rng.nextInt(25) + 5;
        });
      }
    });
  }

  void spawnWave() {
    if (isGameOver) return;
    final waveCount = rng.nextInt(3) + 2;
    for (int i = 0; i < waveCount; i++) {
      final isBomb = rng.nextDouble() < 0.18;
      final type = isBomb
          ? FruitType.bomb
          : FruitType.values[rng.nextInt(FruitType.values.length - 1)];

      final spawnX = 40.0 + rng.nextDouble() * 280.0;
      final spawnVx = (rng.nextDouble() - 0.5) * 4.0;
      final spawnVy = -14.0 - rng.nextDouble() * 5.0; // Upward velocity

      activeFruits.add(FlyingFruit(
        id: ++fruitIdCounter,
        type: type,
        x: spawnX,
        y: 620.0,
        vx: spawnVx,
        vy: spawnVy,
        rotation: rng.nextDouble() * 2 * pi,
        rotationSpeed: (rng.nextDouble() - 0.5) * 0.2,
      ));
    }
  }

  void updatePhysics() {
    if (!mounted || isGameOver) return;
    setState(() {
      // 1. Blade trail fade
      if (bladeTrail.isNotEmpty) {
        if (bladeTrail.length > 10) {
          bladeTrail.removeAt(0);
        }
      }

      // 2. Update fruits
      for (int i = activeFruits.length - 1; i >= 0; i--) {
        final f = activeFruits[i];
        if (!f.isSliced) {
          f.x += f.vx;
          f.y += f.vy;
          f.vy += 0.35; // Gravity
          f.rotation += f.rotationSpeed;

          // Out of screen bounds cleanup
          if (f.y > 660.0 && f.vy > 0) {
            activeFruits.removeAt(i);
          }
        } else {
          // Half 1
          f.half1X -= 3.0;
          f.half1Y += 4.5;
          // Half 2
          f.half2X += 3.0;
          f.half2Y += 4.5;

          if (f.half1Y > 660.0) {
            activeFruits.removeAt(i);
          }
        }
      }

      // 3. Update splash particles
      for (int i = particles.length - 1; i >= 0; i--) {
        final p = particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.opacity -= 0.04;
        if (p.opacity <= 0) {
          particles.removeAt(i);
        }
      }
    });
  }

  void handleBladeTouch(Offset point) {
    if (isGameOver) return;
    setState(() {
      bladeTrail.add(point);
    });

    int currentWaveSlices = 0;

    for (final f in activeFruits) {
      if (f.isSliced) continue;

      final fruitCenter = Offset(f.x + f.size / 2, f.y + f.size / 2);
      final dist = (point - fruitCenter).distance;

      if (dist < f.size * 0.7) {
        // Fruit Sliced!
        f.isSliced = true;
        f.half1X = f.x - 10;
        f.half1Y = f.y;
        f.half2X = f.x + 10;
        f.half2Y = f.y;

        currentWaveSlices++;
        final gained = f.points;
        playerScore = max(0, playerScore + gained);

        // Spawn juice splash particles
        final splashColor = f.type == FruitType.bomb ? Colors.red : (f.type == FruitType.watermelon ? Colors.redAccent : Colors.orangeAccent);
        for (int p = 0; p < 8; p++) {
          particles.add(SplashParticle(
            x: fruitCenter.dx,
            y: fruitCenter.dy,
            vx: (rng.nextDouble() - 0.5) * 8.0,
            vy: (rng.nextDouble() - 0.5) * 8.0,
            color: splashColor,
          ));
        }

        if (f.type == FruitType.bomb) {
          comboBanner = '💣 BOMB HIT! -40 PTS';
          Timer(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => comboBanner = null);
          });
        }
      }
    }

    if (currentWaveSlices >= 2) {
      comboCount += currentWaveSlices;
      final bonus = currentWaveSlices * 10;
      playerScore += bonus;
      setState(() {
        comboBanner = '🔥 ${currentWaveSlices}X COMBO! +$bonus PTS';
      });
      Timer(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => comboBanner = null);
      });
    }
  }

  Future<void> concludeMatch() async {
    gameLoopTimer?.cancel();
    matchTimer?.cancel();
    fruitSpawnerTimer?.cancel();
    opponentAiTimer?.cancel();

    final isWin = playerScore >= opponentScore;
    final outcome = isWin ? 'win' : 'loss';
    final payout = isWin ? (widget.betAmount * 1.9) : 0.0;

    setState(() {
      isGameOver = true;
      matchOutcome = outcome;
      payoutWon = payout;
    });

    try {
      final res = await ApiService.recordMatch(
        gameName: 'Fruit Blade Ninja',
        gameSlug: 'fruit-cutter',
        betAmount: widget.betAmount,
        payoutAmount: payout,
        result: outcome,
        scoreDetails: {
          'player_score': playerScore,
          'opponent_score': opponentScore,
          'opponent_name': widget.opponent.name,
          'opponent_city': widget.opponent.city,
        },
      );
      if (mounted) {
        setState(() {
          matchRef = res['record']?['reference_id'];
          adminWhatsApp = res['admin_whatsapp'];
        });
      }
    } catch (_) {}
  }

  Future<void> handleMidGameForfeit() async {
    final shouldForfeit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: pink, size: 28),
            SizedBox(width: 10),
            Text('⚠️ FORFEIT WARNING', style: TextStyle(color: pink, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you leave now, you will surrender this match immediately and LOSE your ₹${widget.betAmount.toStringAsFixed(2)} entry stake to ${widget.opponent.name}!',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'This rule prevents match abandonment in real-money competitive games.',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CONTINUE PLAYING', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SURRENDER & QUIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldForfeit == true && mounted) {
      gameLoopTimer?.cancel();
      matchTimer?.cancel();
      fruitSpawnerTimer?.cancel();
      opponentAiTimer?.cancel();

      setState(() {
        isGameOver = true;
        isForfeited = true;
        matchOutcome = 'loss';
        payoutWon = 0.0;
      });

      try {
        await ApiService.recordMatch(
          gameName: 'Fruit Blade Ninja',
          gameSlug: 'fruit-cutter',
          betAmount: widget.betAmount,
          payoutAmount: 0.0,
          result: 'loss',
          scoreDetails: {
            'forfeited': true,
            'player_score': playerScore,
            'opponent_name': widget.opponent.name,
          },
        );
      } catch (_) {}

      if (mounted) {
        widget.onGameFinished?.call();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isGameOver) {
          handleMidGameForfeit();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Stack(
            children: [
              // 1. Blade Interactive Gesture Detector
              GestureDetector(
                onPanStart: (details) => handleBladeTouch(details.localPosition),
                onPanUpdate: (details) => handleBladeTouch(details.localPosition),
                onPanEnd: (_) => setState(() => bladeTrail.clear()),
                child: Container(
                  color: Colors.transparent,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),

              // 2. Slicing Blade Trail Painter
              CustomPaint(
                painter: BladeTrailPainter(bladeTrail),
                size: Size.infinite,
              ),

              // 3. Splash Particles
              ...particles.map((p) => Positioned(
                left: p.x,
                top: p.y,
                child: Opacity(
                  opacity: max(0.0, min(1.0, p.opacity)),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: p.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )),

              // 4. Flying Fruits
              ...activeFruits.map((f) {
                if (!f.isSliced) {
                  return Positioned(
                    left: f.x,
                    top: f.y,
                    child: Transform.rotate(
                      angle: f.rotation,
                      child: Text(f.emoji, style: TextStyle(fontSize: f.size)),
                    ),
                  );
                } else {
                  return Positioned(
                    left: f.half1X,
                    top: f.half1Y,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: -0.4,
                          child: Text(f.emoji, style: TextStyle(fontSize: f.size * 0.7)),
                        ),
                        const SizedBox(width: 14),
                        Transform.rotate(
                          angle: 0.4,
                          child: Text(f.emoji, style: TextStyle(fontSize: f.size * 0.7)),
                        ),
                      ],
                    ),
                  );
                }
              }),

              // 5. Match Header (Scores, Timer, Forfeit Button)
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Player Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOU (PLAYER)', style: TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('$playerScore pts', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),

                      // Timer & Pot
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: timeLeft <= 10 ? Colors.red : purple,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '00:${timeLeft.toString().padLeft(2, '0')}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('Pot: ₹${(widget.betAmount * 2).toInt()}', style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),

                      // Opponent Score
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${widget.opponent.name.split(' ').first} (🇮🇳)', style: const TextStyle(color: pink, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('$opponentScore pts', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),

                      // Forfeit / Quit Button
                      IconButton(
                        icon: const Icon(Icons.exit_to_app, color: Colors.white60),
                        tooltip: 'Forfeit Match',
                        onPressed: handleMidGameForfeit,
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Combo Banner Overlay
              if (comboBanner != null)
                Positioned(
                  top: 90,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: gold.withValues(alpha: 0.5), blurRadius: 15),
                        ],
                      ),
                      child: Text(
                        comboBanner!,
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ),

              // 7. Definitive Game Over Victory / Defeat Modal
              if (isGameOver && !isForfeited)
                _buildGameOverModal(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverModal() {
    final isWin = matchOutcome == 'win';
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isWin ? gold : Colors.red, width: 2),
          boxShadow: [
            BoxShadow(
              color: (isWin ? gold : Colors.red).withValues(alpha: 0.4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isWin ? '🏆 MATCH VICTORY!' : '💀 MATCH DEFEAT',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isWin ? gold : Colors.redAccent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isWin
                  ? 'Congratulations! You outscored ${widget.opponent.name}!'
                  : '${widget.opponent.name} scored higher this round.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Score Comparison Row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('YOUR SCORE', style: TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$playerScore', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 35, color: Colors.white24),
                  Column(
                    children: [
                      Text(widget.opponent.name.toUpperCase(), style: const TextStyle(color: pink, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$opponentScore', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payout Announcement
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isWin ? green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isWin ? green : Colors.redAccent),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isWin ? Icons.check_circle : Icons.cancel, color: isWin ? green : Colors.redAccent, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    isWin ? 'Prize Credited: +₹${payoutWon.toStringAsFixed(2)}' : 'Stake Lost: -₹${widget.betAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isWin ? green : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // COLLECT WINNINGS & NOTIFY ADMIN
            if (isWin) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
                icon: const Icon(Icons.card_giftcard, size: 22, color: Colors.black),
                label: Text(
                  'COLLECT WINNINGS (₹${payoutWon.toStringAsFixed(2)})',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  final wa = adminWhatsApp != null
                      ? 'https://wa.me/${adminWhatsApp!.replaceAll("+", "").replaceAll(" ", "")}?text=${Uri.encodeComponent("Hello Admin, I WON ₹${payoutWon.toStringAsFixed(2)} playing Fruit Blade Ninja on BetRally! Score: $playerScore pts. Match Ref: $matchRef. Please verify my wallet credit.")}'
                      : 'https://wa.me/917780383832?text=${Uri.encodeComponent("Hello Admin, I WON ₹${payoutWon.toStringAsFixed(2)} playing Fruit Blade Ninja on BetRally! Score: $playerScore pts. Match Ref: $matchRef. Please verify my wallet credit.")}';
                  final uri = Uri.parse(wa);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                  messenger.showSnackBar(
                    SnackBar(
                      backgroundColor: green,
                      content: Text('🎉 ₹${payoutWon.toStringAsFixed(2)} credited to your wallet!'),
                    ),
                  );
                  widget.onGameFinished?.call();
                  nav.pop();
                },
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      widget.onGameFinished?.call();
                      Navigator.pop(context);
                    },
                    child: const Text('BACK TO LOBBY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() {
                        playerScore = 0;
                        opponentScore = 0;
                        timeLeft = 45;
                        activeFruits.clear();
                        particles.clear();
                        isGameOver = false;
                        matchOutcome = null;
                      });
                      startMatch();
                    },
                    child: const Text('REMATCH', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BladeTrailPainter extends CustomPainter {
  final List<Offset> points;
  BladeTrailPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paintGlow = Paint()
      ..color = teal.withValues(alpha: 0.4)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final paintCore = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paintGlow);
    canvas.drawPath(path, paintCore);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

