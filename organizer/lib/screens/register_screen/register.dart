import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _passwordVisible        = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading              = false;
  final FirebaseAuth _auth     = FirebaseAuth.instance;

  // Firebase Registration Function
  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage("Passwords do not match");
      return;
    }

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      _showMessage("Please fill in all fields");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase registration
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update display name in Firebase
      await userCredential.user
          ?.updateDisplayName(_usernameController.text.trim());

      // Get Firebase UID and username
      final firebaseUid = userCredential.user?.uid;
      final name = _usernameController.text.trim();

      // Call backend API to store user, with "type" set to "organizer"
      final apiUrl = "http://localhost:8080/api/users";
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": firebaseUid,
          "name": name,
          "type": "organizer"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage("Registration Successful!");
        Navigator.pushNamed(context, '/login');
      } else {
        _showMessage("Backend user creation failed: ${response.body}");
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Registration failed");
    } catch (e) {
      _showMessage("An unexpected error occurred");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Google Sign-In for Registration
  Future<void> _googleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        signInOption: SignInOption.standard,
      );

      await googleSignIn.signOut(); // Ensure a fresh sign-in

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        _showMessage("Google Sign-Up was canceled. Please try again.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Update display name with the username field
      await userCredential.user?.updateDisplayName(_usernameController.text.trim());

      final firebaseUid = userCredential.user?.uid;
      final name = _usernameController.text.trim();

      final apiUrl = "http://localhost:8080/api/users";
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": firebaseUid,
          "name": name,
          "type": "organizer"
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushNamed(context, '/home');
      } else {
        _showMessage("Backend user creation failed: ${response.body}");
      }
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? "Google Sign-Up failed");
    } catch (e) {
      _showMessage("An unexpected error occurred. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to display messages
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161616),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _usernameController,
                  hintText: 'Username',
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: !_passwordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: !_confirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 0, 0, 0),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                              onPressed: _register,
                              child: const Text(
                                'SignUp',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _googleSignIn,
                              icon: const Icon(Icons.g_mobiledata,
                                  size: 22, color: Colors.white),
                              label: const Text(
                                'Sign Up with Google',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 80, 26, 206),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
