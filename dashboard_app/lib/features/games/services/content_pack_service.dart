import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/game_item.dart';

/// Singleton service to load and access game items from content_pack.json
class ContentPackService {
  ContentPackService._internal();
  static final ContentPackService instance = ContentPackService._internal();

  bool _loaded = false;
  final Map<String, GameContent> _games = {};
  final Random _random = Random();

  bool get isLoaded => _loaded;

  /// Loads the content pack from assets bundle.
  Future<void> load({String assetPath = 'assets/games/content_pack.json'}) async {
    if (_loaded && _games.isNotEmpty) return;

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final gamesData = data['games'] as Map<String, dynamic>;

      _games.clear();
      gamesData.forEach((gameId, gameJson) {
        _games[gameId] = GameContent.fromJson(gameId, gameJson as Map<String, dynamic>);
      });
      _loaded = true;
      debugPrint('[ContentPackService] Successfully loaded ${_games.length} games from pack.');
    } catch (e) {
      debugPrint('[ContentPackService] Error loading content pack: $e');
      rethrow;
    }
  }

  /// Manually populate or test with json string
  void loadFromJsonString(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final gamesData = data['games'] as Map<String, dynamic>;

    _games.clear();
    gamesData.forEach((gameId, gameJson) {
      _games[gameId] = GameContent.fromJson(gameId, gameJson as Map<String, dynamic>);
    });
    _loaded = true;
  }

  /// Retrieves all items for a game and tier (1-5).
  List<GameItem> getItems(String gameId, int tier) {
    final clampedTier = tier.clamp(1, 5);
    final game = _games[gameId];
    if (game == null) return [];
    final tierContent = game.tiers[clampedTier];
    return tierContent?.items ?? [];
  }

  /// Generates a session round list (default 5 rounds) with shuffled options.
  List<GameItem> generateRounds(String gameId, int tier, {int count = 5}) {
    final pool = getItems(gameId, tier);
    if (pool.isEmpty) return [];

    final shuffledPool = List<GameItem>.from(pool)..shuffle(_random);
    final selected = shuffledPool.take(count).toList();

    // If pool has fewer than count items, repeat if needed
    if (selected.length < count) {
      while (selected.length < count) {
        selected.add(pool[_random.nextInt(pool.length)]);
      }
    }

    // Shuffle options for each item and preserve correctIndex
    return selected.map((item) {
      if (item.options.isEmpty) return item;
      final originalCorrectValue = item.options[item.correctIndex];
      final shuffledOptions = List<String>.from(item.options)..shuffle(_random);
      final newCorrectIndex = shuffledOptions.indexOf(originalCorrectValue);

      return item.copyWith(
        options: shuffledOptions,
        correctIndex: newCorrectIndex,
      );
    }).toList();
  }
}
