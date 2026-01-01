# =========================
# Stores Feature Scaffold
# =========================

Write-Host "Creating Stores feature structure..."

# Base paths
$modelsPath   = "lib\data\models"
$servicesPath = "lib\data\services"
$statePath    = "lib\state"
$uiPath       = "lib\presentation\stores"

# Create directories
New-Item -ItemType Directory -Force -Path $modelsPath
New-Item -ItemType Directory -Force -Path $servicesPath
New-Item -ItemType Directory -Force -Path $statePath
New-Item -ItemType Directory -Force -Path $uiPath

# -------------------------
# Store Model
# -------------------------
$storeModel = @"
class Store {
  final String id;
  final String name;
  final String description;
  final bool isOpen;

  Store({
    required this.id,
    required this.name,
    required this.description,
    required this.isOpen,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      isOpen: json['isOpen'],
    );
  }
}
"@

Set-Content -Path "$modelsPath\store_model.dart" -Value $storeModel

# -------------------------
# Store Service
# -------------------------
$storeService = @"
import 'package:dio/dio.dart';
import '../models/store_model.dart';

class StoreService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:4000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<Store>> getStores() async {
    final res = await _dio.get('/stores');
    return (res.data as List)
        .map((json) => Store.fromJson(json))
        .toList();
  }
}
"@

Set-Content -Path "$servicesPath\store_service.dart" -Value $storeService

# -------------------------
# Store Provider
# -------------------------
$storeProvider = @"
import 'package:flutter/material.dart';
import '../data/models/store_model.dart';
import '../data/services/store_service.dart';

class StoreProvider extends ChangeNotifier {
  final StoreService _service = StoreService();

  List<Store> stores = [];
  bool loading = false;
  String? error;

  Future<void> loadStores() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      stores = await _service.getStores();
    } catch (e) {
      error = 'Failed to load stores';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
"@

Set-Content -Path "$statePath\store_provider.dart" -Value $storeProvider

# -------------------------
# Stores Screen
# -------------------------
$storesScreen = @"
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/store_provider.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Stores')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : ListView.separated(
                  itemCount: provider.stores.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final store = provider.stores[i];
                    return ListTile(
                      title: Text(store.name),
                      subtitle: Text(store.description),
                      trailing: Icon(
                        store.isOpen ? Icons.check_circle : Icons.cancel,
                        color: store.isOpen ? Colors.green : Colors.red,
                      ),
                    );
                  },
                ),
    );
  }
}
"@

Set-Content -Path "$uiPath\stores_screen.dart" -Value $storesScreen

Write-Host "Stores feature created successfully ✅"
Write-Host "Next steps:"
Write-Host "1) Add StoreProvider to MultiProvider in main.dart"
Write-Host "2) Add navigation from Home -> StoresScreen"
Write-Host "3) Implement Backend /stores endpoint"
