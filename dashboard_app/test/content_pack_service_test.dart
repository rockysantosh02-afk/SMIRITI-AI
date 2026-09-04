import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:dashboard_app/features/games/services/content_pack_service.dart';
import 'package:dashboard_app/features/games/controllers/adaptive_difficulty_stub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContentPackService & Adaptive Difficulty Tests', () {
    late String jsonContent;

    setUpAll(() {
      final file = File('assets/games/content_pack.json');
      expect(file.existsSync(), isTrue, reason: 'assets/games/content_pack.json must exist');
      jsonContent = file.readAsStringSync();
    });

    test('Loads content_pack.json successfully and verifies all 7 games and tiers', () {
      final service = ContentPackService.instance;
      service.loadFromJsonString(jsonContent);
      expect(service.isLoaded, isTrue);

      final games = [
        'matching_image',
        'pick_correct',
        'number_game',
        'place_correctly',
        'find_difference',
        'draw_shape',
        'situation_match',
      ];

      for (final g in games) {
        for (int tier = 1; tier <= 5; tier++) {
          final items = service.getItems(g, tier);
          expect(
            items.length >= 8,
            isTrue,
            reason: 'Game $g at Tier $tier must have at least 8 items, found ${items.length}',
          );

          for (final item in items) {
            expect(item.id, isNotEmpty);
            expect(item.image, isNotEmpty);
            expect(item.prompt, isNotEmpty);
            expect(item.options, isNotEmpty);
            expect(item.correctIndex >= 0 && item.correctIndex < item.options.length, isTrue);
          }
        }
      }
    });

    test('generateRounds produces 5 rounds with preserved correctIndex after option shuffle', () {
      final service = ContentPackService.instance;
      service.loadFromJsonString(jsonContent);

      final rounds = service.generateRounds('matching_image', 1, count: 5);
      expect(rounds.length, equals(5));

      for (final r in rounds) {
        expect(r.options.length, greaterThanOrEqualTo(2));
        expect(r.correctIndex >= 0 && r.correctIndex < r.options.length, isTrue);
      }
    });

    test('AdaptiveDifficultyStub adjusts difficulty tiers correctly based on accuracy', () {
      // Promotion (accuracy >= 0.8)
      expect(AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 1, accuracy: 0.8), equals(2));
      expect(AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 2, accuracy: 1.0), equals(3));
      expect(AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 5, accuracy: 1.0), equals(5)); // Max 5

      // Demotion (accuracy <= 0.4)
      expect(AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 3, accuracy: 0.4), equals(2));
      expect(AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 2, accuracy: 0.2), equals(1));
      expect(AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 1, accuracy: 0.0), equals(1)); // Min 1

      // Unchanged (0.4 < accuracy < 0.8)
      expect(AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 3, accuracy: 0.6), equals(3));
      expect(AdaptiveDifficultyStub.calculateNewLevel(currentLevel: 2, accuracy: 0.5), equals(2));
    });
  });
}
