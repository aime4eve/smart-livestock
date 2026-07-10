String formatCurrency(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final decPart = parts[1];

  final buffer = StringBuffer();
  final digits = intPart.split('').reversed.toList();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  final formattedInt = buffer.toString().split('').reversed.join();

  return '¥$formattedInt.$decPart';
}
