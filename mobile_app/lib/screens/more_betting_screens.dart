import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/betting_match_dialog.dart';
import 'indian_betting_screens.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

// ============================================================================
// 1. TEEN PATTI CASH PRO (3-CARD INDIAN POKER)
// ============================================================================
class TeenPattiCashScreen extends StatefulWidget {
  final double userBalance;
  final double betAmount;
  final OpponentProfile opponent;
  final VoidCallback? onGameFinished;

  const TeenPattiCashScreen({
    super.key,
    required this.userBalance,
    required this.betAmount,
    required this.opponent,
    this.onGameFinished,
  });

  @override
  State<TeenPattiCashScreen> createState() => _TeenPattiCashScreenState();
}

class _TeenPattiCashScreenState extends State<TeenPattiCashScreen> {
  List<String> playerCards = [];
  List<String> opponentCards = [];
  bool cardsSeen = false;
  bool isGameOver = false;
  bool isWin = false;
  double payout = 0.0;
  String details = '';

  final ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
  final suits = ['♠', '♥', '♦', '♣'];

  @override
  void initState() {
    super.initState();
    startNewHand();
  }

  void startNewHand() {
    final rand = Random();
    playerCards = [
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
    ];
    opponentCards = [
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
    ];
    cardsSeen = false;
    isGameOver = false;
  }

