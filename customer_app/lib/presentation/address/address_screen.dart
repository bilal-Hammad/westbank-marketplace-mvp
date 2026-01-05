import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../state/address_provider.dart';
import '../../state/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _labelC = TextEditingController(text: 'Home');
  final _cityC = TextEditingController();
  final _areaC = TextEditingController();
  final _detailsC = TextEditingController();
  final _latC = TextEditingController();
  final _lngC = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AddressProvider>();
      provider.addListener(_onProviderChanged);
      provider.loadAddresses();
    });
  }

  @override
  void dispose() {
    context.read<AddressProvider>().removeListener(_onProviderChanged);
    _labelC.dispose();
    _cityC.dispose();
    _areaC.dispose();
    _detailsC.dispose();
    _latC.dispose();
    _lngC.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    final provider = context.read<AddressProvider>();
    if (provider.error == 'Unauthorized') {
      // Token invalid, logout
      context.read<AuthProvider>().logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    }
  }

  double _parseDouble(String v) => double.tryParse(v.trim()) ?? 0.0;

  Future<void> _saveNewAddress() async {
    final provider = context.read<AddressProvider>();

    // Backend requires lat/lng. For MVP, we allow 0.0 but you can later
    // integrate a location picker.
    final lat = _parseDouble(_latC.text);
    final lng = _parseDouble(_lngC.text);

    await provider.createAddress(
      lat: lat,
      lng: lng,
      label: _labelC.text.trim(),
      city: _cityC.text.trim(),
      area: _areaC.text.trim(),
      details: _detailsC.text.trim(),
      isDefault: true,
    );

    if (!mounted) return;

    if (provider.error == null && provider.hasDefaultAddress) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Address'),
        automaticallyImplyLeading: false,
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : provider.addresses.isEmpty
                  ? _AddAddressForm(onSave: _saveNewAddress, labelC: _labelC, cityC: _cityC, areaC: _areaC, detailsC: _detailsC, latC: _latC, lngC: _lngC)
                  : _AddressList(),
    );
  }
}

class _AddAddressForm extends StatelessWidget {
  final Future<void> Function() onSave;
  final TextEditingController labelC;
  final TextEditingController cityC;
  final TextEditingController areaC;
  final TextEditingController detailsC;
  final TextEditingController latC;
  final TextEditingController lngC;

  const _AddAddressForm({
    required this.onSave,
    required this.labelC,
    required this.cityC,
    required this.areaC,
    required this.detailsC,
    required this.latC,
    required this.lngC,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add your default address',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: labelC, hint: 'Label (Home / Work)'),
          const SizedBox(height: 10),
          AppTextField(controller: cityC, hint: 'City'),
          const SizedBox(height: 10),
          AppTextField(controller: areaC, hint: 'Area'),
          const SizedBox(height: 10),
          AppTextField(controller: detailsC, hint: 'Details (building, street...)'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: AppTextField(controller: latC, hint: 'Lat (e.g. 31.9)', keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: AppTextField(controller: lngC, hint: 'Lng (e.g. 35.2)', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: 'Save Address',
            onPressed: onSave,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tip: later we can replace Lat/Lng with a map picker.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AddressList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AddressProvider>();

    return RefreshIndicator(
      onRefresh: provider.loadAddresses,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: provider.addresses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final a = provider.addresses[i];
          return Card(
            child: ListTile(
              title: Text(a.compactLabel()),
              subtitle: Text(a.details),
              leading: Icon(a.isDefault ? Icons.star : Icons.location_on_outlined),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'default') provider.setDefault(a.id);
                  if (v == 'delete') provider.deleteAddress(a.id);
                },
                itemBuilder: (_) => [
                  if (!a.isDefault)
                    const PopupMenuItem(value: 'default', child: Text('Make Default')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
              onTap: () async {
                if (!a.isDefault) {
                  await provider.setDefault(a.id);
                }

                if (!context.mounted) return;
                if (provider.hasDefaultAddress) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
