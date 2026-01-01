import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/auth_provider.dart';
import '../home/inbox_screen.dart';
import 'login_screen.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the OTP.\n\nIf you use the demo backend seed, the OTP appears in the backend terminal log like:\n[OTP][MOCK] phone=... code=1234',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controller,
              hint: 'OTP Code',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Verify & Enter Store',
              loading: auth.loading,
              onPressed: () async {
                final ok = await auth.verifyOtp(controller.text);
                if (!context.mounted) return;

                if (ok) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const InboxScreen()),
                    (route) => false,
                  );
                } else {
                  // If role isn't STORE_OWNER, auth.verifyOtp sets error and logs out.
                  if (!auth.isLoggedIn) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: auth.loading
                  ? null
                  : () {
                      Navigator.pop(context);
                    },
              child: const Text('Back'),
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
