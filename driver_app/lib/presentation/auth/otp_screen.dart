import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/auth_provider.dart';
import '../driver/driver_home_screen.dart';

class OtpScreen extends StatelessWidget {
  final String? name;

  OtpScreen({super.key, this.name});

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              controller: controller,
              hint: 'OTP Code',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Verify',
              loading: auth.loading,
              onPressed: () async {
                await auth.verifyOtp(controller.text);
                if (auth.error == null) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
                    (route) => false,
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
