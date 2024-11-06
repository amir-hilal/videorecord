// lib/components/save_video_modal.dart
import 'package:flutter/material.dart';

class SaveVideoModal extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  const SaveVideoModal(
      {super.key, required this.onSave, required this.onDiscard});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Save Take?',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select “YES” to save, “NO” to discard...',
            style: TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Yes'),
              ),
              ElevatedButton(
                onPressed: onDiscard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('No'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
