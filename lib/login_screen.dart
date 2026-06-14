import 'package:flutter/material.dart';
import 'matching_feed.dart';
import 'dart:math';
import 'dart:async';
import 'signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- COLOR PALETTE ---
const Color darkPurpleBackground = Color(0xFF0F0015);
const Color midPurpleBackground = Color(0xFF3B0040);
const Color primaryPink = Color(0xFFFF4081);

const List<String> _quotes = [
  "Swipe Less. Connect More.",
  "Destiny is just a click away.",
  "Ready for your first meet-cute?",
  "Love is the answer, always.",
  "A chance meeting could change everything.",
  "Your next great adventure awaits.",
  "Meet who you're meant to be with.",
  "The spark is real. Find it now.",
  "Your person is waiting. Let's find them.",
  "Don't settle for less than magical.",
  "Connection starts here.",
  "A beautiful match is inevitable.",
];

// --- 1. HELP PAGE (NEW FULL PAGE) ---
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurpleBackground,
      appBar: AppBar(title: const Text('Help Center'), backgroundColor: midPurpleBackground),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How Meet-Cute Works', style: TextStyle(color: primaryPink, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _helpStep('1. Account Setup', 'Sign up using your email. Make sure to verify your email to access the feed.'),
              _helpStep('2. Discover People', 'Browse through profiles in your area. Use the matching feed to find people with similar interests.'),
              _helpStep('3. Real-time Chat', 'Found someone interesting? Start a conversation immediately with our secure chat system.'),
              _helpStep('4. Safety First', 'You can block or report users who do not follow community guidelines.'),
              const SizedBox(height: 30),
              const Center(child: Text('Need more help? Contact support@meetcute.com', style: TextStyle(color: Colors.white70))),
            ],
          ),
        ),
      ),
    );
  }
  Widget _helpStep(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ]),
    );
  }
}

// --- 2. ABOUT PAGE (NEW FULL PAGE) ---
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkPurpleBackground,
      appBar: AppBar(title: const Text('About Meet-Cute'), backgroundColor: midPurpleBackground),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Terms & Privacy Policy', style: TextStyle(color: primaryPink, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text(
                'Welcome to Meet-Cute. Your privacy and safety are our top priorities. By using this app, you agree to the following:\n\n'
                '• User Conduct: You must be respectful to all users. Harassment or hate speech will lead to immediate account termination.\n\n'
                '• Data Usage: We use your data (name, photo, location) only to provide the matching service. We never sell your data to third parties.\n\n'
                '• Age Requirement: You must be 18 years or older to use this application.\n\n'
                '• Content Ownership: You own the content you post, but you grant us a license to show it to other users for matching purposes.',
                style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
              ),
              SizedBox(height: 40),
              Center(child: Text('Version 1.0.0 (Build 2025)', style: TextStyle(color: Colors.white38))),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late String _currentQuote;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _currentQuote = _quotes[_random.nextInt(_quotes.length)];
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentQuote = _quotes[_random.nextInt(_quotes.length)];
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkPurpleBackground, midPurpleBackground],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: midPurpleBackground,
              onSelected: (value) {
                if (value == 'help') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
                } else if (value == 'about') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'help', child: Text('Help', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'about', child: Text('About', style: TextStyle(color: Colors.white))),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 150,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Column(
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [primaryPink.withOpacity(0.8), Colors.deepPurpleAccent]),
                          boxShadow: [BoxShadow(color: primaryPink.withOpacity(0.4), blurRadius: 15)],
                        ),
                        child: const Icon(Icons.all_inclusive_rounded, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Meet-Cute', style: TextStyle(fontSize: 36, color: primaryPink, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.favorite_sharp, color: Colors.pinkAccent, size: 28),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(flex: 3),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _currentQuote,
                      key: ValueKey(_currentQuote),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 22, letterSpacing: 1.2),
                    ),
                  ),
                  const Spacer(flex: 5),
                  _LoginFieldsSection(
                    onNavigateToSignup: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                    },
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginFieldsSection extends StatefulWidget {
  final VoidCallback onNavigateToSignup;
  const _LoginFieldsSection({required this.onNavigateToSignup});
  @override
  State<_LoginFieldsSection> createState() => _LoginFieldsSectionState();
}

class _LoginFieldsSectionState extends State<_LoginFieldsSection> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  bool _isLoading = false;

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(labelText == 'Email' ? Icons.email_outlined : Icons.lock_outline, color: primaryPink, size: 20),
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF330044),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: primaryPink, width: 2)),
    );
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
      );
      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MatchingFeedScreen()));
        }
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          _showError('Please verify your email. Check your inbox.');
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailCtrl,
            decoration: _inputDecoration('Email'),
            style: const TextStyle(color: Colors.white),
            validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: passwordCtrl,
            obscureText: true,
            decoration: _inputDecoration('Password'),
            style: const TextStyle(color: Colors.white),
            validator: (v) => (v == null || v.length < 6) ? 'Password too short' : null,
          ),
          const SizedBox(height: 25),
          _isLoading 
            ? const CircularProgressIndicator(color: primaryPink)
            : ElevatedButton(
                onPressed: _loginUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  backgroundColor: primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Login', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: widget.onNavigateToSignup,
            child: Text("Don't have an account? Sign Up", style: TextStyle(color: primaryPink.withOpacity(0.8), fontSize: 16)),
          ),
        ],
      ),
    );
  }
}




