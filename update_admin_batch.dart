import 'dart:io';

void main() {
  File file = File('lib/admin/models/admin_models.dart');
  String content = file.readAsStringSync();
  content = content.replaceFirst('final double price;', 'final double realPrice;\n  final double finalPrice;');
  content = content.replaceFirst('required this.price,', 'required this.realPrice,\n    required this.finalPrice,');
  content = content.replaceFirst("price: (data['price'] as num?)?.toDouble() ?? 0.0,", "realPrice: (data['realPrice'] as num?)?.toDouble() ?? 0.0,\n      finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? (data['price'] as num?)?.toDouble() ?? 0.0,");
  content = content.replaceFirst("'price': price,", "'realPrice': realPrice,\n      'finalPrice': finalPrice,");
  file.writeAsStringSync(content);
}
