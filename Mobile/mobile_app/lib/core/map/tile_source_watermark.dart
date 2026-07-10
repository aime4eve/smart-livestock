import 'package:flutter/material.dart';

import 'smart_tile_provider.dart';

/// Small watermark widget showing the active tile source in the map corner.
/// Place inside a Stack over FlutterMap, aligned top-right.
class TileSourceWatermark extends StatelessWidget {
  const TileSourceWatermark({
    super.key,
    required this.provider,
  });

  final SmartTileProvider? provider;

  @override
  Widget build(BuildContext context) {
    if (provider == null) return const SizedBox.shrink();
    return Positioned(
      top: 8,
      right: 8,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            provider!.activeSourceName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
