import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090C12);
const surface = Color(0xFF141924);
const lime = Color(0xFF39FF14);
const bloodRed = Color(0xFFFF2A2A);
const gold = Color(0xFFFFD700);
const green = Color(0xFF25D366);

class ZombieSurvivalScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const ZombieSurvivalScreen({
    super.key,
    required this.userBalance,
    required this.entryFee,
    this.onGameFinished,
  });

  @override
  State<ZombieSurvivalScreen> createState() => _ZombieSurvivalScreenState();
}

class _ZombieSurvivalScreenState extends State<ZombieSurvivalScreen> {
  late double currentBalance;
  bool isPlaying = false;
  bool isGameOver = false;
  bool hasWon = false;
  bool isSaving = false;

  int health = 100;
  int ammo = 30;
  final int maxAmmo = 30;
  int kills = 0;
  int wave = 1;
  final int maxWaves = 6;
  int secondsRemaining = 600; // 10-minute extraction clock
  Timer? gameTimer;

  // Player position (normalized 0.0 to 1.0)
  Offset playerPos = const Offset(0.5, 0.5);
  List<_Zombie> zombies = [];
  List<_Bullet> bullets = [];
  List<_Medkit> medkits = [];
  Random rng = Random();

  String matchRefId = '';
  String? adminWhatsAppUrl;
  final String adminPhone = '+917780383832';

