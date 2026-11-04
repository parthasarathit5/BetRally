import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF070913);
const surface = Color(0xFF13172C);
const cyan = Color(0xFF00F0FF);
const neonPink = Color(0xFFFF007A);
const gold = Color(0xFFFFD700);
const green = Color(0xFF25D366);

class GalaxyStrikeScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const GalaxyStrikeScreen({
    super.key,
    required this.userBalance,
    required this.entryFee,
    this.onGameFinished,
  });

  @override
  State<GalaxyStrikeScreen> createState() => _GalaxyStrikeScreenState();
}

class _GalaxyStrikeScreenState extends State<GalaxyStrikeScreen> with TickerProviderStateMixin {
  late double currentBalance;
  bool isPlaying = false;
  bool isGameOver = false;
  bool hasWon = false;
  bool isSaving = false;

  int score = 0;
  int wave = 1;
  final int maxWaves = 5;
  int health = 100;
  int shield = 100;
  int secondsRemaining = 600; // 10 minutes mission timer
  Timer? gameTimer;

  // Starship position (horizontal -1.0 to 1.0)
  double shipX = 0.0;
  List<_Laser> lasers = [];
  List<_Alien> aliens = [];
  List<_Star> stars = [];
  Random rng = Random();

  String matchRefId = '';
  String? adminWhatsAppUrl;
  final String adminPhone = '+917780383832';

  @override
  void initState() {
    super.initState();
    currentBalance = widget.userBalance;
    _initStars();
  }

