// zoom_control.dart
import 'package:flutter/material.dart';

class ZoomControl extends StatelessWidget {
  final double zoom;
  final void Function(double) setZoom;

  ZoomControl({super.key, required this.zoom, required this.setZoom});

  final List<Map<String, dynamic>> zoomLevels = [
    {'label': '1x', 'value': 1.0},
    {'label': '2x', 'value': 2.0},
    {'label': '4x', 'value': 4.0},
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: zoomLevels.map((level) {
            return GestureDetector(
              onTap: () {
                setZoom(level['value']);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 11),
                decoration: BoxDecoration(
                  color: zoom == level['value']
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  level['label'],
                  style: TextStyle(
                    color: zoom == level['value'] ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
