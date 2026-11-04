import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

// ==========================================
// 1. TEXAS HOLD'EM POKER SCREEN
// ==========================================
class PokerGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const PokerGameScreen({super.key, required this.userBalance, this.entryFee = 50.0, this.onGameFinished});

  @override
  State<PokerGameScreen> createState() => _PokerGameScreenState();
}

class _PokerGameScreenState extends State<PokerGameScreen> {
  List<String> playerCards = [];
  List<String> communityCards = [];
  List<String> opponentCards = [];
  int round = 0; // 0 = Pre-flop, 1 = Flop, 2 = Turn, 3 = River, 4 = Showdown
  double pot = 100.0;
  bool isGameOver = false;
  String? matchRef;
  String? whatsappUrl;

  final suits = ['♠', '♥', '♦', '♣'];
  final ranks = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

  @override
  void initState() {
    super.initState();
    startNewHand();
  }

  void startNewHand() {
    final rand = Random();
    pot = widget.entryFee * 2;
    playerCards = ['${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}', '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}'];
    opponentCards = ['${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}', '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}'];
    communityCards = [
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
      '${ranks[rand.nextInt(13)]}${suits[rand.nextInt(4)]}',
    ];
    round = 1; // Start with flop visible
  }

  void nextStreet() {
    if (round < 3) {
      setState(() => round++);
    } else {
      showdown();
    }
  }

  void showdown() {
    setState(() => round = 4);
    final isWin = Random().nextDouble() > 0.42;
    endGame(isWin ? 'win' : 'loss', isWin ? 'Full House beats Opponent Two Pair!' : 'Opponent held Three of a Kind.');
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? pot : 0.0;

    try {
      final res = await ApiService.recordMatch(
        gameName: "Texas Hold'em Poker",
        gameSlug: 'poker',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {'reason': reason, 'pot': pot},
      );
      if (!mounted) return;
      setState(() {
        matchRef = res['reference_id']?.toString();
        whatsappUrl = res['whatsapp_admin_url']?.toString();
      });
      widget.onGameFinished?.call();
    } catch (_) {}

    _showResultDialog(outcome, reason, payout);
  }

