import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'matching_feed.dart';

class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  Future<void> _checkVerification(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
      
    await user.reload(); //  MUST
    final refreshedUser = FirebaseAuth.instance.currentUser;

    if (refreshedUser != null && refreshedUser.emailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MatchingFeedScreen(),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email first'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read,
                  color: Colors.pinkAccent, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Verify your email',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              const SizedBox(height: 10),
              const Text(
                'We have sent a verification link to your email.\nPlease verify and continue.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _checkVerification(context),
                child: const Text('I HAVE VERIFIED'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
