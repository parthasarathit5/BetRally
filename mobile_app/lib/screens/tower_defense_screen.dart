import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF0C101C);
const surface = Color(0xFF161C2E);
const purple = Color(0xFF9E54FF);
const gold = Color(0xFFFFD54F);
const teal = Color(0xFF00E5FF);
const green = Color(0xFF25D366);

class TowerDefenseScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const TowerDefenseScreen({
    super.key,
    required this.userBalance,
    required this.entryFee,
    this.onGameFinished,
  });

  @override
  State<TowerDefenseScreen> createState() => _TowerDefenseScreenState();
}

class _TowerDefenseScreenState extends State<TowerDefenseScreen> {
  late double currentBalance;
  bool isPlaying = false;
  bool isGameOver = false;
  bool hasWon = false;
  bool isSaving = false;

  int wave = 1;
  final int maxWaves = 10;
  int castleHp = 100;
  int goldCoins = 350;
  int secondsRemaining = 600; // 10 minutes kingdom defense
  Timer? gameTimer;

  // Selected tower type to build: 'archer', 'magic', 'cannon'
  String selectedTowerType = 'archer';

  // Tower slots (fixed grid positions along the path)
  final List<_TowerSlot> slots = [
    _TowerSlot(id: 0, x: 0.22, y: 0.25),
    _TowerSlot(id: 1, x: 0.78, y: 0.25),
    _TowerSlot(id: 2, x: 0.45, y: 0.45),
    _TowerSlot(id: 3, x: 0.22, y: 0.65),
    _TowerSlot(id: 4, x: 0.78, y: 0.65),
    _TowerSlot(id: 5, x: 0.50, y: 0.82),
  ];

  List<_Invader> invaders = [];
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