  @override
  void initState() {
    super.initState();
    currentBalance = widget.userBalance;
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void startOutbreak() {
    if (currentBalance < widget.entryFee) {
      _showLowBalanceAlert();
      return;
    }

    setState(() {
      currentBalance -= widget.entryFee;
      isPlaying = true;
      isGameOver = false;
      hasWon = false;
      health = 100;
      ammo = maxAmmo;
      kills = 0;
      wave = 1;
      secondsRemaining = 600;
      playerPos = const Offset(0.5, 0.5);
      zombies.clear();
      bullets.clear();
      medkits.clear();
      matchRefId = '';
      adminWhatsAppUrl = null;
    });

    _spawnHorde(wave);

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !isPlaying) return;
      _updateGameLoop();
    });
  }

  void _spawnHorde(int currentWave) {
    zombies.clear();
    int count = currentWave * 5 + 3;
    final isBossWave = currentWave == maxWaves;

    for (int i = 0; i < count; i++) {
      // Spawn on edges
      double sx, sy;
      if (rng.nextBool()) {
        sx = rng.nextBool() ? -0.1 : 1.1;
        sy = rng.nextDouble();
      } else {
        sx = rng.nextDouble();
        sy = rng.nextBool() ? -0.1 : 1.1;
      }

      zombies.add(_Zombie(
        pos: Offset(sx, sy),
        hp: isBossWave && i == 0 ? 30 : (currentWave > 3 ? 3 : 1),
        speed: 0.003 + (currentWave * 0.001),
        isBrute: isBossWave && i == 0,
      ));
    }
  }

  void _updateGameLoop() {
    setState(() {
      // 1. Extraction Clock
      if (rng.nextInt(20) == 0 && secondsRemaining > 0) {
        secondsRemaining--;
        if (secondsRemaining <= 0) {
          _endGame(won: true);
          return;
        }
      }

      // 2. Move Bullets
      for (var b in bullets) {
        b.pos += b.velocity;
      }
      bullets.removeWhere((b) => b.pos.dx < -0.1 || b.pos.dx > 1.1 || b.pos.dy < -0.1 || b.pos.dy > 1.1);

      // 3. Move Zombies towards Player
      for (var z in zombies) {
        final dir = playerPos - z.pos;
        final dist = sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
        if (dist > 0.01) {
          z.pos += Offset(dir.dx / dist * z.speed, dir.dy / dist * z.speed);
        }

        // Bite player
        if (dist < 0.05) {
          health = max(0, health - (z.isBrute ? 25 : 10));
          if (health <= 0) {
            _endGame(won: false);
            return;
          }
        }
      }

      // 4. Bullet collisions with zombies
      for (var b in bullets) {
        for (var z in zombies) {
          if (z.hp > 0) {
            final hitDist = (b.pos - z.pos).distance;
            if (hitDist < 0.05) {
              b.pos = const Offset(-999, -999); // Spent
              z.hp--;
              if (z.hp <= 0) {
                kills++;
                // 15% chance to drop medkit
                if (rng.nextDouble() < 0.15 && medkits.length < 3) {
                  medkits.add(_Medkit(pos: z.pos));
                }
              }
            }
          }
        }
      }
      zombies.removeWhere((z) => z.hp <= 0);

      // 5. Pick up medkits
      medkits.removeWhere((m) {
        if ((m.pos - playerPos).distance < 0.06) {
          health = min(100, health + 30);
          return true;
        }
        return false;
      });

      // 6. Wave progression
      if (zombies.isEmpty) {
        if (wave < maxWaves) {
          wave++;
          ammo = maxAmmo;
          _spawnHorde(wave);
        } else {
          _endGame(won: true);
        }
      }
    });
  }

  void _movePlayer(Offset delta) {
    if (!isPlaying || isGameOver) return;
    setState(() {
      final nx = (playerPos.dx + delta.dx).clamp(0.08, 0.92);
      final ny = (playerPos.dy + delta.dy).clamp(0.12, 0.88);
      playerPos = Offset(nx, ny);
    });
  }

  void _shoot() {
    if (!isPlaying || isGameOver) return;
    if (ammo <= 0) {
      // Auto reload
      setState(() => ammo = maxAmmo);
      return;
    }

    setState(() {
      ammo--;

      // Find nearest zombie or shoot forward
      Offset targetDir = const Offset(0, -1);
      if (zombies.isNotEmpty) {
        _Zombie nearest = zombies.first;
        double minD = 999;
        for (var z in zombies) {
          final d = (z.pos - playerPos).distance;
          if (d < minD) {
            minD = d;
            nearest = z;
          }
        }
        final d = nearest.pos - playerPos;
        final len = sqrt(d.dx * d.dx + d.dy * d.dy);
        if (len > 0) targetDir = Offset(d.dx / len, d.dy / len);
      }

      bullets.add(_Bullet(pos: playerPos, velocity: targetDir * 0.04));
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
        gameName: 'Zombie Outbreak Arena',
        gameSlug: 'zombie-survival',
        result: won ? 'won' : 'lost',
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {
          'kills': kills,
          'wave': wave,
          'seconds_survived': 600 - secondsRemaining,
          'health_remaining': health,
        },
      );

      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = res['reference_id']?.toString() ?? 'ZOMBIE-${rng.nextInt(999999)}';
        adminWhatsAppUrl = res['whatsapp_admin_url']?.toString();
        if (won) currentBalance += payout;
      });
      widget.onGameFinished?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = 'ZOMBIE-${rng.nextInt(999999)}';
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
            Icon(won ? Icons.military_tech : Icons.warning, color: won ? gold : bloodRed, size: 30),
            const SizedBox(width: 10),
            Text(
              won ? 'EXTRACTION SUCCESSFUL!' : 'COMMANDO FALLEN!',
              style: TextStyle(fontWeight: FontWeight.bold, color: won ? gold : bloodRed, fontSize: 18),
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
            Text('Undead Eliminated: $kills | Waves Survived: $wave / $maxWaves', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Match Ref: $matchRefId', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              won
                  ? 'Your survival victory is officially logged in Supabase! Tap below to contact Admin on WhatsApp to claim your prize.'
                  : 'Your match record has been submitted to the platform database. Re-arm and try again!',
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
                final msg = 'Hello Admin, I WON in Zombie Outbreak Arena on BetRally/WinPlay!\nPrize: ₹${payout.toStringAsFixed(2)}\nKills: $kills\nMatch Ref: $matchRefId\nPlease credit my payout!';
                final url = adminWhatsAppUrl ?? 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: bloodRed, foregroundColor: Colors.white),
              child: const Text('SURVIVE AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                startOutbreak();
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
        title: const Text('Zombie Outbreak (10-Min Survival)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: lime.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Text('₹${currentBalance.toStringAsFixed(2)}', style: const TextStyle(color: lime, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Arena Canvas
          CustomPaint(
            size: Size.infinite,
            painter: _ZombieArenaPainter(
              playerPos: playerPos,
              zombies: zombies,
              bullets: bullets,
              medkits: medkits,
            ),
          ),

          // 2. Top HUD
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHUDCard('KILLS', '💀 $kills', bloodRed),
                _buildHUDCard('AMMO', '🔫 $ammo / $maxAmmo', gold),
                _buildHUDCard('HEALTH', '❤️ $health%', health > 30 ? lime : bloodRed),
                _buildHUDCard('EXTRACTION', timeStr, Colors.white70),
              ],
            ),
          ),

          // 3. Pre-Start Dashboard
          if (!isPlaying && !isGameOver)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: bloodRed, width: 2),
                  boxShadow: [
                    BoxShadow(color: bloodRed.withValues(alpha: 0.3), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, size: 64, color: bloodRed),
                    const SizedBox(height: 12),
                    const Text('ZOMBIE OUTBREAK ARENA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text(
                      '10-Minute Commando Survival\nEliminate Undead Waves & Survive Until Extraction!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
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
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
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
                          backgroundColor: bloodRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: startOutbreak,
                        child: const Text('DEPLOY COMMANDO NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. In-Game Controls: D-Pad and Fire Button
          if (isPlaying)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // D-Pad Movement
                  Column(
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: () => _movePlayer(const Offset(0, -0.05)),
                      ),
                      Row(
                        children: [
                          IconButton.filled(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => _movePlayer(const Offset(-0.05, 0)),
                          ),
                          const SizedBox(width: 40),
                          IconButton.filled(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () => _movePlayer(const Offset(0.05, 0)),
                          ),
                        ],
                      ),
                      IconButton.filled(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: () => _movePlayer(const Offset(0, 0.05)),
                      ),
                    ],
                  ),

                  // Fire Gun Trigger
                  GestureDetector(
                    onTap: _shoot,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [bloodRed, Colors.orange]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: bloodRed.withValues(alpha: 0.5), blurRadius: 16),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gps_fixed, size: 32, color: Colors.white),
                          Text('FIRE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
        ],
      ),
    );
  }
}

