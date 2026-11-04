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

class PlayingCard {
  final String suit; // '♠', '♥', '♦', '♣'
  final int value; // 1 (A) to 13 (K)
  bool isSelected;

  PlayingCard({required this.suit, required this.value, this.isSelected = false});

  String get label {
    if (value == 1) return 'A';
    if (value == 11) return 'J';
    if (value == 12) return 'Q';
    if (value == 13) return 'K';
    return '$value';
  }

  Color get color => (suit == '♥' || suit == '♦') ? const Color(0xFFE74C3C) : Colors.black;
}

class RummyGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const RummyGameScreen({
    super.key,
    required this.userBalance,
    this.entryFee = 50.0,
    this.onGameFinished,
  });

  @override
  State<RummyGameScreen> createState() => _RummyGameScreenState();
}

class _RummyGameScreenState extends State<RummyGameScreen> {
  List<PlayingCard> playerHand = [];
  PlayingCard? openCard;
  final String wildJoker = '7♦';
  bool hasDrawn = false;
  bool isPlayerTurn = true;
  bool isGameOver = false;

  String? matchRef;
  String? whatsappUrl;
  String message = 'Pick a card from Closed Deck or Open Card!';

  final List<String> suits = ['♠', '♥', '♦', '♣'];

  @override
  void initState() {
    super.initState();
    dealCards();
  }

  void dealCards() {
    final rand = Random();
    playerHand.clear();
    // Deal 13 unique cards
    final Set<String> used = {};
    while (playerHand.length < 13) {
      final s = suits[rand.nextInt(suits.length)];
      final v = rand.nextInt(13) + 1;
      final key = '$v$s';
      if (!used.contains(key)) {
        used.add(key);
        playerHand.add(PlayingCard(suit: s, value: v));
      }
    }
    // Sort hand by suit and value
    playerHand.sort((a, b) {
      final sc = a.suit.compareTo(b.suit);
      if (sc != 0) return sc;
      return a.value.compareTo(b.value);
    });

    openCard = PlayingCard(suit: suits[rand.nextInt(suits.length)], value: rand.nextInt(13) + 1);
  }

  void drawCard(bool fromOpen) {
    if (hasDrawn || !isPlayerTurn || isGameOver) return;

    final rand = Random();
    PlayingCard newCard;
    if (fromOpen && openCard != null) {
      newCard = openCard!;
      openCard = PlayingCard(suit: suits[rand.nextInt(suits.length)], value: rand.nextInt(13) + 1);
    } else {
      newCard = PlayingCard(suit: suits[rand.nextInt(suits.length)], value: rand.nextInt(13) + 1);
    }

    setState(() {
      playerHand.add(newCard);
      hasDrawn = true;
      message = 'Card drawn! Select 1 card from hand to discard.';
    });
  }

