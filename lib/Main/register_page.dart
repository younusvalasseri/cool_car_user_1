import 'package:cool_car_user_1/Providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerNotifierProvider);
    final registerNotifier = ref.read(registerNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Full Name
              const Text('Full Name', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 5),
              TextField(
                keyboardType: TextInputType.name,
                onChanged: registerNotifier.setName,
                decoration: const InputDecoration(
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Email
              const Text('Email', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 5),
              TextField(
                keyboardType: TextInputType.emailAddress,
                onChanged: registerNotifier.setEmail,
                decoration: const InputDecoration(
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Phone Number
              const Text('Enter your mobile number',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 5),
              TextField(
                keyboardType: TextInputType.phone,
                onChanged: registerNotifier.setPhoneNumber,
                decoration: const InputDecoration(
                  hintText: '+1 81234 56789',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Password
              const Text('Password', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 5),
              TextField(
                obscureText: true,
                onChanged: registerNotifier.setPassword,
                decoration: const InputDecoration(
                  hintText: 'Enter a secure password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              // 🔹 Re-enter Password
              const Text('Re-enter Password', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 5),
              TextField(
                obscureText: true,
                onChanged: registerNotifier.setConfirmPassword,
                decoration: const InputDecoration(
                  hintText: 'Confirm your password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Loading Indicator or Register Button
              registerState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () =>
                          registerNotifier.verifyPhoneNumber(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.black,
                      ),
                      child: const Text('Next'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
