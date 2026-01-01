import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/auth_provider.dart';
import 'otp_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final phoneController = TextEditingController();
  final nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          
          children: [
            AppTextField(
              controller: phoneController,
              hint: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: nameController,
              hint: 'Full Name (include "driver" if you are a driver)',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Send OTP',
              loading: auth.loading,
              onPressed: () async {
                await auth.requestOtp(phoneController.text, inputName: nameController.text);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OtpScreen(name: nameController.text)),
                );
              },
            ),
            if (auth.error != null) ...[
  const SizedBox(height: 12),
  Text(auth.error!, style: const TextStyle(color: Colors.red)),
],

          ],
          
        ),
      ),
    );
  }
}
