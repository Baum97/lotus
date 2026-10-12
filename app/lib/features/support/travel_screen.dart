import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

/// Ziele für den Reisemodus. Bewusst eine feste Liste statt Geocoding-Dienst –
/// so verlässt kein Suchbegriff die App.
const travelCities = <String, (double, double)>{
  'Augsburg': (48.37, 10.90),
  'Berlin': (52.52, 13.40),
  'Bremen': (53.08, 8.80),
  'Dresden': (51.05, 13.74),
  'Düsseldorf': (51.23, 6.78),
  'Frankfurt am Main': (50.11, 8.68),
  'Freiburg im Breisgau': (47.99, 7.84),
  'Hamburg': (53.55, 9.99),
  'Hannover': (52.37, 9.73),
  'Heidelberg': (49.40, 8.67),
  'Karlsruhe': (49.01, 8.40),
  'Köln': (50.94, 6.96),
  'Konstanz': (47.66, 9.18),
  'Leipzig': (51.34, 12.37),
  'Mannheim': (49.49, 8.47),
  'München': (48.14, 11.58),
  'Münster': (51.96, 7.63),
  'Nürnberg': (49.45, 11.08),
  'Stuttgart': (48.78, 9.18),
  'Tübingen': (48.52, 9.06),
  'Ulm': (48.40, 9.99),
  'Wien': (48.21, 16.37),
  'Zürich': (47.38, 8.54),
};

class TravelScreen extends ConsumerStatefulWidget {
  const TravelScreen({super.key});

  @override
  ConsumerState<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends ConsumerState<TravelScreen> {
  String? _city;
  double _days = 14;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(myStatusProvider).value;
    final api = ref.read(apiProvider);
    final materialL = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.travelTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.travelIntro),
          const SizedBox(height: 24),
          if (status?.travelCity != null) ...[
            InfoBanner(
              text: l.travelActive(status!.travelCity!, materialL.formatMediumDate(status.travelUntil!)),
              icon: Icons.flight_takeoff,
            ),
            const SizedBox(height: 16),
            AsyncButton(
              outlined: true,
              label: l.travelEnd,
              onPressed: () async {
                await api.clearTravelLocation();
                ref.invalidate(myStatusProvider);
              },
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              initialValue: _city,
              decoration: InputDecoration(labelText: l.travelCity),
              items: [for (final city in travelCities.keys) DropdownMenuItem(value: city, child: Text(city))],
              onChanged: (value) => setState(() => _city = value),
            ),
            const SizedBox(height: 24),
            Text(l.travelDays(_days.round())),
            Slider(
              value: _days,
              min: 1,
              max: 30,
              divisions: 29,
              semanticFormatterCallback: (value) => l.travelDays(value.round()),
              onChanged: (value) => setState(() => _days = value),
            ),
            const SizedBox(height: 16),
            AsyncButton(
              label: l.travelStart,
              icon: Icons.flight_takeoff,
              onPressed: _city == null
                  ? null
                  : () async {
                      final (lat, lon) = travelCities[_city]!;
                      await api.setTravelLocation(lat: lat, lon: lon, city: _city!, days: _days.round());
                      ref.invalidate(myStatusProvider);
                    },
            ),
          ],
        ],
      ),
    );
  }
}
