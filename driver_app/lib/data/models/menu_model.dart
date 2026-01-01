import 'menu_item_model.dart';

class Menu {
  final String id;
  final String storeId;
  final String title;
  final List<MenuItem> items;

  Menu({
    required this.id,
    required this.storeId,
    required this.title,
    required this.items,
  });

  factory Menu.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List?) ?? const [];
    return Menu(
      id: json['id'].toString(),
      storeId: (json['storeId'] ?? '').toString(),
      title: (json['title'] ?? 'Menu').toString(),
      items: itemsJson.map((e) => MenuItem.fromJson(e)).toList().cast<MenuItem>(),
    );
  }
}
