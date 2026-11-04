import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const surfaceLight = Color(0xFF23284C);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const gold = Color(0xFFFFC857);

class MinesGameScreen extends StatefulWidget {
  final VoidCallback? onWalletChanged;
  const MinesGameScreen({super.key, this.onWalletChanged});

  @override
  State<MinesGameScreen> createState() => _MinesGameScreenState();
}

class _MinesGameScreenState extends State<MinesGameScreen> {
  double walletBalance = 0.0;
  double betAmount = 20.0;
  int mineCount = 3;

  int? sessionId;
  bool isPlaying = false;
  bool isRevealing = false;
  bool isCashingOut = false;

  List<int> revealedTiles = [];
  List<int> mineLocations = [];
  double currentMultiplier = 1.0;
  double nextMultiplier = 1.11;
  double currentPayout = 20.0;

  final betChips = [10.0, 20.0, 50.0, 100.0, 500.0];
  final mineChips = [1, 3, 5, 10, 20];

  @override
  void initState() {
    super.initState();
    refreshWallet();
    checkActiveSession();
  }

  Future<void> refreshWallet() async {
    try {
      final res = await ApiService.getWallet();
      if (!mounted) return;
      setState(() {
        walletBalance = double.tryParse(res['balance']?.toString() ?? '0') ?? 0.0;
      });
      widget.onWalletChanged?.call();
    } catch (_) {}
  }

  Future<void> checkActiveSession() async {
    try {
      final res = await ApiService.getMinesActiveSession();
      final active = res['active_session'];
      if (active != null && mounted) {
        setState(() {
          sessionId = active['id'] as int?;
          betAmount = double.tryParse(active['bet_amount']?.toString() ?? '20') ?? 20.0;
          mineCount = active['mine_count'] as int? ?? 3;
          revealedTiles = List<int>.from(active['revealed_tiles'] ?? []);
          currentMultiplier = double.tryParse(active['current_multiplier']?.toString() ?? '1.0') ?? 1.0;
          nextMultiplier = double.tryParse(active['next_multiplier']?.toString() ?? '1.11') ?? 1.11;
          currentPayout = double.tryParse(active['current_payout']?.toString() ?? '$betAmount') ?? betAmount;
          isPlaying = true;
        });
      }
    } catch (_) {}
  }

  double calculateLocalMultiplier(int revealed) {
    if (revealed <= 0) return 1.0;
    double mult = 1.0;
    final safeTotal = 25 - mineCount;
    for (int i = 0; i < revealed; i++) {
      mult *= (25 - i) / (safeTotal - i);
    }
    return double.parse((mult * 0.97).toStringAsFixed(2));
  }

  Future<void> startGame() async {
    if (walletBalance < betAmount || walletBalance <= 0) {
      showLowBalanceDialog();
      return;
    }

    setState(() {
      isPlaying = true;
      revealedTiles = [];
      mineLocations = [];
      currentMultiplier = 1.0;
      nextMultiplier = calculateLocalMultiplier(1);
      currentPayout = betAmount;
    });

    try {
      final res = await ApiService.startMinesGame(
        betAmount: betAmount,
        mineCount: mineCount,
      );

      if (!mounted) return;
      setState(() {
        sessionId = res['session_id'] as int?;
        walletBalance = double.tryParse(res['wallet_balance']?.toString() ?? '') ?? (walletBalance - betAmount);
        nextMultiplier = double.tryParse(res['next_multiplier']?.toString() ?? '') ?? nextMultiplier;
      });
      widget.onWalletChanged?.call();
    } catch (err) {
      setState(() => isPlaying = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start game: $err')),
      );
    }
  }

