import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'services/token_storage.dart';
import 'screens/wallet_screen.dart';
import 'screens/mines_game_screen.dart';
import 'screens/games_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_deposits_screen.dart';
import 'screens/admin_games_screen.dart';
import 'screens/admin_matches_screen.dart';
import 'screens/admin_withdrawals_screen.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const WinPlayApp());

const bg = Color(0xFF090B1A);
const surface = Color(0xFF171A31);
const purple = Color(0xFF9254FF);
const pink = Color(0xFFFF4FA3);
const blue = Color(0xFF398BFF);
const teal = Color(0xFF21D6B5);
const gold = Color(0xFFFFC857);
const cyan = Color(0xFF00E5FF);

class WinPlayApp extends StatelessWidget {
  const WinPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexlyn',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIconColor: purple,
          contentPadding: const EdgeInsets.all(19),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(color: purple, width: 1.5),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF24104D), bg, Color(0xFF102D48)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [purple, pink],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.4),
                      blurRadius: 35,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_esports_rounded,
                  size: 65,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'NEXLYN',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'PLAY • COMPETE • ENJOY',
                style: TextStyle(
                  color: Colors.white60,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: teal),
            ],
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [purple, pink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: purple.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  final String? initialEmail;
  const LoginScreen({super.key, this.initialEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidePassword = true;
  bool rememberMe = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    email.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final enteredEmail = email.text.trim();
    if (!enteredEmail.contains('@') || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email and password')),
      );
      return;
    }

    setState(() => isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final result = await ApiService.login(
        email: enteredEmail,
        password: password.text,
      );

      final access = result['access'] as String?;
      final refresh = result['refresh'] as String?;
      if (access == null || refresh == null) {
        throw Exception('The server did not return both login tokens.');
      }

      await TokenStorage.saveTokens(access: access, refresh: refresh);
      if (!mounted) return;

      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF211044), bg, Color(0xFF102D43)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(
                      Icons.sports_esports_rounded,
                      size: 65,
                      color: pink,
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Welcome back!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your next victory starts here.',
                    style: TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  const SizedBox(height: 35),
                  const Text('EMAIL ADDRESS'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text('PASSWORD'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: password,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        activeColor: purple,
                        onChanged: (value) {
                          setState(() => rememberMe = value ?? false);
                        },
                      ),
                      const Text('Remember me'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: pink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  GradientButton(
                    text: isLoading ? 'SIGNING IN...' : 'SIGN IN',
                    icon: Icons.login_rounded,
                    onPressed: () {
                      if (!isLoading) login();
                    },
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text("New to Nexlyn? "),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          ),
                          child: const Text(
                            'Create account',
                            style: TextStyle(
                              color: teal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings_outlined,
                          color: teal, size: 18),
                      label: const Text(
                        'Admin login',
                        style: TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'PLAY FAIR • HAVE FUN',
                      style: TextStyle(
                        color: Colors.white38,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  final otp = TextEditingController();
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();

  bool isLoading = false;
  int step = 0;
  String resetToken = '';
  String? debugOtp;
  String? whatsappUrl;
  int resendSeconds = 0;
  Timer? resendTimer;

  @override
  void dispose() {
    resendTimer?.cancel();
    email.dispose();
    otp.dispose();
    newPassword.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void startResendTimer() {
    resendTimer?.cancel();
    setState(() => resendSeconds = 60);
    resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => resendSeconds = 0);
      } else {
        if (mounted) setState(() => resendSeconds -= 1);
      }
    });
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? pink : teal,
      ),
    );
  }

  Future<void> requestOtp() async {
    final address = email.text.trim();
    if (!address.contains('@')) {
      showMessage('Enter a valid email address.', isError: true);
      return;
    }
    setState(() => isLoading = true);
    try {
      final result = await ApiService.requestPasswordReset(email: address);
      if (!mounted) return;

      if (result['account_found'] == false) {
        showMessage('No Nexlyn account found with this email. Please check the address.', isError: true);
        return;
      }

      debugOtp = result['debug_otp']?.toString();
      whatsappUrl = result['whatsapp_url']?.toString();
      showMessage(result['message']?.toString() ?? 'Verification code sent to your email!');
      setState(() => step = 1);
      startResendTimer();
    } catch (error) {
      showMessage('Could not send code: $error', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> verifyOtp() async {
    final code = otp.text.trim();
    if (code.length != 6 || int.tryParse(code) == null) {
      showMessage('Enter the six-digit OTP.', isError: true);
      return;
    }
    setState(() => isLoading = true);
    try {
      final result = await ApiService.verifyPasswordResetOtp(
        email: email.text.trim(),
        otp: code,
      );
      if (!mounted) return;
      resetToken = result['reset_token']?.toString() ?? '';
      if (resetToken.isEmpty) {
        showMessage('The server did not return a reset token.', isError: true);
        return;
      }
      setState(() => step = 2);
    } catch (error) {
      showMessage('OTP verification failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> updatePassword() async {
    if (newPassword.text.length < 8) {
      showMessage('Password must contain at least 8 characters.', isError: true);
      return;
    }
    if (newPassword.text != confirmPassword.text) {
      showMessage('Passwords do not match.', isError: true);
      return;
    }
    setState(() => isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final savedEmail = email.text.trim();

    try {
      final result = await ApiService.confirmPasswordReset(
        email: savedEmail,
        resetToken: resetToken,
        newPassword: newPassword.text,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? 'Password updated! Please sign in.'),
          backgroundColor: teal,
        ),
      );
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen(initialEmail: savedEmail)),
      );
    } catch (error) {
      showMessage('Password update failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Forgot password?', 'Verify your email', 'Create new password'];
    final descriptions = [
      'Enter your registered email address. We will send a 6-digit verification code to your inbox.',
      'Enter the 6-digit code sent to ${email.text.trim()}. Check your Inbox and Spam folder.',
      'Choose a new strong password for your Nexlyn account.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Password recovery')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 22),
              const Icon(Icons.mark_email_read_rounded, size: 66, color: teal),
              const SizedBox(height: 22),
              Text(
                titles[step],
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                descriptions[step],
                style: const TextStyle(color: Colors.white60, height: 1.5),
              ),
              const SizedBox(height: 28),
              if (step == 0) ...[
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Your registered email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  text: isLoading ? 'SENDING EMAIL...' : 'SEND OTP CODE',
                  onPressed: isLoading ? () {} : requestOtp,
                ),
              ] else if (step == 1) ...[
                if (debugOtp != null) ...[
                  InkWell(
                    onTap: () {
                      otp.text = debugOtp!;
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: teal.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app, color: teal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verification Code: $debugOtp (Tap to autofill)',
                              style: const TextStyle(color: teal, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (whatsappUrl != null) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF25D366),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat, size: 18),
                    label: const Text('Get OTP on WhatsApp (+91 7780383832)'),
                    onPressed: () async {
                      final uri = Uri.parse(whatsappUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: '000000',
                    prefixIcon: Icon(Icons.password),
                  ),
                ),
                const SizedBox(height: 12),
                GradientButton(
                  text: isLoading ? 'VERIFYING...' : 'VERIFY OTP',
                  onPressed: isLoading ? () {} : verifyOtp,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: (isLoading || resendSeconds > 0) ? null : requestOtp,
                  child: Text(
                    resendSeconds > 0 ? 'Resend code in ${resendSeconds}s' : 'Resend code',
                    style: TextStyle(color: resendSeconds > 0 ? Colors.white38 : teal),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'New password (min 8 chars)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_reset),
                  ),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  text: isLoading ? 'UPDATING...' : 'UPDATE PASSWORD',
                  onPressed: isLoading ? () {} : updatePassword,
                ),
              ],
              if (step > 0)
                TextButton(
                  onPressed: isLoading ? null : () => setState(() => step -= 1),
                  child: const Text('Go back'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF201044), bg, Color(0xFF102B43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_add_alt_1, size: 65, color: teal),
                const SizedBox(height: 20),
                const Text(
                  'Join the game!',
                  style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your Nexlyn account and get 1,000 Welcome Credits!',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 30),
                const Text('USERNAME'),
                const SizedBox(height: 9),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    hintText: 'Choose a username',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('EMAIL ADDRESS'),
                const SizedBox(height: 9),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Your email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('PASSWORD'),
                const SizedBox(height: 9),
                TextField(
                  controller: password,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => hidePassword = !hidePassword);
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                GradientButton(
                  text: isLoading ? 'CREATING ACCOUNT...' : 'CREATE ACCOUNT',
                  icon: Icons.person_add,
                  onPressed: () async {
                    final username = name.text.trim();
                    final enteredEmail = email.text.trim();

                    if (username.isEmpty ||
                        !RegExp(r'^[A-Za-z0-9_]{3,150}$').hasMatch(username) ||
                        !enteredEmail.contains('@') ||
                        password.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Use a username with at least 3 letters/numbers/underscores, a valid email and a password of at least 8 characters.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (isLoading) return;
                    setState(() => isLoading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    try {
                      await ApiService.register(
                        username: username,
                        email: enteredEmail,
                        phoneNumber: '',
                        password: password.text,
                      );

                      if (!mounted) return;
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Account created with ₹100 Welcome Bonus! Please sign in.'),
                        ),
                      );
                      navigator.pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(initialEmail: enteredEmail),
                        ),
                      );
                    } catch (error) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Signup failed: $error')),
                      );
                    } finally {
                      if (mounted) setState(() => isLoading = false);
                    }
                  },
                ),
                const SizedBox(height: 22),
                const Center(
                  child: Text(
                    'By continuing, you agree to play fairly.',
                    style: TextStyle(color: Colors.white38),
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  double walletBalance = 100.0;

  @override
  void initState() {
    super.initState();
    loadWalletBalance();
  }

  Future<void> loadWalletBalance() async {
    try {
      final res = await ApiService.getWallet();
      if (!mounted) return;
      setState(() {
        walletBalance = double.tryParse(res['balance']?.toString() ?? '100') ?? 100.0;
      });
    } catch (_) {}
  }

  void handleSignOut() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void showHomeLowBalanceDialog(String gameName, double fee) {
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
            Text('Required Entry: ₹${fee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
            Text('Your Balance: ₹${walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: pink, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Your wallet balance is 0 or less than entry fee. To play games, contact Admin on WhatsApp to deposit funds.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.black),
            icon: const Icon(Icons.chat, size: 16, color: Colors.black),
            label: const Text('ADD MONEY VIA WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              final msg = 'Hello Admin, I want to add cash to play games on BetRally/WinPlay. Please credit my wallet.';
              final url = 'https://wa.me/917780383832?text=${Uri.encodeComponent(msg)}';
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeOverview(),
      GamesScreen(onWalletChanged: loadWalletBalance),
      WalletScreen(onBalanceUpdated: loadWalletBalance),
      ProfileScreen(onSignOut: handleSignOut),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: surface,
        indicatorColor: purple.withValues(alpha: 0.25),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
          if (index == 2) loadWalletBalance();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: purple),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports, color: teal),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet, color: gold),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: pink),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeOverview() {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NEXLYN',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        actions: [
          // Live Wallet Pill in AppBar
          InkWell(
            onTap: () => setState(() => selectedIndex = 2),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [purple, teal]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '₹${walletBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7137D5), Color(0xFFCB438F), Color(0xFF2855A5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WELCOME TO NEXLYN 👋',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Play Mines & Multiply Your Coins!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Uncover gems, dodge mines and cash out real multipliers directly to your wallet.',
                  style: TextStyle(height: 1.5, color: Colors.white),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.diamond, color: Colors.black),
                  label: const Text('PLAY MINES NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    if (walletBalance < 50.0 || walletBalance <= 0) {
                      showHomeLowBalanceDialog('Mines Arcade', 50.0);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MinesGameScreen(onWalletChanged: loadWalletBalance),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Explore Games Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Games',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => setState(() => selectedIndex = 1),
                child: const Text('See all', style: TextStyle(color: teal)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Featured Game Cards
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (walletBalance < 50.0 || walletBalance <= 0) {
                      showHomeLowBalanceDialog('Mines Arcade', 50.0);
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MinesGameScreen(onWalletChanged: loadWalletBalance),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: teal, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: teal.withValues(alpha: 0.25),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.diamond, color: teal, size: 36),
                            Text('🔥 HOT', style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 14),
                        Text('Mines Arcade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text('Up to 1000x Win', style: TextStyle(color: teal, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => selectedIndex = 1),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: purple.withValues(alpha: 0.5)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sports_cricket, color: purple, size: 36),
                        SizedBox(height: 14),
                        Text('Cricket Clash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text('Tournament Live', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Wallet Shortcut Card
          InkWell(
            onTap: () => setState(() => selectedIndex = 2),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: gold, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Virtual Wallet Balance',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current: ₹${walletBalance.toStringAsFixed(2)} • Tap to Deposit or Withdraw',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white54),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidePassword = true;
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    final address = email.text.trim();
    if (address.isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter admin email and password.')),
      );
      return;
    }

    setState(() => loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final result = await ApiService.adminLogin(
        email: address,
        password: password.text,
      );
      final access = result['access'] as String?;
      final refresh = result['refresh'] as String?;
      if (access == null || refresh == null) {
        throw Exception('The server did not return login tokens.');
      }
      await TokenStorage.saveTokens(access: access, refresh: refresh);
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Admin login failed: $error')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nexlyn Admin Portal')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.admin_panel_settings, size: 70, color: teal),
              const SizedBox(height: 18),
              const Text(
                'Staff / Admin Sign In',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only accounts with staff or superuser privileges can sign in here.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Admin email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: password,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  hintText: 'Admin password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => hidePassword = !hidePassword),
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                text: loading ? 'SIGNING IN...' : 'ACCESS DASHBOARD',
                icon: Icons.shield_outlined,
                onPressed: loading ? () {} : signIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? stats;
  bool loadingStats = true;
  String? statsError;

  @override
  void initState() {
    super.initState();
    loadDashboardStats();
  }

  Future<void> loadDashboardStats() async {
    setState(() {
      loadingStats = true;
      statsError = null;
    });
    try {
      final res = await ApiService.getAdminStats();
      if (!mounted) return;
      setState(() {
        stats = res;
        loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        statsError = e.toString();
        loadingStats = false;
      });
    }
  }

  Future<void> logout(BuildContext context) async {
    await TokenStorage.clearTokens();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXLYN ADMIN'),
        actions: [
          IconButton(
            tooltip: 'Refresh Stats',
            onPressed: loadDashboardStats,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [purple, pink],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ADMIN CONTROL CENTER',
                        style: TextStyle(color: Colors.white70)),
                    SizedBox(height: 10),
                    Text('Welcome, Administrator',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text('Manage players, verify deposits and oversee games.',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _AdminFeatureTile(
                icon: Icons.people_alt_outlined,
                title: 'User Management (All Access & Wallets)',
                subtitle: 'Search players, view balances, edit status, & direct credit/debit wallet',
                badgeText: 'FULL ACCESS',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AdminUsersScreen(),
                )).then((_) => loadDashboardStats()),
              ),
              _AdminFeatureTile(
                icon: Icons.history_edu,
                title: 'Player Match Activity & Records',
                subtitle: 'Live feed of all competitive matches, wins, losses & scores in Supabase',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AdminMatchesScreen(),
                )),
              ),
              _AdminFeatureTile(
                icon: Icons.price_check,
                title: 'Deposit Requests & Approvals',
                subtitle: 'Verify WhatsApp deposits & credit player wallets directly',
                badgeText: (stats != null && (stats!['pending_deposits'] as int? ?? 0) > 0)
                    ? '${stats!['pending_deposits']} PENDING'
                    : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AdminDepositsScreen(),
                )).then((_) => loadDashboardStats()),
              ),
              _AdminFeatureTile(
                icon: Icons.account_balance_wallet,
                title: 'Withdrawal Requests (Min ₹500)',
                subtitle: 'Inspect player UPI details, approve & process payouts',
                badgeText: (stats != null && (stats!['pending_withdrawals'] as int? ?? 0) > 0)
                    ? '${stats!['pending_withdrawals']} PENDING'
                    : null,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AdminWithdrawalsScreen(),
                )).then((_) => loadDashboardStats()),
              ),
              _AdminFeatureTile(
                icon: Icons.sports_esports_outlined,
                title: 'Game Catalog & Entry Stakes',
                subtitle: 'Toggle active status & configure betting stakes for all games',
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AdminGamesScreen(),
                )).then((_) => loadDashboardStats()),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nexlyn Admin Control Center • Supabase Database Connected',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (loadingStats) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: teal),
              ),
              SizedBox(width: 14),
              Text('Fetching platform statistics...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (statsError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: gold),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Live stats offline (Local demo mode). Click refresh to reconnect.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final totalPlayers = stats?['total_players']?.toString() ?? '0';
    final pool = stats?['total_wallet_pool']?.toString() ?? '0.00';
    final houseProfit = stats?['house_profit']?.toString() ?? '0.00';
    final pendingDep = stats?['pending_deposits']?.toString() ?? '0';
    final pendingWth = stats?['pending_withdrawals']?.toString() ?? '0';
    final totalMatches = stats?['total_matches']?.toString() ?? '0';
    final matchesWon = stats?['matches_won']?.toString() ?? '0';
    final recentAct = (stats?['recent_activity'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.0,
          children: [
            _buildStatCard(
              icon: Icons.people,
              label: 'Total Players',
              value: totalPlayers,
              color: teal,
            ),
            _buildStatCard(
              icon: Icons.account_balance_wallet,
              label: 'User Balances Pool',
              value: '₹$pool',
              color: blue,
            ),
            _buildStatCard(
              icon: Icons.monetization_on,
              label: 'House Profit',
              value: '₹$houseProfit',
              color: gold,
            ),
            _buildStatCard(
              icon: Icons.price_check,
              label: 'Pending Deposits',
              value: pendingDep,
              color: pendingDep != '0' ? gold : Colors.white60,
            ),
            _buildStatCard(
              icon: Icons.outbox,
              label: 'Pending Withdrawals',
              value: pendingWth,
              color: pendingWth != '0' ? pink : Colors.white60,
            ),
            _buildStatCard(
              icon: Icons.sports_esports,
              label: 'Matches (Wins/Total)',
              value: '$matchesWon / $totalMatches',
              color: purple,
            ),
          ],
        ),
        if (recentAct.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.bolt, color: gold, size: 18),
              SizedBox(width: 6),
              Text(
                'LIVE PLAYER ACTIVITY TICKER',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: recentAct.take(4).map((act) {
                final isWin = act['result'] == 'win';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isWin ? teal : pink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${act["username"]} played ${act["game_name"]} (Bet ₹${act["bet_amount"]})',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        isWin ? '+₹${act["payout_amount"]}' : 'LOST',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isWin ? teal : pink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        act['created_at'].toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.16),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

class _AdminFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback? onTap;

  const _AdminFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: teal.withValues(alpha: 0.15),
          child: Icon(icon, color: teal),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold, width: 0.8),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final search = TextEditingController();
  List<dynamic> users = [];
  bool loading = false;
  String? error;
  int page = 1;
  int totalCount = 0;
  bool hasNext = false;
  bool hasPrev = false;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await ApiService.getAdminUsers(
        search: search.text.trim(),
        page: page,
      );
      if (!mounted) return;
      setState(() {
        totalCount = res['count'] as int? ?? 0;
        hasNext = res['next'] != null;
        hasPrev = res['previous'] != null;
        users = (res['results'] as List?) ?? [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> toggleStatus(Map<String, dynamic> user) async {
    final int id = user['id'] as int;
    final bool current = user['is_active'] == true;
    final bool desired = !current;

    final messenger = ScaffoldMessenger.of(context);

    try {
      await ApiService.setAdminUserStatus(userId: id, isActive: desired);
      if (!mounted) return;
      setState(() {
        user['is_active'] = desired;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            desired
                ? 'Player ${user['username']} activated.'
                : 'Player ${user['username']} deactivated.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Accounts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: loadUsers,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: search,
                onSubmitted: (_) {
                  page = 1;
                  loadUsers();
                },
                decoration: InputDecoration(
                  hintText: 'Search by username, email or phone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      page = 1;
                      loadUsers();
                    },
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: surface,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                OutlinedButton.icon(
                  onPressed: hasPrev && !loading ? () { page--; loadUsers(); } : null,
                  icon: const Icon(Icons.chevron_left), label: const Text('Previous'),
                ),
                Text(
                  'Page $page  ($totalCount players)',
                  style: const TextStyle(color: Colors.white70),
                ),
                OutlinedButton.icon(
                  onPressed: hasNext && !loading ? () { page++; loadUsers(); } : null,
                  icon: const Icon(Icons.chevron_right), label: const Text('Next'),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> showPlayerInspection(Map<String, dynamic> user) async {
    final username = user['username']?.toString() ?? 'Player';
    final email = user['email']?.toString() ?? '-';
    final phone = user['phone_number']?.toString() ?? 'Not provided';
    final dateJoined = user['date_joined']?.toString().split('T').first ?? '-';
    String currentBalance = user['wallet_balance']?.toString() ?? '0.00';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: teal.withValues(alpha: 0.18),
                              child: Text(
                                username.isNotEmpty ? username[0].toUpperCase() : 'P',
                                style: const TextStyle(
                                  color: teal,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 28),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            teal.withValues(alpha: 0.15),
                            blue.withValues(alpha: 0.12),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: teal.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WALLET BALANCE',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('Available Funds', style: TextStyle(fontSize: 12, color: Colors.white38)),
                            ],
                          ),
                          Text(
                            '₹$currentBalance',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoRow(Icons.phone_outlined, 'Phone', phone),
                    _infoRow(Icons.calendar_today_outlined, 'Registered', dateJoined),
                    _infoRow(
                      Icons.shield_outlined,
                      'Account Status',
                      user['is_active'] == true ? 'Active' : 'Deactivated / Banned',
                      color: user['is_active'] == true ? teal : pink,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('CREDIT WALLET', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              showAdjustmentDialog(user, 'credit');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: pink,
                              side: const BorderSide(color: pink),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.remove_circle_outline),
                            label: const Text('DEBIT WALLET', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.pop(ctx);
                              showAdjustmentDialog(user, 'debit');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showAdjustmentDialog(Map<String, dynamic> user, String action) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: action == 'credit' ? 'Admin reward / adjustment' : 'Admin penalty / adjustment');
    bool adjusting = false;
    final isCredit = action == 'credit';

    await showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(
                    isCredit ? Icons.add_circle : Icons.remove_circle,
                    color: isCredit ? teal : pink,
                  ),
                  const SizedBox(width: 10),
                  Text(isCredit ? 'Credit Player Wallet' : 'Debit Player Wallet'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player: ${user['username']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current Balance: ₹${user['wallet_balance'] ?? '0.00'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Adjustment Amount (₹)',
                        hintText: 'e.g. 100.00',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reason / Description',
                        hintText: 'e.g. Tournament reward, dispute resolution',
                        prefixIcon: Icon(Icons.edit_note),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: adjusting ? null : () => Navigator.pop(dlgCtx),
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isCredit ? teal : pink,
                    foregroundColor: isCredit ? Colors.black : Colors.white,
                  ),
                  onPressed: adjusting
                      ? null
                      : () async {
                          final double? amt = double.tryParse(amountCtrl.text.trim());
                          if (amt == null || amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid positive amount.')),
                            );
                            return;
                          }
                          setDlgState(() => adjusting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(dlgCtx);
                          try {
                            final res = await ApiService.adminAdjustWallet(
                              userId: user['id'] as int,
                              action: action,
                              amount: amt,
                              description: reasonCtrl.text.trim(),
                            );
                            if (!mounted) return;
                            setState(() {
                              user['wallet_balance'] = res['new_balance']?.toString() ??
                                  (isCredit
                                      ? (double.parse(user['wallet_balance'] ?? '0') + amt).toStringAsFixed(2)
                                      : (double.parse(user['wallet_balance'] ?? '0') - amt).toStringAsFixed(2));
                            });
                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Successfully ${isCredit ? 'credited' : 'debited'} ₹${amt.toStringAsFixed(2)} to ${user['username']}.',
                                ),
                              ),
                            );
                          } catch (e) {
                            setDlgState(() => adjusting = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Adjustment failed: $e')),
                            );
                          }
                        },
                  child: Text(adjusting ? 'PROCESSING...' : (isCredit ? 'CREDIT' : 'DEBIT')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBody() {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: pink, size: 42),
            const SizedBox(height: 12),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: loadUsers, child: const Text('Retry')),
          ]),
        ),
      );
    }
    if (users.isEmpty) return const Center(child: Text('No players found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = Map<String, dynamic>.from(users[index] as Map);
        final active = user['is_active'] == true;
        final bal = user['wallet_balance']?.toString() ?? '0.00';
        return Card(
          color: surface,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            onTap: () => showPlayerInspection(user),
            leading: CircleAvatar(
              backgroundColor: teal.withValues(alpha: .15),
              child: Text(
                (user['username'] as String? ?? 'P').isNotEmpty
                    ? (user['username'] as String)[0].toUpperCase()
                    : 'P',
                style: const TextStyle(color: teal, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user['username']?.toString() ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: teal.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '₹$bal',
                    style: const TextStyle(
                      color: teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${user['email'] ?? ''}\nTap to inspect profile & adjust wallet',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Adjust Wallet',
                  icon: const Icon(Icons.account_balance_wallet_outlined, color: teal),
                  onPressed: () => showPlayerInspection(user),
                ),
                Switch(
                  value: active,
                  activeThumbColor: teal,
                  onChanged: (_) => toggleStatus(user),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
