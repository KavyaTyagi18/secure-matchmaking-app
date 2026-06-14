
/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_verification_screen.dart';

// --- PASSWORD VALIDATION LOGIC ---
bool isStrongPassword(String password) {
  final regex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_#]).{8,}$',
  );
  return regex.hasMatch(password);
}

// --- COLOR PALETTE ---
const Color darkPurpleBackground = Color(0xFF0F0015);
const Color midPurpleBackground = Color(0xFF3B0040);
const Color primaryPink = Color(0xFFFF4081);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // --- DATA VARIABLES ---
  String? selectedGender;
  DateTime selectedDOB = DateTime(2000, 1, 1);
  double selectedHeight = 175;
  String? selectedLocation;
  Set<String> selectedInterests = {};
  Set<String> selectedVibes = {};
  String? selectedIntent;
  String? selectedSmoking;
  String? selectedDrinking;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // Note: otpController is removed as it's no longer needed

  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    // Corrected step limit to 14 since OTP step is removed
    if (_currentPage < 14) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400), 
        curve: Curves.easeOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- UPDATED SIGNUP STEPS (OTP REMOVED) ---
    final List<Widget> signUpSteps = [
      const SignUpStepCard(title: 'Welcome to Meet-Cute.', subtitle: 'Let\'s start with what we should call you.', isInputStep: true, inputLabel: 'Your Name'),
      SignUpStepCard(title: 'When is your birthday?', subtitle: 'You must be 18+ to join.', isDOBStep: true, onDOBSelected: (val) => selectedDOB = val),
      SignUpStepCard(title: 'How do you identify?', subtitle: 'We use this to find you the best matches.', isGenderStep: true, onGenderSelected: (val) => selectedGender = val),
      const SignUpStepCard(title: 'What is your Email?', subtitle: 'Required for notifications.', isEmailInputStep: true),
      const SignUpStepCard(title: 'Create a Secure Password.', subtitle: 'Use a strong password.', isPasswordStep: true),
      const SignUpStepCard(title: 'What is your Phone Number?', subtitle: 'Enter for profile information.', isPhoneInputStep: true),
      // Step 6 (OTP) is completely removed from this list
      SignUpStepCard(title: 'Where Are You Located?', subtitle: 'Matches nearby.', isLocationStep: true, onLocationChanged: (val) => selectedLocation = val),
      SignUpStepCard(title: 'Tell us about your height.', subtitle: 'Key filter for many people.', isHeightStep: true, onHeightSelected: (val) => selectedHeight = val),
      const SignUpStepCard(title: 'Your Best Angle.', subtitle: 'Add a high-quality photo.', isImageStep: true),
      SignUpStepCard(title: 'Obsessions & Interests.', subtitle: 'Pick at least three.', isSelectionStep: true, options: const ['Photography', 'Coding', 'Hiking', 'Cooking', 'Gaming', 'Reading', 'Art', 'Music', 'Travel', 'Movies'], onInterestsChanged: (val) => selectedInterests = val),
      SignUpStepCard(title: 'What\'s Your Vibe?', subtitle: 'Describe yourself best.', isSelectionStep: true, options: const ['Spontaneous', 'Intellectual', 'Creative', 'Chill', 'Intense', 'Wanderlust', 'Funny', 'Serious'], onVibesChanged: (val) => selectedVibes = val),
      const SignUpStepCard(title: 'Your Professional Life.', subtitle: 'Career/Education info.', isCareerStep: true),
      SignUpStepCard(title: 'Your Lifestyle.', subtitle: 'Smoking and drinking status.', isLifestyleStep: true, onSmokingSelected: (val) => selectedSmoking = val, onDrinkingSelected: (val) => selectedDrinking = val),
      SignUpStepCard(title: 'What Are You Looking For?', subtitle: 'Dating intentions.', isIntentStep: true, options: const ['Long-term relationship', 'Short-term fun', 'New friends', 'Figuring it out'], onIntentSelected: (val) => selectedIntent = val),
      const SignUpStepCard(title: 'You\'re All Set!', subtitle: 'Ready to find your Meet-Cute?', isFinalStep: true),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkPurpleBackground, midPurpleBackground])),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(value: (_currentPage + 1) / signUpSteps.length, backgroundColor: Colors.white10, color: Colors.pinkAccent),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Controls navigation via button only
                  itemCount: signUpSteps.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) => Column(
                    children: [
                      Expanded(child: signUpSteps[i]),
                      Padding(padding: const EdgeInsets.all(20), child: _buildNavBtn(i, signUpSteps.length)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBtn(int index, int total) {
    bool isLast = index == total - 1;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60), 
        backgroundColor: isLast ? Colors.pinkAccent : Colors.deepPurpleAccent, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
      ),
      onPressed: () async {
        // Validation Checks
        if (index == 3 && (emailController.text.isEmpty || !emailController.text.contains('@'))) return;
        if (index == 4 && !isStrongPassword(passwordController.text)) return;
        
        // At Phone Number step (index 5), just proceed to the next page
        if (index == 5) {
          _nextPage();
          return;
        }

        if (isLast) {
          try {
            // Create Firebase Auth User
            final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: emailController.text.trim(), 
              password: passwordController.text.trim()
            );

            // Save all data to Firestore including Phone Number
            await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
              'uid': cred.user!.uid,
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'phoneNumber': phoneController.text.trim(),
              'gender': selectedGender,
              'birthDate': selectedDOB.toIso8601String(),
              'height': selectedHeight.round(),
              'location': selectedLocation,
              'interests': selectedInterests.toList(),
              'vibe': selectedVibes.toList(),
              'lookingFor': selectedIntent,
              'smoking': selectedSmoking,
              'drinking': selectedDrinking,
              'profileCompleted': true,
              'createdAt': FieldValue.serverTimestamp(),
            });

            // Send Verification Email
            await cred.user!.sendEmailVerification();
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmailVerificationScreen()));
            }
          } catch (e) { 
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); 
          }
        } else { 
          _nextPage(); 
        }
      },
      child: Text(isLast ? 'START MATCHING' : 'CONTINUE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

// --- SIGN UP STEP CARD COMPONENT ---
class SignUpStepCard extends StatefulWidget {
  final String title, subtitle;
  final bool isInputStep, isSelectionStep, isImageStep, isFinalStep, isLocationStep, isDOBStep, isGenderStep, isEmailInputStep, isPhoneInputStep, isPasswordStep, isHeightStep, isCareerStep, isLifestyleStep, isIntentStep;
  final List<String> options;
  final String? inputLabel;
  final ValueChanged<String?>? onGenderSelected, onLocationChanged, onIntentSelected, onSmokingSelected, onDrinkingSelected;
  final ValueChanged<DateTime>? onDOBSelected;
  final ValueChanged<double>? onHeightSelected;
  final ValueChanged<Set<String>>? onInterestsChanged, onVibesChanged;

  const SignUpStepCard({
    super.key, required this.title, required this.subtitle, 
    this.isInputStep = false, this.isSelectionStep = false, this.isImageStep = false, 
    this.isFinalStep = false, this.isLocationStep = false, this.isDOBStep = false, 
    this.isGenderStep = false, this.isEmailInputStep = false, this.isPhoneInputStep = false, 
    this.isPasswordStep = false, this.isHeightStep = false, this.isCareerStep = false, 
    this.isLifestyleStep = false, this.isIntentStep = false, this.options = const [], 
    this.inputLabel, this.onGenderSelected, this.onDOBSelected, this.onHeightSelected, 
    this.onLocationChanged, this.onInterestsChanged, this.onVibesChanged, 
    this.onIntentSelected, this.onSmokingSelected, this.onDrinkingSelected,
  });

  @override
  State<SignUpStepCard> createState() => _SignUpStepCardState();
}

class _SignUpStepCardState extends State<SignUpStepCard> {
  final Set<String> _selectedOptions = {};
  String? _gender, _smoke, _drink, _intent, _passwordError;
  DateTime _date = DateTime(2000, 1, 1);
  double _height = 175;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        color: const Color(0xFF1F0025).withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 28, color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(widget.subtitle, style: const TextStyle(fontSize: 16, color: Colors.white60)),
              const SizedBox(height: 30),
              if (widget.isInputStep) _buildField('Name'),
              if (widget.isEmailInputStep) _buildField('Email Address'),
              if (widget.isPhoneInputStep) _buildField('Phone Number'),
              if (widget.isPasswordStep) _buildPass(),
              if (widget.isDOBStep) _buildDOB(),
              if (widget.isGenderStep) _buildGender(),
              if (widget.isHeightStep) _buildHeight(),
              if (widget.isSelectionStep) _buildChips(),
              if (widget.isCareerStep) const Column(children: [TextField(decoration: InputDecoration(labelText: 'Job Title')), TextField(decoration: InputDecoration(labelText: 'Education'))]),
              if (widget.isLifestyleStep) _buildLife(),
              if (widget.isIntentStep) _buildIntent(),
              if (widget.isLocationStep) _buildLoc(),
              if (widget.isImageStep) const Center(child: Icon(Icons.camera_alt, size: 80, color: Colors.white24)),
              if (widget.isFinalStep) const Center(child: Icon(Icons.favorite, size: 80, color: Colors.pinkAccent)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label) {
    final parent = context.findAncestorStateOfType<_SignupScreenState>();
    var ctrl = (label == 'Email Address') ? parent?.emailController : (label == 'Phone Number' ? parent?.phoneController : parent?.nameController);
    return TextField(controller: ctrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70)));
  }

  Widget _buildPass() {
    final parent = context.findAncestorStateOfType<_SignupScreenState>();
    final ctrl = parent?.passwordController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              if (value.isEmpty) {
                _passwordError = null;
              } else if (!isStrongPassword(value)) {
                _passwordError = "8+ chars, Upper, Lower, Number & Symbol required.";
              } else {
                _passwordError = null;
              }
            });
          },
          decoration: const InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: Colors.white70),
            prefixIcon: Icon(Icons.lock_outline, color: Colors.pinkAccent),
          ),
        ),
        if (_passwordError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(_passwordError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildDOB() {
    return ActionChip(label: Text("${_date.day}/${_date.month}/${_date.year}"), onPressed: () async {
      DateTime? p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1950), lastDate: DateTime.now());
      if (p != null) { setState(() => _date = p); widget.onDOBSelected?.call(p); }
    });
  }

  Widget _buildGender() {
    return Wrap(spacing: 10, children: ['Male', 'Female', 'Non-binary', 'Prefer not to say'].map((g) => ChoiceChip(selected: _gender == g, label: Text(g), onSelected: (s) { setState(() => _gender = s ? g : null); widget.onGenderSelected?.call(_gender); })).toList());
  }

  Widget _buildHeight() {
    return Column(children: [Text("${_height.round()} cm", style: const TextStyle(color: Colors.white, fontSize: 24)), Slider(value: _height, min: 140, max: 210, onChanged: (v) { setState(() => _height = v); widget.onHeightSelected?.call(v); })]);
  }

  Widget _buildChips() {
    return Wrap(spacing: 8, runSpacing: 8, children: widget.options.map((o) => FilterChip(selected: _selectedOptions.contains(o), label: Text(o), onSelected: (s) {
      setState(() { if (s && _selectedOptions.length < 3) { _selectedOptions.add(o); } else { _selectedOptions.remove(o); } });
      widget.onInterestsChanged?.call(_selectedOptions); widget.onVibesChanged?.call(_selectedOptions);
    })).toList());
  }

  Widget _buildLife() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Smoking:", style: TextStyle(color: Colors.white)),
      Wrap(spacing: 5, children: ['Never', 'Socially', 'Often'].map((s) => ChoiceChip(selected: _smoke == s, label: Text(s), onSelected: (v) { setState(() => _smoke = v ? s : null); widget.onSmokingSelected?.call(_smoke); })).toList()),
      const SizedBox(height: 10),
      const Text("Drinking:", style: TextStyle(color: Colors.white)),
      Wrap(spacing: 5, children: ['Never', 'Socially', 'Often'].map((d) => ChoiceChip(selected: _drink == d, label: Text(d), onSelected: (v) { setState(() => _drink = v ? d : null); widget.onDrinkingSelected?.call(_drink); })).toList()),
    ]);
  }

  Widget _buildIntent() {
    return Wrap(spacing: 10, children: widget.options.map((i) => ChoiceChip(selected: _intent == i, label: Text(i), onSelected: (v) { setState(() => _intent = v ? i : null); widget.onIntentSelected?.call(_intent); })).toList());
  }

  Widget _buildLoc() {
    return TextField(onChanged: (v) => widget.onLocationChanged?.call(v), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'City / Area'));
  }
}*/
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // NEW: For Base64
// NEW: For File
import 'dart:typed_data'; // NEW: For Bytes
import 'package:image_picker/image_picker.dart'; // NEW: For Picker
import 'email_verification_screen.dart';

