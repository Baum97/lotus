import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config.dart';
import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Raster mit bis zu 6 Fotos; Hinzufügen aus der Galerie, Löschen per Tipp.
class PhotosEditor extends ConsumerStatefulWidget {
  const PhotosEditor({super.key});

  @override
  ConsumerState<PhotosEditor> createState() => _PhotosEditorState();
}

class _PhotosEditorState extends ConsumerState<PhotosEditor> {
  bool _uploading = false;

  Future<void> _add(int position) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await ref.read(apiProvider).uploadPhoto(await file.readAsBytes(), position);
      ref.invalidate(ownPhotosProvider);
      ref.invalidate(myStatusProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(Photo photo) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deletePhotoTitle),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiProvider).deletePhoto(photo);
      ref.invalidate(ownPhotosProvider);
      ref.invalidate(myStatusProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final photos = ref.watch(ownPhotosProvider);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.photosHint, style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        photos.when(
          loading: () => const SizedBox(height: 200, child: LoadingView()),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(ownPhotosProvider)),
          data: (photos) => GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 4 / 5,
            children: [
              for (var i = 0; i < AppConfig.maxPhotos; i++)
                if (i < photos.length)
                  GestureDetector(
                    onTap: () => _delete(photos[i]),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RoundedPhoto(url: photos[i].url, radius: 16),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: scheme.surface.withValues(alpha: 0.9),
                            child: Icon(Icons.close, size: 16, color: scheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (i == photos.length)
                  _AddTile(busy: _uploading, label: l.addPhoto, onTap: _uploading ? null : () => _add(i))
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.busy, required this.label, required this.onTap});

  final bool busy;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: busy
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: scheme.primary),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.primary, fontSize: 12),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
