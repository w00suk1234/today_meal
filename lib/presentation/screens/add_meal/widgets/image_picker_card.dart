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
    final hasPreview = previewImageBytes != null;

    return AppCard(
      onTap: () => _showImageSourcePicker(context),
      padding: const EdgeInsets.all(12),
      color: AppColors.lightGreenBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasPreview
                  ? Container(
                      color: AppColors.creamBackground,
                      alignment: Alignment.center,
                      child: Image.memory(
                        previewImageBytes!,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
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
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _EmptyPhotoIcon(),
                          SizedBox(height: 10),
                          Text(
                            '음식 사진을 추가해 주세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '카메라 또는 갤러리에서 선택해 주세요',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          _PickPhotoButton(hasPreview: hasPreview),
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

class _EmptyPhotoIcon extends StatelessWidget {
  const _EmptyPhotoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.add_photo_alternate_outlined,
        size: 29,
        color: AppColors.primary,
      ),
    );
  }
}

class _PickPhotoButton extends StatelessWidget {
  const _PickPhotoButton({required this.hasPreview});

  final bool hasPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.touch_app_rounded,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              hasPreview ? '사진 바꾸기' : '사진 선택하기',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
