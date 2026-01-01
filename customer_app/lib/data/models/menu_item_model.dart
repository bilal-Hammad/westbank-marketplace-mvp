class MenuItem {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int basePrice;
  final int prepMinutes;
  final List<OptionGroup> optionGroups;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.basePrice,
    required this.prepMinutes,
    required this.optionGroups,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final og = (json['optionGroups'] as List?) ?? const [];
    return MenuItem(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      basePrice: (json['basePrice'] ?? 0) is int ? (json['basePrice'] ?? 0) : int.tryParse('${json['basePrice']}') ?? 0,
      prepMinutes: (json['prepMinutes'] ?? 15) is int ? (json['prepMinutes'] ?? 15) : int.tryParse('${json['prepMinutes']}') ?? 15,
      optionGroups: og.map((e) => OptionGroup.fromJson(e)).toList().cast<OptionGroup>(),
    );
  }
}

class OptionGroup {
  final String id;
  final String name;
  final int minSelect;
  final int maxSelect;
  final List<OptionItem> options;

  OptionGroup({
    required this.id,
    required this.name,
    required this.minSelect,
    required this.maxSelect,
    required this.options,
  });

  factory OptionGroup.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List?) ?? const [];
    return OptionGroup(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      minSelect: (json['minSelect'] ?? 0) is int ? (json['minSelect'] ?? 0) : int.tryParse('${json['minSelect']}') ?? 0,
      maxSelect: (json['maxSelect'] ?? 1) is int ? (json['maxSelect'] ?? 1) : int.tryParse('${json['maxSelect']}') ?? 1,
      options: opts.map((e) => OptionItem.fromJson(e)).toList().cast<OptionItem>(),
    );
  }
}

class OptionItem {
  final String id;
  final String name;
  final int priceAdd;

  OptionItem({
    required this.id,
    required this.name,
    required this.priceAdd,
  });

  factory OptionItem.fromJson(Map<String, dynamic> json) {
    return OptionItem(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      priceAdd: (json['priceAdd'] ?? 0) is int ? (json['priceAdd'] ?? 0) : int.tryParse('${json['priceAdd']}') ?? 0,
    );
  }
}
