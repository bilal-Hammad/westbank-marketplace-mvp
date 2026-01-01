import 'address_model.dart';

class Delivery {
  final String id;
  final String providerType;
  final String status;
  final DateTime? scheduledMoveAt;
  final DateTime? confirmedAt;
  final OrderForDriver order;

  Delivery({
    required this.id,
    required this.providerType,
    required this.status,
    required this.scheduledMoveAt,
    required this.confirmedAt,
    required this.order,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return Delivery(
      id: json['id'].toString(),
      providerType: (json['providerType'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      scheduledMoveAt: parseDt(json['scheduledMoveAt']),
      confirmedAt: parseDt(json['confirmedAt']),
      order: OrderForDriver.fromJson((json['order'] as Map).cast<String, dynamic>()),
    );
  }
}

class OrderForDriver {
  final String id;
  final String status;
  final String notesToStore;
  final String notesToDriver;
  final StoreSummary store;
  final BranchSummary branch;
  final Address address;
  final List<OrderItem> items;

  OrderForDriver({
    required this.id,
    required this.status,
    required this.notesToStore,
    required this.notesToDriver,
    required this.store,
    required this.branch,
    required this.address,
    required this.items,
  });

  factory OrderForDriver.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];

    return OrderForDriver(
      id: json['id'].toString(),
      status: (json['status'] ?? '').toString(),
      notesToStore: (json['notesToStore'] ?? '').toString(),
      notesToDriver: (json['notesToDriver'] ?? '').toString(),
      store: StoreSummary.fromJson((json['store'] as Map).cast<String, dynamic>()),
      branch: BranchSummary.fromJson((json['branch'] as Map).cast<String, dynamic>()),
      address: Address.fromJson((json['address'] as Map).cast<String, dynamic>()),
      items: itemsJson
          .map((e) => OrderItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class StoreSummary {
  final String id;
  final String name;

  StoreSummary({required this.id, required this.name});

  factory StoreSummary.fromJson(Map<String, dynamic> json) {
    return StoreSummary(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class BranchSummary {
  final String id;
  final String name;
  final String city;
  final String area;

  BranchSummary({
    required this.id,
    required this.name,
    required this.city,
    required this.area,
  });

  factory BranchSummary.fromJson(Map<String, dynamic> json) {
    return BranchSummary(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      area: (json['area'] ?? '').toString(),
    );
  }

  String compact() {
    final parts = [name, city, area].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? 'Branch' : parts.join(' • ');
  }
}

class OrderItem {
  final String id;
  final String nameSnap;
  final int unitPrice;
  final int qty;
  final String notes;
  final List<OrderItemOption> options;

  OrderItem({
    required this.id,
    required this.nameSnap,
    required this.unitPrice,
    required this.qty,
    required this.notes,
    required this.options,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, int fallback) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    final optsJson = (json['options'] as List?) ?? const [];

    return OrderItem(
      id: json['id'].toString(),
      nameSnap: (json['nameSnap'] ?? '').toString(),
      unitPrice: parseInt(json['unitPrice'], 0),
      qty: parseInt(json['qty'], 1),
      notes: (json['notes'] ?? '').toString(),
      options: optsJson
          .map((e) => OrderItemOption.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class OrderItemOption {
  final String nameSnap;
  final int priceAdd;

  OrderItemOption({required this.nameSnap, required this.priceAdd});

  factory OrderItemOption.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, int fallback) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? fallback;
    }

    return OrderItemOption(
      nameSnap: (json['nameSnap'] ?? '').toString(),
      priceAdd: parseInt(json['priceAdd'], 0),
    );
  }
}