// --- PASSWORD VALIDATION LOGIC ---
bool isStrongPassword(String password) {
  final regex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_#]).{8,}$',
  );
  return regex.hasMatch(password);
}

// --- COLOR PALETTE ---
const Color darkPurpleBackground = Color(0xFF0F0015);
const Color midPurpleBackground = Color(0xFF3B0040);
const Color primaryPink = Color(0xFFFF4081);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // --- DATA VARIABLES ---
  String? selectedGender;
  DateTime selectedDOB = DateTime(2000, 1, 1);
  double selectedHeight = 175;
  String? selectedLocation;
  Set<String> selectedInterests = {};
  Set<String> selectedVibes = {};
  String? selectedIntent;
  String? selectedSmoking;
  String? selectedDrinking;
  String? _base64Image; // NEW: To store the image string

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 14) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400), 
        curve: Curves.easeOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> signUpSteps = [
      const SignUpStepCard(title: 'Welcome to Meet-Cute.', subtitle: 'Let\'s start with what we should call you.', isInputStep: true, inputLabel: 'Your Name'),
      SignUpStepCard(title: 'When is your birthday?', subtitle: 'You must be 18+ to join.', isDOBStep: true, onDOBSelected: (val) => selectedDOB = val),
      SignUpStepCard(title: 'How do you identify?', subtitle: 'We use this to find you the best matches.', isGenderStep: true, onGenderSelected: (val) => selectedGender = val),
      const SignUpStepCard(title: 'What is your Email?', subtitle: 'Required for notifications.', isEmailInputStep: true),
      const SignUpStepCard(title: 'Create a Secure Password.', subtitle: 'Use a strong password.', isPasswordStep: true),
      const SignUpStepCard(title: 'What is your Phone Number?', subtitle: 'Enter for profile information.', isPhoneInputStep: true),
      SignUpStepCard(title: 'Where Are You Located?', subtitle: 'Matches nearby.', isLocationStep: true, onLocationChanged: (val) => selectedLocation = val),
      SignUpStepCard(title: 'Tell us about your height.', subtitle: 'Key filter for many people.', isHeightStep: true, onHeightSelected: (val) => selectedHeight = val),
      SignUpStepCard(title: 'Your Best Angle.', subtitle: 'Add a high-quality photo.', isImageStep: true, onImageSelected: (val) => _base64Image = val), // UPDATED
      SignUpStepCard(title: 'Obsessions & Interests.', subtitle: 'Pick at least three.', isSelectionStep: true, options: const ['Photography', 'Coding', 'Hiking', 'Cooking', 'Gaming', 'Reading', 'Art', 'Music', 'Travel', 'Movies'], onInterestsChanged: (val) => selectedInterests = val),
      SignUpStepCard(title: 'What\'s Your Vibe?', subtitle: 'Describe yourself best.', isSelectionStep: true, options: const ['Spontaneous', 'Intellectual', 'Creative', 'Chill', 'Intense', 'Wanderlust', 'Funny', 'Serious'], onVibesChanged: (val) => selectedVibes = val),
      const SignUpStepCard(title: 'Your Professional Life.', subtitle: 'Career/Education info.', isCareerStep: true),
      SignUpStepCard(title: 'Your Lifestyle.', subtitle: 'Smoking and drinking status.', isLifestyleStep: true, onSmokingSelected: (val) => selectedSmoking = val, onDrinkingSelected: (val) => selectedDrinking = val),
      SignUpStepCard(title: 'What Are You Looking For?', subtitle: 'Dating intentions.', isIntentStep: true, options: const ['Long-term relationship', 'Short-term fun', 'New friends', 'Figuring it out'], onIntentSelected: (val) => selectedIntent = val),
      const SignUpStepCard(title: 'You\'re All Set!', subtitle: 'Ready to find your Meet-Cute?', isFinalStep: true),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkPurpleBackground, midPurpleBackground])),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(value: (_currentPage + 1) / signUpSteps.length, backgroundColor: Colors.white10, color: Colors.pinkAccent),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), 
                  itemCount: signUpSteps.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) => Column(
                    children: [
                      Expanded(child: signUpSteps[i]),
                      Padding(padding: const EdgeInsets.all(20), child: _buildNavBtn(i, signUpSteps.length)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBtn(int index, int total) {
    bool isLast = index == total - 1;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60), 
        backgroundColor: isLast ? Colors.pinkAccent : Colors.deepPurpleAccent, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
      ),
      onPressed: () async {
        // Validation Checks
        if (index == 3 && (emailController.text.isEmpty || !emailController.text.contains('@'))) return;
        if (index == 4 && !isStrongPassword(passwordController.text)) return;
        
        // NEW: Mandatory Image check at the image step (index 8)
        if (index == 8 && (_base64Image == null || _base64Image!.isEmpty)) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please insert the image")));
           return;
        }

        if (isLast) {
          // FINAL VALIDATION: Ensure image is there before submitting
          if (_base64Image == null || _base64Image!.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please insert the image")));
            return;
          }

          try {
            final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: emailController.text.trim(), 
              password: passwordController.text.trim()
            );

            await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
              'uid': cred.user!.uid,
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'phoneNumber': phoneController.text.trim(),
              'gender': selectedGender,
              'birthDate': selectedDOB.toIso8601String(),
              'height': selectedHeight.round(),
              'location': selectedLocation,
              'interests': selectedInterests.toList(),
              'vibe': selectedVibes.toList(),
              'lookingFor': selectedIntent,
              'smoking': selectedSmoking,
              'drinking': selectedDrinking,
              'imageUrl': _base64Image, // NEW: Saves Base64 string to Firestore
              'profileCompleted': true,
              'createdAt': FieldValue.serverTimestamp(),
              'isOnline': true,
            });

            await cred.user!.sendEmailVerification();
            if (mounted) {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmailVerificationScreen()));
            }
          } catch (e) { 
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); 
          }
        } else { 
          _nextPage(); 
        }
      },
      child: Text(isLast ? 'START MATCHING' : 'CONTINUE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class SignUpStepCard extends StatefulWidget {
  final String title, subtitle;
  final bool isInputStep, isSelectionStep, isImageStep, isFinalStep, isLocationStep, isDOBStep, isGenderStep, isEmailInputStep, isPhoneInputStep, isPasswordStep, isHeightStep, isCareerStep, isLifestyleStep, isIntentStep;
  final List<String> options;
  final String? inputLabel;
  final ValueChanged<String?>? onGenderSelected, onLocationChanged, onIntentSelected, onSmokingSelected, onDrinkingSelected, onImageSelected;
  final ValueChanged<DateTime>? onDOBSelected;
  final ValueChanged<double>? onHeightSelected;
  final ValueChanged<Set<String>>? onInterestsChanged, onVibesChanged;

  const SignUpStepCard({
    super.key, required this.title, required this.subtitle, 
    this.isInputStep = false, this.isSelectionStep = false, this.isImageStep = false, 
    this.isFinalStep = false, this.isLocationStep = false, this.isDOBStep = false, 
    this.isGenderStep = false, this.isEmailInputStep = false, this.isPhoneInputStep = false, 
    this.isPasswordStep = false, this.isHeightStep = false, this.isCareerStep = false, 
    this.isLifestyleStep = false, this.isIntentStep = false, this.options = const [], 
    this.inputLabel, this.onGenderSelected, this.onDOBSelected, this.onHeightSelected, 
    this.onLocationChanged, this.onInterestsChanged, this.onVibesChanged, 
    this.onIntentSelected, this.onSmokingSelected, this.onDrinkingSelected,
    this.onImageSelected,
  });

  @override
  State<SignUpStepCard> createState() => _SignUpStepCardState();
}