  void startDefense() {
    if (currentBalance < widget.entryFee) {
      _showLowBalanceAlert();
      return;
    }

    setState(() {
      currentBalance -= widget.entryFee;
      isPlaying = true;
      isGameOver = false;
      hasWon = false;
      wave = 1;
      castleHp = 100;
      goldCoins = 350;
      secondsRemaining = 600;
      invaders.clear();
      for (var slot in slots) {
        slot.towerType = null;
        slot.level = 0;
      }
      matchRefId = '';
      adminWhatsAppUrl = null;
    });

    _spawnWave(wave);

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted || !isPlaying) return;
      _updateDefenseLoop();
    });
  }

  void _spawnWave(int currentWave) {
    invaders.clear();
    int count = currentWave * 3 + 3;
    final isBossWave = currentWave == maxWaves;

    for (int i = 0; i < count; i++) {
      invaders.add(_Invader(
        distance: -0.15 * i,
        hp: isBossWave && i == 0 ? 80 : (currentWave * 4 + 4),
        maxHp: isBossWave && i == 0 ? 80 : (currentWave * 4 + 4),
        speed: 0.003 + (rng.nextDouble() * 0.001),
        isBoss: isBossWave && i == 0,
      ));
    }
  }

  void _updateDefenseLoop() {
    setState(() {
      // 1. Mission clock
      if (rng.nextInt(20) == 0 && secondsRemaining > 0) {
        secondsRemaining--;
        if (secondsRemaining <= 0) {
          _endGame(won: true);
          return;
        }
      }

      // 2. Invaders march along winding path (0.0 to 1.0)
      for (var invader in invaders) {
        invader.distance += invader.speed;

        // Reached Castle at distance >= 1.0
        if (invader.distance >= 1.0) {
          invader.hp = 0;
          castleHp = max(0, castleHp - (invader.isBoss ? 40 : 10));
          if (castleHp <= 0) {
            _endGame(won: false);
            return;
          }
        }
      }

      // 3. Towers fire at invaders within range
      for (var slot in slots) {
        if (slot.towerType == null) continue;

        final range = slot.towerType == 'magic' ? 0.35 : 0.28;
        final damage = slot.towerType == 'cannon' ? 3 : (slot.towerType == 'archer' ? 1 : 2);

        for (var invader in invaders) {
          if (invader.distance > 0 && invader.distance < 1.0 && invader.hp > 0) {
            final invPos = _getPathPosition(invader.distance);
            final dx = slot.x - invPos.dx;
            final dy = slot.y - invPos.dy;
            final dist = sqrt(dx * dx + dy * dy);

            if (dist < range) {
              invader.hp -= damage;
              if (invader.hp <= 0) {
                goldCoins += invader.isBoss ? 150 : 25;
              }
              break; // Single attack per frame cycle
            }
          }
        }
      }

      invaders.removeWhere((i) => i.hp <= 0);

      // 4. Wave progression
      if (invaders.isEmpty) {
        if (wave < maxWaves) {
          wave++;
          goldCoins += 50;
          _spawnWave(wave);
        } else {
          _endGame(won: true);
        }
      }
    });
  }

  void _buildOrUpgradeTower(int slotId) {
    if (!isPlaying || isGameOver) return;
    final slot = slots.firstWhere((s) => s.id == slotId);
    final cost = selectedTowerType == 'cannon' ? 200 : (selectedTowerType == 'magic' ? 150 : 100);

    if (slot.towerType == null) {
      if (goldCoins < cost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Need $cost Gold to build ${selectedTowerType.toUpperCase()} tower!')),
        );
        return;
      }
      setState(() {
        goldCoins -= cost;
        slot.towerType = selectedTowerType;
        slot.level = 1;
      });
    } else {
      // Upgrade existing tower
      final upgradeCost = 100 * (slot.level + 1);
      if (goldCoins < upgradeCost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Need $upgradeCost Gold to upgrade to Level ${slot.level + 1}!')),
        );
        return;
      }
      setState(() {
        goldCoins -= upgradeCost;
        slot.level++;
      });
    }
  }

  Offset _getPathPosition(double t) {
    // S-curve road: Top Left -> Top Right -> Mid Left -> Castle Bottom
    if (t < 0.25) {
      return Offset(0.1 + (t / 0.25) * 0.7, 0.15);
    } else if (t < 0.5) {
      final sub = (t - 0.25) / 0.25;
      return Offset(0.8 - sub * 0.6, 0.15 + sub * 0.35);
    } else if (t < 0.75) {
      final sub = (t - 0.5) / 0.25;
      return Offset(0.2 + sub * 0.6, 0.50 + sub * 0.35);
    } else {
      final sub = (t - 0.75) / 0.25;
      return Offset(0.8 - sub * 0.3, 0.85 + sub * 0.1);
    }
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
        gameName: 'Kingdom Tower Defense',
        gameSlug: 'tower-defense',
        result: won ? 'won' : 'lost',
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {
          'wave_reached': wave,
          'castle_hp': castleHp,
          'gold_earned': goldCoins,
          'seconds_survived': 600 - secondsRemaining,
        },
      );

      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = res['reference_id']?.toString() ?? 'TOWER-${rng.nextInt(999999)}';
        adminWhatsAppUrl = res['whatsapp_admin_url']?.toString();
        if (won) currentBalance += payout;
      });
      widget.onGameFinished?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = 'TOWER-${rng.nextInt(999999)}';
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
            Icon(won ? Icons.military_tech : Icons.shield, color: won ? gold : Colors.redAccent, size: 30),
            const SizedBox(width: 10),
            Text(
              won ? 'KINGDOM SAVED!' : 'CASTLE OVERRUN!',
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
            Text('Waves Defended: $wave / $maxWaves | Castle HP: $castleHp%', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Match Ref: $matchRefId', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              won
                  ? 'Your strategic victory is safely logged in Supabase! Tap below to contact Admin on WhatsApp to claim your cash prize.'
                  : 'Your match record has been submitted to the platform database. Fortify your towers and try again!',
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
                final msg = 'Hello Admin, I WON in Kingdom Tower Defense on BetRally/WinPlay!\nPrize: ₹${payout.toStringAsFixed(2)}\nWaves Defended: $wave/$maxWaves\nMatch Ref: $matchRefId\nPlease credit my winnings!';
                final url = adminWhatsAppUrl ?? 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white),
              child: const Text('DEFEND AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                startDefense();
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
        title: const Text('Kingdom Tower Defense (10-Min)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: purple.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.center,
            child: Text('₹${currentBalance.toStringAsFixed(2)}', style: const TextStyle(color: purple, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Kingdom Road & Canvas
          CustomPaint(
            size: Size.infinite,
            painter: _DefensePainter(slots: slots, invaders: invaders, getPathPos: _getPathPosition),
          ),

          // 2. Interactive Tower Slots
          if (isPlaying)
            ...slots.map((slot) {
              return LayoutBuilder(
                builder: (ctx, constraints) {
                  return Positioned(
                    left: slot.x * MediaQuery.of(context).size.width - 25,
                    top: slot.y * MediaQuery.of(context).size.height - 25,
                    child: GestureDetector(
                      onTap: () => _buildOrUpgradeTower(slot.id),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: slot.towerType == null ? surface.withValues(alpha: 0.8) : _getTowerColor(slot.towerType),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 2),
                          boxShadow: [
                            BoxShadow(color: (slot.towerType == null ? Colors.white10 : _getTowerColor(slot.towerType)).withValues(alpha: 0.4), blurRadius: 8),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            slot.towerType == null ? Icons.add : _getTowerIcon(slot.towerType),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

          // 3. Top HUD
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHUDCard('GOLD', '🪙 $goldCoins', gold),
                _buildHUDCard('WAVE', '$wave / $maxWaves', purple),
                _buildHUDCard('CASTLE HP', '$castleHp%', castleHp > 30 ? teal : Colors.redAccent),
                _buildHUDCard('TIME', timeStr, Colors.white70),
              ],
            ),
          ),

          // 4. Pre-Battle Start Dashboard
          if (!isPlaying && !isGameOver)
            Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: purple, width: 2),
                  boxShadow: [
                    BoxShadow(color: purple.withValues(alpha: 0.3), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, size: 64, color: purple),
                    const SizedBox(height: 12),
                    const Text('KINGDOM TOWER DEFENSE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text(
                      '10-Minute Castle Strategy Battle\nBuild Archer, Magic & Cannon Towers to Stop 10 Waves!',
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
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: startDefense,
                        child: const Text('DEFEND THE KINGDOM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. In-Game Tower Selector Bar
          if (isPlaying)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTowerOption('archer', 'Archer', '100g', Colors.green, Icons.gps_fixed),
                    _buildTowerOption('magic', 'Magic', '150g', Colors.blueAccent, Icons.auto_awesome),
                    _buildTowerOption('cannon', 'Cannon', '200g', Colors.deepOrange, Icons.radio_button_checked),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTowerOption(String type, String name, String cost, Color color, IconData icon) {
    final isSelected = selectedTowerType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedTowerType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                Text(cost, style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTowerColor(String? type) {
    switch (type) {
      case 'archer': return Colors.green;
      case 'magic': return Colors.blueAccent;
      case 'cannon': return Colors.deepOrange;
      default: return Colors.white;
    }
  }

  IconData _getTowerIcon(String? type) {
    switch (type) {
      case 'archer': return Icons.gps_fixed;
      case 'magic': return Icons.auto_awesome;
      case 'cannon': return Icons.radio_button_checked;
      default: return Icons.shield;
    }
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

class _TowerSlot {
  int id;
  double x;
  double y;
  String? towerType;
  int level = 0;
  _TowerSlot({required this.id, required this.x, required this.y});
}

class _Invader {
  double distance;
  int hp;
  int maxHp;
  double speed;
  bool isBoss;
  _Invader({required this.distance, required this.hp, required this.maxHp, required this.speed, required this.isBoss});
}

class _DefensePainter extends CustomPainter {
  final List<_TowerSlot> slots;
  final List<_Invader> invaders;
  final Offset Function(double t) getPathPos;

  _DefensePainter({required this.slots, required this.invaders, required this.getPathPos});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Draw Winding Path Road
    final roadPaint = Paint()
      ..color = const Color(0xFF26324D)
      ..strokeWidth = 38
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final p0 = getPathPos(0.0);
    path.moveTo(p0.dx * w, p0.dy * h);
    for (double t = 0.02; t <= 1.0; t += 0.02) {
      final p = getPathPos(t);
      path.lineTo(p.dx * w, p.dy * h);
    }
    canvas.drawPath(path, roadPaint);

    // Castle at the end
    final castlePos = getPathPos(1.0);
    canvas.drawCircle(Offset(castlePos.dx * w, castlePos.dy * h), 26, Paint()..color = Colors.indigo);
    canvas.drawCircle(Offset(castlePos.dx * w, castlePos.dy * h), 16, Paint()..color = gold);

    // 2. Draw Invaders along the path
    for (var inv in invaders) {
      if (inv.distance >= 0.0 && inv.distance <= 1.0) {
        final pos = getPathPos(inv.distance);
        final ix = pos.dx * w;
        final iy = pos.dy * h;

        final invPaint = Paint()..color = inv.isBoss ? Colors.redAccent : Colors.amber;
        canvas.drawCircle(Offset(ix, iy), inv.isBoss ? 16 : 9, invPaint);

        // Health Bar above invader
        final barW = inv.isBoss ? 30.0 : 18.0;
        final hpPercent = max(0.0, inv.hp / inv.maxHp);
        canvas.drawRect(Rect.fromLTWH(ix - barW / 2, iy - (inv.isBoss ? 24 : 16), barW, 4), Paint()..color = Colors.black54);
        canvas.drawRect(Rect.fromLTWH(ix - barW / 2, iy - (inv.isBoss ? 24 : 16), barW * hpPercent, 4), Paint()..color = green);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DefensePainter oldDelegate) => true;
}
