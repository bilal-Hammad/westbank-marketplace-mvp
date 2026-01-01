# ==================================
# Stage 1 - Full Address Module
# ==================================

$base = "lib"

function WriteFile($path, $content) {
    $full = "$base/$path"
    $dir = Split-Path $full
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    Write-Host "Writing $full"
    $content | Out-File -Encoding UTF8 -Force $full
}

# -------------------------------
# Address Provider
# -------------------------------
WriteFile "state/address_provider.dart" @"
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressProvider extends ChangeNotifier {
  String? _address;

  String? get address => _address;

  bool get hasAddress => _address != null && _address!.isNotEmpty;

  Future<void> loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    _address = prefs.getString('address');
    notifyListeners();
  }

  Future<void> saveAddress(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('address', value);
    _address = value;
    notifyListeners();
  }
}
"@

# -------------------------------
# Address Screen
# -------------------------------
WriteFile "presentation/address/address_screen.dart" @"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/address_provider.dart';

class AddressScreen extends StatelessWidget {
  AddressScreen({super.key});

  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final addressProvider = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Address'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Where should we deliver?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: controller,
              hint: 'Enter your address',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Save Address',
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;

                await addressProvider.saveAddress(controller.text.trim());

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(
                        child: Text(
                          'HOME (Stage 1)',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
"@

Write-Host ""
Write-Host "✅ Address module (Provider + Screen) installed successfully!"
