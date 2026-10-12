/// Anbieterangaben für das Impressum (§ 5 DDG) – VOR dem ersten fremden Nutzer ausfüllen.
///
/// Pflicht für eine natürliche Person (kein Spielraum):
///  * vollständiger Vor- und Nachname (kein Künstlername, keine Abkürzung)
///  * ladungsfähige Anschrift: Straße, Hausnummer, PLZ, Ort – KEIN Postfach
///  * E-Mail-Adresse UND ein zweiter schneller Kontaktweg (Telefonnummer)
///  * USt-IdNr. / Wirtschafts-IdNr. nur, falls vorhanden – sonst leer lassen
///
/// Dieselben Angaben gehören in docs/IMPRESSUM.md (Web-Version für den Play Store).
class LegalInfo {
  static const name = '[Vorname Nachname]';
  static const street = '[Straße Hausnummer]';
  static const postalCodeCity = '[PLZ Ort]';
  static const country = 'Deutschland';
  static const email = '[kontakt@example.de]';
  static const phone = '[+49 …]';

  /// Nur angeben, wenn vorhanden (Kleinunternehmer ohne USt-IdNr.: leer lassen).
  static const vatId = '';

  /// Nur angeben, wenn vorhanden.
  static const economicId = '';

  /// true, sobald alle Pflichtangaben ausgefüllt sind.
  static bool get isComplete =>
      [name, street, postalCodeCity, email, phone].every((value) => value.isNotEmpty && !value.startsWith('['));
}
