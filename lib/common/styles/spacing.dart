import 'package:flutter/widgets.dart';

class Space {
  Space._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static Widget v(double h) => SizedBox(height: h);
  static Widget h(double w) => SizedBox(width: w);

  static Widget vXs() => const SizedBox(height: xs);
  static Widget vSm() => const SizedBox(height: sm);
  static Widget vMd() => const SizedBox(height: md);
  static Widget vLg() => const SizedBox(height: lg);
  static Widget vXl() => const SizedBox(height: xl);
  static Widget vXxl() => const SizedBox(height: xxl);

  static Widget hXs() => const SizedBox(width: xs);
  static Widget hSm() => const SizedBox(width: sm);
  static Widget hMd() => const SizedBox(width: md);
  static Widget hLg() => const SizedBox(width: lg);
  static Widget hXl() => const SizedBox(width: xl);
  static Widget hXxl() => const SizedBox(width: xxl);
}
