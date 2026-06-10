import 'package:flutter_test/flutter_test.dart';
import 'package:fitforge/core/theme.dart';

void main() {
  test('FitForge brand colors are defined', () {
    expect(AppColors.primary.value, 0xFF1D9E75);
    expect(AppColors.navy900.value, 0xFF0F172A);
  });
}
