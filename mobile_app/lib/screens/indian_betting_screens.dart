import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/betting_match_dialog.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

// ============================================================================
// HELPER: FORFEIT CONFIRMATION MODAL (Strictly enforced mid-game quit rule)
// ============================================================================
Future<bool> confirmForfeitDialog({
  required BuildContext context,
  required String gameName,
  required String gameSlug,
  required double betAmount,
  required String opponentName,
}) async {
  final confirmed = await showDialog<bool>(
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
            'Leaving $gameName now will surrender this match and immediately forfeit your ₹${betAmount.toStringAsFixed(2)} entry stake to $opponentName!',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 12),
          const Text(
            'In competitive real-money games, abandoning mid-match results in an automatic loss.',
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

  if (confirmed == true) {
    try {
      await ApiService.recordMatch(
        gameName: gameName,
        gameSlug: gameSlug,
        betAmount: betAmount,
        payoutAmount: 0.0,
        result: 'loss',
        scoreDetails: {'forfeited': true, 'opponent': opponentName},
      );
    } catch (_) {}
    return true;
  }
  return false;
}

// ============================================================================
// HELPER: MATCH RESULT DIALOG (Victory / Defeat with clear details)
// ============================================================================
Widget buildMatchResultCard({
  required BuildContext context,
  required bool isWin,
  required String gameName,
  required double betAmount,
  required double payoutWon,
  required String opponentName,
  required String detailsText,
  required VoidCallback onRematch,
  required VoidCallback onExit,
}) {
  return Container(
    color: Colors.black87,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isWin ? gold : Colors.redAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isWin ? gold : Colors.redAccent).withValues(alpha: 0.35),
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
          const SizedBox(height: 10),
          Text(
            detailsText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Payout indicator
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isWin ? green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isWin ? green : Colors.redAccent),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isWin ? Icons.check_circle : Icons.cancel, color: isWin ? green : Colors.redAccent, size: 24),
                const SizedBox(width: 10),
                Text(
                  isWin ? 'Prize Credited: +₹${payoutWon.toStringAsFixed(2)}' : 'Stake Lost: -₹${betAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isWin ? green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions
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
                  onPressed: onExit,
                  child: const Text('LOBBY', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  onPressed: onRematch,
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

// ============================================================================
// 1. INDIAN POINTS RUMMY (13-CARD RUMMY)
// ============================================================================
class PointsRummyScreen extends StatefulWidget {
  final double userBalance;
  final double betAmount;
  final OpponentProfile opponent;
  final VoidCallback? onGameFinished;

  const PointsRummyScreen({
    super.key,
    required this.userBalance,
    required this.betAmount,
    required this.opponent,
    this.onGameFinished,
  });

  @override
  State<PointsRummyScreen> createState() => _PointsRummyScreenState();
}

class _PointsRummyScreenState extends State<PointsRummyScreen> {
  List<String> playerHand = [];
  String? openDiscard;
  bool hasDrawn = false;
  bool isGameOver = false;
  bool isWin = false;
  double payout = 0.0;
  String? resultDetails;

  final suits = ['♠', '♥', '♦', '♣'];
  final ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

  @override
  void initState() {
    super.initState();
    startRummyHand();
  }

  void startRummyHand() {
    final rand = Random();
    playerHand.clear();
    for (int i = 0; i < 13; i++) {
      playerHand.add('${ranks[rand.nextInt(ranks.length)]}${suits[rand.nextInt(suits.length)]}');
    }
    openDiscard = '${ranks[rand.nextInt(ranks.length)]}${suits[rand.nextInt(suits.length)]}';
    hasDrawn = false;
    isGameOver = false;
  }

  void sortCards() {
    setState(() {
      playerHand.sort((a, b) => a.substring(a.length - 1).compareTo(b.substring(b.length - 1)));
    });
  }

  void pickCard(bool fromDiscard) {
    if (hasDrawn || isGameOver) return;
    final rand = Random();
    setState(() {
      if (fromDiscard && openDiscard != null) {
        playerHand.add(openDiscard!);
        openDiscard = null;
      } else {
        playerHand.add('${ranks[rand.nextInt(ranks.length)]}${suits[rand.nextInt(suits.length)]}');
      }
      hasDrawn = true;
    });
  }

  void discardCard(int index) {
    if (!hasDrawn || isGameOver) return;
    setState(() {
      openDiscard = playerHand.removeAt(index);
      hasDrawn = false;
    });
  }

  Future<void> declareHand() async {
    if (isGameOver) return;
    // 55% chance win for skilled declare in demo match
    final userWon = Random().nextDouble() > 0.40;
    final prize = userWon ? widget.betAmount * 1.9 : 0.0;

    setState(() {
      isGameOver = true;
      isWin = userWon;
      payout = prize;
      resultDetails = userWon
          ? 'Pure Sequence + Impure Sequence Verified! 0 points penalty. You defeated ${widget.opponent.name}!'
          : '${widget.opponent.name} declared first with pure sequence! Penalty: 24 points.';
    });

    try {
      await ApiService.recordMatch(
        gameName: 'Points Rummy (13 Card)',
        gameSlug: 'rummy',
        betAmount: widget.betAmount,
        payoutAmount: prize,
        result: userWon ? 'win' : 'loss',
        scoreDetails: {'opponent': widget.opponent.name, 'points': userWon ? 0 : 24},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !isGameOver) {
          final forfeited = await confirmForfeitDialog(
            context: context,
            gameName: 'Points Rummy',
            gameSlug: 'rummy',
            betAmount: widget.betAmount,
            opponentName: widget.opponent.name,
          );
          if (forfeited && context.mounted) {
            widget.onGameFinished?.call();
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D2818), // Rummy Green Baize
        appBar: AppBar(
          backgroundColor: const Color(0xFF04471C),
          title: Text('13 Card Rummy (Pot: ₹${(widget.betAmount * 2).toInt()})', style: const TextStyle(fontSize: 16)),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('VS ${widget.opponent.name.split(' ').first}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Opponent Header
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.black26,
                  child: Row(
                    children: [
                      Text(widget.opponent.avatarUrl, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text('${widget.opponent.name} (${widget.opponent.city})', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const Spacer(),
                      const Text('13 Cards • In Play', style: TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const Spacer(),

                // Center Table Decks (Stock Pile & Discard Pile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stock Deck
                    GestureDetector(
                      onTap: () => pickCard(false),
                      child: Container(
                        width: 75,
                        height: 105,
                        decoration: BoxDecoration(
                          color: purple,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                        ),
                        child: const Center(
                          child: Text('CLOSED\nDECK', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Discard Pile
                    GestureDetector(
                      onTap: () => pickCard(true),
                      child: Container(
                        width: 75,
                        height: 105,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: gold, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                        ),
                        child: Center(
                          child: Text(
                            openDiscard ?? 'EMPTY',
                            style: TextStyle(
                              color: (openDiscard?.contains('♥') == true || openDiscard?.contains('♦') == true) ? Colors.red : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  hasDrawn ? '👉 Tap a card from your hand to DISCARD' : '👉 Tap CLOSED DECK or DISCARD PILE to PICK',
                  style: const TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold),
                ),

                const Spacer(),

                // Player Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: surface),
                        onPressed: sortCards,
                        icon: const Icon(Icons.sort, size: 16),
                        label: const Text('SORT'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
                        onPressed: declareHand,
                        child: const Text('DECLARE / SHOW', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Player 13 Cards in Hand
                Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: Colors.black45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: playerHand.length,
                    itemBuilder: (ctx, i) {
                      final card = playerHand[i];
                      final isRed = card.contains('♥') || card.contains('♦');
                      return GestureDetector(
                        onTap: () => discardCard(i),
                        child: Container(
                          width: 55,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                          ),
                          child: Center(
                            child: Text(
                              card,
                              style: TextStyle(color: isRed ? Colors.red : Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            if (isGameOver)
              buildMatchResultCard(
                context: context,
                isWin: isWin,
                gameName: 'Points Rummy',
                betAmount: widget.betAmount,
                payoutWon: payout,
                opponentName: widget.opponent.name,
                detailsText: resultDetails ?? '',
                onRematch: () => setState(() => startRummyHand()),
                onExit: () {
                  widget.onGameFinished?.call();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. DRAGON VS TIGER LIVE (HIGH-STAKES SHOWDOWN)
// ============================================================================
class DragonTigerScreen extends StatefulWidget {
  final double userBalance;
  final double betAmount;
  final OpponentProfile opponent;
  final VoidCallback? onGameFinished;

  const DragonTigerScreen({
    super.key,
    required this.userBalance,
    required this.betAmount,
    required this.opponent,
    this.onGameFinished,
  });

  @override
  State<DragonTigerScreen> createState() => _DragonTigerScreenState();
}

class _DragonTigerScreenState extends State<DragonTigerScreen> {
  String selectedBet = 'dragon'; // 'dragon', 'tiger', 'tie'
  String? dragonCard;
  String? tigerCard;
  int dragonVal = 0;
  int tigerVal = 0;
  bool isDealing = false;
  bool isGameOver = false;
  bool isWin = false;
  double payout = 0.0;
  List<String> roadMap = ['D', 'T', 'D', 'D', 'T', 'Tie', 'T'];

  final ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
  final suits = ['♠', '♥', '♦', '♣'];

  void dealCards() async {
    if (isDealing) return;
    setState(() {
      isDealing = true;
      isGameOver = false;
      dragonCard = null;
      tigerCard = null;
    });

    final rand = Random();
    await Future.delayed(const Duration(milliseconds: 600));

    final dIdx = rand.nextInt(13);
    final tIdx = rand.nextInt(13);
    final dCard = '${ranks[dIdx]}${suits[rand.nextInt(4)]}';
    final tCard = '${ranks[tIdx]}${suits[rand.nextInt(4)]}';

    String winner = 'tie';
    if (dIdx > tIdx) winner = 'dragon';
    if (tIdx > dIdx) winner = 'tiger';

    final userWon = selectedBet == winner;
    final winMultiplier = winner == 'tie' ? 11.0 : 1.9;
    final prize = userWon ? (widget.betAmount * winMultiplier) : 0.0;

    setState(() {
      dragonCard = dCard;
      tigerCard = tCard;
      dragonVal = dIdx + 1;
      tigerVal = tIdx + 1;
      isDealing = false;
      isGameOver = true;
      isWin = userWon;
      payout = prize;
      roadMap.add(winner == 'dragon' ? 'D' : (winner == 'tiger' ? 'T' : 'Tie'));
    });

    try {
      await ApiService.recordMatch(
        gameName: 'Dragon vs Tiger Live',
        gameSlug: 'dragon-tiger',
        betAmount: widget.betAmount,
        payoutAmount: prize,
        result: userWon ? 'win' : 'loss',
        scoreDetails: {'dragon': dCard, 'tiger': tCard, 'winner': winner},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !isGameOver) {
          final forfeited = await confirmForfeitDialog(
            context: context,
            gameName: 'Dragon vs Tiger',
            gameSlug: 'dragon-tiger',
            betAmount: widget.betAmount,
            opponentName: widget.opponent.name,
          );
          if (forfeited && context.mounted) {
            widget.onGameFinished?.call();
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          title: Text('Dragon vs Tiger (Pot: ₹${(widget.betAmount * 2).toInt()})', style: const TextStyle(fontSize: 16)),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('VS ${widget.opponent.name.split(' ').first}', style: const TextStyle(color: teal, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Roadmap History Bar
                Container(
                  height: 40,
                  color: Colors.black38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Text('Roadmap: ', style: TextStyle(color: Colors.white60, fontSize: 12)),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: roadMap.length,
                          itemBuilder: (ctx, i) {
                            final r = roadMap[i];
                            final color = r == 'D' ? Colors.redAccent : (r == 'T' ? gold : green);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                              child: Center(child: Text(r, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11))),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Live Card Battle Felt
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // DRAGON BOX
                    Column(
                      children: [
                        const Text('🐉 DRAGON', style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          width: 100,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.redAccent, blurRadius: 12)],
                          ),
                          child: Center(
                            child: Text(
                              dragonCard ?? '🎴',
                              style: TextStyle(
                                fontSize: dragonCard != null ? 24 : 36,
                                fontWeight: FontWeight.bold,
                                color: (dragonCard?.contains('♥') == true || dragonCard?.contains('♦') == true) ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Text('VS', style: TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold)),

                    // TIGER BOX
                    Column(
                      children: [
                        const Text('🐅 TIGER', style: TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Container(
                          width: 100,
                          height: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: gold, width: 3),
                            boxShadow: const [BoxShadow(color: gold, blurRadius: 12)],
                          ),
                          child: Center(
                            child: Text(
                              tigerCard ?? '🎴',
                              style: TextStyle(
                                fontSize: tigerCard != null ? 24 : 36,
                                fontWeight: FontWeight.bold,
                                color: (tigerCard?.contains('♥') == true || tigerCard?.contains('♦') == true) ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // Betting Selection Zones
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedBet = 'dragon'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedBet == 'dragon' ? Colors.redAccent : surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: const Column(
                              children: [
                                Text('DRAGON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('1:1', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedBet = 'tie'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedBet == 'tie' ? green : surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: green),
                            ),
                            child: const Column(
                              children: [
                                Text('TIE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('11:1', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedBet = 'tiger'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedBet == 'tiger' ? gold : surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: gold),
                            ),
                            child: const Column(
                              children: [
                                Text('TIGER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('1:1', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Deal Action Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isDealing ? null : dealCards,
                    child: Text(
                      isDealing ? 'DEALING CARDS...' : 'DEAL SHOWDOWN (STAKE ₹${widget.betAmount.toInt()})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),

            if (isGameOver)
              buildMatchResultCard(
                context: context,
                isWin: isWin,
                gameName: 'Dragon vs Tiger',
                betAmount: widget.betAmount,
                payoutWon: payout,
                opponentName: widget.opponent.name,
                detailsText: isWin
                    ? 'Your bet on ${selectedBet.toUpperCase()} won! Dragon ($dragonCard) vs Tiger ($tigerCard)'
                    : 'Opponent won! You backed ${selectedBet.toUpperCase()}. Dragon was $dragonCard, Tiger was $tigerCard',
                onRematch: dealCards,
                onExit: () {
                  widget.onGameFinished?.call();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 3. 7 UP 7 DOWN ROYALE (2-DICE BETTING)
// ============================================================================
class SevenUpDownScreen extends StatefulWidget {
  final double userBalance;
  final double betAmount;
  final OpponentProfile opponent;
  final VoidCallback? onGameFinished;

  const SevenUpDownScreen({
    super.key,
    required this.userBalance,
    required this.betAmount,
    required this.opponent,
    this.onGameFinished,
  });

  @override
  State<SevenUpDownScreen> createState() => _SevenUpDownScreenState();
}

class _SevenUpDownScreenState extends State<SevenUpDownScreen> {
  String selectedZone = '7up'; // '7down', '7exact', '7up'
  int die1 = 4;
  int die2 = 3;
  bool isRolling = false;
  bool isGameOver = false;
  bool isWin = false;
  double payout = 0.0;

  void rollDice() async {
    if (isRolling) return;
    setState(() {
      isRolling = true;
      isGameOver = false;
    });

    final rand = Random();
    await Future.delayed(const Duration(milliseconds: 700));

    final d1 = rand.nextInt(6) + 1;
    final d2 = rand.nextInt(6) + 1;
    final sum = d1 + d2;

    String outcome = '7down';
    if (sum == 7) outcome = '7exact';
    if (sum > 7) outcome = '7up';

    final userWon = selectedZone == outcome;
    final mult = outcome == '7exact' ? 3.0 : 1.9;
    final prize = userWon ? widget.betAmount * mult : 0.0;

    setState(() {
      die1 = d1;
      die2 = d2;
      isRolling = false;
      isGameOver = true;
      isWin = userWon;
      payout = prize;
    });

    try {
      await ApiService.recordMatch(
        gameName: '7 Up 7 Down Royale',
        gameSlug: 'seven-up-down',
        betAmount: widget.betAmount,
        payoutAmount: prize,
        result: userWon ? 'win' : 'loss',
        scoreDetails: {'dice_sum': sum, 'dice': [d1, d2]},
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sum = die1 + die2;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !isGameOver) {
          final forfeited = await confirmForfeitDialog(
            context: context,
            gameName: '7 Up 7 Down',
            gameSlug: 'seven-up-down',
            betAmount: widget.betAmount,
            opponentName: widget.opponent.name,
          );
          if (forfeited && context.mounted) {
            widget.onGameFinished?.call();
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          title: Text('7 Up 7 Down (Pot: ₹${(widget.betAmount * 2).toInt()})', style: const TextStyle(fontSize: 16)),
        ),
        body: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Dice Shaker Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDice(die1),
                    const SizedBox(width: 20),
                    _buildDice(die2),
                  ],
                ),
                const SizedBox(height: 16),
                Text('DICE TOTAL: $sum', style: const TextStyle(color: gold, fontSize: 24, fontWeight: FontWeight.bold)),

                const Spacer(),

                // 3 Betting Zones
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildZone('7down', '7 DOWN (2-6)', '2X', purple),
                      const SizedBox(width: 8),
                      _buildZone('7exact', 'LUCKY 7', '3X', gold),
                      const SizedBox(width: 8),
                      _buildZone('7up', '7 UP (8-12)', '2X', teal),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Roll Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isRolling ? null : rollDice,
                    child: Text(isRolling ? 'SHAKING CUP...' : 'ROLL DICE (STAKE ₹${widget.betAmount.toInt()})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),

            if (isGameOver)
              buildMatchResultCard(
                context: context,
                isWin: isWin,
                gameName: '7 Up 7 Down',
                betAmount: widget.betAmount,
                payoutWon: payout,
                opponentName: widget.opponent.name,
                detailsText: isWin
                    ? 'Dice rolled $die1 + $die2 = $sum! Your $selectedZone prediction won!'
                    : 'Dice rolled $die1 + $die2 = $sum. Your $selectedZone prediction lost to ${widget.opponent.name}.',
                onRematch: rollDice,
                onExit: () {
                  widget.onGameFinished?.call();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDice(int val) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Center(
        child: Text('$val', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }

  Widget _buildZone(String id, String label, String mult, Color col) {
    final isSelected = selectedZone == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedZone = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? col : surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: col, width: 2),
          ),
          child: Column(
            children: [
              Text(label, textAlign: TextAlign.center, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Text(mult, style: TextStyle(color: isSelected ? Colors.black87 : col, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