  void discardCard(int index) {
    if (!hasDrawn || !isPlayerTurn || isGameOver) return;

    setState(() {
      openCard = playerHand.removeAt(index);
      hasDrawn = false;
      isPlayerTurn = false;
      message = 'Opponent is drawing & melding cards...';
    });

    // Opponent takes turn after 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || isGameOver) return;
      opponentTurn();
    });
  }

  void opponentTurn() {
    final rand = Random();
    setState(() {
      openCard = PlayingCard(suit: suits[rand.nextInt(suits.length)], value: rand.nextInt(13) + 1);
      isPlayerTurn = true;
      message = 'Your turn! Pick a card from Closed Deck or Open Card.';
    });
  }

  void declareShow() {
    if (isGameOver) return;

    // Check hand validity (at least 2 sequences)
    bool hasPureSeq = false;
    // Count consecutive values in same suit
    for (int i = 0; i < playerHand.length - 2; i++) {
      if (playerHand[i].suit == playerHand[i + 1].suit &&
          playerHand[i + 1].suit == playerHand[i + 2].suit &&
          playerHand[i + 1].value == playerHand[i].value + 1 &&
          playerHand[i + 2].value == playerHand[i + 1].value + 1) {
        hasPureSeq = true;
        break;
      }
    }

    if (hasPureSeq) {
      finishMatch('win', 'Valid Show! Pure sequence & melds verified! 0 points penalty.');
    } else {
      finishMatch('loss', 'Invalid Show! Hand missing mandatory Pure Sequence.');
    }
  }

  Future<void> finishMatch(String outcome, String reason) async {
    setState(() => isGameOver = true);
    final isWin = outcome == 'win';
    final payout = isWin ? (widget.entryFee * 1.9) : 0.0;

    try {
      final res = await ApiService.recordMatch(
        gameName: 'Rummy Royale',
        gameSlug: 'rummy',
        result: outcome,
        betAmount: widget.entryFee,
        payoutAmount: payout,
        scoreDetails: {'reason': reason, 'cards_count': playerHand.length},
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
            Text(isWin ? 'RUMMY SHOW WIN!' : 'SHOW FAILED', style: TextStyle(color: isWin ? gold : pink, fontWeight: FontWeight.bold)),
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
              decoration: BoxDecoration(
                color: isWin ? teal.withValues(alpha: 0.15) : pink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isWin ? 'Prize Payout:' : 'Match Fee:', style: const TextStyle(color: Colors.white70)),
                  Text(
                    isWin ? '+₹${payout.toStringAsFixed(2)}' : '-₹${widget.entryFee.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isWin ? teal : pink),
                  ),
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
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('BACK TO GAMES'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rummy Royale (13 Cards)'),
        backgroundColor: bg,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: gold.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: gold, size: 16),
                const SizedBox(width: 4),
                Text('Entry ₹${widget.entryFee.toStringAsFixed(0)}', style: const TextStyle(color: gold, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Wild Joker & Table Info
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B3B2B), // Felt table green
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('WILD JOKER: ', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                          child: Text(wildJoker, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Text(isPlayerTurn ? 'YOUR TURN' : 'OPPONENT TURN', style: TextStyle(color: isPlayerTurn ? teal : pink, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),

              // Deck Area (Closed Deck & Open Card)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Closed deck
                    GestureDetector(
                      onTap: () => drawCard(false),
                      child: Column(
                        children: [
                          Container(
                            width: 65,
                            height: 90,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3799),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white54, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
                            ),
                            child: const Center(
                              child: Icon(Icons.style, color: Colors.white, size: 30),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('DRAW CLOSED', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 36),
                    // Open card
                    if (openCard != null)
                      GestureDetector(
                        onTap: () => drawCard(true),
                        child: Column(
                          children: [
                            _buildCardWidget(openCard!),
                            const SizedBox(height: 6),
                            const Text('PICK OPEN', style: TextStyle(fontSize: 10, color: teal, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Status message
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
                child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.bold)),
              ),

              const Spacer(),

              // Player Hand Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('YOUR HAND (${playerHand.length} CARDS)', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    if (hasDrawn)
                      const Text('Tap a card to Discard', style: TextStyle(color: pink, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 13 Cards Hand Display (Horizontal Scroll)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: playerHand.length,
                  itemBuilder: (context, index) {
                    final card = playerHand[index];
                    return GestureDetector(
                      onTap: () {
                        if (hasDrawn) {
                          discardCard(index);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildCardWidget(card),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Actions (Declare Show / Drop)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: pink,
                          side: const BorderSide(color: pink),
                        ),
                        onPressed: isGameOver ? null : () => finishMatch('loss', 'You dropped the game (20 points).'),
                        child: const Text('DROP GAME'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                        ),
                        icon: const Icon(Icons.verified),
                        label: const Text('DECLARE SHOW', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: isGameOver ? null : declareShow,
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

  Widget _buildCardWidget(PlayingCard card) {
    return Container(
      width: 58,
      height: 85,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              '${card.label}${card.suit}',
              style: TextStyle(color: card.color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Text(card.suit, style: TextStyle(color: card.color, fontSize: 24)),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              card.label,
              style: TextStyle(color: card.color, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
