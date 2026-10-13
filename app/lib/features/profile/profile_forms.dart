import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../l10n/gen/app_localizations.dart';

/// Bearbeitbarer Stand von Profil und Suchpräferenzen (Onboarding und "Profil bearbeiten").
class ProfileDraft {
  ProfileDraft();

  factory ProfileDraft.from(OwnProfile profile, MatchPreferences? preferences) {
    final draft = ProfileDraft()
      ..name = profile.displayName
      ..gender = profile.gender
      ..city = profile.city ?? ''
      ..bio = profile.bio ?? '';
    if (preferences != null) {
      draft
        ..interestedIn = {...preferences.interestedIn}
        ..intention = preferences.intention
        ..intentionPublic = preferences.intentionPublic
        ..ages = RangeValues(preferences.ageMin.toDouble(), preferences.ageMax.toDouble())
        ..distanceKm = preferences.maxDistanceKm.toDouble()
        ..children = preferences.children
        ..smoking = preferences.smoking
        ..lifestylePublic = preferences.lifestylePublic
        ..childrenDealbreaker = preferences.childrenDealbreaker
        ..smokingDealbreaker = preferences.smokingDealbreaker;
    }
    return draft;
  }

  String name = '';
  DateTime? birthdate;
  Gender? gender;
  String city = '';
  String bio = '';
  Set<Gender> interestedIn = {};
  Intention? intention;
  bool intentionPublic = true;
  RangeValues ages = const RangeValues(20, 45);
  double distanceKm = 50;
  ChildrenWish? children;
  Smoking? smoking;
  bool lifestylePublic = true;
  bool childrenDealbreaker = false;
  bool smokingDealbreaker = false;

  MatchPreferences toPreferences() => MatchPreferences(
        interestedIn: interestedIn,
        intention: intention!,
        intentionPublic: intentionPublic,
        ageMin: ages.start.round(),
        ageMax: ages.end.round(),
        maxDistanceKm: distanceKm.round(),
        children: children,
        smoking: smoking,
        lifestylePublic: lifestylePublic,
        childrenDealbreaker: childrenDealbreaker && children != null && children != ChildrenWish.open,
        smokingDealbreaker: smokingDealbreaker,
      );

  /// Gibt eine Fehlermeldung zurück, falls die Grundangaben unvollständig sind.
  String? validateBasics(AppLocalizations l, {required bool needsBirthdate}) {
    if (name.trim().isEmpty) return l.nameRequired;
    if (needsBirthdate && birthdate == null) return l.birthdateRequired;
    if (needsBirthdate && !isAdult(birthdate!)) return l.errorTooYoung;
    if (gender == null) return l.interestedInRequired;
    return null;
  }

  String? validatePreferences(AppLocalizations l) {
    if (interestedIn.isEmpty || intention == null) return l.interestedInRequired;
    return null;
  }

  static bool isAdult(DateTime birthdate) {
    final now = DateTime.now();
    final eighteenth = DateTime(birthdate.year + 18, birthdate.month, birthdate.day);
    return !eighteenth.isAfter(DateTime(now.year, now.month, now.day));
  }
}

String genderLabel(AppLocalizations l, Gender gender) => switch (gender) {
      Gender.woman => l.genderWoman,
      Gender.man => l.genderMan,
      Gender.diverse => l.genderDiverse,
    };

String intentionLabel(AppLocalizations l, Intention intention) => switch (intention) {
      Intention.relationship => l.intentionRelationship,
      Intention.openToRelationship => l.intentionOpen,
      Intention.unsure => l.intentionUnsure,
    };

String childrenLabel(AppLocalizations l, ChildrenWish value) => switch (value) {
      ChildrenWish.want => l.childrenWant,
      ChildrenWish.dontWant => l.childrenDontWant,
      ChildrenWish.open => l.childrenOpen,
      ChildrenWish.haveKids => l.childrenHave,
    };

String smokingLabel(AppLocalizations l, Smoking value) => switch (value) {
      Smoking.never => l.smokingNever,
      Smoking.sometimes => l.smokingSometimes,
      Smoking.regularly => l.smokingRegularly,
    };

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(text, style: theme.textTheme.titleMedium),
        if (hint != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(hint!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
      ]),
    );
  }
}

/// Name, Geburtsdatum (nur beim Anlegen), Geschlecht, Stadt, Über mich.
class BasicsSection extends StatefulWidget {
  const BasicsSection({super.key, required this.draft, required this.onChanged, required this.showBirthdate});

  final ProfileDraft draft;
  final VoidCallback onChanged;
  final bool showBirthdate;

  @override
  State<BasicsSection> createState() => _BasicsSectionState();
}

