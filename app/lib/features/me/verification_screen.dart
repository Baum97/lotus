import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Gesten-Selfie aufnehmen; in der Beta prüft ein Admin das Selfie manuell.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  late Future<VerificationRequest> _request = ref.read(apiProvider).startVerification();

  Future<void> _takeSelfie(VerificationRequest request) async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1280,
      imageQuality: 85,
    );
    if (photo == null) return;
    await ref.read(apiProvider).submitVerification(request.id, await photo.readAsBytes());
    ref.invalidate(myStatusProvider);
    setState(() => _request = ref.read(apiProvider).startVerification());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.verificationTitle)),
      body: FutureBuilder<VerificationRequest>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              onRetry: () => setState(() => _request = ref.read(apiProvider).startVerification()),
            );
          }
          if (!snapshot.hasData) return const LoadingView();
          final request = snapshot.data!;
          if (request.status == VerificationStatus.pending) {
            return EmptyState(icon: Icons.hourglass_empty, title: l.verificationSubmitted);
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Icon(Icons.front_hand_outlined, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(request.gesture, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(l.verificationIntro, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AsyncButton(label: l.takeSelfie, icon: Icons.photo_camera_front, onPressed: () => _takeSelfie(request)),
            ]),
          );
        },
      ),
    );
  }
}
