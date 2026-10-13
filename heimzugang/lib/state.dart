import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'plan.dart';

/// Hält Profil und Fortschritt. Alles bleibt lokal auf dem Gerät.
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    final roh = _prefs.getString(_profilKey);
    if (roh != null) {
      try {
        _profil = Profil.fromJson(jsonDecode(roh) as Map<String, Object?>);
      } on Object {
        // Unlesbares Profil (z. B. nach Umbenennung einer Option): neu einrichten lassen.
        _prefs.remove(_profilKey);
      }
    }
    _erledigt = {...?_prefs.getStringList(_erledigtKey)};
    _notizen = {
      for (final e in (jsonDecode(_prefs.getString(_notizenKey) ?? '{}') as Map).entries)
        e.key as String: e.value as String,
    };
  }

  static const _profilKey = 'profil';
  static const _erledigtKey = 'erledigt';
  static const _notizenKey = 'notizen';

  final SharedPreferences _prefs;
  Profil? _profil;
  Set<String> _erledigt = {};
  Map<String, String> _notizen = {};

  Profil? get profil => _profil;
  List<Abschnitt> get plan => _profil == null ? const [] : erstellePlan(_profil!);

  bool istErledigt(String schrittId) => _erledigt.contains(schrittId);

  /// Eigene Notizen wie IP-Adressen oder Gerätenamen (Schlüssel siehe [Notiz]).
  String notiz(String key) => _notizen[key] ?? '';

  ({int erledigt, int gesamt}) fortschritt([Abschnitt? nur]) {
    final schritte = [
      for (final a in nur == null ? plan : [nur]) ...a.schritte,
    ];
    return (erledigt: schritte.where((s) => _erledigt.contains(s.id)).length, gesamt: schritte.length);
  }

  Future<void> setzeProfil(Profil p) async {
    _profil = p;
    notifyListeners();
    await _prefs.setString(_profilKey, jsonEncode(p.toJson()));
  }

  Future<void> setzeErledigt(String schrittId, bool erledigt) async {
    erledigt ? _erledigt.add(schrittId) : _erledigt.remove(schrittId);
    notifyListeners();
    await _prefs.setStringList(_erledigtKey, _erledigt.toList());
  }

  Future<void> setzeNotiz(String key, String wert) async {
    wert.trim().isEmpty ? _notizen.remove(key) : _notizen[key] = wert.trim();
    notifyListeners();
    await _prefs.setString(_notizenKey, jsonEncode(_notizen));
  }

  /// Löscht alles, was die App gespeichert hat.
  Future<void> zuruecksetzen() async {
    _profil = null;
    _erledigt = {};
    _notizen = {};
    notifyListeners();
    await _prefs.clear();
  }
}

/// Feste Notizfelder, die der Verbindungstest vorschlägt.
enum Notiz {
  heimIp('Heimnetz-IP des Heimgeräts', 'z. B. 192.168.178.20'),
  vpnIp('Adresse über VPN/Tailscale', 'z. B. 100.101.102.103'),
  dyndns('MyFRITZ!/DynDNS-Adresse', 'z. B. xyz.myfritz.net'),
  freigabe('Name der Freigabe', 'z. B. Daten');

  const Notiz(this.label, this.hinweis);
  final String label;
  final String hinweis;
}