  void _initStars() {
    stars = List.generate(40, (_) => _Star(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: rng.nextDouble() * 2.5 + 1.0,
      speed: rng.nextDouble() * 0.008 + 0.004,
    ));
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void startMission() {
    if (currentBalance < widget.entryFee) {
      _showLowBalanceAlert();
      return;
    }

    setState(() {
      currentBalance -= widget.entryFee;
      isPlaying = true;
      isGameOver = false;
      hasWon = false;
      score = 0;
      wave = 1;
      health = 100;
      shield = 100;
      secondsRemaining = 600;
      shipX = 0.0;
      lasers.clear();
      aliens.clear();
      matchRefId = '';
      adminWhatsAppUrl = null;
    });

    _spawnWave(wave);

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !isPlaying) return;
      _updateGameLoop();
    });
  }

  void _spawnWave(int currentWave) {
    aliens.clear();
    int count = currentWave * 4 + 2;
    for (int i = 0; i < count; i++) {
      aliens.add(_Alien(
        x: (rng.nextDouble() * 1.6) - 0.8,
        y: -0.2 - (rng.nextDouble() * 0.8),
        hp: currentWave == maxWaves && i == 0 ? 25 : (currentWave > 2 ? 3 : 1),
        isBoss: currentWave == maxWaves && i == 0,
        speed: 0.006 + (currentWave * 0.002),
      ));
    }
  }

  void _updateGameLoop() {
    setState(() {
      // 1. Mission timer
      if (rng.nextInt(20) == 0 && secondsRemaining > 0) {
        secondsRemaining--;
        if (secondsRemaining <= 0) {
          _endGame(won: true);
          return;
        }
      }

      // 2. Stars animation
      for (var star in stars) {
        star.y += star.speed;
        if (star.y > 1.0) {
          star.y = 0.0;
          star.x = rng.nextDouble();
        }
      }

      // 3. Move lasers
      for (var laser in lasers) {
        laser.y -= 0.04;
      }
      lasers.removeWhere((l) => l.y < -0.1);

      // 4. Move aliens & check collisions
      for (var alien in aliens) {
        alien.y += alien.speed;

        // Collision with ship
        if ((alien.y >= 0.82 && alien.y <= 0.95) && (alien.x - shipX).abs() < 0.15) {
          alien.hp = 0;
          if (shield > 0) {
            shield = max(0, shield - 25);
          } else {
            health = max(0, health - 20);
          }
          if (health <= 0) {
            _endGame(won: false);
            return;
          }
        }

        // Alien reaches bottom
        if (alien.y > 1.05) {
          alien.y = -0.1;
          alien.x = (rng.nextDouble() * 1.6) - 0.8;
          if (shield > 0) {
            shield = max(0, shield - 10);
          } else {
            health = max(0, health - 10);
          }
          if (health <= 0) {
            _endGame(won: false);
            return;
          }
        }
      }

      // 5. Laser hits alien
      for (var laser in lasers) {
        for (var alien in aliens) {
          if (alien.hp > 0 && (laser.x - alien.x).abs() < 0.12 && (laser.y - alien.y).abs() < 0.08) {
            laser.y = -1.0; // Mark laser spent
            alien.hp--;
            if (alien.hp <= 0) {
              score += alien.isBoss ? 500 : 50;
            }
          }
        }
      }
      aliens.removeWhere((a) => a.hp <= 0);

      // 6. Wave completion check
      if (aliens.isEmpty) {
        if (wave < maxWaves) {
          wave++;
          shield = min(100, shield + 30);
          _spawnWave(wave);
        } else {
          _endGame(won: true);
        }
      }
    });
  }

  void _fireLaser() {
    if (!isPlaying || isGameOver) return;
    setState(() {
      lasers.add(_Laser(x: shipX - 0.04, y: 0.85));
      lasers.add(_Laser(x: shipX + 0.04, y: 0.85));
    });
  }

  Future<void> _endGame({required bool won}) async {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
      hasWon = won;
      isSaving = true;
    });

    final payout = won ? widget.entryFee * 2.0 : 0.0;

    try {
      final res = await ApiService.recordMatch(
        gameName: 'Galaxy Strike',
        gameSlug: 'galaxy-strike',
        result: won ? 'won' : 'lost',
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {
          'score': score,
          'wave': wave,
          'seconds_survived': 600 - secondsRemaining,
          'health': health,
        },
      );

      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = res['reference_id']?.toString() ?? 'GALAXY-${rng.nextInt(999999)}';
        adminWhatsAppUrl = res['whatsapp_admin_url']?.toString();
        if (won) {
          currentBalance += payout;
        }
      });
      widget.onGameFinished?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = 'GALAXY-${rng.nextInt(999999)}';
        if (won) currentBalance += payout;
      });
    }

    _showResultDialog(won: won, payout: payout);
  }

  void _showResultDialog({required bool won, required double payout}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(won ? Icons.emoji_events : Icons.cancel, color: won ? gold : Colors.redAccent, size: 30),
            const SizedBox(width: 10),
            Text(
              won ? 'MISSION ACCOMPLISHED!' : 'SHIP DESTROYED!',
              style: TextStyle(fontWeight: FontWeight.bold, color: won ? gold : Colors.redAccent, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              won ? 'Prize Won: ₹${payout.toStringAsFixed(2)}' : 'Entry: ₹${widget.entryFee.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: won ? green : Colors.white70),
            ),
            const SizedBox(height: 8),
            Text('Final Score: $score pts | Wave: $wave / $maxWaves', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Match Ref: $matchRefId', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              won
                  ? 'Your victory has been officially recorded in Supabase! Tap below to contact Admin on WhatsApp to claim your cash prize.'
                  : 'Your match result has been saved in the platform database. Better luck on your next mission!',
              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Exit to Lobby', style: TextStyle(color: Colors.white54)),
          ),
          if (won)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.black),
              icon: const Icon(Icons.chat, color: Colors.black, size: 18),
              label: const Text('CLAIM PRIZE ON WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(ctx);
                final cleanPhone = adminPhone.replaceAll(RegExp(r'\D'), '');
                final msg = 'Hello Admin, I WON in Galaxy Strike on BetRally/WinPlay!\nPrize: ₹${payout.toStringAsFixed(2)}\nScore: $score\nMatch Ref: $matchRefId\nPlease credit/transfer my payout!';
                final url = adminWhatsAppUrl ?? 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cyan, foregroundColor: Colors.black),
              child: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                startMission();
              },
            ),
        ],
      ),
    );
  }

  void _showLowBalanceAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: gold, size: 28),
            SizedBox(width: 10),
            Text('Insufficient Balance', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Required Entry: ₹${widget.entryFee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            Text('Your Balance: ₹${currentBalance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Your wallet balance must be equal or greater than the entry fee to play. Contact Admin on WhatsApp to deposit cash.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.black),
            icon: const Icon(Icons.chat, size: 16, color: Colors.black),
            label: const Text('ADD CASH VIA WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final cleanPhone = adminPhone.replaceAll(RegExp(r'\D'), '');
              final msg = 'Hello Admin, I need to add cash to play games on BetRally/WinPlay. Please credit my wallet.';
              final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mins = secondsRemaining ~/ 60;
    final secs = secondsRemaining % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        title: const Text('Galaxy Strike (10-Min Arcade)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cyan.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Text('₹${currentBalance.toStringAsFixed(2)}', style: const TextStyle(color: cyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Starfield background
          CustomPaint(
            size: Size.infinite,
            painter: _SpacePainter(stars: stars, lasers: lasers, aliens: aliens, shipX: shipX),
          ),

          // 2. Mission HUD
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHUDCard('SCORE', '$score', cyan),
                _buildHUDCard('WAVE', '$wave / $maxWaves', neonPink),
                _buildHUDCard('SURVIVE', timeStr, gold),
              ],
            ),
          ),

          // 3. Health & Shield Bars
          if (isPlaying)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('SHIELD ', style: TextStyle(color: cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: shield / 100, backgroundColor: Colors.white10, color: cyan, minHeight: 6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('HULL   ', style: TextStyle(color: neonPink, fontSize: 10, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: health / 100, backgroundColor: Colors.white10, color: neonPink, minHeight: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 4. Mission Pre-Start Dashboard
          if (!isPlaying && !isGameOver)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cyan, width: 2),
                  boxShadow: [
                    BoxShadow(color: cyan.withValues(alpha: 0.3), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rocket_launch, size: 64, color: cyan),
                    const SizedBox(height: 12),
                    const Text('GALAXY STRIKE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text(
                      '10-Minute Tactical Space Combat\nDefeat 5 Alien Waves & Mothership Boss',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Entry Fee:', style: TextStyle(color: Colors.white60)),
                          Text('₹${widget.entryFee.toStringAsFixed(2)}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Victory Payout:', style: TextStyle(color: Colors.white60)),
                          Text('₹${(widget.entryFee * 2.0).toStringAsFixed(2)} (2.0x)', style: const TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: startMission,
                        child: const Text('DEPLOY STARSHIP NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. In-Game Controls
          if (isPlaying)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  // Move Left
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          shipX = max(-0.85, shipX - 0.2);
                        });
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cyan.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: cyan),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Fire Laser
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: _fireLaser,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [neonPink, cyan]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: neonPink.withValues(alpha: 0.5), blurRadius: 12),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flash_on, color: Colors.white),
                            SizedBox(width: 8),
                            Text('FIRE LASERS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Move Right
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          shipX = min(0.85, shipX + 0.2);
                        });
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cyan.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.arrow_forward_ios, color: cyan),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHUDCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
        ],
      ),
    );
  }
}

