import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with Google (Forces Account Selection)
  Future<User?> signInWithGoogle() async {
    try {
      // Ensure previous sign-in session is cleared
      final GoogleSignIn googleSignIn = GoogleSignIn(
        signInOption: SignInOption.standard, // Ensures account selection
      );

      await googleSignIn.disconnect(); // Clear previous session
      await googleSignIn.signOut(); // Ensure a fresh sign-in

      // Start Google Sign-In process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled login
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

// Sign out
  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect(); // Disconnect to clear cached user
    await googleSignIn.signOut(); // Ensures fresh sign-in next time
  }
}
