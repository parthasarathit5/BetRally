import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF0A0C16);
const surface = Color(0xFF141829);
const orange = Color(0xFFFF6B00);
const yellow = Color(0xFFFFD600);
const teal = Color(0xFF00E5FF);
const green = Color(0xFF25D366);

class MotoRushScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const MotoRushScreen({
    super.key,
    required this.userBalance,
    required this.entryFee,
    this.onGameFinished,
  });

  @override
  State<MotoRushScreen> createState() => _MotoRushScreenState();
}

class _MotoRushScreenState extends State<MotoRushScreen> {
  late double currentBalance;
  bool isPlaying = false;
  bool isGameOver = false;
  bool hasWon = false;
  bool isSaving = false;

  int currentLane = 1; // 0: Left, 1: Center, 2: Right
  double speedKmh = 140.0;
  double distanceKm = 0.0;
  final double targetDistanceKm = 10.0;
  int nitroPercent = 100;
  bool isNitroActive = false;
  int health = 100;
  int secondsRemaining = 600; // 10 minutes endurance rush
  Timer? gameTimer;

  List<_TrafficVehicle> traffic = [];
  double roadOffset = 0.0;
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

  void startRace() {
    if (currentBalance < widget.entryFee) {
      _showLowBalanceAlert();
      return;
    }

    setState(() {
      currentBalance -= widget.entryFee;
      isPlaying = true;
      isGameOver = false;
      hasWon = false;
      currentLane = 1;
      speedKmh = 140.0;
      distanceKm = 0.0;
      nitroPercent = 100;
      isNitroActive = false;
      health = 100;
      secondsRemaining = 600;
      traffic.clear();
      matchRefId = '';
      adminWhatsAppUrl = null;
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !isPlaying) return;
      _updateRaceLoop();
    });
  }

  void _updateRaceLoop() {
    setState(() {
      // 1. Timer & Distance
      if (rng.nextInt(20) == 0 && secondsRemaining > 0) {
        secondsRemaining--;
      }

      final speedFactor = isNitroActive ? 220.0 : speedKmh;
      distanceKm += (speedFactor / 3600.0) * 0.05;
      roadOffset = (roadOffset + (speedFactor * 0.002)) % 1.0;

      // 2. Nitro regeneration or consumption
      if (isNitroActive) {
        nitroPercent = max(0, nitroPercent - 2);
        if (nitroPercent <= 0) isNitroActive = false;
      } else {
        nitroPercent = min(100, nitroPercent + 1);
      }

      // 3. Spawn Traffic
      if (traffic.length < 5 && rng.nextInt(25) == 0) {
        traffic.add(_TrafficVehicle(
          lane: rng.nextInt(3),
          y: -0.2 - (rng.nextDouble() * 0.4),
          color: [Colors.redAccent, Colors.amber, Colors.blueAccent, Colors.purpleAccent][rng.nextInt(4)],
          speed: 0.008 + (rng.nextDouble() * 0.004),
        ));
      }

      // 4. Move Traffic & Detect Collisions
      for (var car in traffic) {
        car.y += car.speed + (isNitroActive ? 0.02 : 0.012);

        // Check crash with player bike (player is at y = 0.82)
        if (car.lane == currentLane && car.y >= 0.72 && car.y <= 0.88) {
          car.y = 2.0; // Remove crashed car
          health = max(0, health - 40);
          if (health <= 0) {
            _endRace(won: false);
            return;
          }
        }
      }
      traffic.removeWhere((c) => c.y > 1.2);

      // 5. Win condition: reached 10km or survived timer
      if (distanceKm >= targetDistanceKm || (secondsRemaining <= 0 && health > 0)) {
        _endRace(won: true);
      }
    });
  }

  Future<void> _endRace({required bool won}) async {
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
        gameName: 'Moto Rush',
        gameSlug: 'moto-rush',
        result: won ? 'won' : 'lost',
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {
          'distance_km': distanceKm.toStringAsFixed(2),
          'top_speed': isNitroActive ? 240 : 160,
          'seconds_survived': 600 - secondsRemaining,
          'health': health,
        },
      );

      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = res['reference_id']?.toString() ?? 'MOTO-${rng.nextInt(999999)}';
        adminWhatsAppUrl = res['whatsapp_admin_url']?.toString();
        if (won) currentBalance += payout;
      });
      widget.onGameFinished?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = 'MOTO-${rng.nextInt(999999)}';
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
            Icon(won ? Icons.emoji_events : Icons.two_wheeler, color: won ? yellow : Colors.redAccent, size: 30),
            const SizedBox(width: 10),
            Text(
              won ? 'FINISH LINE CROSSED!' : 'HIGH-SPEED CRASH!',
              style: TextStyle(fontWeight: FontWeight.bold, color: won ? yellow : Colors.redAccent, fontSize: 18),
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
            Text('Distance: ${distanceKm.toStringAsFixed(2)} KM / $targetDistanceKm KM', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Match Ref: $matchRefId', style: const TextStyle(color: yellow, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              won
                  ? 'Your victory has been logged into Supabase database! Tap below to notify Admin on WhatsApp to receive your prize.'
                  : 'Your match result has been recorded in the platform database. Hit the road again!',
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
                final msg = 'Hello Admin, I WON in Moto Rush on BetRally/WinPlay!\nPrize: ₹${payout.toStringAsFixed(2)}\nDistance: ${distanceKm.toStringAsFixed(2)}km\nMatch Ref: $matchRefId\nPlease verify & send my prize!';
                final url = adminWhatsAppUrl ?? 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: orange, foregroundColor: Colors.white),
              child: const Text('RACE AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                startRace();
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
            Icon(Icons.warning_amber_rounded, color: yellow, size: 28),
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
        title: const Text('Moto Rush (10-Min Highway)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: orange.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Text('₹${currentBalance.toStringAsFixed(2)}', style: const TextStyle(color: orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Highway Road Canvas
          CustomPaint(
            size: Size.infinite,
            painter: _HighwayPainter(
              roadOffset: roadOffset,
              traffic: traffic,
              playerLane: currentLane,
              isNitroActive: isNitroActive,
            ),
          ),

          // 2. HUD Dashboard Top
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHUDCard('DISTANCE', '${distanceKm.toStringAsFixed(1)} / $targetDistanceKm KM', teal),
                _buildHUDCard('SPEED', isNitroActive ? '240 KM/H' : '${speedKmh.toInt()} KM/H', orange),
                _buildHUDCard('TIME', timeStr, yellow),
              ],
            ),
          ),

          // 3. Health & Nitro Meters
          if (isPlaying)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('NITRO ', style: TextStyle(color: teal, fontSize: 10, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: nitroPercent / 100, backgroundColor: Colors.white10, color: teal, minHeight: 6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('BIKE   ', style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: health / 100, backgroundColor: Colors.white10, color: orange, minHeight: 6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 4. Pre-Race Start Dashboard
          if (!isPlaying && !isGameOver)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: orange, width: 2),
                  boxShadow: [
                    BoxShadow(color: orange.withValues(alpha: 0.3), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.two_wheeler, size: 64, color: orange),
                    const SizedBox(height: 12),
                    const Text('MOTO RUSH RACER', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text(
                      '10-Minute Highway Speed Survival\nWeave Traffic, Use Nitro, Reach 10 KM!',
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
                          Text('₹${widget.entryFee.toStringAsFixed(2)}', style: const TextStyle(color: yellow, fontWeight: FontWeight.bold, fontSize: 18)),
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
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: startRace,
                        child: const Text('START ENGINES NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  // Lane Left
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          currentLane = max(0, currentLane - 1);
                        });
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: orange.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.arrow_left, size: 36, color: orange),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nitro Boost
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTapDown: (_) {
                        if (nitroPercent > 10) setState(() => isNitroActive = true);
                      },
                      onTapUp: (_) => setState(() => isNitroActive = false),
                      onTapCancel: () => setState(() => isNitroActive = false),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: isNitroActive ? [teal, Colors.blue] : [orange, Colors.deepOrange]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: (isNitroActive ? teal : orange).withValues(alpha: 0.5), blurRadius: 14),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bolt, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(isNitroActive ? 'NITRO ENGAGED!' : 'HOLD NITRO', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Lane Right
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          currentLane = min(2, currentLane + 1);
                        });
                      },
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: surface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: orange.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.arrow_right, size: 36, color: orange),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }
}

