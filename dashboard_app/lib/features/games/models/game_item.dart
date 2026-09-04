/// Model classes for game content loaded from content_pack.json
library;

class GameItem {
  final String id;
  final String image;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? domain;
  final int? tier;
  final Map<String, dynamic> raw;

  GameItem({
    required this.id,
    required this.image,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.domain,
    this.tier,
    this.raw = const {},
  });

  factory GameItem.fromJson(Map<String, dynamic> json) {
    return GameItem(
      id: json['id'] as String,
      image: json['image'] as String,
      prompt: json['prompt'] as String,
      options: (json['options'] as List<dynamic>).map((e) => e.toString()).toList(),
      correctIndex: json['correctIndex'] as int,
      domain: json['domain'] as String?,
      tier: json['tier'] as int?,
      raw: json,
    );
  }

  GameItem copyWith({
    String? id,
    String? image,
    String? prompt,
    List<String>? options,
    int? correctIndex,
    String? domain,
    int? tier,
    Map<String, dynamic>? raw,
  }) {
    return GameItem(
      id: id ?? this.id,
      image: image ?? this.image,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      domain: domain ?? this.domain,
      tier: tier ?? this.tier,
      raw: raw ?? this.raw,
    );
  }
}

class Tier {
  final int level;
  final List<GameItem> items;

  Tier({required this.level, required this.items});

  factory Tier.fromJson(int level, List<dynamic> jsonList) {
    return Tier(
      level: level,
      items: jsonList
          .map((item) => GameItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GameContent {
  final String gameId;
  final Map<int, Tier> tiers;

  GameContent({required this.gameId, required this.tiers});

  factory GameContent.fromJson(String gameId, Map<String, dynamic> json) {
    final rawTiers = json['tiers'] as Map<String, dynamic>;
    final tiersMap = <int, Tier>{};
    rawTiers.forEach((key, value) {
      final level = int.tryParse(key) ?? 1;
      tiersMap[level] = Tier.fromJson(level, value as List<dynamic>);
    });
    return GameContent(gameId: gameId, tiers: tiersMap);
  }
}
