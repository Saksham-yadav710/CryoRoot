import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryoroots/models/crop_profile.dart';
import 'package:cryoroots/services/mock/crop_profiles_data.dart';
import 'package:cryoroots/services/crop/crop_condition_lookup_service.dart';
import 'package:cryoroots/state/produce_providers.dart';
import 'package:cryoroots/features/produce/widgets/crop_autocomplete_selector.dart';

void main() {
  group('Enormous Crop Profiles Catalog Tests', () {
    test('Catalog contains comprehensive list of 50+ crops', () {
      final profiles = CropProfilesData.getProfiles();
      expect(profiles.length, greaterThanOrEqualTo(50));
    });

    test('All crops have scientifically consistent parameters', () {
      final profiles = CropProfilesData.getProfiles();
      for (final crop in profiles) {
        expect(crop.id.isNotEmpty, isTrue, reason: 'Empty ID in ${crop.name}');
        expect(crop.name.isNotEmpty, isTrue);
        expect(crop.category.isNotEmpty, isTrue);
        expect(crop.optimalTempMin, lessThanOrEqualTo(crop.optimalTempMax),
            reason: '${crop.name}: min temp must be <= max temp');
        expect(
            crop.optimalHumidityMin, lessThanOrEqualTo(crop.optimalHumidityMax),
            reason: '${crop.name}: min humidity must be <= max humidity');
        expect(crop.optimalHumidityMin, greaterThanOrEqualTo(50.0),
            reason: '${crop.name}: humidity should be >= 50%');
        expect(crop.optimalHumidityMax, lessThanOrEqualTo(100.0),
            reason: '${crop.name}: humidity should be <= 100%');
        expect(crop.maxStorageDays, greaterThan(0),
            reason: '${crop.name}: maxStorageDays must be > 0');
        expect(crop.chillingInjuryTemp, lessThan(crop.optimalTempMax),
            reason:
                '${crop.name}: chilling injury threshold must be below optimal temp max');
        expect(crop.defaultPricePerKg, greaterThan(0),
            reason: '${crop.name}: price must be positive');
        expect(crop.storageAdvice.isNotEmpty, isTrue,
            reason: '${crop.name}: advice must not be empty');
      }
    });

    test('Aliases and regional lookups resolve correctly', () {
      final profiles = CropProfilesData.getProfiles();

      // Search for "Aloo" or "Alu"
      final potato = profiles.firstWhere(
        (c) => c.aliases.any((a) => a.toLowerCase() == 'aloo'),
      );
      expect(potato.name.toLowerCase().contains('potato'), isTrue);

      // Search for "Tamatar"
      final tomato = profiles.firstWhere(
        (c) => c.aliases.any((a) => a.toLowerCase() == 'tamatar'),
      );
      expect(tomato.name.toLowerCase().contains('tomato'), isTrue);

      // Search for "Palak"
      final palak = profiles.firstWhere(
        (c) => c.aliases.any((a) => a.toLowerCase() == 'palak'),
      );
      expect(palak.name.toLowerCase().contains('spinach'), isTrue);
    });
  });

  group('Real-Time Crop Condition Lookup Service Tests', () {
    test('Correctly deduces conditions for novel leafy green crop', () async {
      final result = await CropConditionLookupService.fetchConditionsForCrop(
          'Sorrel Leaves');
      expect(result.name, 'Sorrel Leaves');
      expect(result.category, contains('Leafy'));
      expect(result.optimalTempMin, lessThanOrEqualTo(1.0));
      expect(result.optimalTempMax, lessThanOrEqualTo(3.0));
      expect(result.optimalHumidityMin, greaterThanOrEqualTo(90.0));
      expect(result.isCustom, isTrue);
    });

    test('Correctly deduces dry conditions for allium crop', () async {
      final result = await CropConditionLookupService.fetchConditionsForCrop(
          'Spring Leek Onion');
      expect(result.category, 'Allium');
      expect(result.optimalHumidityMax, lessThanOrEqualTo(75.0),
          reason: 'Alliums must have dry RH <= 75% to prevent neck rot');
      expect(result.optimalTempMin, lessThanOrEqualTo(1.0));
    });

    test('Correctly identifies cucurbit chilling sensitivity', () async {
      final result = await CropConditionLookupService.fetchConditionsForCrop(
          'Yellow Zucchini Squash');
      expect(result.category, contains('Cucurbit'));
      expect(result.chillingInjuryTemp, greaterThanOrEqualTo(7.0),
          reason: 'Cucurbits suffer chilling injury below 7°C');
      expect(result.optimalTempMin, greaterThanOrEqualTo(9.0));
    });

    test('Correctly estimates mushroom storage', () async {
      final result = await CropConditionLookupService.fetchConditionsForCrop(
          'Shiitake Mushroom Fungi');
      expect(result.category, contains('Mushroom'));
      expect(result.optimalTempMin, 0.0);
      expect(result.maxStorageDays, lessThanOrEqualTo(10));
    });
  });

  group('Custom Crop State & Riverpod Integration Tests', () {
    test(
        'Adding custom crop updates userCustomCropsProvider and cropProfilesProvider',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialProfiles = container.read(cropProfilesProvider);
      final initialCount = initialProfiles.length;

      const newCrop = CropProfile(
        id: 'CUSTOM-DRAGON-FRUIT-123',
        name: 'Purple Dragon Fruit',
        category: 'Tropical Fruit',
        iconEmoji: '🐉',
        optimalTempMin: 10.0,
        optimalTempMax: 12.0,
        optimalHumidityMin: 85.0,
        optimalHumidityMax: 90.0,
        maxStorageDays: 21,
        defaultPricePerKg: 180.0,
        chillingInjuryTemp: 7.0,
        storageAdvice: 'Store at 10°C - 12°C with good air circulation.',
        isCustom: true,
      );

      container.read(userCustomCropsProvider.notifier).addCustomCrop(newCrop);

      final updatedProfiles = container.read(cropProfilesProvider);
      expect(updatedProfiles.length, initialCount + 1);
      expect(updatedProfiles.first.name, 'Purple Dragon Fruit');
      expect(updatedProfiles.first.isCustom, isTrue);
    });
  });

  group('CropAutocompleteSelector Widget Tests', () {
    testWidgets('Renders input field and filters crops as letters are typed',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final profiles = CropProfilesData.getProfiles();
      CropProfile? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CropAutocompleteSelector(
                cropProfiles: profiles,
                selectedCrop: selected,
                onCropSelected: (c) => selected = c,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CropAutocompleteSelector), findsOneWidget);
      expect(find.text('Search or Select Vegetable / Crop'), findsOneWidget);

      // Tap to open dropdown
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      // Dropdown overlay should appear
      expect(find.textContaining('ALL AVAILABLE VEGETABLES'), findsOneWidget);

      // Type "pota" to filter
      await tester.enterText(find.byType(TextFormField), 'pota');
      await tester.pumpAndSettle();

      // Should show matching Potato options
      expect(find.textContaining('MATCHING CROPS'), findsOneWidget);
      expect(find.textContaining('Potato (Table Consumption)'), findsOneWidget);

      // Select Potato
      await tester.tap(find.textContaining('Potato (Table Consumption)').first);
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.name, contains('Potato'));
    });
  });
}