  Future<void> showDown() async {
    if (isGameOver) return;
    cardsSeen = true;
    final userWon = Random().nextDouble() > 0.45;
    final prize = userWon ? (widget.betAmount * 1.9) : 0.0;

    setState(() {
      isGameOver = true;
      isWin = userWon;
      payout = prize;
      details = userWon
          ? 'Pure Sequence beats ${widget.opponent.name}\'s Pair! You take the ₹${(widget.betAmount * 2).toInt()} Pot!'
          : '${widget.opponent.name} held Color Flush. Better luck in next hand!';
    });

    try {
      await ApiService.recordMatch(
        gameName: 'Teen Patti Cash Pro',
        gameSlug: 'teen-patti',
        betAmount: widget.betAmount,
        payoutAmount: prize,
        result: userWon ? 'win' : 'loss',
        scoreDetails: {'hand': playerCards, 'opponent_hand': opponentCards},
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
            gameName: 'Teen Patti Cash',
            gameSlug: 'teen-patti',
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
        backgroundColor: const Color(0xFF0F1E36),
        appBar: AppBar(
          backgroundColor: const Color(0xFF162A4A),
          title: Text('Teen Patti (Pot: ₹${(widget.betAmount * 2).toInt()})', style: const TextStyle(fontSize: 16)),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Opponent Face Down Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.opponent.avatarUrl, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 8),
                      Text('${widget.opponent.name} (Chaal Active)', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => _buildCard(isGameOver ? opponentCards[i] : '🎴', isHidden: !isGameOver)),
                ),

                const Spacer(),

                // Center Pot Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: gold)),
                  child: Text('POT: ₹${(widget.betAmount * 2).toInt()}', style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
                ),

                const Spacer(),

                // Player Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => _buildCard(cardsSeen ? playerCards[i] : '🎴', isHidden: !cardsSeen)),
                ),
                const SizedBox(height: 12),

                // Player Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      if (!cardsSeen)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black),
                            onPressed: () => setState(() => cardsSeen = true),
                            child: const Text('SEE CARDS', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      if (!cardsSeen) const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black),
                          onPressed: showDown,
                          child: const Text('SHOW / CHAAL', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (isGameOver)
              buildMatchResultCard(
                context: context,
                isWin: isWin,
                gameName: 'Teen Patti Cash Pro',
                betAmount: widget.betAmount,
                payoutWon: payout,
                opponentName: widget.opponent.name,
                detailsText: details,
                onRematch: () => setState(() => startNewHand()),
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

  Widget _buildCard(String text, {bool isHidden = false}) {
    final isRed = text.contains('♥') || text.contains('♦');
    return Container(
      width: 70,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isHidden ? purple : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isHidden ? Colors.white30 : gold, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: isHidden ? 28 : 20,
            fontWeight: FontWeight.bold,
            color: isHidden ? Colors.white : (isRed ? Colors.red : Colors.black),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. ANDAR BAHAR DELUXE (TRADITIONAL INDIAN BETTING)
// ============================================================================
class AndarBaharScreen extends StatefulWidget {
  final double userBalance;
  final double betAmount;
  final OpponentProfile opponent;
  final VoidCallback? onGameFinished;

  const AndarBaharScreen({
    super.key,
    required this.userBalance,
    required this.betAmount,
    required this.opponent,
    this.onGameFinished,
  });

  @override
  State<AndarBaharScreen> createState() => _AndarBaharScreenState();
}

class _AndarBaharScreenState extends State<AndarBaharScreen> {
  String selectedSide = 'andar'; // 'andar' or 'bahar'
  String jokerCard = '8♠';
  String jokerRank = '8';
  List<String> andarCards = [];
  List<String> baharCards = [];
  bool isDealing = false;
  bool isGameOver = false;
  bool isWin = false;
  double payout = 0.0;
  String winningSide = '';

  final ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];
  final suits = ['♠', '♥', '♦', '♣'];

  @override
  void initState() {
    super.initState();
    initRound();
  }

  void initRound() {
    final rand = Random();
    jokerRank = ranks[rand.nextInt(ranks.length)];
    jokerCard = '$jokerRank${suits[rand.nextInt(suits.length)]}';
    andarCards.clear();
    baharCards.clear();
    isDealing = false;
    isGameOver = false;
  }

  Future<void> startDealing() async {
    if (isDealing) return;
    setState(() => isDealing = true);

    final rand = Random();
    bool matchFound = false;
    int dealCount = 0;

    while (!matchFound && dealCount < 12) {
      await Future.delayed(const Duration(milliseconds: 350));
      dealCount++;
      final isAndarTurn = dealCount % 2 == 1;

      // 25% chance matching rank appears
      final willMatch = rand.nextDouble() < 0.28 || dealCount >= 10;
      final cardRank = willMatch ? jokerRank : ranks[rand.nextInt(ranks.length)];
      final card = '$cardRank${suits[rand.nextInt(suits.length)]}';

      if (!mounted) return;
      setState(() {
        if (isAndarTurn) {
          andarCards.add(card);
        } else {
          baharCards.add(card);
        }
      });

      if (cardRank == jokerRank) {
        matchFound = true;
        winningSide = isAndarTurn ? 'andar' : 'bahar';
      }
    }

    final userWon = selectedSide == winningSide;
    final prize = userWon ? (widget.betAmount * 1.9) : 0.0;

    setState(() {
      isDealing = false;
      isGameOver = true;
      isWin = userWon;
      payout = prize;
    });

    try {
      await ApiService.recordMatch(
        gameName: 'Andar Bahar Deluxe',
        gameSlug: 'andar-bahar',
        betAmount: widget.betAmount,
        payoutAmount: prize,
        result: userWon ? 'win' : 'loss',
        scoreDetails: {'joker': jokerCard, 'winner': winningSide},
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
            gameName: 'Andar Bahar',
            gameSlug: 'andar-bahar',
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
          title: Text('Andar Bahar (Pot: ₹${(widget.betAmount * 2).toInt()})', style: const TextStyle(fontSize: 16)),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // JOKER CARD IN CENTER
                const SizedBox(height: 16),
                const Text('JOKER (TARGET MATCH)', style: TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 110,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: gold, width: 3)),
                  child: Center(
                    child: Text(
                      jokerCard,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: (jokerCard.contains('♥') || jokerCard.contains('♦')) ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ANDAR (INSIDE) ROW
                _buildCardTrack('ANDAR (Inside)', andarCards, Colors.blueAccent),
                const SizedBox(height: 14),

                // BAHAR (OUTSIDE) ROW
                _buildCardTrack('BAHAR (Outside)', baharCards, Colors.orangeAccent),

                const Spacer(),

                // Bet Choice Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: isDealing ? null : () => setState(() => selectedSide = 'andar'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedSide == 'andar' ? Colors.blueAccent : surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.blueAccent, width: 2),
                            ),
                            child: const Column(
                              children: [
                                Text('ANDAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('1.9X', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: isDealing ? null : () => setState(() => selectedSide = 'bahar'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedSide == 'bahar' ? Colors.orangeAccent : surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.orangeAccent, width: 2),
                            ),
                            child: const Column(
                              children: [
                                Text('BAHAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('1.9X', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Deal Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isDealing ? null : startDealing,
                    child: Text(
                      isDealing ? 'DEALING CARDS...' : 'START DEAL (STAKE ₹${widget.betAmount.toInt()})',
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
                gameName: 'Andar Bahar',
                betAmount: widget.betAmount,
                payoutWon: payout,
                opponentName: widget.opponent.name,
                detailsText: isWin
                    ? 'Matching $jokerRank landed on ${winningSide.toUpperCase()}! You won the match pot!'
                    : 'Matching $jokerRank landed on ${winningSide.toUpperCase()}. ${widget.opponent.name} takes the pot.',
                onRematch: () {
                  initRound();
                  startDealing();
                },
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

  Widget _buildCardTrack(String title, List<String> cards, Color col) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: col.withValues(alpha: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: cards.isEmpty
                ? const Center(child: Text('Waiting for deal...', style: TextStyle(color: Colors.white38, fontSize: 12)))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: cards.length,
                    itemBuilder: (ctx, i) {
                      final c = cards[i];
                      final isRed = c.contains('♥') || c.contains('♦');
                      final isMatch = c.startsWith(jokerRank);
                      return Container(
                        width: 36,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isMatch ? gold : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: isMatch ? Border.all(color: Colors.red, width: 2) : null,
                        ),
                        child: Center(
                          child: Text(c, style: TextStyle(color: isRed ? Colors.red : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. SPEED LUDO CLASH (ZUPEE STYLE 2-PLAYER TOKEN BATTLE)
// ============================================================================
class SpeedLudoClashScreen extends StatefulWidget {
  final double userBalance;
  final double betAmount;
  final OpponentProfile opponent;
  final VoidCallback? onGameFinished;

  const SpeedLudoClashScreen({
    super.key,
    required this.userBalance,
    required this.betAmount,
    required this.opponent,
    this.onGameFinished,
  });

  @override
  State<SpeedLudoClashScreen> createState() => _SpeedLudoClashScreenState();
}

class _SpeedLudoClashScreenState extends State<SpeedLudoClashScreen> {
  int playerScore = 0;
  int opponentScore = 0;
  int diceVal = 6;
  int turnsLeft = 14;
  bool isPlayerTurn = true;
  bool isRolling = false;
  bool isGameOver = false;
  bool isWin = false;
  double payout = 0.0;
  String eventText = 'Roll dice to move your tokens!';

  void rollDice() async {
    if (isRolling || !isPlayerTurn || isGameOver) return;
    setState(() => isRolling = true);

    final rand = Random();
    await Future.delayed(const Duration(milliseconds: 400));
    final roll = rand.nextInt(6) + 1;

    final gotBonus = roll == 6 || rand.nextDouble() < 0.25;
    final pointsGained = roll * 4 + (gotBonus ? 25 : 0);

    setState(() {
      diceVal = roll;
      playerScore += pointsGained;
      isRolling = false;
      turnsLeft--;
      eventText = gotBonus ? '⚔️ Opponent token captured! +$pointsGained PTS!' : 'Moved token $roll steps! +$pointsGained PTS';
    });

    if (turnsLeft <= 0) {
      concludeLudoMatch();
      return;
    }

    // Opponent Turn AI
    setState(() => isPlayerTurn = false);
    await Future.delayed(const Duration(milliseconds: 700));

    final oppRoll = rand.nextInt(6) + 1;
    final oppBonus = oppRoll == 6 || rand.nextDouble() < 0.25;
    final oppGained = oppRoll * 4 + (oppBonus ? 25 : 0);

    if (mounted && !isGameOver) {
      setState(() {
        opponentScore += oppGained;
        isPlayerTurn = true;
      });
    }
  }

  Future<void> concludeLudoMatch() async {
    final userWon = playerScore >= opponentScore;
    final prize = userWon ? (widget.betAmount * 1.9) : 0.0;

    setState(() {
      isGameOver = true;
      isWin = userWon;
      payout = prize;
    });

    try {
      await ApiService.recordMatch(
        gameName: 'Speed Ludo Clash',
        gameSlug: 'speed-ludo',
        betAmount: widget.betAmount,
        payoutAmount: prize,
        result: userWon ? 'win' : 'loss',
        scoreDetails: {'player_score': playerScore, 'opponent_score': opponentScore},
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
            gameName: 'Speed Ludo',
            gameSlug: 'speed-ludo',
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
          title: Text('Speed Ludo (Pot: ₹${(widget.betAmount * 2).toInt()})', style: const TextStyle(fontSize: 16)),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Top Header (Scores & Turns)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOU (RED)', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$playerScore pts', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(10)),
                        child: Text('$turnsLeft Turns Left', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${widget.opponent.name.split(' ').first} (GREEN)', style: const TextStyle(color: green, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$opponentScore pts', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Mini Ludo Board Visualizer
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: gold, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
                  ),
                  child: Stack(
                    children: [
                      Positioned(top: 15, left: 15, child: _buildHomeZone('RED BASE', Colors.redAccent)),
                      Positioned(bottom: 15, right: 15, child: _buildHomeZone('GREEN BASE', green)),
                      const Center(child: Text('🏆\nFINISH', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: gold))),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text(eventText, style: const TextStyle(color: teal, fontSize: 13, fontWeight: FontWeight.w600)),

                const Spacer(),

                // Dice Roll Area
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                      ),
                      child: Center(
                        child: Text(
                          '$diceVal',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPlayerTurn ? gold : Colors.white24,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isPlayerTurn ? rollDice : null,
                    child: Text(
                      isPlayerTurn ? 'ROLL DICE & MOVE TOKEN' : 'OPPONENT THINKING...',
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
                gameName: 'Speed Ludo Clash',
                betAmount: widget.betAmount,
                payoutWon: payout,
                opponentName: widget.opponent.name,
                detailsText: isWin
                    ? 'Final Score: $playerScore vs $opponentScore! You captured the pot!'
                    : 'Final Score: $playerScore vs $opponentScore. ${widget.opponent.name} won by score attack.',
                onRematch: () {
                  setState(() {
                    playerScore = 0;
                    opponentScore = 0;
                    turnsLeft = 14;
                    isGameOver = false;
                  });
                },
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

  Widget _buildHomeZone(String label, Color col) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(color: col.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: col)),
      child: Center(
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 11)),
      ),
    );
  }
}

// ============================================================================
// 4. CRICKET SUPER OVER (6 BALLS BETTING CHASE)
// ============================================================================
class CricketSuperOverScreen extends StatefulWidget {
  final double userBalance;
  final double betAmount;
  final OpponentProfile opponent;
  final VoidCallback? onGameFinished;

  const CricketSuperOverScreen({
    super.key,
    required this.userBalance,
    required this.betAmount,
    required this.opponent,
    this.onGameFinished,
  });

  @override
  State<CricketSuperOverScreen> createState() => _CricketSuperOverScreenState();
}

class _CricketSuperOverScreenState extends State<CricketSuperOverScreen> {
  int target = 16;
  int currentRuns = 0;
  int ballsBowled = 0;
  int wickets = 0;
  List<String> ballOutcomes = [];
  bool isHitting = false;
  bool isGameOver = false;
  bool isWin = false;
  double payout = 0.0;
  String shotCommentary = 'Opponent set 16 Runs off 6 Balls. Smash boundaries to win!';

  void hitShot() async {
    if (isHitting || isGameOver) return;
    setState(() => isHitting = true);

    final rand = Random();
    await Future.delayed(const Duration(milliseconds: 450));

    final roll = rand.nextDouble();
    String outcome;
    int runsGained = 0;

    if (roll < 0.25) {
      outcome = '6';
      runsGained = 6;
      shotCommentary = '💥 MASSIVE MAXIMUM! 6 RUNS INTO THE STANDS!';
    } else if (roll < 0.55) {
      outcome = '4';
      runsGained = 4;
      shotCommentary = '⚡ PIERCED THROUGH COVERS! 4 RUNS!';
    } else if (roll < 0.75) {
      outcome = '2';
      runsGained = 2;
      shotCommentary = '🏃 Quick double between the wickets! 2 Runs.';
    } else if (roll < 0.90) {
      outcome = '1';
      runsGained = 1;
      shotCommentary = 'Pushed to long-on for a single.';
    } else {
      outcome = 'W';
      wickets++;
      shotCommentary = '🔴 CAUGHT AT DEEP MID-WICKET! WICKET!';
    }

    ballsBowled++;
    currentRuns += runsGained;
    ballOutcomes.add(outcome);
    isHitting = false;

    if (currentRuns >= target) {
      concludeMatch(true, 'Target chased down in $ballsBowled balls! You defeated ${widget.opponent.name}!');
    } else if (ballsBowled >= 6 || wickets >= 2) {
      concludeMatch(false, 'Super Over ended. Scored $currentRuns/$wickets (Needed $target).');
    } else {
      setState(() {});
    }
  }

  Future<void> concludeMatch(bool won, String text) async {
    final prize = won ? (widget.betAmount * 1.9) : 0.0;
    setState(() {
      isGameOver = true;
      isWin = won;
      payout = prize;
      shotCommentary = text;
    });

    try {
      await ApiService.recordMatch(
        gameName: 'Cricket Super Over',
        gameSlug: 'cricket-over',
        betAmount: widget.betAmount,
        payoutAmount: prize,
        result: won ? 'win' : 'loss',
        scoreDetails: {'runs': currentRuns, 'wickets': wickets, 'balls': ballsBowled},
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
            gameName: 'Cricket Super Over',
            gameSlug: 'cricket-over',
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
          title: Text('Cricket Super Over (Pot: ₹${(widget.betAmount * 2).toInt()})', style: const TextStyle(fontSize: 16)),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Target scoreboard
                Container(
                  padding: const EdgeInsets.all(16),
                  color: surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TARGET TO WIN', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('$target Runs (6 Balls)', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('CURRENT SCORE', style: TextStyle(color: green, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('$currentRuns / $wickets ($ballsBowled/6 ov)', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Pitch Visualizer
                Container(
                  width: 260,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gold.withValues(alpha: 0.5)),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🏏', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text('SUPER OVER PITCH', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(shotCommentary, textAlign: TextAlign.center, style: const TextStyle(color: teal, fontSize: 13, fontWeight: FontWeight.bold)),
                ),

                const Spacer(),

                // Ball Trackers
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final hasBall = i < ballOutcomes.length;
                    final val = hasBall ? ballOutcomes[i] : '${i + 1}';
                    final isW = val == 'W';
                    final isSix = val == '6' || val == '4';
                    return Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: hasBall ? (isW ? Colors.redAccent : (isSix ? gold : surface)) : bg,
                        shape: BoxShape.circle,
                        border: Border.all(color: hasBall ? Colors.white : Colors.white24),
                      ),
                      child: Center(
                        child: Text(
                          val,
                          style: TextStyle(
                            color: hasBall ? (isSix ? Colors.black : Colors.white) : Colors.white38,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // Hit Shot Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isHitting || isGameOver ? null : hitShot,
                    child: Text(
                      isHitting ? 'TIMING SHOT...' : 'SMASH SHOT (BALL ${ballsBowled + 1}/6)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),

            if (isGameOver)
              buildMatchResultCard(
                context: context,
                isWin: isWin,
                gameName: 'Cricket Super Over',
                betAmount: widget.betAmount,
                payoutWon: payout,
                opponentName: widget.opponent.name,
                detailsText: shotCommentary,
                onRematch: () {
                  setState(() {
                    currentRuns = 0;
                    ballsBowled = 0;
                    wickets = 0;
                    ballOutcomes.clear();
                    isGameOver = false;
                  });
                },
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

