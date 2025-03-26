import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Providers/auth_provider.dart';
import 'register_page.dart';
import '../Widgets/text_field.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.watch(authNotifierProvider.notifier);
    final authState = ref.watch(authNotifierProvider);
    final emailController = ref.watch(emailControllerProvider);
    final passwordController = ref.watch(passwordControllerProvider);
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Upper Part - Background Image & Welcome Message
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      // 🔹 Background Image
                      Positioned.fill(
                        child: Image.asset(
                          'assets/building.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(flex: 5, child: Container()),
              ],
            ),
          ),

          // 🔹 Bottom Part - Login Form
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * .65,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Color.fromARGB(99, 230, 234, 239),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 🔹 Car Image Overlapping the Section
                    Align(
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/car.png',
                        width: 150,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Email & Password Fields
                    CustomTextField(
                        hint: "Email",
                        controller: authNotifier.emailController),
                    CustomTextField(
                        hint: "Password",
                        controller: authNotifier.passwordController,
                        isPassword: true),

                    // 🔹 Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),

                    // 🔹 Login Button
                    ElevatedButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => authNotifier.signInWithEmail(
                                emailController.text.trim(),
                                passwordController.text.trim(),
                                context,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: const BorderSide(color: Colors.white, width: 2),
                        ),
                        elevation: 5,
                      ),
                      child: authState.isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              "Sign In",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),

                    const SizedBox(height: 15),

                    // 🔹 Social Media Login
                    const Text("Login with social media",
                        style: TextStyle(color: Colors.black)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialButton('assets/google_icon.png',
                            () => authNotifier.signInWithGoogle(context)),
                        const SizedBox(width: 20),
                        _socialButton('assets/facebook_icon.png',
                            () => authNotifier.signInWithFacebook(context)),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Sign Up Link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterPage()),
                        );
                      },
                      child: const SizedBox(
                        width: double.infinity,
                        child: Text(
                          "Don't have an account? Sign up",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton(String asset, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 30,
        child: Image.asset(asset, height: 28),
      ),
    );
  }
}