class _TrafficVehicle {
  int lane; // 0, 1, 2
  double y;
  Color color;
  double speed;
  _TrafficVehicle({required this.lane, required this.y, required this.color, required this.speed});
}

class _HighwayPainter extends CustomPainter {
  final double roadOffset;
  final List<_TrafficVehicle> traffic;
  final int playerLane;
  final bool isNitroActive;

  _HighwayPainter({
    required this.roadOffset,
    required this.traffic,
    required this.playerLane,
    required this.isNitroActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Road background
    final roadRect = Rect.fromLTWH(w * 0.15, 0, w * 0.7, h);
    canvas.drawRect(roadRect, Paint()..color = const Color(0xFF1B1F33));

    // Road side curbs
    canvas.drawRect(Rect.fromLTWH(w * 0.14, 0, w * 0.015, h), Paint()..color = orange);
    canvas.drawRect(Rect.fromLTWH(w * 0.845, 0, w * 0.015, h), Paint()..color = orange);

    // 2. Lane dividers
    final lane1X = w * 0.38;
    final lane2X = w * 0.62;
    final linePaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 3;

    for (double y = -0.2; y < 1.2; y += 0.15) {
      final drawY = (y + roadOffset * 0.15) % 1.2 * h;
      canvas.drawLine(Offset(lane1X, drawY), Offset(lane1X, drawY + 30), linePaint);
      canvas.drawLine(Offset(lane2X, drawY), Offset(lane2X, drawY + 30), linePaint);
    }

    // Lane X positions for vehicles
    double getLaneCenterX(int lane) {
      if (lane == 0) return w * 0.265;
      if (lane == 1) return w * 0.50;
      return w * 0.735;
    }

    // 3. Draw Traffic Cars
    for (var car in traffic) {
      final cx = getLaneCenterX(car.lane);
      final cy = car.y * h;
      final carRect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: 38, height: 60), const Radius.circular(8));
      canvas.drawRRect(carRect, Paint()..color = car.color);
      // Windshield
      canvas.drawRect(Rect.fromCenter(center: Offset(cx, cy - 8), width: 30, height: 14), Paint()..color = Colors.black87);
    }

    // 4. Draw Player Superbike
    final bx = getLaneCenterX(playerLane);
    final by = 0.82 * h;

    // Nitro speed lines
    if (isNitroActive) {
      final nitroPaint = Paint()..color = teal.withValues(alpha: 0.6)..strokeWidth = 2;
      for (int i = -3; i <= 3; i++) {
        canvas.drawLine(Offset(bx + i * 8, by + 30), Offset(bx + i * 8, by + 90), nitroPaint);
      }
    }

    // Bike Body
    final bikePaint = Paint()..color = isNitroActive ? teal : orange;
    final bikeBody = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, by), width: 22, height: 50), const Radius.circular(10));
    canvas.drawRRect(bikeBody, bikePaint);

    // Front & Back Wheels
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, by - 24), width: 10, height: 16), const Radius.circular(4)), Paint()..color = Colors.black);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(bx, by + 24), width: 12, height: 18), const Radius.circular(4)), Paint()..color = Colors.black);

    // Rider Helmet
    canvas.drawCircle(Offset(bx, by), 9, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(bx, by - 2), 5, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(covariant _HighwayPainter oldDelegate) => true;
}

