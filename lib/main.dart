import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}



// =====================
// ROOT APP
// =====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const WelcomeScreen(),
    );
  }
}

// =====================
// COLORS
// =====================
const Color darkPurpleBackground = Color(0xFF0F0015);
const Color midPurpleBackground = Color(0xFF3B0040);
const Color primaryPink = Color(0xFFFF4081);
const Color softWhite = Color(0xFFF8F8F8);

// =====================
// WELCOME SCREEN
// =====================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkPurpleBackground, midPurpleBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // LOGO
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          primaryPink,
                          Colors.deepPurpleAccent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPink.withOpacity(0.45),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.all_inclusive_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),

                  const SizedBox(height: 26),

                  // 🔥 BIG TITLE (MATCHES SCREENSHOT)
                  const Text(
                    'Your story begins\nnow.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34, // ⬅ BIG LIKE IMAGE
                      fontWeight: FontWeight.w700,
                      color: primaryPink,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // SUBTITLE
                  const Text(
                    'Find your destiny with a simple\nconnection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 10,
                      ),
                      child: const Text(
                        'START YOUR JOURNEY',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: softWhite,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
