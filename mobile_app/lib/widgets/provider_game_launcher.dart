import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/provider_games_service.dart';
import 'provider_embed_view.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const surfaceLight = Color(0xFF222649);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const gold = Color(0xFFFFC857);
const green = Color(0xFF25D366);

class ProviderGameLauncherScreen extends StatefulWidget {
  final ProviderGame game;
  final double userBalance;
  final double entryFee;
  final VoidCallback? onSessionCompleted;

  const ProviderGameLauncherScreen({
    super.key,
    required this.game,
    required this.userBalance,
    this.entryFee = 50.0,
    this.onSessionCompleted,
  });

  @override
  State<ProviderGameLauncherScreen> createState() => _ProviderGameLauncherScreenState();
}

class _ProviderGameLauncherScreenState extends State<ProviderGameLauncherScreen> {
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isLoading = true;
  int _reloadKey = 0;
  double _currentBalance = 0.0;
  bool _isClaimingWin = false;
  bool _hasCollectedWin = false;

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.userBalance;
    _startSessionTimer();
    _autoOpenOnMobile();
  }

  void _startSessionTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  Future<void> _autoOpenOnMobile() async {
    if (!kIsWeb && widget.game.launchUrl != 'local:chess') {
      final uri = Uri.parse(widget.game.launchUrl);
      try {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } catch (_) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Calculate dynamic multiplier based on play session
  double _calculateMultiplier() {
    if (_secondsElapsed < 15) return 1.5;
    if (_secondsElapsed < 45) return 1.9;
    if (_secondsElapsed < 90) return 2.2;
    return 2.5;
  }

  Future<void> _collectWinnings() async {
    if (_isClaimingWin || _hasCollectedWin) return;

    final multiplier = _calculateMultiplier();
    final winAmount = (widget.entryFee * multiplier).roundToDouble();

    setState(() => _isClaimingWin = true);

    try {
      final res = await ApiService.recordMatch(
        gameName: widget.game.title,
        gameSlug: widget.game.id,
        result: 'win',
        betAmount: widget.entryFee,
        payoutAmount: winAmount,
        scoreDetails: {
          'seconds_played': _secondsElapsed,
          'provider': widget.game.provider,
          'multiplier': '${multiplier}x',
        },
      );

      final newBal = double.tryParse(res['wallet_balance']?.toString() ?? '') ??
          (_currentBalance + (winAmount - widget.entryFee));

      if (!mounted) return;
      setState(() {
        _currentBalance = newBal;
        _isClaimingWin = false;
        _hasCollectedWin = true;
      });

      widget.onSessionCompleted?.call();

      _showVictoryDialog(winAmount, multiplier, newBal);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isClaimingWin = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error claiming win: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showVictoryDialog(double winAmount, double multiplier, double newBalance) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Column(
            children: [
              Icon(Icons.emoji_events, color: gold, size: 55),
              SizedBox(height: 10),
              Text(
                'VICTORY CLAIMED! 🎉',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You Won ₹${winAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: green,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${multiplier}x Multiplier • ${widget.game.title}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Updated Wallet:', style: TextStyle(color: Colors.white60, fontSize: 13)),
                    Text(
                      '₹${newBalance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '✅ Amount automatically credited to your wallet in database.',
                style: TextStyle(color: teal, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Return to lobby
                },
                child: const Text(
                  'COLLECT & RETURN TO LOBBY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProviderInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified, color: teal, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.game.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Provider: ${widget.game.provider}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow('Engine ID', widget.game.engineIdentifier),
              _buildInfoRow('Category', widget.game.category.toUpperCase()),
              _buildInfoRow('Theoretical RTP', widget.game.rtp),
              _buildInfoRow('Licensing', widget.game.licensingInfo),
              _buildInfoRow('Status', 'Live Online Playable Engine'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Game', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameUrl = widget.game.launchUrl;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onSessionCompleted?.call();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () {
              widget.onSessionCompleted?.call();
              Navigator.pop(context);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.game.title,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.game.provider} • ${_formatDuration(_secondsElapsed)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Prominent Win Claim / Cash Out Button
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasCollectedWin ? Colors.grey.shade800 : green,
                  foregroundColor: _hasCollectedWin ? Colors.white54 : Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: _isClaimingWin
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Icon(
                        _hasCollectedWin ? Icons.check_circle : Icons.emoji_events,
                        size: 16,
                        color: _hasCollectedWin ? Colors.white54 : Colors.black,
                      ),
                label: Text(
                  _hasCollectedWin ? 'WIN COLLECTED' : 'COLLECT WIN (₹${(widget.entryFee * _calculateMultiplier()).toInt()})',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                onPressed: (_isClaimingWin || _hasCollectedWin) ? null : _collectWinnings,
              ),
            ),

            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
              tooltip: 'Reload Engine',
              onPressed: () {
                setState(() {
                  _reloadKey++;
                  _isLoading = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white70, size: 20),
              tooltip: 'Provider Information',
              onPressed: () => _showProviderInfo(context),
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new, color: teal, size: 20),
              tooltip: 'Open in Full Window',
              onPressed: () => launchUrl(Uri.parse(gameUrl), mode: LaunchMode.externalApplication),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: kIsWeb
                  ? buildProviderEmbedView(
                      key: ValueKey('embed_view_$_reloadKey'),
                      url: gameUrl,
                      viewId: '${widget.game.id}_$_reloadKey',
                      onLoaded: () {
                        if (mounted) setState(() => _isLoading = false);
                      },
                    )
                  : _buildMobileNativeView(gameUrl),
            ),
            if (_isLoading && kIsWeb)
              Positioned.fill(
                child: Container(
                  color: bg,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: teal),
                        const SizedBox(height: 18),
                        Text(
                          'Launching ${widget.game.provider} Engine...',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Certified Game: ${widget.game.title}',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNativeView(String gameUrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [purple, pink]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.sports_esports, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            Text(
              widget.game.title,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by ${widget.game.provider}',
              style: const TextStyle(color: teal, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Play Game Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => launchUrl(Uri.parse(gameUrl), mode: LaunchMode.inAppWebView),
            ),
          ],
        ),
      ),
    );
  }
}
