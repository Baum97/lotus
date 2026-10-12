import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/lotus_api.dart';
import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../home/home_shell.dart';
import '../profile/profile_view.dart';

/// Profile nacheinander ansehen – so lange, bis die Likes des Tages aufgebraucht sind.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _queue = <ProfileSummary>[];
  Future<FullProfile>? _current;
  bool _loading = true;
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _refill();
  }

  LotusApi get _api => ref.read(apiProvider);

  Future<void> _refill() async {
    setState(() {
      _loading = _queue.isEmpty;
      _error = null;
    });
    try {
      final fresh = await _api.candidates();
      final known = _queue.map((p) => p.id).toSet();
      _queue.addAll(fresh.where((p) => !known.contains(p.id)));
      _showFirst();
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _showFirst() {
    _current = _queue.isEmpty ? null : _api.fullProfile(_queue.first);
  }

  Future<void> _advance() async {
    _queue.removeAt(0);
    ref.invalidate(myStatusProvider);
    setState(_showFirst);
    if (_queue.length < 3) await _refill();
  }

  Future<void> _decide(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      if (e is LotusException && e.key == 'profile_not_available') await _advance();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pass() => _decide(() async {
        await _api.pass(_queue.first.id);
        await _advance();
      });

  void _undo() => _decide(() async {
        final userId = await _api.undoLastPass();
        final summary = await _api.profileSummary(userId);
        ref.invalidate(myStatusProvider);
        if (summary != null) {
          _queue.removeWhere((p) => p.id == userId);
          _queue.insert(0, summary);
          setState(_showFirst);
        }
        if (mounted) showMessage(context, AppLocalizations.of(context).undoDone);
      });

  Future<void> _like(LikeTarget type, String targetId, String preview) async {
    final comment = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LikeSheet(preview: preview),
    );
    if (comment == null || !mounted) return;
    final person = _queue.first;
    await _decide(() async {
      final result = await _api.like(person.id, targetType: type, targetId: targetId, comment: comment);
      if (result.isMatch && mounted) {
        ref.invalidate(matchesProvider);
        await _showMatch(person.displayName, result.matchId!);
      }
      await _advance();
    });
  }

  Future<void> _showMatch(String name, String matchId) async {
    final l = AppLocalizations.of(context);
    final matches = await _api.matches();
    final queued = matches.any((m) => m.matchId == matchId && m.state == MatchState.queued);
    if (!mounted) return;
    final openChats = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const LotusLogo(size: 64),
        title: Text(l.matchTitle, textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.matchBody(name), textAlign: TextAlign.center),
          if (queued) ...[const SizedBox(height: 12), Text(l.matchQueued, textAlign: TextAlign.center)],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.keepDiscovering)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.openChats)),
        ],
      ),
    );
    if (openChats == true) ref.read(homeTabProvider.notifier).select(HomeTab.chats);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = ref.watch(myStatusProvider).value;
    final likesLeft = status?.likesRemaining ?? 0;

    Widget body;
    if (_loading) {
      body = const LoadingView();
    } else if (_error != null) {
      body = ErrorView(error: _error!, onRetry: _refill);
    } else if (_current == null) {
      body = likesLeft == 0
          ? EmptyState(icon: Icons.nightlight_outlined, title: l.likesUsedUpTitle, body: l.likesUsedUpBody)
          : EmptyState(
              icon: Icons.spa_outlined,
              title: l.noCandidatesTitle,
              body: l.noCandidatesBody,
              action: OutlinedButton(onPressed: _refill, child: Text(l.retry)),
            );
    } else {
      body = FutureBuilder<FullProfile>(
        key: ValueKey(_queue.first.id),
        future: _current,
        builder: (context, snapshot) {
          if (snapshot.hasError) return ErrorView(error: snapshot.error!, onRetry: () => setState(_showFirst));
          if (!snapshot.hasData) return const LoadingView();
          return ProfileView(profile: snapshot.data!, onLike: likesLeft > 0 && !_busy ? _like : null);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.tabDiscover),
        actions: [
          if (status != null) ...[
            Pill(icon: Icons.favorite, label: l.likesLeft(likesLeft)),
            IconButton(
              tooltip: l.undoButton(status.undosRemaining),
              onPressed: status.undosRemaining > 0 && !_busy ? _undo : null,
              icon: Badge.count(
                count: status.undosRemaining,
                isLabelVisible: status.undosRemaining > 0,
                child: const Icon(Icons.undo),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _current == null || _loading
          ? null
          : FloatingActionButton.extended(
              heroTag: 'pass',
              onPressed: _busy ? null : _pass,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              icon: const Icon(Icons.close),
              label: Text(l.pass),
            ),
    );
  }
}

/// Like bestätigen, optional mit Kommentar. Gibt den Kommentar zurück ('' = ohne).
class _LikeSheet extends StatefulWidget {
  const _LikeSheet({required this.preview});

  final String preview;

  @override
  State<_LikeSheet> createState() => _LikeSheetState();
}

class _LikeSheetState extends State<_LikeSheet> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.likeSheetTitle, style: theme.textTheme.titleLarge),
        if (widget.preview.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('„${widget.preview}“',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _comment,
          autofocus: true,
          maxLength: 300,
          maxLines: 3,
          minLines: 1,
          decoration: InputDecoration(hintText: l.likeCommentHint),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, _comment.text),
          icon: const Icon(Icons.favorite),
          label: Text(l.likeSend),
        ),
      ]),
    );
  }
}
