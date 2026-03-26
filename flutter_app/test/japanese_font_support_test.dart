import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Verifies that the Japanese ARB file contains proper CJK characters
/// (Hiragana, Katakana, Kanji) and that the localization infrastructure
/// is correctly configured for Japanese text rendering.
///
/// Since Flutter widget tests use a test font that replaces all glyphs with
/// rectangles, full visual rendering verification requires manual testing on
/// actual devices. These tests validate the data layer: that the Japanese
/// translations are present, non-empty, and contain the expected character sets.
void main() {
  late Map<String, dynamic> enArb;
  late Map<String, dynamic> jaArb;

  setUpAll(() {
    final enFile = File('lib/l10n/app_en.arb');
    final jaFile = File('lib/l10n/app_ja.arb');
    enArb = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
    jaArb = json.decode(jaFile.readAsStringSync()) as Map<String, dynamic>;
  });

  group('Japanese ARB file CJK character verification', () {
    test('Japanese ARB contains Hiragana characters', () {
      final allValues = _translationValues(jaArb);
      final hasHiragana = allValues.any(
        (v) => v.runes.any((r) => r >= 0x3040 && r <= 0x309F),
      );
      expect(hasHiragana, isTrue,
          reason: 'Japanese translations should contain Hiragana characters');
    });

    test('Japanese ARB contains Katakana characters', () {
      final allValues = _translationValues(jaArb);
      final hasKatakana = allValues.any(
        (v) => v.runes.any((r) => r >= 0x30A0 && r <= 0x30FF),
      );
      expect(hasKatakana, isTrue,
          reason: 'Japanese translations should contain Katakana characters');
    });

    test('Japanese ARB contains Kanji characters', () {
      final allValues = _translationValues(jaArb);
      final hasKanji = allValues.any(
        (v) => v.runes.any((r) => r >= 0x4E00 && r <= 0x9FFF),
      );
      expect(hasKanji, isTrue,
          reason: 'Japanese translations should contain Kanji (CJK Unified Ideographs)');
    });
  });

  group('Japanese translation key completeness', () {
    test('Japanese ARB has all keys from English template', () {
      final enKeys = _translationKeys(enArb);
      final jaKeys = _translationKeys(jaArb);
      final missing = enKeys.difference(jaKeys);
      expect(missing, isEmpty,
          reason: 'Japanese ARB is missing keys: $missing');
    });

    test('All Japanese translations are non-empty strings', () {
      for (final entry in jaArb.entries) {
        if (entry.key.startsWith('@')) continue;
        expect(entry.value, isA<String>(),
            reason: 'Key "${entry.key}" should be a String');
        expect((entry.value as String).trim(), isNotEmpty,
            reason: 'Key "${entry.key}" should not be empty');
      }
    });
  });

  group('Japanese translations for key UI screens', () {
    test('Tab labels are translated to Japanese', () {
      expect(jaArb['searchTab'], '検索');
      expect(jaArb['resultsTab'], '結果');
      expect(jaArb['guideTab'], 'ガイド');
      expect(jaArb['bedwarsTab'], 'ベッドウォーズ');
      expect(jaArb['updatesTab'], '更新情報');
    });

    test('App title is translated to Japanese', () {
      expect(jaArb['appTitle'], contains('鉱石'));
      expect(jaArb['appTitle'], contains('ファインダー'));
    });

    test('Error messages are translated to Japanese', () {
      expect(jaArb['errorEmptySeed'], isNotEmpty);
      expect(jaArb['errorEmptySeed'], isNot(equals(enArb['errorEmptySeed'])),
          reason: 'Japanese error message should differ from English');
      expect(jaArb['errorEnableSearchType'], isNotEmpty);
      expect(jaArb['errorSelectStructure'], isNotEmpty);
      expect(jaArb['errorSelectOre'], isNotEmpty);
    });

    test('Guide content is translated to Japanese', () {
      expect(jaArb['guideDiamondTitle'], isNotEmpty);
      expect(jaArb['guideGoldTitle'], isNotEmpty);
      expect(jaArb['guideNetheriteTitle'], isNotEmpty);
      expect(jaArb['guideIronTitle'], isNotEmpty);
      expect(jaArb['guideRedstoneTitle'], isNotEmpty);
      expect(jaArb['guideCoalTitle'], isNotEmpty);
      expect(jaArb['guideLapisTitle'], isNotEmpty);
      expect(jaArb['guideStructureTitle'], isNotEmpty);
    });

    test('Bedwars guide content is translated to Japanese', () {
      expect(jaArb['bedwarsGameObjectiveTitle'], isNotEmpty);
      expect(jaArb['bedwarsBedDefenseTitle'], isNotEmpty);
      expect(jaArb['bedwarsCombatTipsTitle'], isNotEmpty);
    });

    test('About dialog content is translated to Japanese', () {
      expect(jaArb['aboutTitle'], isNotEmpty);
      expect(jaArb['aboutWhatTitle'], isNotEmpty);
      expect(jaArb['aboutSupportTitle'], isNotEmpty);
    });

    test('Release notes content is translated to Japanese', () {
      expect(jaArb['releaseNotesHeader'], isNotEmpty);
      expect(jaArb['releaseNotesBedwarsSection'], isNotEmpty);
    });
  });
}

/// Extracts translation keys (non-metadata) from an ARB map.
Set<String> _translationKeys(Map<String, dynamic> arb) {
  return arb.keys.where((k) => !k.startsWith('@')).toSet();
}

/// Extracts all string translation values from an ARB map.
List<String> _translationValues(Map<String, dynamic> arb) {
  return arb.entries
      .where((e) => !e.key.startsWith('@') && e.value is String)
      .map((e) => e.value as String)
      .toList();
}
