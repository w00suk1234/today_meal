import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../widgets/app_card.dart';

class ImagePickerCard extends StatelessWidget {
  const ImagePickerCard({
    required this.previewImageBytes,
    required this.onPickGallery,
    required this.onPickCamera,
    super.key,
  });

  final Uint8List? previewImageBytes;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => _showImageSourcePicker(context),
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
                  if (previewImageBytes == null)
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
                          const Text('이 영역을 눌러 카메라 또는 갤러리를 선택해 주세요',
                              style: AppTextStyles.caption),
                        ],
                      ),
                    )
                  else
                    Container(
                      color: AppColors.creamBackground,
                      alignment: Alignment.center,
                      child: Image.memory(
                        previewImageBytes!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                    ),
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
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 17),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              previewImageBytes == null ? '눌러서 사진 선택하기' : '눌러서 사진 바꾸기',
                              style: const TextStyle(
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

  void _showImageSourcePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  minTileHeight: 52,
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text(
                    '카메라로 촬영',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onPickCamera();
                  },
                ),
                ListTile(
                  minTileHeight: 52,
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.teal,
                  ),
                  title: const Text(
                    '갤러리에서 선택',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    onPickGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
