import 'package:flutter/material.dart';
import '../services/provider_games_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const surfaceLight = Color(0xFF222649);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const gold = Color(0xFFFFC857);

class AdminProvidersScreen extends StatefulWidget {
  const AdminProvidersScreen({super.key});

  @override
  State<AdminProvidersScreen> createState() => _AdminProvidersScreenState();
}

class _AdminProvidersScreenState extends State<AdminProvidersScreen> {
  bool _isLoading = true;
  final Map<String, ProviderConfig> _configs = {};

  @override
  void initState() {
    super.initState();
    _loadAllConfigs();
  }

  Future<void> _loadAllConfigs() async {
    setState(() => _isLoading = true);
    for (final p in ProviderGamesService.allProviders) {
      _configs[p] = await ProviderGamesService.getProviderConfig(p);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _openConfigDialog(String providerName) {
    final cfg = _configs[providerName] ?? ProviderConfig(
      providerName: providerName,
      status: 'Awaiting B2B Credentials',
      isConfigured: false,
    );

    final operatorCodeCtrl = TextEditingController(text: cfg.operatorCode ?? '');
    final apiKeyCtrl = TextEditingController(text: cfg.apiKey ?? '');
    final secretKeyCtrl = TextEditingController(text: cfg.secretKey ?? '');
    final endpointCtrl = TextEditingController(text: cfg.endpointUrl ?? '');
    bool isEnabled = cfg.isConfigured;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.settings_suggest, color: teal),
                  const SizedBox(width: 10),
                  Text('$providerName Config', style: const TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure official API credentials for $providerName.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: operatorCodeCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Operator / Agent ID',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: apiKeyCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'API Key / Token',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: secretKeyCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Secret Key / HMAC Salt',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: endpointCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Custom Gateway Endpoint (Optional)',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable Provider Feed', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Toggle live integration status', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      value: isEnabled,
                      activeThumbColor: teal,
                      onChanged: (val) {
                        setModalState(() => isEnabled = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: purple),
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(context);
                    final newCfg = ProviderConfig(
                      providerName: providerName,
                      status: isEnabled ? 'Active (Configured)' : 'Disabled by Admin',
                      isConfigured: isEnabled,
                      operatorCode: operatorCodeCtrl.text.trim(),
                      apiKey: apiKeyCtrl.text.trim(),
                      secretKey: secretKeyCtrl.text.trim(),
                      endpointUrl: endpointCtrl.text.trim(),
                      lastChecked: DateTime.now(),
                    );
                    await ProviderGamesService.saveProviderConfig(newCfg);
                    if (!mounted) return;
                    navigator.pop();
                    _loadAllConfigs();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('$providerName configuration updated!'),
                        backgroundColor: teal,
                      ),
                    );
                  },
                  child: const Text('Save Credentials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: const Text(
          'GAME PROVIDER MANAGEMENT',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Status',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllConfigs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [purple, pink]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.hub_outlined, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Third-Party Provider Hub',
                                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Real-time health monitoring, API credential dispatch, and catalog control.',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Provider List Grid
                      const Text(
                        'Verified Provider Network',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ProviderGamesService.allProviders.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 12),
                        itemBuilder: (ctx, index) {
                          final pName = ProviderGamesService.allProviders[index];
                          final cfg = _configs[pName];
                          final isConfigured = cfg?.isConfigured ?? false;
                          final status = cfg?.status ?? 'Pending Setup';

                          final bool isSocialAuthorized = (pName == 'Famobi' || pName == 'GameDistribution' || pName == 'Nexlyn Core Engine');

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSocialAuthorized
                                    ? teal.withValues(alpha: 0.3)
                                    : (isConfigured ? purple.withValues(alpha: 0.4) : Colors.white10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSocialAuthorized
                                        ? teal.withValues(alpha: 0.15)
                                        : (isConfigured ? purple.withValues(alpha: 0.15) : bg),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isSocialAuthorized
                                        ? Icons.verified
                                        : (isConfigured ? Icons.check_circle : Icons.vpn_key_outlined),
                                    color: isSocialAuthorized ? teal : (isConfigured ? purple : gold),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            pName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isSocialAuthorized
                                                  ? teal.withValues(alpha: 0.2)
                                                  : Colors.white10,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isSocialAuthorized ? 'Authorized Social' : 'B2B Gated',
                                              style: TextStyle(
                                                color: isSocialAuthorized ? teal : Colors.white60,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        status,
                                        style: TextStyle(
                                          color: isSocialAuthorized ? teal : (isConfigured ? Colors.white70 : gold),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.settings, size: 16, color: Colors.white),
                                  label: const Text('Configure', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: surfaceLight,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _openConfigDialog(pName),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Integration Health & Security Notice
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.security, color: teal, size: 24),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Credentials are stored securely in client encrypted storage. No secrets are exposed to unauthorized endpoints.',
                                style: TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
