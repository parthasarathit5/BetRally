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

class ProviderGameLauncherScreen extends StatefulWidget {
  final ProviderGame game;
  final double userCredits;
  final VoidCallback? onSessionCompleted;

  const ProviderGameLauncherScreen({
    super.key,
    required this.game,
    required this.userCredits,
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

  @override
  void initState() {
    super.initState();
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
    if (!kIsWeb && widget.game.launchUrl != null) {
      final uri = Uri.parse(widget.game.launchUrl!);
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

  Future<void> _recordSessionEnd() async {
    // Record social engagement points (10 XP per minute of play)
    final pointsAwarded = (_secondsElapsed > 10) ? ((_secondsElapsed ~/ 60) + 1) * 10.0 : 5.0;
    try {
      await ApiService.recordMatch(
        gameName: widget.game.title,
        gameSlug: widget.game.id,
        betAmount: 0.0,
        payoutAmount: pointsAwarded,
        result: 'win',
        scoreDetails: {
          'seconds_played': _secondsElapsed,
          'provider': widget.game.provider,
        },
      );
    } catch (_) {}
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
              _buildInfoRow('Integration Mode', widget.game.isOfficiallyAuthorized ? 'Authorized Social Free-Play' : 'Commercial Agreement Pending'),
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
          _recordSessionEnd();
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
              _recordSessionEnd();
              widget.onSessionCompleted?.call();
              Navigator.pop(context);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.game.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.game.provider} • Session: ${_formatDuration(_secondsElapsed)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: purple.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text(
                  'RTP: ${widget.game.rtp}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
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
            if (gameUrl != null)
              IconButton(
                icon: const Icon(Icons.open_in_new, color: teal, size: 20),
                tooltip: 'Open in Full Window',
                onPressed: () => launchUrl(Uri.parse(gameUrl), mode: LaunchMode.externalApplication),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: (gameUrl == null)
            ? _buildCredentialsPendingView()
            : Stack(
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
                                'Loading ${widget.game.provider} Engine...',
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
            const Text(
              'Tap below to launch the authorized mobile engine in fullscreen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 30),
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

  Widget _buildCredentialsPendingView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: gold.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(Icons.vpn_key_outlined, color: gold, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                '${widget.game.provider} Integration Status',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  'Pending Commercial B2B Agreement',
                  style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nexlyn integrates genuine third-party game engines. Direct live launch for ${widget.game.title} requires an active operator agreement and signed credentials.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Provider', widget.game.provider),
                    _buildInfoRow('Engine ID', widget.game.engineIdentifier),
                    _buildInfoRow('Required Auth', widget.game.requiredCredentials),
                    _buildInfoRow('Licensing', widget.game.licensingInfo),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text('Return to Lobby', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: surfaceLight,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
