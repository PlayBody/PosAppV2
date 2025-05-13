import 'package:intl/intl.dart';

class CategoryModel {
  final String id;
  final String companyId;
  final String code;
  final String name;
  final String alias;
  final String description;
  final int orderNo;
  final String color;
  
  const CategoryModel(
      {required this.id,
      required this.companyId,
      required this.code,
      required this.name,
      required this.alias,
      required this.description,
      required this.orderNo,
      required this.color});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {

    return CategoryModel(
        id: json['id'],
        companyId: json['company_id'] ?? 2,
        code: json['code'] ?? '',
        name: json['name'],
        alias: json['alias'],
        description: json['description'],
        orderNo: json['order_no'] == null ? 1 : int.parse(json['order_no']),
        color: json['color']);
  }
}
