# ===============================
# Stage 1 - Core Widgets Installer
# ===============================

$base = "lib"

function WriteFile($path, $content) {
    $full = "$base/$path"
    Write-Host "Writing $full"
    $content | Out-File -Encoding UTF8 -Force $full
}

# Ensure folder exists
New-Item -ItemType Directory -Force -Path "lib/core/widgets" | Out-Null

# -------------------------------
# AppTextField
# -------------------------------
WriteFile "core/widgets/app_text_field.dart" @"
import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool obscureText;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
      ),
    );
  }
}
"@

# -------------------------------
# PrimaryButton
# -------------------------------
WriteFile "core/widgets/primary_button.dart" @"
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
"@

Write-Host ""
Write-Host "✅ Core widgets installed successfully!"
