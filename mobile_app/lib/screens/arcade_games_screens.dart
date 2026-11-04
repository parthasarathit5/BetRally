import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

// ==========================================
// 1. SPEED LUDO SCREEN
// ==========================================
class SpeedLudoScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const SpeedLudoScreen({super.key, required this.userBalance, this.entryFee = 20.0, this.onGameFinished});

  @override
  State<SpeedLudoScreen> createState() => _SpeedLudoScreenState();
}

class _SpeedLudoScreenState extends State<SpeedLudoScreen> {
  int playerPos = 0;
  int botPos = 0;
  final int finishPos = 30;
  int currentDice = 1;
  bool isRolling = false;
  bool isGameOver = false;

  void rollDice() {
    if (isRolling || isGameOver) return;
    setState(() => isRolling = true);

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() => currentDice = Random().nextInt(6) + 1);
      if (timer.tick > 6) {
        timer.cancel();
        setState(() {
          isRolling = false;
          playerPos = min(finishPos, playerPos + currentDice);
          // Bot moves
          final botRoll = Random().nextInt(6) + 1;
          botPos = min(finishPos, botPos + botRoll);

          if (playerPos >= finishPos) {
            endGame('win', 'Ludo Victory! Your token reached Home first!');
          } else if (botPos >= finishPos) {
            endGame('loss', 'Ludo Defeat! Opponent token reached Home.');
          }
        });
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.85) : 0.0;

    await ApiService.recordMatch(
      gameName: 'Speed Ludo',
      gameSlug: 'ludo',
      result: outcome,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      scoreDetails: {'player_pos': playerPos, 'bot_pos': botPos},
    );
    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'LUDO CHAMPION!' : 'MATCH LOST', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speed Ludo (Race to Home)'), backgroundColor: bg),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Positions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(children: [const Text('YOU (RED)', style: TextStyle(color: teal, fontWeight: FontWeight.bold)), Text('$playerPos / $finishPos', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold))]),
                  Column(children: [const Text('BOT (YELLOW)', style: TextStyle(color: gold, fontWeight: FontWeight.bold)), Text('$botPos / $finishPos', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold))]),
                ],
              ),
              // Track
              LinearProgressIndicator(value: playerPos / finishPos, minHeight: 18, color: teal, backgroundColor: surface),
              LinearProgressIndicator(value: botPos / finishPos, minHeight: 18, color: gold, backgroundColor: surface),
              // Dice
              GestureDetector(
                onTap: isRolling || isGameOver ? null : rollDice,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)]),
                  child: Center(
                    child: Text('$currentDice', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
                onPressed: isRolling || isGameOver ? null : rollDice,
                child: Text(isRolling ? 'ROLLING...' : 'ROLL DICE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. 8-BALL POOL SCREEN
// ==========================================
class Pool8BallScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const Pool8BallScreen({super.key, required this.userBalance, this.entryFee = 30.0, this.onGameFinished});

  @override
  State<Pool8BallScreen> createState() => _Pool8BallScreenState();
}

class _Pool8BallScreenState extends State<Pool8BallScreen> {
  int ballsPotted = 0;
  final int totalBalls = 7;
  double aimAngle = 0.0;
  bool isStriking = false;
  bool isGameOver = false;

  void strike() {
    if (isStriking || isGameOver) return;
    setState(() => isStriking = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final potted = Random().nextDouble() > 0.35;
      setState(() {
        isStriking = false;
        if (potted) ballsPotted++;

        if (ballsPotted >= totalBalls) {
          endGame('win', '8-Ball Pocketed! Victory on the break!');
        }
      });
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.85) : 0.0;

    await ApiService.recordMatch(
      gameName: '8-Ball Pool',
      gameSlug: 'pool',
      result: outcome,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      scoreDetails: {'balls_potted': ballsPotted},
    );
    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'POOL CHAMPION!' : 'GAME OVER', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('8-Ball Pool'), backgroundColor: bg),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('BALLS POTTED: $ballsPotted / $totalBalls', style: const TextStyle(color: teal, fontSize: 18, fontWeight: FontWeight.bold)),
              // Pool Table
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                height: 240,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F5A31), // Pool felt
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF5C3317), width: 14), // Wood rail
                ),
                child: Center(
                  child: Icon(Icons.circle, color: isStriking ? Colors.white : gold, size: 36),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
                icon: const Icon(Icons.sports_baseball),
                label: Text(isStriking ? 'STRIKING...' : 'STRIKE CUE BALL', style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: isStriking || isGameOver ? null : strike,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. EUROPEAN ROULETTE SCREEN
// ==========================================
class RouletteScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const RouletteScreen({super.key, required this.userBalance, this.entryFee = 20.0, this.onGameFinished});

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen> {
  int? winningNumber;
  String? selectedColor; // 'red', 'black', 'green'
  bool isSpinning = false;
  bool isGameOver = false;

  void spin(String color) {
    if (isSpinning || isGameOver) return;
    setState(() {
      selectedColor = color;
      isSpinning = true;
    });

    Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() => winningNumber = Random().nextInt(37)); // 0-36
      if (timer.tick > 12) {
        timer.cancel();
        setState(() {
          isSpinning = false;
          final isRed = winningNumber! % 2 == 1;
          final winColor = winningNumber == 0 ? 'green' : (isRed ? 'red' : 'black');
          final isWin = selectedColor == winColor;
          endGame(isWin ? 'win' : 'loss', isWin ? 'Ball stopped on $winningNumber ($winColor)! Won 2x!' : 'Ball stopped on $winningNumber ($winColor).');
        });
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 2.0) : 0.0;

    await ApiService.recordMatch(
      gameName: 'European Roulette',
      gameSlug: 'roulette',
      result: outcome,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      scoreDetails: {'winning_number': winningNumber, 'reason': reason},
    );
    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'ROULETTE WIN!' : 'SPIN LOST', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('European Roulette'), backgroundColor: bg),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Wheel Display
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(shape: BoxShape.circle, color: surface, border: Border.all(color: gold, width: 6)),
                child: Center(
                  child: Text('${winningNumber ?? '??'}', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: gold)),
                ),
              ),
              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC0392B), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)), onPressed: isSpinning || isGameOver ? null : () => spin('red'), child: const Text('RED (2x)', style: TextStyle(fontWeight: FontWeight.bold))),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AE60), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)), onPressed: isSpinning || isGameOver ? null : () => spin('green'), child: const Text('GREEN ZERO (14x)', style: TextStyle(fontWeight: FontWeight.bold))),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)), onPressed: isSpinning || isGameOver ? null : () => spin('black'), child: const Text('BLACK (2x)', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. SNAKES & LADDERS SCREEN
// ==========================================
class SnakesLaddersScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const SnakesLaddersScreen({super.key, required this.userBalance, this.entryFee = 15.0, this.onGameFinished});

  @override
  State<SnakesLaddersScreen> createState() => _SnakesLaddersScreenState();
}

