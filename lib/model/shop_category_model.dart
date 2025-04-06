class ShopCategoryModel {
  ShopCategoryModel({
    this.categoryName,
    this.description,
  });

  ShopCategoryModel.fromJson(dynamic json) {
    categoryName = json['categoryName'];
    description = json['description'];
  }

  String? categoryName;
  String? description;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['categoryName'] = categoryName;
    map['description'] = description;

    return map;
  }
}
