import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Avatar circulaire réutilisable.
/// - Affiche la photo de profil si disponible, sinon les initiales.
/// - [editable] : affiche un bouton appareil photo pour changer la photo.
/// - [size] : diamètre du cercle (défaut 52).
class UserAvatar extends ConsumerStatefulWidget {
  final double size;
  final bool editable;
  final String? photoUrl;
  final String initials;
  final Gradient? gradient;

  const UserAvatar({
    super.key,
    this.size = 52,
    this.editable = false,
    required this.photoUrl,
    required this.initials,
    this.gradient,
  });

  @override
  ConsumerState<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends ConsumerState<UserAvatar> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final mime = file.name.toLowerCase().endsWith('.png')
          ? 'image/png'
          : file.name.toLowerCase().endsWith('.webp')
              ? 'image/webp'
              : 'image/jpeg';

      final ok = await ref.read(authProvider.notifier).uploadPhoto(base64, mime);
      if (mounted && !ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de mettre à jour la photo'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.photoUrl;

    final avatar = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: url == null
            ? (widget.gradient ?? AppColors.primaryGradient)
            : null,
        color: url != null ? AppColors.surfaceVariant : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                width: widget.size,
                height: widget.size,
                errorBuilder: (_, __, ___) => _initialsWidget(),
              )
            : _initialsWidget(),
      ),
    );

    if (!widget.editable) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _uploading ? null : _pickAndUpload,
            child: Container(
              width: widget.size * 0.36,
              height: widget.size * 0.36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: _uploading
                  ? const Padding(
                      padding: EdgeInsets.all(4),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: widget.size * 0.18,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initialsWidget() {
    return Center(
      child: Text(
        widget.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: widget.size * 0.33,
        ),
      ),
    );
  }
}
