import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../services/store.dart';
import '../../widgets/common.dart';
import 'stats_screen.dart';
import 'travel_screen.dart';

/// Lotus Plus (Komfort-Abo) und Spenden. Nichts davon beeinflusst das Matching.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  StreamSubscription<StoreEvent>? _events;

  @override
  void initState() {
    super.initState();
    _events = ref.read(storeProvider).events.listen(handleStoreEvent(context, ref));
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(myStatusProvider).value;
    final products = ref.watch(storeProductsProvider).value ?? const <String, ProductDetails>{};
    final store = ref.read(storeProvider);
    final plus = products[StoreProducts.plus];
    final materialL = MaterialLocalizations.of(context);

    void open(Widget screen) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: Text(l.supportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.supportIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          if (products.isEmpty && !(status?.hasPlus ?? false)) ...[
            InfoBanner(text: l.storeUnavailable),
            const SizedBox(height: 20),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Icon(Icons.spa, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(l.plusTitle, style: theme.textTheme.titleLarge),
                  const Spacer(),
                  if (plus != null && !(status?.hasPlus ?? false))
                    Text(l.plusPerMonth(plus.price), style: theme.textTheme.titleSmall),
                ]),
                const SizedBox(height: 12),
                for (final (icon, text) in [
                  (Icons.flight_takeoff, l.plusFeatureTravel),
                  (Icons.insights_outlined, l.plusFeatureStats),
                  (Icons.balance, l.plusFeatureFair),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(icon, size: 20, color: theme.colorScheme.secondary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(text)),
                    ]),
                  ),
                const SizedBox(height: 12),
                if (status?.hasPlus ?? false) ...[
                  InfoBanner(
                    text: l.plusActiveUntil(materialL.formatMediumDate(status!.plusUntil!)),
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => open(const TravelScreen()),
                        icon: const Icon(Icons.flight_takeoff),
                        label: Text(l.travelTitle),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => open(const StatsScreen()),
                        icon: const Icon(Icons.insights_outlined),
                        label: Text(l.statsTitle),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Text(l.plusManageHint, style: theme.textTheme.bodySmall),
                ] else
                  AsyncButton(label: l.plusSubscribe, onPressed: plus == null ? null : () => store.buy(plus)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Icon(Icons.volunteer_activism_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(l.donateTitle, style: theme.textTheme.titleLarge),
                ]),
                const SizedBox(height: 8),
                Text(l.donateText),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final id in StoreProducts.donations)
                    if (products[id] != null)
                      AsyncButton(outlined: true, label: products[id]!.price, onPressed: () => store.buy(products[id]!)),
                ]),
              ]),
            ),
          ),
          if (products.isNotEmpty)
            TextButton(onPressed: store.restore, child: Text(l.restorePurchases)),
        ],
      ),
    );
  }
}

/// Reagiert auf Kauf-Ereignisse: Status neu laden und kurz Bescheid geben.
void Function(StoreEvent) handleStoreEvent(BuildContext context, WidgetRef ref) {
  return (event) {
    if (!context.mounted) return;
    final l = AppLocalizations.of(context);
    switch (event.type) {
      case StoreEventType.pending:
        showMessage(context, l.purchasePending);
      case StoreEventType.error:
        showMessage(context, l.purchaseFailed);
      case StoreEventType.success:
        ref.invalidate(myStatusProvider);
        if (event.productId != StoreProducts.plus) showMessage(context, l.donateThanks);
    }
  };
}
