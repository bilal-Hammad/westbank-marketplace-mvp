class Store {
  final String id;
  final String name;
  final String type;
  final String fulfillmentType;
  final bool isOpen;
  final List<StoreBranch> branches;

  Store({
    required this.id,
    required this.name,
    required this.type,
    required this.fulfillmentType,
    required this.isOpen,
    required this.branches,
  });

  /// Backend store shape (simplified):
  /// {
  ///   id: string,
  ///   name: string,
  ///   type: string,
  ///   fulfillmentType: string,
  ///   branches: [ { id, name, city, area, lat, lng, isOpen, defaultPrepTimeMinutes } ]
  /// }
  factory Store.fromJson(Map<String, dynamic> json) {
    final branchesJson = (json['branches'] as List?) ?? const [];
    final branches = branchesJson
        .map((e) => StoreBranch.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return Store(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      fulfillmentType: (json['fulfillmentType'] ?? '').toString(),
      // Backend returns only open branches in /stores, so if list is empty => closed.
      isOpen: branches.isNotEmpty,
      branches: branches,
    );
  }
}

class StoreBranch {
  final String id;
  final String name;
  final String city;
  final String area;
  final double lat;
  final double lng;
  final bool isOpen;
  final int defaultPrepTimeMinutes;

  StoreBranch({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
    required this.lat,
    required this.lng,
    required this.isOpen,
    required this.defaultPrepTimeMinutes,
  });

  String compact() {
    final parts = [name, city, area]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Branch' : parts.join(' • ');
  }

  factory StoreBranch.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    int parseInt(dynamic v, int fallback) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return StoreBranch(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      isOpen: json['isOpen'] == true,
      defaultPrepTimeMinutes: parseInt(json['defaultPrepTimeMinutes'], 15),
    );
  }
}