class _Star {
  double x;
  double y;
  double size;
  double speed;
  _Star({required this.x, required this.y, required this.size, required this.speed});
}

class _Laser {
  double x;
  double y;
  _Laser({required this.x, required this.y});
}

class _Alien {
  double x;
  double y;
  int hp;
  bool isBoss;
  double speed;
  _Alien({required this.x, required this.y, required this.hp, required this.isBoss, required this.speed});
}

class _SpacePainter extends CustomPainter {
  final List<_Star> stars;
  final List<_Laser> lasers;
  final List<_Alien> aliens;
  final double shipX;

  _SpacePainter({required this.stars, required this.lasers, required this.aliens, required this.shipX});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Stars
    final starPaint = Paint()..color = Colors.white;
    for (var s in stars) {
      starPaint.color = Colors.white.withValues(alpha: min(1.0, s.size / 2.5));
      canvas.drawCircle(Offset(s.x * w, s.y * h), s.size, starPaint);
    }

    // 2. Draw Lasers
    final laserPaint = Paint()
      ..color = cyan
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var l in lasers) {
      final lx = (l.x + 1.0) / 2.0 * w;
      final ly = l.y * h;
      canvas.drawLine(Offset(lx, ly), Offset(lx, ly - 18), laserPaint);
    }

    // 3. Draw Aliens
    for (var a in aliens) {
      final ax = (a.x + 1.0) / 2.0 * w;
      final ay = a.y * h;
      final aPaint = Paint()..color = a.isBoss ? neonPink : gold;

      if (a.isBoss) {
        // Mothership boss
        final rect = Rect.fromCenter(center: Offset(ax, ay), width: 70, height: 40);
        canvas.drawOval(rect, aPaint);
        canvas.drawCircle(Offset(ax, ay), 12, Paint()..color = cyan);
      } else {
        // Drone alien
        final path = Path()
          ..moveTo(ax, ay + 15)
          ..lineTo(ax - 18, ay - 12)
          ..lineTo(ax + 18, ay - 12)
          ..close();
        canvas.drawPath(path, aPaint);
      }
    }

    // 4. Draw Player Starship
    final sx = (shipX + 1.0) / 2.0 * w;
    final sy = 0.88 * h;

    final shipPath = Path()
      ..moveTo(sx, sy - 28)
      ..lineTo(sx - 24, sy + 18)
      ..lineTo(sx, sy + 8)
      ..lineTo(sx + 24, sy + 18)
      ..close();

    final shipPaint = Paint()..color = cyan;
    canvas.drawPath(shipPath, shipPaint);

    // Thruster glow
    final thrusterPaint = Paint()..color = Colors.orangeAccent;
    canvas.drawCircle(Offset(sx, sy + 14), 6, thrusterPaint);
  }

  @override
  bool shouldRepaint(covariant _SpacePainter oldDelegate) => true;
}