class _BasicsSectionState extends State<BasicsSection> {
  late final _name = TextEditingController(text: widget.draft.name);
  late final _city = TextEditingController(text: widget.draft.city);
  late final _bio = TextEditingController(text: widget.draft.bio);
  final _birthdate = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final birthdate = widget.draft.birthdate;
    _birthdate.text = birthdate == null ? '' : MaterialLocalizations.of(context).formatCompactDate(birthdate);
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _bio.dispose();
    _birthdate.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.draft.birthdate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (picked != null && mounted) {
      setState(() {
        widget.draft.birthdate = picked;
        _birthdate.text = MaterialLocalizations.of(context).formatCompactDate(picked);
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = widget.draft;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        maxLength: 40,
        decoration: InputDecoration(labelText: l.nameLabel, counterText: ''),
        onChanged: (value) => draft.name = value,
      ),
      if (widget.showBirthdate) ...[
        const SizedBox(height: 16),
        // Schreibgeschütztes Textfeld statt InkWell, damit Screenreader es als Eingabefeld erkennen
        TextField(
          controller: _birthdate,
          readOnly: true,
          onTap: _pickBirthdate,
          decoration: InputDecoration(
            labelText: l.birthdateLabel,
            helperText: l.birthdateHint,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
        ),
      ],
      _SectionLabel(l.genderLabel),
      Wrap(spacing: 8, children: [
        for (final gender in Gender.values)
          ChoiceChip(
            label: Text(genderLabel(l, gender)),
            selected: draft.gender == gender,
            onSelected: (_) {
              setState(() => draft.gender = gender);
              widget.onChanged();
            },
          ),
      ]),
      const SizedBox(height: 24),
      TextField(
        controller: _city,
        textCapitalization: TextCapitalization.words,
        maxLength: 60,
        decoration: InputDecoration(labelText: l.cityLabel, hintText: l.cityHint, counterText: ''),
        onChanged: (value) => draft.city = value,
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _bio,
        maxLines: 4,
        maxLength: 500,
        decoration: InputDecoration(labelText: l.bioLabel),
        onChanged: (value) => draft.bio = value,
      ),
    ]);
  }
}

/// Wen man kennenlernen möchte (privat), Dating-Ziel (Anzeige optional), Alter und Entfernung.
class PreferencesSection extends StatefulWidget {
  const PreferencesSection({super.key, required this.draft, required this.onChanged});

  final ProfileDraft draft;
  final VoidCallback onChanged;

  @override
  State<PreferencesSection> createState() => _PreferencesSectionState();
}

class _PreferencesSectionState extends State<PreferencesSection> {
  void _update(VoidCallback change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final draft = widget.draft;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SectionLabel(l.interestedInLabel, hint: l.interestedInHint),
      Wrap(spacing: 8, children: [
        for (final gender in Gender.values)
          FilterChip(
            label: Text(genderLabel(l, gender)),
            selected: draft.interestedIn.contains(gender),
            onSelected: (selected) => _update(() {
              selected ? draft.interestedIn.add(gender) : draft.interestedIn.remove(gender);
            }),
          ),
      ]),
      _SectionLabel(l.intentionLabel),
      RadioGroup<Intention>(
        groupValue: draft.intention,
        onChanged: (value) => _update(() => draft.intention = value),
        child: Column(children: [
          for (final intention in Intention.values)
            RadioListTile<Intention>(
              contentPadding: EdgeInsets.zero,
              value: intention,
              title: Text(intentionLabel(l, intention)),
            ),
        ]),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: draft.intentionPublic,
        title: Text(l.intentionPublicLabel),
        subtitle: Text(l.intentionPublicHint),
        onChanged: (value) => _update(() => draft.intentionPublic = value),
      ),
      _SectionLabel(l.ageRangeLabel(draft.ages.start.round(), draft.ages.end.round())),
      RangeSlider(
        values: draft.ages,
        min: 18,
        max: 99,
        divisions: 81,
        semanticFormatterCallback: (value) => '${value.round()}',
        onChanged: (values) => _update(() => draft.ages = values),
      ),
      _SectionLabel(l.distanceLabel(draft.distanceKm.round())),
      Slider(
        value: draft.distanceKm,
        min: 1,
        max: 150,
        divisions: 149,
        semanticFormatterCallback: (value) => '${value.round()} km',
        onChanged: (value) => _update(() => draft.distanceKm = value),
      ),
      // Optional: Kinderwunsch & Rauchen – erneutes Antippen hebt die Auswahl auf
      _SectionLabel(l.childrenLabel, hint: l.optionalHint),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final value in ChildrenWish.values)
          ChoiceChip(
            label: Text(childrenLabel(l, value)),
            selected: draft.children == value,
            onSelected: (selected) => _update(() => draft.children = selected ? value : null),
          ),
      ]),
      if (draft.children != null && draft.children != ChildrenWish.open)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: draft.childrenDealbreaker,
          title: Text(l.childrenDealbreaker),
          onChanged: (value) => _update(() => draft.childrenDealbreaker = value),
        ),
      _SectionLabel(l.smokingLabel, hint: l.optionalHint),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final value in Smoking.values)
          ChoiceChip(
            label: Text(smokingLabel(l, value)),
            selected: draft.smoking == value,
            onSelected: (selected) => _update(() => draft.smoking = selected ? value : null),
          ),
      ]),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: draft.smokingDealbreaker,
        title: Text(l.smokingDealbreaker),
        onChanged: (value) => _update(() => draft.smokingDealbreaker = value),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: draft.lifestylePublic,
        title: Text(l.lifestylePublicLabel),
        subtitle: Text(l.lifestylePublicHint),
        onChanged: (value) => _update(() => draft.lifestylePublic = value),
      ),
    ]);
  }
}
