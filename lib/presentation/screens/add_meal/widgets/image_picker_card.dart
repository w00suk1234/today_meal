import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';

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
    return AppCard(
      padding: const EdgeInsets.all(14),
      color: AppColors.lightGreenBackground,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageBytes == null)
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primarySoft,
                            AppColors.creamBackground
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 31,
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 12),
                          const Text('음식 사진을 추가해 주세요',
                              style: TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          const Text('카메라 또는 갤러리에서 먼저 선택해 주세요',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    )
                  else
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.44),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.white, size: 17),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '사진 선택 후 AI 분석 가능',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
