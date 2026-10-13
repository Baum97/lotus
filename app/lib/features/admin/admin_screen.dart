import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';

final _pendingVerificationsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(apiProvider).adminPendingVerifications(),
);
final _openReportsProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).adminOpenReports());
final _recentPhotosProvider = FutureProvider.autoDispose((ref) => ref.watch(apiProvider).adminRecentPhotos());

/// Signierte URLs für Dateien in einem privaten Bucket (Admins dürfen alle lesen).
/// Schlüssel ist "bucket|pfad1|pfad2…" – ein String, damit der Provider stabil bleibt
/// (Listen sind nie gleich und würden bei jedem Neuzeichnen neu laden).
final _signedUrlsProvider = FutureProvider.autoDispose.family<Map<String, String>, String>((ref, key) {
  final parts = key.split('|');
  return ref.watch(apiProvider).signedUrls(parts.first, parts.skip(1).toList());
});

String _urlKey(String bucket, Iterable<String> paths) => [bucket, ...paths].join('|');

/// Admin-Bereich für die Beta: Selfies prüfen, Meldungen bearbeiten, Fotos moderieren.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.adminTitle),
          actions: [
            IconButton(
              tooltip: l.adminGrantPlus,
              icon: const Icon(Icons.spa_outlined),
              onPressed: () => showDialog<void>(context: context, builder: (_) => const _GrantPlusDialog()),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l.adminVerifications),
              Tab(text: l.adminReports),
              Tab(text: l.adminPhotos),
            ],
          ),
        ),
        body: const TabBarView(children: [_VerificationsTab(), _ReportsTab(), _PhotosTab()]),
      ),
    );
  }
}

/// Beta: Lotus Plus kostenlos an Tester:innen vergeben (30 Tage).
class _GrantPlusDialog extends ConsumerStatefulWidget {
  const _GrantPlusDialog();

  @override
  ConsumerState<_GrantPlusDialog> createState() => _GrantPlusDialogState();
}

class _GrantPlusDialogState extends ConsumerState<_GrantPlusDialog> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.adminGrantPlus),
      content: TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: l.adminGrantPlusHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        AsyncButton(
          label: l.save,
          onPressed: () async {
            final until = await ref.read(apiProvider).adminGrantPlus(_email.text);
            if (!context.mounted) return;
            Navigator.pop(context);
            showMessage(context, l.adminGrantPlusDone(MaterialLocalizations.of(context).formatMediumDate(until)));
          },
        ),
      ],
    );
  }
}

class _AsyncList<T> extends ConsumerWidget {
  const _AsyncList({required this.provider, required this.itemBuilder});

  final FutureProvider<List<T>> provider;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return ref
        .watch(provider)
        .when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(provider)),
          data: (items) => items.isEmpty
              ? EmptyState(icon: Icons.check_circle_outline, title: l.adminNothing)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) => itemBuilder(context, items[i]),
                ),
        );
  }
}

class _VerificationsTab extends ConsumerWidget {
  const _VerificationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiProvider);
    return _AsyncList<PendingVerification>(
      provider: _pendingVerificationsProvider,
      itemBuilder: (context, v) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(v.displayName, style: Theme.of(context).textTheme.titleLarge),
              Text(l.gestureLabel(v.gesture)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LabeledImages(label: l.selfieLabel, bucket: 'selfies', paths: [v.selfiePath]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _LabeledImages(label: l.profilePhotosLabel, bucket: 'photos', paths: v.photoPaths),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AsyncButton(
                      outlined: true,
                      label: l.reject,
                      onPressed: () async {
                        await api.adminReviewVerification(v.requestId, approve: false);
                        ref.invalidate(_pendingVerificationsProvider);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AsyncButton(
                      label: l.approve,
                      onPressed: () async {
                        await api.adminReviewVerification(v.requestId, approve: true);
                        ref.invalidate(_pendingVerificationsProvider);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledImages extends ConsumerWidget {
  const _LabeledImages({required this.label, required this.bucket, required this.paths});

  final String label;
  final String bucket;
  final List<String> paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urls = ref.watch(_signedUrlsProvider(_urlKey(bucket, paths))).value ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final path in paths) SizedBox(width: 96, child: RoundedPhoto(url: urls[path], radius: 12))],
        ),
      ],
    );
  }
}

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiProvider);
    final theme = Theme.of(context);

    Future<void> resolve(AdminReport report, TrustStatus? status) async {
      await api.adminResolveReport(report.reportId, status: status);
      ref.invalidate(_openReportsProvider);
    }

    String reason(ReportReason r) => switch (r) {
      ReportReason.fake => l.reportReasonFake,
      ReportReason.scam => l.reportReasonScam,
      ReportReason.harassment => l.reportReasonHarassment,
      ReportReason.inappropriate => l.reportReasonInappropriate,
      ReportReason.underage => l.reportReasonUnderage,
      ReportReason.other => l.reportReasonOther,
    };

    return _AsyncList<AdminReport>(
      provider: _openReportsProvider,
      itemBuilder: (context, r) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${r.reportedName} · ${reason(r.reason)}', style: theme.textTheme.titleMedium),
              Text(l.reportedBy(r.reporterName), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              if (r.details != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('„${r.details}“')),
              const SizedBox(height: 8),
              Text(l.reportsAgainst(r.reportsAgainstUser), style: theme.textTheme.bodySmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AsyncButton(outlined: true, label: l.dismiss, onPressed: () => resolve(r, null)),
                  AsyncButton(outlined: true, label: l.restrict, onPressed: () => resolve(r, TrustStatus.restricted)),
                  AsyncButton(label: l.suspend, onPressed: () => resolve(r, TrustStatus.suspended)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotosTab extends ConsumerWidget {
  const _PhotosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiProvider);
    final photos = ref.watch(_recentPhotosProvider);
    return photos.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_recentPhotosProvider)),
      data: (photos) {
        if (photos.isEmpty) return EmptyState(icon: Icons.check_circle_outline, title: l.adminNothing);
        final urls = ref.watch(_signedUrlsProvider(_urlKey('photos', photos.map((p) => p.storagePath)))).value ?? {};
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.58,
          ),
          itemCount: photos.length,
          itemBuilder: (context, i) {
            final photo = photos[i];
            Future<void> moderate(bool approve) async {
              await api.adminSetPhotoModeration(photo.photoId, approve: approve);
              ref.invalidate(_recentPhotosProvider);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundedPhoto(url: urls[photo.storagePath], radius: 12),
                const SizedBox(height: 6),
                Text(photo.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    IconButton(
                      tooltip: l.reject,
                      icon: const Icon(Icons.block),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => moderate(false),
                    ),
                    const Spacer(),
                    IconButton(tooltip: l.approve, icon: const Icon(Icons.check), onPressed: () => moderate(true)),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
