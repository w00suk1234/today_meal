import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImagePickerCard extends StatelessWidget {
  const ImagePickerCard({
    required this.imageBytes,
    required this.onPickGallery,
    required this.onPickCamera,
    super.key,
  });

  final Uint8List? imageBytes;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: imageBytes == null
                    ? Container(
                        color: const Color(0xFFEAF3EF),
                        child: const Icon(Icons.add_photo_alternate_outlined, size: 48, color: Color(0xFF1F9D7A)),
                      )
                    : Image.memory(imageBytes!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('사진 업로드'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPickCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('카메라 촬영'),
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
