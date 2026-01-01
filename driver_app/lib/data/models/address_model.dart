class Address {
  final String id;
  final String label;
  final String city;
  final String area;
  final String details;
  final double lat;
  final double lng;
  final bool isDefault;

  Address({
    required this.id,
    required this.label,
    required this.city,
    required this.area,
    required this.details,
    required this.lat,
    required this.lng,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0.0;
    }

    return Address(
      id: json['id'].toString(),
      label: (json['label'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      isDefault: json['isDefault'] == true,
    );
  }

  String compactLabel() {
    final parts = [label, city, area]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Address' : parts.join(' • ');
  }
}