  void _showResultDialog(String outcome, String reason, double payout) {
    final isWin = outcome == 'win';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied, color: isWin ? gold : pink, size: 28),
            const SizedBox(width: 10),
            Text(isWin ? 'POKER POT WON!' : 'HAND LOST', style: TextStyle(color: isWin ? gold : pink, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isWin ? teal.withValues(alpha: 0.15) : pink.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isWin ? 'Pot Won:' : 'Match Fee:', style: const TextStyle(color: Colors.white70)),
                  Text(isWin ? '+₹${payout.toStringAsFixed(2)}' : '-₹${widget.entryFee.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isWin ? teal : pink)),
                ],
              ),
            ),
            if (matchRef != null) ...[
              const SizedBox(height: 10),
              Text('Match Ref: $matchRef', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ],
        ),
        actions: [
          if (whatsappUrl != null)
            TextButton.icon(
              icon: const Icon(Icons.chat, color: green, size: 18),
              label: const Text('REPORT TO ADMIN', style: TextStyle(color: green, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final uri = Uri.parse(whatsappUrl!);
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
          FilledButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('BACK TO GAMES'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int visibleCommunity = round == 1 ? 3 : (round == 2 ? 4 : (round >= 3 ? 5 : 0));

    return Scaffold(
      appBar: AppBar(title: const Text("Texas Hold'em Poker"), backgroundColor: bg),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Opponent
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('OPPONENT', style: TextStyle(color: pink, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: opponentCards.map((c) => _cardWidget(round == 4 ? c : '🂠', isHidden: round < 4)).toList(),
                    ),
                  ],
                ),
              ),

              // Community Cards & Pot
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1B3B2B), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text('POT: ₹${pot.toStringAsFixed(0)}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return i < visibleCommunity ? _cardWidget(communityCards[i]) : _cardWidget('?', isHidden: true);
                      }),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Player Hole Cards
              Column(
                children: [
                  const Text('YOUR HOLE CARDS', style: TextStyle(color: teal, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: playerCards.map((c) => _cardWidget(c)).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(foregroundColor: pink, side: const BorderSide(color: pink)),
                        onPressed: isGameOver ? null : () => endGame('loss', 'You folded hand.'),
                        child: const Text('FOLD'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black),
                        onPressed: isGameOver ? null : nextStreet,
                        child: Text(round < 3 ? 'CHECK / CALL' : 'SHOWDOWN', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardWidget(String text, {bool isHidden = false}) {
    final isRed = text.contains('♥') || text.contains('♦');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 52,
      height: 75,
      decoration: BoxDecoration(color: isHidden ? const Color(0xFF1E3799) : Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: isHidden ? Colors.white : (isRed ? Colors.red : Colors.black), fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}

// ==========================================
// 2. ANDAR BAHAR SCREEN
// ==========================================
class AndarBaharScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const AndarBaharScreen({super.key, required this.userBalance, this.entryFee = 20.0, this.onGameFinished});

  @override
  State<AndarBaharScreen> createState() => _AndarBaharScreenState();
}

class _AndarBaharScreenState extends State<AndarBaharScreen> {
  final String jokerCard = 'K♠';
  List<String> andarCards = [];
  List<String> baharCards = [];
  String? selectedBet; // 'andar' or 'bahar'
  bool isDealing = false;
  bool isGameOver = false;

  void placeBet(String side) {
    if (isDealing || isGameOver) return;
    setState(() {
      selectedBet = side;
      isDealing = true;
      andarCards.clear();
      baharCards.clear();
    });

    dealCardsSequence();
  }

  void dealCardsSequence() {
    final deck = ['7♥', '9♦', '4♣', 'Q♠', 'J♥', '10♦', 'K♦'];
    int i = 0;

    Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final card = deck[i % deck.length];
      final isAndarTurn = (i % 2 == 0);

      setState(() {
        if (isAndarTurn) {
          andarCards.add(card);
        } else {
          baharCards.add(card);
        }
      });

      if (card.startsWith('K')) {
        timer.cancel();
        final winningSide = isAndarTurn ? 'andar' : 'bahar';
        final isWin = selectedBet == winningSide;
        endGame(isWin ? 'win' : 'loss', isWin ? 'Matching King landed on ${winningSide.toUpperCase()}!' : 'Matching King landed on ${winningSide.toUpperCase()}.');
        return;
      }

      i++;
      if (i >= deck.length) {
        timer.cancel();
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.95) : 0.0;

    try {
      await ApiService.recordMatch(
        gameName: 'Andar Bahar',
        gameSlug: 'andar-bahar',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {'reason': reason, 'side': selectedBet},
      );
    } catch (_) {}

    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'VICTORY!' : 'LOST', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [
          FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Andar Bahar Classic'), backgroundColor: bg),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Joker card in center
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF1B3B2B), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    const Text('DEALER JOKER CARD', style: TextStyle(color: gold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _miniCard(jokerCard),
                  ],
                ),
              ),

              // Andar & Bahar Slots
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _dealColumn('ANDAR', andarCards, teal)),
                    Container(width: 1, color: Colors.white24),
                    Expanded(child: _dealColumn('BAHAR', baharCards, purple)),
                  ],
                ),
              ),

              // Betting buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black),
                        onPressed: isDealing ? null : () => placeBet('andar'),
                        child: const Text('BET ANDAR (1.95x)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white),
                        onPressed: isDealing ? null : () => placeBet('bahar'),
                        child: const Text('BET BAHAR (1.95x)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dealColumn(String title, List<String> cards, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: cards.length,
            itemBuilder: (_, i) => Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: _miniCard(cards[i]))),
          ),
        ),
      ],
    );
  }

  Widget _miniCard(String val) {
    final isRed = val.contains('♥') || val.contains('♦');
    return Container(
      width: 48,
      height: 64,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
      child: Center(
        child: Text(val, style: TextStyle(color: isRed ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ==========================================
// 3. BLACKJACK 21 SCREEN
// ==========================================
class BlackjackGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const BlackjackGameScreen({super.key, required this.userBalance, this.entryFee = 25.0, this.onGameFinished});

  @override
  State<BlackjackGameScreen> createState() => _BlackjackGameScreenState();
}

class _BlackjackGameScreenState extends State<BlackjackGameScreen> {
  List<int> playerHand = [10, 8];
  List<int> dealerHand = [10];
  bool isGameOver = false;

  int get playerTotal => playerHand.reduce((a, b) => a + b);
  int get dealerTotal => dealerHand.reduce((a, b) => a + b);

  void hit() {
    if (isGameOver) return;
    setState(() {
      playerHand.add(Random().nextInt(10) + 1);
      if (playerTotal > 21) {
        endGame('loss', 'BUST! Player hand exceeded 21 ($playerTotal).');
      }
    });
  }

  void stand() {
    if (isGameOver) return;
    // Dealer draws to 17
    while (dealerTotal < 17) {
      dealerHand.add(Random().nextInt(10) + 1);
    }

    if (dealerTotal > 21 || playerTotal > dealerTotal) {
      endGame('win', 'Victory! $playerTotal beats Dealer $dealerTotal.');
    } else if (playerTotal < dealerTotal) {
      endGame('loss', 'Dealer wins with $dealerTotal against $playerTotal.');
    } else {
      endGame('draw', 'Push / Tie at $playerTotal.');
    }
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 2.0) : 0.0;

    try {
      await ApiService.recordMatch(
        gameName: 'Blackjack 21',
        gameSlug: 'blackjack',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {'player': playerTotal, 'dealer': dealerTotal, 'reason': reason},
      );
    } catch (_) {}

    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? '21 VICTORY!' : 'DEFEAT', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [
          FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blackjack 21'), backgroundColor: bg),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Dealer
              Column(
                children: [
                  Text('DEALER TOTAL: $dealerTotal', style: const TextStyle(color: pink, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: dealerHand.map((v) => _card(v)).toList()),
                ],
              ),
              // Player
              Column(
                children: [
                  Text('YOUR TOTAL: $playerTotal', style: const TextStyle(color: teal, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: playerHand.map((v) => _card(v)).toList()),
                ],
              ),
              // Controls
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black), onPressed: isGameOver ? null : hit, child: const Text('HIT'))),
                    const SizedBox(width: 16),
                    Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: gold, foregroundColor: Colors.black), onPressed: isGameOver ? null : stand, child: const Text('STAND'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(int val) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 50,
      height: 70,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Center(child: Text('$val', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16))),
    );
  }
}

// ==========================================
// 4. CALL BREAK SCREEN
// ==========================================
class CallBreakScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const CallBreakScreen({super.key, required this.userBalance, this.entryFee = 20.0, this.onGameFinished});

  @override
  State<CallBreakScreen> createState() => _CallBreakScreenState();
}

