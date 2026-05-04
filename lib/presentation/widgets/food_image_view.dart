import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class FoodImageView extends StatelessWidget {
  const FoodImageView({
    required this.imageRef,
    this.size = 56,
    this.borderRadius = 14,
    super.key,
  });

  final String? imageRef;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeDataUrl(imageRef);
    final image = bytes == null
        ? Container(
            color: const Color(0xFFEAF3EF),
            child: const Icon(Icons.restaurant, color: Color(0xFF1F9D7A)),
          )
        : Image.memory(bytes, fit: BoxFit.cover);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Uint8List? _decodeDataUrl(String? value) {
    if (value == null || !value.startsWith('data:image')) {
      return null;
    }
    try {
      return base64Decode(value.substring(value.indexOf(',') + 1));
    } catch (_) {
      return null;
    }
  }
}
