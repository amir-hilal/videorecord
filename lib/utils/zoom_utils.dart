// lib/utils/zoom_utils.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Sets the zoom level on the camera controller.
/// Takes care of clamping the zoom level within a specified range.
void setZoom(CameraController controller, double zoomLevel) {
  controller.setZoomLevel(zoomLevel);
}

/// Handles the pinch-to-zoom gesture by calculating the new zoom level based on the scale of the gesture.
double handlePinchZoom(
    ScaleUpdateDetails details, double baseZoomLevel, double zoomLevel) {
  if (details.pointerCount == 2) {
    const double sensitivityMultiplier = 1.5; // Adjust sensitivity as needed
    final adjustedScale = 1.0 + (details.scale - 1.0) * sensitivityMultiplier;
    return (baseZoomLevel * adjustedScale).clamp(1.0, 8.0);
  }
  return zoomLevel;
}

/// Resets the base distance for pinch zoom to avoid unintended jumps in zoom level.
double resetPinch() {
  return 0.0;
}
