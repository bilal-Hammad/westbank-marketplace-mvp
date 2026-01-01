# ===============================
# Stage 1 - Address Installer
# ===============================

$base = "lib"

function WriteFile($path, $content) {
    $full = "$base/$path"
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
  String? address;

  Future<void> loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    address = prefs.getString('address');
    notifyListeners();
  }

  Future<void> saveAddress(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('address', value);
    address = value;
    notifyListeners();
  }

  bool get hasAddress => address != null && address!.isNotEmpty;
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

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final address = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Your Address')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              controller: controller,
              hint: 'Enter your address',
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              text: 'Save Address',
              onPressed: () async {
                await address.saveAddress(controller.text);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      body: Center(child: Text('HOME (Stage 1)')),
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
Write-Host "✅ Address module installed successfully!"