class _SnakesLaddersScreenState extends State<SnakesLaddersScreen> {
  int pos = 1;
  int botPos = 1;
  int dice = 1;
  bool isGameOver = false;

  void roll() {
    if (isGameOver) return;
    setState(() {
      dice = Random().nextInt(6) + 1;
      pos = min(100, pos + dice);
      // Ladder bonus at 14 -> 38
      if (pos == 14) pos = 38;
      // Snake bite at 45 -> 18
      if (pos == 45) pos = 18;

      botPos = min(100, botPos + Random().nextInt(6) + 1);

      if (pos >= 100) {
        endGame('win', 'Victory! Reached square 100 first!');
      } else if (botPos >= 100) {
        endGame('loss', 'Defeat! Bot reached square 100.');
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.85) : 0.0;

    await ApiService.recordMatch(
      gameName: 'Snakes & Ladders',
      gameSlug: 'snakes-ladders',
      result: outcome,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      scoreDetails: {'pos': pos, 'bot': botPos},
    );
    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'SNAKES & LADDERS WIN!' : 'GAME OVER', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Snakes & Ladders (1-100)'), backgroundColor: bg),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('YOUR TILE: $pos / 100', style: const TextStyle(color: teal, fontSize: 22, fontWeight: FontWeight.bold)),
            Text('BOT TILE: $botPos / 100', style: const TextStyle(color: pink, fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: isGameOver ? null : roll,
              child: Text('ROLL DICE ($dice)', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. FRUIT SLICE SCREEN
// ==========================================
class FruitSliceScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const FruitSliceScreen({super.key, required this.userBalance, this.entryFee = 10.0, this.onGameFinished});

  @override
  State<FruitSliceScreen> createState() => _FruitSliceScreenState();
}

class _FruitSliceScreenState extends State<FruitSliceScreen> {
  int fruitsSliced = 0;
  final int target = 15;
  String currentFruit = '🍉';
  bool isGameOver = false;

  final fruits = ['🍉', '🍊', '🍎', '🍍', '🍓', '💣'];

  void slice() {
    if (isGameOver) return;
    if (currentFruit == '💣') {
      endGame('loss', 'BOOM! Sliced a skull bomb!');
      return;
    }

    setState(() {
      fruitsSliced++;
      currentFruit = fruits[Random().nextInt(fruits.length)];
      if (fruitsSliced >= target) {
        endGame('win', 'Ninja Master! Sliced $target fruits!');
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.9) : 0.0;

    await ApiService.recordMatch(
      gameName: 'Fruit Slice',
      gameSlug: 'fruit-slice',
      result: outcome,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      scoreDetails: {'fruits_sliced': fruitsSliced},
    );
    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'FRUIT NINJA WIN!' : 'BOMB HIT!', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fruit Slice Arcade'), backgroundColor: bg),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('SLICED: $fruitsSliced / $target (Avoid 💣)', style: const TextStyle(color: teal, fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: isGameOver ? null : slice,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(shape: BoxShape.circle, color: surface),
                child: Center(child: Text(currentFruit, style: const TextStyle(fontSize: 60))),
              ),
            ),
            const Text('TAP THE FLYING FRUIT RAPIDLY TO SLICE!', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 6. KNIFE HIT SCREEN
// ==========================================
class KnifeHitScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const KnifeHitScreen({super.key, required this.userBalance, this.entryFee = 10.0, this.onGameFinished});

  @override
  State<KnifeHitScreen> createState() => _KnifeHitScreenState();
}

class _KnifeHitScreenState extends State<KnifeHitScreen> {
  int knivesStuck = 0;
  final int target = 7;
  bool isGameOver = false;

  void throwKnife() {
    if (isGameOver) return;
    // 15% collision chance
    if (knivesStuck > 2 && Random().nextDouble() < 0.15) {
      endGame('loss', 'CLINK! Your knife struck an existing knife.');
      return;
    }

    setState(() {
      knivesStuck++;
      if (knivesStuck >= target) {
        endGame('win', 'Target cleared! All $target knives stuck!');
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.9) : 0.0;

    await ApiService.recordMatch(
      gameName: 'Knife Hit',
      gameSlug: 'knife-hit',
      result: outcome,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      scoreDetails: {'knives': knivesStuck},
    );
    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'TARGET SHATTERED!' : 'DEFEAT', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Knife Hit (Target)'), backgroundColor: bg),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('KNIVES: $knivesStuck / $target', style: const TextStyle(color: teal, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF8B5A2B), border: Border.all(color: gold, width: 4)),
              child: Center(child: Text('🎯 $knivesStuck', style: const TextStyle(fontSize: 32))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: isGameOver ? null : throwKnife,
              child: const Text('THROW KNIFE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. ARCHERY MASTER SCREEN
// ==========================================
class ArcheryScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const ArcheryScreen({super.key, required this.userBalance, this.entryFee = 15.0, this.onGameFinished});

  @override
  State<ArcheryScreen> createState() => _ArcheryScreenState();
}

class _ArcheryScreenState extends State<ArcheryScreen> {
  int totalScore = 0;
  int arrowsLeft = 3;
  bool isGameOver = false;

  void releaseArrow() {
    if (isGameOver || arrowsLeft <= 0) return;
    final ring = Random().nextInt(4); // 10, 9, 8, 7
    final pts = ring == 0 ? 10 : (ring == 1 ? 9 : (ring == 2 ? 8 : 7));

    setState(() {
      arrowsLeft--;
      totalScore += pts;
      if (arrowsLeft <= 0) {
        final isWin = totalScore >= 25;
        endGame(isWin ? 'win' : 'loss', isWin ? 'Bulls-eye! Scored $totalScore / 30 pts!' : 'Finished with $totalScore pts (Needed 25).');
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.85) : 0.0;

    await ApiService.recordMatch(
      gameName: 'Archery Master',
      gameSlug: 'archery',
      result: outcome,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      scoreDetails: {'score': totalScore},
    );
    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'BULLS-EYE WIN!' : 'MATCH OVER', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archery Master'), backgroundColor: bg),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('SCORE: $totalScore | ARROWS: $arrowsLeft', style: const TextStyle(color: teal, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: gold, border: Border.all(color: Colors.red, width: 14)),
              child: const Center(child: Text('10', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              onPressed: isGameOver || arrowsLeft <= 0 ? null : releaseArrow,
              child: const Text('RELEASE ARROW', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 8. BOTTLE SHOOT SCREEN
// ==========================================
class BottleShootScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const BottleShootScreen({super.key, required this.userBalance, this.entryFee = 15.0, this.onGameFinished});

  @override
  State<BottleShootScreen> createState() => _BottleShootScreenState();
}

class _BottleShootScreenState extends State<BottleShootScreen> {
  int bottlesHit = 0;
  final int totalBottles = 8;
  bool isGameOver = false;

  void shoot() {
    if (isGameOver) return;
    setState(() {
      bottlesHit++;
      if (bottlesHit >= totalBottles) {
        endGame('win', 'Sharpshooter! All $totalBottles bottles shattered!');
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.85) : 0.0;

    await ApiService.recordMatch(
      gameName: 'Bottle Shoot',
      gameSlug: 'bottle-shoot',
      result: outcome,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      scoreDetails: {'bottles': bottlesHit},
    );
    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'SHARPSHOOTER WIN!' : 'TIME OUT', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bottle Shoot'), backgroundColor: bg),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('BOTTLES SHATTERED: $bottlesHit / $totalBottles', style: const TextStyle(color: teal, fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalBottles, (i) => Icon(i < bottlesHit ? Icons.broken_image : Icons.liquor, color: i < bottlesHit ? Colors.white30 : gold, size: 36)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14)),
              icon: const Icon(Icons.gps_fixed),
              label: const Text('SHOOT BOTTLE', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: isGameOver ? null : shoot,
            ),
          ],
        ),
      ),
    );
  }
}