  Future<void> onTileTap(int index) async {
    if (!isPlaying || isRevealing || revealedTiles.contains(index)) return;

    setState(() => isRevealing = true);

    if (sessionId != null) {
      try {
        final res = await ApiService.revealMinesTile(
          sessionId: sessionId!,
          tileIndex: index,
        );

        if (!mounted) return;

        if (res['status'] == 'busted') {
          setState(() {
            isPlaying = false;
            mineLocations = List<int>.from(res['mine_locations'] ?? [index]);
            revealedTiles.add(index);
          });
          showBustedDialog();
        } else if (res['status'] == 'cashed_out') {
          setState(() {
            isPlaying = false;
            revealedTiles = List<int>.from(res['revealed_tiles'] ?? []);
            mineLocations = List<int>.from(res['mine_locations'] ?? []);
            currentMultiplier = double.tryParse(res['current_multiplier']?.toString() ?? '1.0') ?? 1.0;
            currentPayout = double.tryParse(res['payout']?.toString() ?? '0') ?? 0.0;
            walletBalance = double.tryParse(res['wallet_balance']?.toString() ?? '') ?? walletBalance;
          });
          showWinDialog(autoCleared: true);
          widget.onWalletChanged?.call();
        } else {
          setState(() {
            revealedTiles = List<int>.from(res['revealed_tiles'] ?? []);
            currentMultiplier = double.tryParse(res['current_multiplier']?.toString() ?? '1.0') ?? 1.0;
            currentPayout = double.tryParse(res['current_payout']?.toString() ?? '0') ?? (betAmount * currentMultiplier);
            nextMultiplier = double.tryParse(res['next_multiplier']?.toString() ?? '1.0') ?? (currentMultiplier * 1.15);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) setState(() => isRevealing = false);
      }
    } else {
      // Local fallback mode
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      if (mineLocations.contains(index)) {
        setState(() {
          isPlaying = false;
          revealedTiles.add(index);
          isRevealing = false;
        });
        showBustedDialog();
      } else {
        revealedTiles.add(index);
        final mult = calculateLocalMultiplier(revealedTiles.length);
        final nMult = calculateLocalMultiplier(revealedTiles.length + 1);
        setState(() {
          currentMultiplier = mult;
          currentPayout = betAmount * mult;
          nextMultiplier = nMult;
          isRevealing = false;
        });
      }
    }
  }

  Future<void> cashout() async {
    if (!isPlaying || isCashingOut || revealedTiles.isEmpty) return;

    setState(() => isCashingOut = true);

    if (sessionId != null) {
      try {
        final res = await ApiService.cashoutMines(sessionId: sessionId!);
        if (!mounted) return;

        setState(() {
          isPlaying = false;
          mineLocations = List<int>.from(res['mine_locations'] ?? []);
          currentPayout = double.tryParse(res['payout']?.toString() ?? '0') ?? currentPayout;
          walletBalance = double.tryParse(res['wallet_balance']?.toString() ?? '') ?? (walletBalance + currentPayout);
        });
        showWinDialog();
        widget.onWalletChanged?.call();
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cashout failed: $err')),
        );
      } finally {
        if (mounted) setState(() => isCashingOut = false);
      }
    } else {
      // Local fallback
      setState(() {
        isPlaying = false;
        walletBalance += currentPayout;
        isCashingOut = false;
      });
      showWinDialog();
    }
  }

  void showLowBalanceDialog() {
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
            Text('Bet Amount: ₹${betAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            Text('Current Balance: ₹${walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: pink, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Your wallet balance must be equal or greater than the bet amount to play. Contact Admin on WhatsApp to deposit cash.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.black),
            icon: const Icon(Icons.chat, size: 16, color: Colors.black),
            label: const Text('ADD CASH VIA WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final msg = 'Hello Admin, I want to add cash to play Mines Arcade on BetRally/WinPlay. Please credit my wallet.';
              final url = 'https://wa.me/917780383832?text=${Uri.encodeComponent(msg)}';
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  void showBustedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Text('💥', style: TextStyle(fontSize: 28)),
            SizedBox(width: 10),
            Text('BOOM! Hit a Mine', style: TextStyle(color: pink, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'You hit a hidden mine! Better luck on the next round.\n\nLost: ₹${betAmount.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: purple),
            onPressed: () {
              Navigator.pop(ctx);
              refreshWallet();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void showWinDialog({bool autoCleared = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Text('🎉', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Text(
              autoCleared ? 'ALL MINES CLEARED!' : 'CASHOUT SUCCESS!',
              style: const TextStyle(color: teal, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multiplier: ${currentMultiplier.toStringAsFixed(2)}x',
              style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You Won: ₹${currentPayout.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            const Text(
              'Funds have been credited directly to your WinPlay wallet!',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(ctx);
              refreshWallet();
            },
            child: const Text('Collect & Continue', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MINES ARCADE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        actions: [
          // Wallet Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [purple, pink]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  '₹${walletBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Game Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isPlaying ? teal.withValues(alpha: 0.4) : Colors.white12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('CURRENT', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            '${currentMultiplier.toStringAsFixed(2)}x',
                            style: TextStyle(
                              color: isPlaying ? teal : Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.white12),
                      Column(
                        children: [
                          const Text('NEXT TILE', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            isPlaying ? '${nextMultiplier.toStringAsFixed(2)}x' : '-',
                            style: const TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.white12),
                      Column(
                        children: [
                          const Text('CASHOUT', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            isPlaying ? '₹${currentPayout.toStringAsFixed(2)}' : '₹${betAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 5x5 Mines Grid
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 25,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final isRevealed = revealedTiles.contains(index);
                        final isMine = mineLocations.contains(index);

                        Color cellColor = surfaceLight;
                        Widget cellContent = const SizedBox.shrink();

                        if (isRevealed) {
                          if (isMine) {
                            cellColor = pink.withValues(alpha: 0.35);
                            cellContent = const Text('💣', style: TextStyle(fontSize: 26));
                          } else {
                            cellColor = teal.withValues(alpha: 0.25);
                            cellContent = const Text('💎', style: TextStyle(fontSize: 26));
                          }
                        } else if (!isPlaying && mineLocations.isNotEmpty && isMine) {
                          // Show remaining mines when game is over
                          cellColor = pink.withValues(alpha: 0.2);
                          cellContent = const Text('💣', style: TextStyle(fontSize: 22));
                        }

                        return InkWell(
                          onTap: isPlaying ? () => onTileTap(index) : null,
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isRevealed
                                    ? (isMine ? pink : teal)
                                    : (isPlaying ? purple.withValues(alpha: 0.3) : Colors.white12),
                                width: isRevealed ? 2 : 1,
                              ),
                            ),
                            child: Center(child: cellContent),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Game Action / Cashout Button
                if (isPlaying)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: revealedTiles.isNotEmpty ? gold : Colors.grey.shade800,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: isCashingOut
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            )
                          : const Icon(Icons.monetization_on, color: Colors.black, size: 24),
                      label: Text(
                        revealedTiles.isNotEmpty
                            ? 'CASHOUT ₹${currentPayout.toStringAsFixed(2)} (${currentMultiplier.toStringAsFixed(2)}x)'
                            : 'PICK A TILE TO BEGIN',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      onPressed: (revealedTiles.isNotEmpty && !isCashingOut) ? cashout : null,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                      label: Text(
                        'BET ₹${betAmount.toStringAsFixed(2)} & PLAY',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 1),
                      ),
                      onPressed: startGame,
                    ),
                  ),

                const SizedBox(height: 24),

                // Bet Amount & Mine Count Controls (Only when not playing)
                if (!isPlaying) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BET AMOUNT (₹)',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: betChips.map((chip) {
                            final isSel = betAmount == chip;
                            return ChoiceChip(
                              label: Text('₹${chip.toInt()}'),
                              selected: isSel,
                              selectedColor: purple.withValues(alpha: 0.35),
                              labelStyle: TextStyle(
                                color: isSel ? purple : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) => setState(() => betAmount = chip),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'NUMBER OF MINES',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: mineChips.map((m) {
                            final isSel = mineCount == m;
                            return ChoiceChip(
                              label: Text('$m Mines'),
                              selected: isSel,
                              selectedColor: pink.withValues(alpha: 0.35),
                              labelStyle: TextStyle(
                                color: isSel ? pink : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (_) => setState(() => mineCount = m),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

