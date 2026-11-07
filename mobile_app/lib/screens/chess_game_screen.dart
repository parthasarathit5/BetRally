import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/game_result_dialog.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const teal = Color(0xFF21D6B5);
const pink = Color(0xFFFF4FA3);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

class ChessGameScreen extends StatefulWidget {
  final double userBalance;
  final double entryFee;
  final VoidCallback? onGameFinished;

  const ChessGameScreen({
    super.key,
    required this.userBalance,
    this.entryFee = 20.0,
    this.onGameFinished,
  });

  @override
  State<ChessGameScreen> createState() => _ChessGameScreenState();
}

class _ChessGameScreenState extends State<ChessGameScreen> {
  // 8x8 Board. Positive = White (Player), Negative = Black (Opponent AI), 0 = Empty
  // 1: Pawn, 2: Knight, 3: Bishop, 4: Rook, 5: Queen, 6: King
  late List<List<int>> board;
  int? selectedRow;
  int? selectedCol;
  List<Point<int>> validMoves = [];

  bool isPlayerTurn = true;
  bool isGameOver = false;
  String gameStatus = 'Your Turn (White)';
  String? result; // 'win', 'loss', 'draw'

  int playerTimeSeconds = 180; // 3 min blitz
  int opponentTimeSeconds = 180;
  Timer? gameTimer;
  bool isSubmittingResult = false;
  String? matchRef;
  String? whatsappUrl;

  final Map<int, String> pieceSymbols = {
    1: '♙', 2: '♘', 3: '♗', 4: '♖', 5: '♕', 6: '♔',
    -1: '♟', -2: '♞', -3: '♝', -4: '♜', -5: '♛', -6: '♚',
  };

