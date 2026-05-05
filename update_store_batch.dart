import 'dart:io';

void main() {
  File file = File('lib/store/models/store_models.dart');
  String content = file.readAsStringSync();
  content = content.replaceFirst('final double price;', 'final double realPrice;\n  final double finalPrice;');
  content = content.replaceFirst('required this.price,', 'required this.realPrice,\n    required this.finalPrice,');
  file.writeAsStringSync(content);
}
