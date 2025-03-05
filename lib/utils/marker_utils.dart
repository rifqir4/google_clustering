import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'
    hide Cluster;

import '../data/cluster.dart';

class MarkerUtils {
  final Map<String, BitmapDescriptor> _cachedBitmaps = {};

  Future<Marker> Function(Cluster) get basicMarkerBuilder => (cluster) async {
        return Marker(
          markerId: MarkerId(cluster.getId()),
          position: cluster.location,
          onTap: () {
            if (kDebugMode) {
              print(cluster);
            }
          },
          icon: await _getBitmap(cluster),
        );
      };

  Future<BitmapDescriptor> _getBitmap(Cluster cluster) async {
    if (!cluster.isMultiple) {
      if (_cachedBitmaps.containsKey('single')) {
        return _cachedBitmaps['single']!;
      }
      return await _buildBasicBitmap(75);
    }

    return await _buildBasicBitmap(125, text: cluster.count.toString());
  }

  Future<BitmapDescriptor> _buildBasicBitmap(
    int size, {
    String? text,
  }) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint1 = Paint()..color = Color(0xFF4CAF50);

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2.0, paint1);

    if (text != null) {
      final painter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: text,
          style: TextStyle(
            fontSize: size / 3,
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
        )
        ..layout();

      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }

    final img = await pictureRecorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ImageByteFormat.png);

    if (data == null) return BitmapDescriptor.defaultMarker;

    return BitmapDescriptor.bytes(data.buffer.asUint8List());
  }
}