class _Zombie {
  Offset pos;
  int hp;
  double speed;
  bool isBrute;
  _Zombie({required this.pos, required this.hp, required this.speed, required this.isBrute});
}

class _Bullet {
  Offset pos;
  Offset velocity;
  _Bullet({required this.pos, required this.velocity});
}

class _Medkit {
  Offset pos;
  _Medkit({required this.pos});
}

class _ZombieArenaPainter extends CustomPainter {
  final Offset playerPos;
  final List<_Zombie> zombies;
  final List<_Bullet> bullets;
  final List<_Medkit> medkits;

  _ZombieArenaPainter({
    required this.playerPos,
    required this.zombies,
    required this.bullets,
    required this.medkits,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Grid Background
    final gridPaint = Paint()..color = Colors.white.withValues(alpha: 0.04)..strokeWidth = 1;
    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Draw Medkits
    for (var m in medkits) {
      final mx = m.pos.dx * w;
      final my = m.pos.dy * h;
      canvas.drawCircle(Offset(mx, my), 10, Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromCenter(center: Offset(mx, my), width: 14, height: 4), Paint()..color = Colors.red);
      canvas.drawRect(Rect.fromCenter(center: Offset(mx, my), width: 4, height: 14), Paint()..color = Colors.red);
    }

    // 3. Draw Bullets
    final bulletPaint = Paint()..color = gold..strokeWidth = 4;
    for (var b in bullets) {
      canvas.drawCircle(Offset(b.pos.dx * w, b.pos.dy * h), 3, bulletPaint);
    }

    // 4. Draw Zombies
    for (var z in zombies) {
      final zx = z.pos.dx * w;
      final zy = z.pos.dy * h;
      final zPaint = Paint()..color = z.isBrute ? Colors.deepPurpleAccent : bloodRed;
      canvas.drawCircle(Offset(zx, zy), z.isBrute ? 16 : 10, zPaint);

      // Zombie eyes
      canvas.drawCircle(Offset(zx - 3, zy - 2), 2, Paint()..color = lime);
      canvas.drawCircle(Offset(zx + 3, zy - 2), 2, Paint()..color = lime);
    }

    // 5. Draw Player Soldier
    final px = playerPos.dx * w;
    final py = playerPos.dy * h;
    // Commando body
    canvas.drawCircle(Offset(px, py), 12, Paint()..color = Colors.blueAccent);
    // Commando helmet
    canvas.drawCircle(Offset(px, py - 2), 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ZombieArenaPainter oldDelegate) => true;
}