class _SignUpStepCardState extends State<SignUpStepCard> {
  final Set<String> _selectedOptions = {};
  String? _gender, _smoke, _drink, _intent, _passwordError, _localBase64;
  DateTime _date = DateTime(2000, 1, 1);
  double _height = 175;

  // NEW: Pick image logic inside the card
  void _pickAndConvert() async {
    String? base64 = await ImageHelper.pickImageToBase64();
    if (base64 != null) {
      setState(() => _localBase64 = base64);
      widget.onImageSelected?.call(base64);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Card(
        color: const Color(0xFF1F0025).withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: const TextStyle(fontSize: 28, color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(widget.subtitle, style: const TextStyle(fontSize: 16, color: Colors.white60)),
              const SizedBox(height: 30),
              if (widget.isInputStep) _buildField('Name'),
              if (widget.isEmailInputStep) _buildField('Email Address'),
              if (widget.isPhoneInputStep) _buildField('Phone Number'),
              if (widget.isPasswordStep) _buildPass(),
              if (widget.isDOBStep) _buildDOB(),
              if (widget.isGenderStep) _buildGender(),
              if (widget.isHeightStep) _buildHeight(),
              if (widget.isSelectionStep) _buildChips(),
              if (widget.isCareerStep) const Column(children: [TextField(decoration: InputDecoration(labelText: 'Job Title')), TextField(decoration: InputDecoration(labelText: 'Education'))]),
              if (widget.isLifestyleStep) _buildLife(),
              if (widget.isIntentStep) _buildIntent(),
              if (widget.isLocationStep) _buildLoc(),
              if (widget.isImageStep) // UPDATED
                 Center(
                   child: GestureDetector(
                     onTap: _pickAndConvert,
                     child: _localBase64 == null 
                      ? const Icon(Icons.camera_alt, size: 80, color: Colors.white24)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.memory(base64Decode(_localBase64!), width: 150, height: 150, fit: BoxFit.cover),
                        ),
                   ),
                 ),
              if (widget.isFinalStep) const Center(child: Icon(Icons.favorite, size: 80, color: Colors.pinkAccent)),
            ],
          ),
        ),
      ),
    );
  }

  // --- ALL YOUR REMAINING BUILD METHODS (UNCHANGED) ---
  Widget _buildField(String label) {
    final parent = context.findAncestorStateOfType<_SignupScreenState>();
    var ctrl = (label == 'Email Address') ? parent?.emailController : (label == 'Phone Number' ? parent?.phoneController : parent?.nameController);
    return TextField(controller: ctrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(color: Colors.white70)));
  }

  Widget _buildPass() {
    final parent = context.findAncestorStateOfType<_SignupScreenState>();
    final ctrl = parent?.passwordController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: ctrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              if (value.isEmpty) { _passwordError = null; } 
              else if (!isStrongPassword(value)) { _passwordError = "8+ chars, Upper, Lower, Number & Symbol required."; } 
              else { _passwordError = null; }
            });
          },
          decoration: const InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: Colors.white70), prefixIcon: Icon(Icons.lock_outline, color: Colors.pinkAccent)),
        ),
        if (_passwordError != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_passwordError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
      ],
    );
  }

  Widget _buildDOB() {
    return ActionChip(label: Text("${_date.day}/${_date.month}/${_date.year}"), onPressed: () async {
      DateTime? p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1950), lastDate: DateTime.now());
      if (p != null) { setState(() => _date = p); widget.onDOBSelected?.call(p); }
    });
  }

  Widget _buildGender() {
    return Wrap(spacing: 10, children: ['Male', 'Female', 'Non-binary', 'Prefer not to say'].map((g) => ChoiceChip(selected: _gender == g, label: Text(g), onSelected: (s) { setState(() => _gender = s ? g : null); widget.onGenderSelected?.call(_gender); })).toList());
  }

  Widget _buildHeight() {
    return Column(children: [Text("${_height.round()} cm", style: const TextStyle(color: Colors.white, fontSize: 24)), Slider(value: _height, min: 140, max: 210, onChanged: (v) { setState(() => _height = v); widget.onHeightSelected?.call(v); })]);
  }

  Widget _buildChips() {
    return Wrap(spacing: 8, runSpacing: 8, children: widget.options.map((o) => FilterChip(selected: _selectedOptions.contains(o), label: Text(o), onSelected: (s) {
      setState(() { if (s && _selectedOptions.length < 3) { _selectedOptions.add(o); } else { _selectedOptions.remove(o); } });
      widget.onInterestsChanged?.call(_selectedOptions); widget.onVibesChanged?.call(_selectedOptions);
    })).toList());
  }

  Widget _buildLife() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Smoking:", style: TextStyle(color: Colors.white)),
      Wrap(spacing: 5, children: ['Never', 'Socially', 'Often'].map((s) => ChoiceChip(selected: _smoke == s, label: Text(s), onSelected: (v) { setState(() => _smoke = v ? s : null); widget.onSmokingSelected?.call(_smoke); })).toList()),
      const SizedBox(height: 10),
      const Text("Drinking:", style: TextStyle(color: Colors.white)),
      Wrap(spacing: 5, children: ['Never', 'Socially', 'Often'].map((d) => ChoiceChip(selected: _drink == d, label: Text(d), onSelected: (v) { setState(() => _drink = v ? d : null); widget.onDrinkingSelected?.call(_drink); })).toList()),
    ]);
  }

  Widget _buildIntent() {
    return Wrap(spacing: 10, children: widget.options.map((i) => ChoiceChip(selected: _intent == i, label: Text(i), onSelected: (v) { setState(() => _intent = v ? i : null); widget.onIntentSelected?.call(_intent); })).toList());
  }

  Widget _buildLoc() {
    return TextField(onChanged: (v) => widget.onLocationChanged?.call(v), style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'City / Area'));
  }
}

// --- NEW HELPER CLASS ---
class ImageHelper {
  static final ImagePicker _picker = ImagePicker();
  static Future<String?> pickImageToBase64() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 15, // MANDATORY: Keeps string under Firestore 1MB limit
      maxWidth: 400,
    );
    if (image != null) {
      Uint8List imageBytes = await image.readAsBytes();
      return base64Encode(imageBytes);
    }
    return null;
  }
}