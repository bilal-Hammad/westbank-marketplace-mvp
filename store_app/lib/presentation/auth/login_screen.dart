import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/auth_provider.dart';
import 'otp_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final controller = TextEditingController(text: auth.phone.isNotEmpty ? auth.phone : '970599000001');

    return Scaffold(
      appBar: AppBar(title: const Text('Store Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Demo Store Owner (seed): 970599000001\nOTP will be printed in the backend console (MOCK).',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controller,
              hint: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Send OTP',
              loading: auth.loading,
              onPressed: () async {
                await auth.requestOtp(controller.text);
                if (context.mounted && auth.error == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OtpScreen()),
                  );
                }
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