class _CallBreakScreenState extends State<CallBreakScreen> {
  int tricksWon = 0;
  final int bid = 3;
  int currentRound = 1;
  bool isGameOver = false;

  void playTrick() {
    if (isGameOver) return;
    setState(() {
      final won = Random().nextBool();
      if (won) tricksWon++;
      currentRound++;

      if (currentRound > 5) {
        final isWin = tricksWon >= bid;
        endGame(isWin ? 'win' : 'loss', isWin ? 'Bid achieved! Won $tricksWon tricks (Bid: $bid)!' : 'Bid failed! Won $tricksWon tricks (Bid: $bid).');
      }
    });
  }

  Future<void> endGame(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.9) : 0.0;

    try {
      await ApiService.recordMatch(
        gameName: 'Call Break',
        gameSlug: 'call-break',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {'tricks': tricksWon, 'bid': bid},
      );
    } catch (_) {}

    widget.onGameFinished?.call();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surface,
        title: Text(isWin ? 'TRICKS WON!' : 'BID LOST', style: TextStyle(color: isWin ? gold : pink)),
        content: Text(reason),
        actions: [FilledButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('BACK TO GAMES'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Call Break (Spades Trump)'), backgroundColor: bg),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('TRUMP SUIT: ♠ SPADES', style: const TextStyle(color: gold, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('Your Bid: $bid Tricks', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              Text('Tricks Won: $tricksWon / 5', style: const TextStyle(color: teal, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                onPressed: isGameOver ? null : playTrick,
                child: Text('PLAY TRICK #$currentRound', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
