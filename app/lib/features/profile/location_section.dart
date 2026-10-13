import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Holt den ungefähren Standort (ca. 1 km genau) und speichert ihn.
Future<bool> updateLocation(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    if (context.mounted) showMessage(context, l.locationDenied);
    return false;
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
  );
  await ref.read(apiProvider).setLocation(position.latitude, position.longitude);
  ref.invalidate(myStatusProvider);
  if (context.mounted) showMessage(context, l.locationSaved);
  return true;
}

class LocationSection extends ConsumerWidget {
  const LocationSection({super.key, required this.hasLocation});

  final bool hasLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.place_outlined, size: 56, color: scheme.secondary),
        const SizedBox(height: 16),
        Text(l.locationHint, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (hasLocation)
          InfoBanner(text: l.locationSaved, icon: Icons.check_circle_outline)
        else
          AsyncButton(label: l.locationButton, icon: Icons.my_location, onPressed: () => updateLocation(context, ref)),
      ],
    );
  }
}
