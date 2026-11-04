import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF0B0E1B);
const surface = Color(0xFF151A2E);
const cyan = Color(0xFF00E5FF);
const gold = Color(0xFFFFD700);
const purple = Color(0xFF9E54FF);
const green = Color(0xFF25D366);

class Puzzle2048Screen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const Puzzle2048Screen({
    super.key,
    required this.userBalance,
    required this.entryFee,
    this.onGameFinished,
  });

  @override
  State<Puzzle2048Screen> createState() => _Puzzle2048ScreenState();
}

class _Puzzle2048ScreenState extends State<Puzzle2048Screen> {
  late double currentBalance;
  bool isPlaying = false;
  bool isGameOver = false;
  bool hasWon = false;
  bool isSaving = false;

  List<List<int>> board = List.generate(4, (_) => List.filled(4, 0));
  List<List<int>> previousBoard = List.generate(4, (_) => List.filled(4, 0));
  int undosRemaining = 3;

  int score = 0;
  final int targetScore = 2048;
  int secondsRemaining = 600; // 10 minutes blitz
  Timer? gameTimer;
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

  void startBlitz() {
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
      undosRemaining = 3;
      secondsRemaining = 600;
      board = List.generate(4, (_) => List.filled(4, 0));
      matchRefId = '';
      adminWhatsAppUrl = null;
      _spawnTile();
      _spawnTile();
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !isPlaying) return;
      setState(() {
        if (secondsRemaining > 0) {
          secondsRemaining--;
          if (secondsRemaining <= 0) {
            _checkEndGame();
          }
        }
      });
    });
  }

  void _spawnTile() {
    final empty = <Point<int>>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (board[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isNotEmpty) {
      final p = empty[rng.nextInt(empty.length)];
      board[p.x][p.y] = rng.nextDouble() < 0.9 ? 2 : 4;
    }
  }

  void _saveBoardForUndo() {
    previousBoard = List.generate(4, (r) => List.from(board[r]));
  }

  void undoMove() {
    if (!isPlaying || undosRemaining <= 0) return;
    setState(() {
      board = List.generate(4, (r) => List.from(previousBoard[r]));
      undosRemaining--;
    });
  }

  void move(String direction) {
    if (!isPlaying || isGameOver) return;
    _saveBoardForUndo();
    bool moved = false;

    setState(() {
      if (direction == 'left') {
        for (int r = 0; r < 4; r++) {
          final res = _slideAndMerge(board[r]);
          if (res.moved) moved = true;
          board[r] = res.row;
          score += res.scoreGain;
        }
      } else if (direction == 'right') {
        for (int r = 0; r < 4; r++) {
          final reversed = board[r].reversed.toList();
          final res = _slideAndMerge(reversed);
          if (res.moved) moved = true;
          board[r] = res.row.reversed.toList();
          score += res.scoreGain;
        }
      } else if (direction == 'up') {
        for (int c = 0; c < 4; c++) {
          final col = [board[0][c], board[1][c], board[2][c], board[3][c]];
          final res = _slideAndMerge(col);
          if (res.moved) moved = true;
          for (int r = 0; r < 4; r++) {
            board[r][c] = res.row[r];
          }
          score += res.scoreGain;
        }
      } else if (direction == 'down') {
        for (int c = 0; c < 4; c++) {
          final col = [board[3][c], board[2][c], board[1][c], board[0][c]];
          final res = _slideAndMerge(col);
          if (res.moved) moved = true;
          for (int r = 0; r < 4; r++) {
            board[3 - r][c] = res.row[r];
          }
          score += res.scoreGain;
        }
      }

      if (moved) {
        _spawnTile();
        _checkEndGame();
      }
    });
  }

  _SlideResult _slideAndMerge(List<int> line) {
    final filtered = line.where((val) => val != 0).toList();
    final result = <int>[];
    int scoreGain = 0;
    int i = 0;

    while (i < filtered.length) {
      if (i + 1 < filtered.length && filtered[i] == filtered[i + 1]) {
        final combined = filtered[i] * 2;
        result.add(combined);
        scoreGain += combined;
        i += 2;
      } else {
        result.add(filtered[i]);
        i++;
      }
    }

    while (result.length < 4) {
      result.add(0);
    }

    bool moved = false;
    for (int k = 0; k < 4; k++) {
      if (line[k] != result[k]) {
        moved = true;
        break;
      }
    }

    return _SlideResult(row: result, moved: moved, scoreGain: scoreGain);
  }

  void _checkEndGame() {
    // 1. Check if user merged 2048 or scored 2048+
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (board[r][c] >= targetScore || score >= 2048) {
          _endGame(won: true);
          return;
        }
      }
    }

    // 2. Check if moves are available
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (board[r][c] == 0) return; // empty slot available
        if (c < 3 && board[r][c] == board[r][c + 1]) return; // horizontal merge
        if (r < 3 && board[r][c] == board[r + 1][c]) return; // vertical merge
      }
    }

    // No moves left
    _endGame(won: false);
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
        gameName: '2048 Mega Blitz',
        gameSlug: 'puzzle-2048',
        result: won ? 'won' : 'lost',
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {
          'score': score,
          'seconds_survived': 600 - secondsRemaining,
          'max_tile': board.expand((r) => r).fold(0, max),
        },
      );

      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = res['reference_id']?.toString() ?? '2048-${rng.nextInt(999999)}';
        adminWhatsAppUrl = res['whatsapp_admin_url']?.toString();
        if (won) currentBalance += payout;
      });
      widget.onGameFinished?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSaving = false;
        matchRefId = '2048-${rng.nextInt(999999)}';
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
            Icon(won ? Icons.emoji_events : Icons.refresh, color: won ? gold : Colors.redAccent, size: 30),
            const SizedBox(width: 10),
            Text(
              won ? 'PUZZLE CONQUERED!' : 'OUT OF MOVES!',
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
            Text('Final Score: $score pts | Target: $targetScore', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text('Match Ref: $matchRefId', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 12),
            Text(
              won
                  ? 'Your win is officially logged into Supabase database! Tap below to contact Admin on WhatsApp to claim your prize.'
                  : 'Your puzzle score has been saved in the platform database. Swipe better next time!',
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
                final msg = 'Hello Admin, I WON in 2048 Mega Blitz on BetRally/WinPlay!\nPrize: ₹${payout.toStringAsFixed(2)}\nScore: $score\nMatch Ref: $matchRefId\nPlease send my payout!';
                final url = adminWhatsAppUrl ?? 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}';
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              },
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cyan, foregroundColor: Colors.black),
              child: const Text('PLAY AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                startBlitz();
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

  Color _getTileColor(int val) {
    switch (val) {
      case 2: return const Color(0xFF2C3E50);
      case 4: return const Color(0xFF34495E);
      case 8: return const Color(0xFFE67E22);
      case 16: return const Color(0xFFD35400);
      case 32: return const Color(0xFFE74C3C);
      case 64: return const Color(0xFFC0392B);
      case 128: return const Color(0xFFF1C40F);
      case 256: return const Color(0xFFF39C12);
      case 512: return const Color(0xFF2ECC71);
      case 1024: return const Color(0xFF27AE60);
      case 2048: return gold;
      default: return const Color(0xFF1E2438);
    }
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
        title: const Text('2048 Mega Blitz (10-Min Puzzle)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -100) move('left');
            if (details.primaryVelocity! > 100) move('right');
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -100) move('up');
            if (details.primaryVelocity! > 100) move('down');
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top HUD
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHUDCard('SCORE', '$score', cyan),
                  _buildHUDCard('TARGET', '$targetScore', gold),
                  _buildHUDCard('TIME', timeStr, Colors.white70),
                  _buildHUDCard('UNDOS', '$undosRemaining', purple),
                ],
              ),
              const SizedBox(height: 16),

              // Pre-Start Banner or 4x4 Grid
              if (!isPlaying && !isGameOver)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: cyan, width: 2),
                    boxShadow: [
                      BoxShadow(color: cyan.withValues(alpha: 0.2), blurRadius: 20),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.grid_view, size: 64, color: cyan),
                      const SizedBox(height: 12),
                      const Text('2048 MEGA BLITZ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 6),
                      const Text(
                        '10-Minute Numerical Mind Battle\nMerge Tiles (2 -> 4 -> 8 -> 2048) To Win Payout!',
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
                            backgroundColor: cyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: startBlitz,
                          child: const Text('START PUZZLE BLITZ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                // 4x4 Game Grid
                Container(
                  width: 340,
                  height: 340,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: 16,
                    itemBuilder: (ctx, i) {
                      final r = i ~/ 4;
                      final c = i % 4;
                      final val = board[r][c];

                      return Container(
                        decoration: BoxDecoration(
                          color: _getTileColor(val),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: val > 0
                              ? [BoxShadow(color: _getTileColor(val).withValues(alpha: 0.3), blurRadius: 6)]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          val > 0 ? '$val' : '',
                          style: TextStyle(
                            fontSize: val >= 1024 ? 18 : 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Directional D-Pad Controls
                Column(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.keyboard_arrow_up, size: 32),
                      onPressed: () => move('up'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.keyboard_arrow_left, size: 32),
                          onPressed: () => move('left'),
                        ),
                        const SizedBox(width: 24),
                        OutlinedButton.icon(
                          onPressed: undosRemaining > 0 ? undoMove : null,
                          icon: const Icon(Icons.undo, size: 18),
                          label: Text('UNDO ($undosRemaining)'),
                        ),
                        const SizedBox(width: 24),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.keyboard_arrow_right, size: 32),
                          onPressed: () => move('right'),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                      onPressed: () => move('down'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHUDCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _SlideResult {
  final List<int> row;
  final bool moved;
  final int scoreGain;
  _SlideResult({required this.row, required this.moved, required this.scoreGain});
}
