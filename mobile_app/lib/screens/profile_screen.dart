import 'package:flutter/material.dart';
import '../services/token_storage.dart';
import '../services/api_service.dart';

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const teal = Color(0xFF21D6B5);
const blue = Color(0xFF398BFF);
const gold = Color(0xFFFFC857);

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSignOut;
  const ProfileScreen({super.key, required this.onSignOut});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String username = 'WinPlayer';
  String email = 'user@example.com';
  double balance = 100.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final wallet = await ApiService.getWallet();
      if (!mounted) return;
      setState(() {
        username = wallet['username']?.toString() ?? 'Player';
        email = wallet['user_email']?.toString() ?? 'player@winplay.com';
        balance = double.tryParse(wallet['balance']?.toString() ?? '100') ?? 100.0;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MY PROFILE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Avatar Card
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [purple, pink, teal]),
                  ),
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: surface,
                    child: Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'W',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: teal),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: teal.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'PRO PLAYER',
                    style: TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Stats Overview
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: teal, size: 28),
                      const SizedBox(height: 8),
                      const Text('WALLET', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      Text(
                        '₹${balance.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.military_tech, color: gold, size: 28),
                      SizedBox(height: 8),
                      Text('LEVEL', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      SizedBox(height: 4),
                      Text(
                        'Gold Tier',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Account Settings List
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security, color: purple),
                  title: const Text('Account Security'),
                  subtitle: const Text('Password reset & verification OTP', style: TextStyle(color: Colors.white38)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Use the "Forgot password" flow on login for OTP reset.')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 60, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: blue),
                  title: const Text('Notifications'),
                  subtitle: const Text('Game invites & tournament alerts', style: TextStyle(color: Colors.white38)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 60, color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.help_outline, color: teal),
                  title: const Text('Support & Rules'),
                  subtitle: const Text('Fair play guidelines & customer help', style: TextStyle(color: Colors.white38)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: pink,
                side: const BorderSide(color: pink, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('LOGOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              onPressed: () async {
                await TokenStorage.clearTokens();
                widget.onSignOut();
              },
            ),
          ),
        ],
      ),
    );
  }
}
