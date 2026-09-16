import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';
import 'package:hkt_livestock_agentic/features/devices/domain/device_eui.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

/// Full-screen scanner that returns a validated device EUI.
///
/// Accepts QR codes (TB ear tags) and 1D barcodes (GAT collar labels). Pops
/// with the lowercased 16-hex-digit EUI once a code carrying a device EUI is
/// recognized; pops with `null` when the user closes the page or chooses
/// manual entry.
class QrEuiScanPage extends StatefulWidget {
  const QrEuiScanPage({super.key});

  /// Pushes the scanner and resolves with the scanned EUI, or `null`.
  static Future<String?> push(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrEuiScanPage()),
    );
  }

  @override
  State<QrEuiScanPage> createState() => _QrEuiScanPageState();
}

class _QrEuiScanPageState extends State<QrEuiScanPage> {
  // Landscape window: wide enough for 1D barcodes, still fits a QR code.
  static const double _scanWindowWidth = 320;
  static const double _scanWindowHeight = 160;
  static const double _scanWindowLift = 60;

  MobileScannerController? _controller;
  bool _completed = false;
  DateTime _lastInvalidHintAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  MobileScannerController _createController() => MobileScannerController(
        formats: const [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39,
          BarcodeFormat.code93,
          BarcodeFormat.codabar,
          BarcodeFormat.ean13,
          BarcodeFormat.ean8,
          BarcodeFormat.upcA,
          BarcodeFormat.upcE,
          BarcodeFormat.itf14,
        ],
        detectionSpeed: DetectionSpeed.normal,
      );

  Future<void> _restart() async {
    final old = _controller;
    if (old != null) await old.dispose();
    if (mounted) setState(() => _controller = _createController());
  }

  void _onDetect(BarcodeCapture capture) {
    if (_completed || !mounted) return;
    for (final barcode in capture.barcodes) {
      final eui = parseDeviceEui(barcode.rawValue ?? '');
      if (eui != null) {
        _completed = true;
        Navigator.of(context).pop(eui);
        return;
      }
    }
    // Scanned a code that is not a device EUI; keep scanning but tell the
    // user, throttled so a held-up wrong label does not spam snackbars.
    final now = DateTime.now();
    if (now.difference(_lastInvalidHintAt) < const Duration(seconds: 3)) {
      return;
    }
    _lastInvalidHintAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.qrScanNotEui),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - _scanWindowLift),
      width: _scanWindowWidth,
      height: _scanWindowHeight,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.qrScanTitle),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_controller != null)
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller!,
              builder: (context, state, _) => IconButton(
                tooltip: l10n.qrScanTorch,
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => unawaited(_controller?.toggleTorch()),
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_controller != null)
            MobileScanner(
              key: ValueKey(_controller),
              controller: _controller,
              onDetect: _onDetect,
              scanWindow: scanWindow,
              errorBuilder: (context, error) => _ScannerErrorView(
                message:
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? l10n.qrScanPermissionDenied
                        : l10n.qrScanGenericError,
                onManualEntry: () => Navigator.of(context).pop(),
                onRetry: _restart,
              ),
              placeholderBuilder: (context) => const ColoredBox(
                color: Colors.black,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else
            const ColoredBox(color: Colors.black),
          CustomPaint(painter: _ScanFramePainter(scanWindow: scanWindow)),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: scanWindow.bottom + AppSpacing.lg,
            child: Text(
              l10n.qrScanHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({
    required this.message,
    required this.onManualEntry,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onManualEntry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onManualEntry,
                    child: Text(l10n.qrScanManualEntry),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: onRetry,
                    child: Text(l10n.qrScanRetry),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.scanWindow});

  final Rect scanWindow;

  @override
  void paint(Canvas canvas, Size size) {
    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(
          scanWindow,
          const Radius.circular(AppSpacing.sm),
        ),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = const Color(0x8A000000));

    const cornerLength = 28.0;
    final left = scanWindow.left;
    final top = scanWindow.top;
    final right = scanWindow.right;
    final bottom = scanWindow.bottom;
    final corners = Path()
      ..moveTo(left, top + cornerLength)
      ..lineTo(left, top)
      ..lineTo(left + cornerLength, top)
      ..moveTo(right - cornerLength, top)
      ..lineTo(right, top)
      ..lineTo(right, top + cornerLength)
      ..moveTo(right, bottom - cornerLength)
      ..lineTo(right, bottom)
      ..lineTo(right - cornerLength, bottom)
      ..moveTo(left + cornerLength, bottom)
      ..lineTo(left, bottom)
      ..lineTo(left, bottom - cornerLength);
    canvas.drawPath(
      corners,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) =>
      scanWindow != oldDelegate.scanWindow;
}
