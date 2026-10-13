import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers.dart';
import '../../widgets/common.dart';
import '../me/verification_screen.dart';
import '../profile/profile_view.dart';

enum _ChatAction { profile, end, block, report }

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.match});

  final MatchSummary match;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  MatchSummary get match => widget.match;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(apiProvider).sendMessage(match.matchId, text);
      _input.clear();
      ref.invalidate(matchesProvider);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _leave() {
    ref.invalidate(matchesProvider);
    ref.invalidate(myStatusProvider);
    Navigator.pop(context);
  }

  Future<void> _onAction(_ChatAction action) async {
    final l = AppLocalizations.of(context);
    final api = ref.read(apiProvider);
    switch (action) {
      case _ChatAction.profile:
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => _OtherProfileScreen(userId: match.otherUser, name: match.displayName),
          ),
        );
      case _ChatAction.end:
        final goodbye = await showDialog<String>(context: context, builder: (_) => const _EndChatDialog());
        if (goodbye == null) return;
        try {
          await api.closeMatch(match.matchId, goodbye: goodbye);
          _leave();
        } catch (e) {
          if (mounted) showError(context, e);
        }
      case _ChatAction.block:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l.blockTitle(match.displayName)),
            content: Text(l.blockBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.block)),
            ],
          ),
        );
        if (confirmed != true) return;
        try {
          await api.block(match.otherUser);
          _leave();
        } catch (e) {
          if (mounted) showError(context, e);
        }
      case _ChatAction.report:
        final sent = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => ReportSheet(userId: match.otherUser, name: match.displayName),
        );
        if (sent == true && mounted) showMessage(context, l.reportSent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = ref.read(apiProvider).currentUserId;
    final status = ref.watch(myStatusProvider).value;
    final messages = ref.watch(chatMessagesProvider(match.matchId));
    final canWrite = match.state == MatchState.active && (status?.verified ?? false);

    Widget? banner;
    if (match.state == MatchState.closed) {
      banner = InfoBanner(text: l.chatClosedBanner);
    } else if (match.state == MatchState.queued) {
      banner = InfoBanner(text: l.chatQueuedBanner, icon: Icons.hourglass_empty);
    } else if (status != null && !status.verified) {
      banner = InfoBanner(
        text: l.verifyToChat,
        icon: Icons.verified_outlined,
        action: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const VerificationScreen())),
          child: Text(l.verifyNow),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(child: Text(match.displayName)),
            if (match.verified) ...[const SizedBox(width: 6), const VerifiedBadge(small: true)],
          ],
        ),
        actions: [
          PopupMenuButton<_ChatAction>(
            onSelected: _onAction,
            itemBuilder: (_) => [
              PopupMenuItem(value: _ChatAction.profile, child: Text(l.viewProfile)),
              if (match.state != MatchState.closed) PopupMenuItem(value: _ChatAction.end, child: Text(l.endChat)),
              PopupMenuItem(value: _ChatAction.block, child: Text(l.block)),
              PopupMenuItem(value: _ChatAction.report, child: Text(l.report)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (banner != null) Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: banner),
            Expanded(
              child: messages.when(
                loading: () => const LoadingView(),
                error: (e, _) =>
                    ErrorView(error: e, onRetry: () => ref.invalidate(chatMessagesProvider(match.matchId))),
                data: (messages) => messages.isEmpty
                    ? EmptyState(icon: Icons.waving_hand_outlined, title: l.chatNoMessages)
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (_, i) {
                          final message = messages[messages.length - 1 - i];
                          return _Bubble(message: message, mine: message.senderId == me);
                        },
                      ),
              ),
            ),
            if (canWrite)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 5,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(hintText: l.messageHint, counterText: ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(onPressed: _sending ? null : _send, icon: const Icon(Icons.send)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);
    // Warnungen nur bei Nachrichten der anderen Person
    final warning = mine
        ? null
        : switch (message.safetyFlag) {
            SafetyFlag.money => l.safetyMoney,
            SafetyFlag.link => l.safetyLink,
            SafetyFlag.offPlatform => l.safetyOffPlatform,
            null => null,
          };
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                decoration: BoxDecoration(
                  color: mine ? scheme.primary : scheme.surfaceContainerLowest,
                  border: mine ? null : Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(mine ? 18 : 4),
                    bottomRight: Radius.circular(mine ? 4 : 18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      message.body,
                      style: TextStyle(color: mine ? scheme.onPrimary : scheme.onSurface, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: (mine ? scheme.onPrimary : scheme.onSurfaceVariant).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (warning != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: InfoBanner(text: warning, icon: Icons.shield_outlined, warning: true),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndChatDialog extends StatefulWidget {
  const _EndChatDialog();

  @override
  State<_EndChatDialog> createState() => _EndChatDialogState();
}

class _EndChatDialogState extends State<_EndChatDialog> {
  late final _goodbye = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _goodbye.text = AppLocalizations.of(context).goodbyeDefault;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _goodbye.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.endChatTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.endChatBody),
          const SizedBox(height: 16),
          TextField(
            controller: _goodbye,
            maxLines: 4,
            minLines: 2,
            decoration: InputDecoration(labelText: l.goodbyeLabel),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _goodbye.text), child: Text(l.endChat)),
      ],
    );
  }
}

/// Meldung mit Grund und optionalen Details.
class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({super.key, required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  ReportReason? _reason;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l, ReportReason reason) => switch (reason) {
    ReportReason.fake => l.reportReasonFake,
    ReportReason.scam => l.reportReasonScam,
    ReportReason.harassment => l.reportReasonHarassment,
    ReportReason.inappropriate => l.reportReasonInappropriate,
    ReportReason.underage => l.reportReasonUnderage,
    ReportReason.other => l.reportReasonOther,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.reportTitle(widget.name), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value),
              child: Column(
                children: [
                  for (final reason in ReportReason.values)
                    RadioListTile<ReportReason>(
                      contentPadding: EdgeInsets.zero,
                      value: reason,
                      title: Text(_label(l, reason)),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _details,
              maxLines: 3,
              maxLength: 1000,
              decoration: InputDecoration(labelText: l.reportDetails),
            ),
            const SizedBox(height: 8),
            AsyncButton(
              label: l.reportSend,
              onPressed: _reason == null
                  ? null
                  : () async {
                      await ref.read(apiProvider).report(widget.userId, _reason!, details: _details.text);
                      if (context.mounted) Navigator.pop(context, true);
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherProfileScreen extends ConsumerWidget {
  const _OtherProfileScreen({required this.userId, required this.name});

  final String userId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final profile = ref.watch(fullProfileProvider(userId));
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: profile.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(fullProfileProvider(userId))),
        data: (profile) => profile == null
            ? EmptyState(icon: Icons.person_off_outlined, title: l.errorProfileNotAvailable)
            : ProfileView(profile: profile),
      ),
    );
  }
}