  @override
  void initState() {
    super.initState();
    initializeBoard();
    startTimer();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void initializeBoard() {
    board = [
      [-4, -2, -3, -5, -6, -3, -2, -4],
      [-1, -1, -1, -1, -1, -1, -1, -1],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [4, 2, 3, 5, 6, 3, 2, 4],
    ];
  }

  void startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isGameOver) {
        timer.cancel();
        return;
      }
      setState(() {
        if (isPlayerTurn) {
          if (playerTimeSeconds > 0) {
            playerTimeSeconds--;
          } else {
            endGame('loss', 'Time out! Opponent won on time.');
          }
        } else {
          if (opponentTimeSeconds > 0) {
            opponentTimeSeconds--;
          } else {
            endGame('win', 'Opponent flagged! You won on time.');
          }
        }
      });
    });
  }

  void onSquareTapped(int row, int col) {
    if (!isPlayerTurn || isGameOver) return;

    final piece = board[row][col];

    // If tapping one's own piece, select it and show legal moves
    if (piece > 0) {
      setState(() {
        selectedRow = row;
        selectedCol = col;
        validMoves = calculateLegalMoves(row, col, piece);
      });
      return;
    }

    // If a piece is already selected, check if target square is in legal moves
    if (selectedRow != null && selectedCol != null) {
      final isTargetValid = validMoves.any((m) => m.x == row && m.y == col);
      if (isTargetValid) {
        makePlayerMove(selectedRow!, selectedCol!, row, col);
      } else {
        setState(() {
          selectedRow = null;
          selectedCol = null;
          validMoves = [];
        });
      }
    }
  }

  void makePlayerMove(int fromR, int fromC, int toR, int toC) {
    final capturedPiece = board[toR][toC];
    setState(() {
      board[toR][toC] = board[fromR][fromC];
      board[fromR][fromC] = 0;
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      isPlayerTurn = false;
      gameStatus = 'Opponent Thinking...';
    });

    // Check if opponent King captured
    if (capturedPiece == -6) {
      endGame('win', 'Checkmate! You captured the Black King!');
      return;
    }

    // Opponent AI responds after short delay
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || isGameOver) return;
      makeOpponentMove();
    });
  }

  void makeOpponentMove() {
    // Find all valid black moves
    List<Map<String, dynamic>> allMoves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c] < 0) {
          final moves = calculateLegalMoves(r, c, board[r][c]);
          for (final m in moves) {
            final targetPiece = board[m.x][m.y];
            int priority = 0;
            if (targetPiece == 6) {
              priority = 1000;
            } else if (targetPiece == 5) {
              priority = 90;
            } else if (targetPiece == 4) {
              priority = 50;
            } else if (targetPiece == 3 || targetPiece == 2) {
              priority = 30;
            } else if (targetPiece == 1) {
              priority = 10;
            }
            allMoves.add({
              'fromR': r,
              'fromC': c,
              'toR': m.x,
              'toC': m.y,
              'priority': priority + Random().nextInt(5),
            });
          }
        }
      }
    }

    if (allMoves.isEmpty) {
      endGame('win', 'Stalemate / No moves! Victory awarded.');
      return;
    }

    allMoves.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
    final chosen = allMoves.first;

    final targetPiece = board[chosen['toR']][chosen['toC']];

    setState(() {
      board[chosen['toR']][chosen['toC']] = board[chosen['fromR']][chosen['fromC']];
      board[chosen['fromR']][chosen['fromC']] = 0;
      isPlayerTurn = true;
      gameStatus = 'Your Turn (White)';
    });

    if (targetPiece == 6) {
      endGame('loss', 'Checkmate! Your King was captured.');
    }
  }

  List<Point<int>> calculateLegalMoves(int r, int c, int piece) {
    List<Point<int>> moves = [];
    final isWhite = piece > 0;
    final type = piece.abs();

    switch (type) {
      case 1: // Pawn
        final dir = isWhite ? -1 : 1;
        // Forward 1
        if (isInBounds(r + dir, c) && board[r + dir][c] == 0) {
          moves.add(Point(r + dir, c));
          // Forward 2 from start
          final startRow = isWhite ? 6 : 1;
          if (r == startRow && board[r + 2 * dir][c] == 0) {
            moves.add(Point(r + 2 * dir, c));
          }
        }
        // Diagonal captures
        for (int dc in [-1, 1]) {
          final nr = r + dir;
          final nc = c + dc;
          if (isInBounds(nr, nc)) {
            final target = board[nr][nc];
            if (isWhite ? target < 0 : target > 0) {
              moves.add(Point(nr, nc));
            }
          }
        }
        break;

      case 2: // Knight
        final jumps = [
          [-2, -1], [-2, 1], [-1, -2], [-1, 2],
          [1, -2], [1, 2], [2, -1], [2, 1],
        ];
        for (final j in jumps) {
          final nr = r + j[0];
          final nc = c + j[1];
          if (isInBounds(nr, nc)) {
            final t = board[nr][nc];
            if (isWhite ? t <= 0 : t >= 0) moves.add(Point(nr, nc));
          }
        }
        break;

      case 3: // Bishop
        _addRayMoves(moves, r, c, isWhite, [[-1, -1], [-1, 1], [1, -1], [1, 1]]);
        break;

      case 4: // Rook
        _addRayMoves(moves, r, c, isWhite, [[-1, 0], [1, 0], [0, -1], [0, 1]]);
        break;

      case 5: // Queen
        _addRayMoves(moves, r, c, isWhite, [
          [-1, -1], [-1, 1], [1, -1], [1, 1],
          [-1, 0], [1, 0], [0, -1], [0, 1],
        ]);
        break;

      case 6: // King
        final deltas = [
          [-1, -1], [-1, 0], [-1, 1],
          [0, -1],           [0, 1],
          [1, -1],  [1, 0],  [1, 1],
        ];
        for (final d in deltas) {
          final nr = r + d[0];
          final nc = c + d[1];
          if (isInBounds(nr, nc)) {
            final t = board[nr][nc];
            if (isWhite ? t <= 0 : t >= 0) moves.add(Point(nr, nc));
          }
        }
        break;
    }
    return moves;
  }

  void _addRayMoves(List<Point<int>> moves, int r, int c, bool isWhite, List<List<int>> dirs) {
    for (final d in dirs) {
      int nr = r + d[0];
      int nc = c + d[1];
      while (isInBounds(nr, nc)) {
        final t = board[nr][nc];
        if (t == 0) {
          moves.add(Point(nr, nc));
        } else {
          if (isWhite ? t < 0 : t > 0) moves.add(Point(nr, nc));
          break;
        }
        nr += d[0];
        nc += d[1];
      }
    }
  }

  bool isInBounds(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  Future<void> endGame(String outcome, String reason) async {
    gameTimer?.cancel();
    setState(() {
      isGameOver = true;
      result = outcome;
      gameStatus = reason;
    });

    final isWin = outcome == 'win';
    final payout = GameResultDialog.calculatePayout(widget.entryFee);

    GameResultDialog.show(
      context: context,
      gameName: 'Blitz Chess Pro',
      gameSlug: 'chess',
      won: isWin,
      betAmount: widget.entryFee,
      payoutAmount: payout,
      reason: reason,
      scoreDetails: {
        'reason': reason,
        'player_time_left': playerTimeSeconds,
        'opponent_time_left': opponentTimeSeconds,
      },
      onFinished: widget.onGameFinished,
    );
  }

  String formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blitz Chess (1v1)'),
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
              // Opponent Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: pink,
                      radius: 16,
                      child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Grandmaster AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Black Pieces', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(formatTime(opponentTimeSeconds), style: const TextStyle(fontWeight: FontWeight.bold, color: pink)),
                    ),
                  ],
                ),
              ),

              // Game Status Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isPlayerTurn ? teal.withValues(alpha: 0.15) : purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    gameStatus,
                    style: TextStyle(
                      color: isPlayerTurn ? teal : purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // 8x8 Chess Board
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: purple, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                          itemCount: 64,
                          itemBuilder: (context, index) {
                            final r = index ~/ 8;
                            final c = index % 8;
                            final piece = board[r][c];
                            final isDarkSquare = (r + c) % 2 == 1;
                            final isSelected = selectedRow == r && selectedCol == c;
                            final isMoveTarget = validMoves.any((m) => m.x == r && m.y == c);

                            Color sqColor = isDarkSquare ? const Color(0xFF262D4A) : const Color(0xFF38436B);
                            if (isSelected) sqColor = purple.withValues(alpha: 0.7);
                            if (isMoveTarget) sqColor = teal.withValues(alpha: 0.5);

                            return GestureDetector(
                              onTap: () => onSquareTapped(r, c),
                              child: Container(
                                color: sqColor,
                                child: Stack(
                                  children: [
                                    if (isMoveTarget && piece == 0)
                                      Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: teal,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    if (piece != 0)
                                      Center(
                                        child: Text(
                                          pieceSymbols[piece] ?? '',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: piece > 0 ? Colors.white : const Color(0xFFFF85A1),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Player Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: teal,
                      radius: 16,
                      child: Icon(Icons.person, size: 18, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You (Player)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('White Pieces', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(formatTime(playerTimeSeconds), style: const TextStyle(fontWeight: FontWeight.bold, color: teal)),
                    ),
                  ],
                ),
              ),

              // Action buttons (Resign / Draw offer)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: pink,
                          side: const BorderSide(color: pink),
                        ),
                        onPressed: isGameOver ? null : () => endGame('loss', 'You resigned the game.'),
                        child: const Text('RESIGN'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: isGameOver ? null : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opponent declined draw offer. Keep playing!')),
                          );
                        },
                        child: const Text('OFFER DRAW', style: TextStyle(fontWeight: FontWeight.bold)),
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
}
