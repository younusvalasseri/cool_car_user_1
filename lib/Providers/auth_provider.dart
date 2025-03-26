import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_car_user_1/Main/verify_otp_page.dart';
import 'package:cool_car_user_1/Views/home_page.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

/// ✅ Authentication State Stream Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
final emailControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});

final passwordControllerProvider = Provider<TextEditingController>((ref) {
  return TextEditingController();
});
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
        (ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _checkAuthState();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _checkAuthState() {
    _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
    });
  }

  void setUser(User? user) {
    state = AsyncValue.data(user);
  }

  Future<void> signUpUser(
      String name, String email, String password, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // ✅ Store user details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setUser(_auth.currentUser);
      scaffoldMessenger.showSnackBar(
          SnackBar(content: Text("🎉 Welcome, $name! Account created.")));
    } on FirebaseAuthException catch (e) {
      _showError(scaffoldMessenger, e.message ?? "Signup failed");
    }
  }

  Future<void> signInWithEmail(
      String email, String password, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      setUser(_auth.currentUser);
    } on FirebaseAuthException catch (e) {
      _showError(scaffoldMessenger, e.message ?? "Login failed");
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // 🔹 If user does not exist in Firestore, prompt for mobile number
        if (!userDoc.exists) {
          if (!context.mounted) return;
          String? phoneNumber = await _promptForPhoneNumber(context);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name': user.displayName ?? "Google User",
            'email': user.email,
            'phone': phoneNumber ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      setUser(_auth.currentUser);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  /// **Prompt user to enter phone number manually**
  Future<String?> _promptForPhoneNumber(BuildContext context) async {
    TextEditingController phoneController = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Your Phone Number"),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: "+1 123 456 7890"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null), // Cancel
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, phoneController.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      return 'Unknown User';
    }
  }

  Future<void> signInWithFacebook(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final fb.LoginResult result = await fb.FacebookAuth.instance.login(
        permissions: [
          "public_profile",
          "email",
          "user_mobile_phone"
        ], // ✅ Request phone number
      );

      if (result.status == fb.LoginStatus.success) {
        final fb.AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential =
            FacebookAuthProvider.credential(accessToken.token);

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        User? user = userCredential.user;

        if (user != null) {
          final fbUserData = await fb.FacebookAuth.instance.getUserData(
            fields: "name,email,phone",
          );
          if (!context.mounted) return;
          String? phoneNumber =
              fbUserData["phone"] ?? await _promptForPhoneNumber(context);

          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'name': user.displayName ?? "Facebook User",
              'email': user.email,
              'phone': phoneNumber ?? '',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }

        setUser(_auth.currentUser);
      } else {
        _showError(scaffoldMessenger, "Facebook Sign-In Failed");
      }
    } on FirebaseAuthException catch (e) {
      _showError(scaffoldMessenger, e.message ?? "Facebook Sign-In Error");
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    setUser(null);
  }

  void _showError(ScaffoldMessengerState scaffoldMessenger, String message) {
    scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

final registerNotifierProvider =
    StateNotifierProvider<RegisterNotifier, RegisterState>(
        (ref) => RegisterNotifier());

class RegisterNotifier extends StateNotifier<RegisterState> {
  RegisterNotifier() : super(RegisterState());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  void setName(String name) => state = state.copyWith(name: name);
  void setEmail(String email) => state = state.copyWith(email: email);
  void setPhoneNumber(String number) =>
      state = state.copyWith(phoneNumber: number);
  void setPassword(String password) =>
      state = state.copyWith(password: password);
  void setConfirmPassword(String confirmPassword) =>
      state = state.copyWith(confirmPassword: confirmPassword);

  /// **🔹 Verify Phone Number & Send OTP**
  Future<void> verifyPhoneNumber(BuildContext context) async {
    if (state.phoneNumber.isEmpty ||
        state.name.isEmpty ||
        state.email.isEmpty ||
        state.password.isEmpty ||
        state.confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ All fields are required.")),
      );
      return;
    }

    if (state.password != state.confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Passwords do not match.")),
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    await _auth.verifyPhoneNumber(
      phoneNumber: state.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        await _saveUserToFirestore(
            userCredential.user!, state.name, state.email, state.password);
      },
      verificationFailed: (FirebaseAuthException e) {
        state = state.copyWith(isLoading: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Verification failed: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        state = state.copyWith(isLoading: false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpPage(
              verificationId: verificationId,
              phoneNumber: state.phoneNumber,
              name: state.name,
              email: state.email,
              password: state.password,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// **🔹 Save User to Firestore (With Password Hashing)**
  Future<void> _saveUserToFirestore(
      User user, String name, String email, String password) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    DocumentSnapshot userDoc = await userRef.get();
    if (!userDoc.exists) {
      String hashedPassword = _hashPassword(password);
      await userRef.set({
        'name': name,
        'email': email,
        'phoneNumber': user.phoneNumber,
        'password': hashedPassword, // ✅ Store Hashed Password
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// **🔹 Hash Password Before Storing**
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// **🔹 Register State Class**
class RegisterState {
  final String name;
  final String email;
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final bool isLoading;

  RegisterState({
    this.name = '',
    this.email = '',
    this.phoneNumber = '',
    this.password = '',
    this.confirmPassword = '',
    this.isLoading = false,
  });

  RegisterState copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? password,
    String? confirmPassword,
    bool? isLoading,
  }) {
    return RegisterState(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final otpNotifierProvider =
    StateNotifierProvider<OtpNotifier, OtpState>((ref) => OtpNotifier());

/// **🔹 OTP Notifier**
class OtpNotifier extends StateNotifier<OtpState> {
  OtpNotifier() : super(OtpState());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// **🔹 Set OTP Input**
  void setOtp(String otp) {
    state = state.copyWith(otpCode: otp);
  }

  /// **🔹 Verify OTP & Navigate to Home**
  Future<void> verifyOtp(BuildContext context, String verificationId) async {
    if (state.otpCode.isEmpty || state.otpCode.length < 6) return;

    state = state.copyWith(isLoading: true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: state.otpCode,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      await _saveUserToFirestore(userCredential.user!, state.name, state.email);

      state = state.copyWith(isLoading: false);

      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP verification failed: $e")),
      );
    }
  }

  /// **🔹 Save User to Firestore**
  Future<void> _saveUserToFirestore(
      User user, String name, String email) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    DocumentSnapshot userDoc = await userRef.get();
    if (!userDoc.exists) {
      await userRef.set({
        'name': name,
        'email': email,
        'phoneNumber': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

class OtpState {
  final String otpCode;
  final bool isLoading;
  final String phoneNumber;
  final String verificationId;
  final String name; // ✅ Include name
  final String email; // ✅ Include email

  OtpState({
    this.otpCode = '',
    this.isLoading = false,
    this.phoneNumber = '',
    this.verificationId = '',
    this.name = '', // ✅ Default to empty string
    this.email = '', // ✅ Default to empty string
  });

  OtpState copyWith({
    String? otpCode,
    bool? isLoading,
    String? phoneNumber,
    String? verificationId,
    String? name,
    String? email,
  }) {
    return OtpState(
      otpCode: otpCode ?? this.otpCode,
      isLoading: isLoading ?? this.isLoading,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      name: name ?? this.name, // ✅ Preserve values
      email: email ?? this.email, // ✅ Preserve values
    );
  }
}
