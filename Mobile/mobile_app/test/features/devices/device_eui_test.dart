import 'package:flutter_test/flutter_test.dart';

import 'package:hkt_livestock_agentic/features/devices/domain/device_eui.dart';

void main() {
  group('parseDeviceEui', () {
    test('accepts a bare 16-hex-digit EUI and lowercases it', () {
      expect(parseDeviceEui('70B3D57ED0069A12'), '70b3d57ed0069a12');
      expect(parseDeviceEui('70b3d57ed0069a12'), '70b3d57ed0069a12');
      // GAT-100 collar label: Code128 barcode carries the bare DevEui.
      expect(parseDeviceEui('0095690A00008C91'), '0095690a00008c91');
    });

    test('trims surrounding whitespace before matching', () {
      expect(parseDeviceEui('  70b3d57ed0069a12\n'), '70b3d57ed0069a12');
    });

    test('extracts a bounded EUI from wider payloads', () {
      expect(
        parseDeviceEui('DevEui:0095690A00008C91'),
        '0095690a00008c91',
        reason: 'label text style with prefix',
      );
      expect(
        parseDeviceEui('https://example.com/70b3d57ed0069a12'),
        '70b3d57ed0069a12',
        reason: 'URL-shaped payload embedding the EUI',
      );
    });

    test('rejects payloads without a bounded 16-hex-digit run', () {
      expect(parseDeviceEui(''), isNull);
      expect(parseDeviceEui('70B3D57ED0069A1'), isNull, reason: '15 digits');
      expect(parseDeviceEui('70B3D57ED0069A122'), isNull, reason: '17 digits');
      expect(parseDeviceEui('70B3D57ED0069AG2'), isNull, reason: 'non-hex G');
      expect(
        parseDeviceEui('12345678901234567890'),
        isNull,
        reason: '20-digit run: extracting 16 digits would be a false positive',
      );
      expect(
        parseDeviceEui('EAN 5901234123457'),
        isNull,
        reason: '13-digit EAN',
      );
      expect(
        parseDeviceEui('70B3D57E D0069A12'),
        isNull,
        reason: 'two 8-digit runs do not form a bounded 16-digit run',
      );
    });
  });
}
