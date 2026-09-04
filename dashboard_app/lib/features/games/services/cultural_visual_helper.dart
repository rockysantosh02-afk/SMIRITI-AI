import 'package:flutter/material.dart';

/// Representation of an authentic North-East India (NER) cultural item
class CulturalItemMeta {
  final String key;
  final String nameAs;
  final String nameEn;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;

  const CulturalItemMeta({
    required this.key,
    required this.nameAs,
    required this.nameEn,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
  });
}

/// Helper providing metadata and rich illustrated widgets for all NER items
class CulturalVisualHelper {
  static const Map<String, CulturalItemMeta> items = {
    'japi': CulturalItemMeta(
      key: 'japi',
      nameAs: 'জাপি',
      nameEn: 'Japi (Conical Hat)',
      description: 'Traditional woven conical bamboo and palm hat',
      icon: Icons.shield_rounded,
      primaryColor: Color(0xFFD9381E),
      accentColor: Color(0xFFFFF8E7),
    ),
    'gamosa': CulturalItemMeta(
      key: 'gamosa',
      nameAs: 'গামোচা',
      nameEn: 'Gamosa (Handwoven Towel)',
      description: 'White woven cloth with intricate red floral motifs',
      icon: Icons.dry_cleaning_rounded,
      primaryColor: Color(0xFFC41E3A),
      accentColor: Color(0xFFFFFFFF),
    ),
    'dhol': CulturalItemMeta(
      key: 'dhol',
      nameAs: 'ঢোল',
      nameEn: 'Dhol (Bihu Drum)',
      description: 'Traditional two-sided rhythm drum of Bihu',
      icon: Icons.album_rounded,
      primaryColor: Color(0xFF8B4513),
      accentColor: Color(0xFFDEB887),
    ),
    'pepa': CulturalItemMeta(
      key: 'pepa',
      nameAs: 'পেঁপা',
      nameEn: 'Pepa (Horn Pipe)',
      description: 'Buffalo horn pipe instrument with bamboo reed',
      icon: Icons.music_note_rounded,
      primaryColor: Color(0xFF2F4F4F),
      accentColor: Color(0xFFDAA520),
    ),
    'xorai': CulturalItemMeta(
      key: 'xorai',
      nameAs: 'শৰাই',
      nameEn: 'Xorai (Offering Tray)',
      description: 'Bell-metal offering tray on a raised pedestal',
      icon: Icons.emoji_events_rounded,
      primaryColor: Color(0xFFB8860B),
      accentColor: Color(0xFFFFD700),
    ),
    'king_chili': CulturalItemMeta(
      key: 'king_chili',
      nameAs: 'ভোট জলকীয়া',
      nameEn: 'King Chili (Bhut Jolokia)',
      description: 'Legendary fragrant fiery red chili',
      icon: Icons.local_fire_department_rounded,
      primaryColor: Color(0xFFD2143A),
      accentColor: Color(0xFFFF6347),
    ),
    'bamboo_shoot': CulturalItemMeta(
      key: 'bamboo_shoot',
      nameAs: 'বাঁহৰ খৰিচা',
      nameEn: 'Bamboo Shoot (Khorisa)',
      description: 'Tender fermented bamboo shoot delicacy',
      icon: Icons.spa_rounded,
      primaryColor: Color(0xFF556B2F),
      accentColor: Color(0xFF9ACD32),
    ),
    'assam_tea': CulturalItemMeta(
      key: 'assam_tea',
      nameAs: 'অসম চাহ',
      nameEn: 'Assam Tea (Lal Saah)',
      description: 'World renowned rich black aromatic Assam tea',
      icon: Icons.coffee_rounded,
      primaryColor: Color(0xFF4A2C11),
      accentColor: Color(0xFF8B5A2B),
    ),
    'muga_silk': CulturalItemMeta(
      key: 'muga_silk',
      nameAs: 'মুগা ৰেচম',
      nameEn: 'Muga Silk (Golden Silk)',
      description: 'Naturally golden wild lustrous silk of Assam',
      icon: Icons.checkroom_rounded,
      primaryColor: Color(0xFFCFB53B),
      accentColor: Color(0xFFFFE4B5),
    ),
    'malbhog_kol': CulturalItemMeta(
      key: 'malbhog_kol',
      nameAs: 'মালভোগ কল',
      nameEn: 'Malbhog Banana',
      description: 'Sweet scented indigenous banana variety',
      icon: Icons.eco_rounded,
      primaryColor: Color(0xFFDAA520),
      accentColor: Color(0xFFFFFACD),
    ),
    'tamul_paan': CulturalItemMeta(
      key: 'tamul_paan',
      nameAs: 'তামোল-পাণ',
      nameEn: 'Tamul-Paan',
      description: 'Areca nut & betel leaf hospitality offering',
      icon: Icons.energy_savings_leaf_rounded,
      primaryColor: Color(0xFF2E8B57),
      accentColor: Color(0xFF8FBC8F),
    ),
    'masor_tenga': CulturalItemMeta(
      key: 'masor_tenga',
      nameAs: 'মাছৰ টেঙা',
      nameEn: 'Masor Tenga (Sour Fish)',
      description: 'Signature light tangy fish curry with elephant apple',
      icon: Icons.set_meal_rounded,
      primaryColor: Color(0xFFE25822),
      accentColor: Color(0xFFFFDAB9),
    ),
    'joha_rice': CulturalItemMeta(
      key: 'joha_rice',
      nameAs: 'জোহা চাউল',
      nameEn: 'Joha Rice',
      description: 'Fragrant, aromatic heirloom winter rice',
      icon: Icons.grain_rounded,
      primaryColor: Color(0xFF8B8589),
      accentColor: Color(0xFFFFF8DC),
    ),
    'bihu_dance': CulturalItemMeta(
      key: 'bihu_dance',
      nameAs: 'বিহু নৃত্য',
      nameEn: 'Bihu Dance',
      description: 'Joyful folk spring dance celebration',
      icon: Icons.celebration_rounded,
      primaryColor: Color(0xFFC71585),
      accentColor: Color(0xFFFFB6C1),
    ),
    'brahmaputra': CulturalItemMeta(
      key: 'brahmaputra',
      nameAs: 'ব্ৰহ্মপুত্ৰ নদী',
      nameEn: 'Brahmaputra River',
      description: 'Majestic red lifeline river of Assam',
      icon: Icons.water_rounded,
      primaryColor: Color(0xFF1E90FF),
      accentColor: Color(0xFFB0E0E6),
    ),
    'rhino': CulturalItemMeta(
      key: 'rhino',
      nameAs: 'এশিঙীয়া গঁড়',
      nameEn: 'One-Horned Rhino',
      description: 'Pride of Kaziranga National Park',
      icon: Icons.pets_rounded,
      primaryColor: Color(0xFF708090),
      accentColor: Color(0xFFD3D3D3),
    ),
    'kopou_phool': CulturalItemMeta(
      key: 'kopou_phool',
      nameAs: 'কপৌ ফুল',
      nameEn: 'Kopou Phool (Foxtail Orchid)',
      description: 'Pink foxtail orchid adorning Bihu dancers hair',
      icon: Icons.filter_vintage_rounded,
      primaryColor: Color(0xFF9370DB),
      accentColor: Color(0xFFE6E6FA),
    ),
    'gogona': CulturalItemMeta(
      key: 'gogona',
      nameAs: 'গগনা',
      nameEn: 'Gogona',
      description: 'Delicate bamboo jaw harp played with mouth',
      icon: Icons.graphic_eq_rounded,
      primaryColor: Color(0xFF8FBC8F),
      accentColor: Color(0xFFF5DEB3),
    ),
    'tokari': CulturalItemMeta(
      key: 'tokari',
      nameAs: 'টকাৰী',
      nameEn: 'Tokari',
      description: 'Ancient string instrument used in folk geet',
      icon: Icons.queue_music_rounded,
      primaryColor: Color(0xFFCD853F),
      accentColor: Color(0xFFF4A460),
    ),
    'pitha': CulturalItemMeta(
      key: 'pitha',
      nameAs: 'তিল পিঠা',
      nameEn: 'Til Pitha',
      description: 'Crisp roasted rice rolls stuffed with sesame and jaggery',
      icon: Icons.cookie_rounded,
      primaryColor: Color(0xFFD2691E),
      accentColor: Color(0xFFFFEFD5),
    ),
    'taat_xaal': CulturalItemMeta(
      key: 'taat_xaal',
      nameAs: 'তাঁত শাল',
      nameEn: 'Taat-xaal (Handloom)',
      description: 'Traditional wooden frame weaving loom',
      icon: Icons.grid_view_rounded,
      primaryColor: Color(0xFF6A5ACD),
      accentColor: Color(0xFFE6E6FA),
    ),
    'majuli': CulturalItemMeta(
      key: 'majuli',
      nameAs: 'মাজুলী',
      nameEn: 'Majuli River Island',
      description: 'World-famous river island and center of neo-Vaishnavism',
      icon: Icons.landscape_rounded,
      primaryColor: Color(0xFF2E8B57),
      accentColor: Color(0xFFE0FFFF),
    ),
    'kamakhya': CulturalItemMeta(
      key: 'kamakhya',
      nameAs: 'কামাখ্যা মন্দিৰ',
      nameEn: 'Kamakhya Temple',
      description: 'Historic Nilachal hill Shakti peeth',
      icon: Icons.temple_hindu_rounded,
      primaryColor: Color(0xFFB22222),
      accentColor: Color(0xFFFFD700),
    ),
    'rang_ghar': CulturalItemMeta(
      key: 'rang_ghar',
      nameAs: 'ৰংঘৰ',
      nameEn: 'Rang Ghar',
      description: 'Historic two-storeyed royal Ahom pavilion',
      icon: Icons.stadium_rounded,
      primaryColor: Color(0xFF8B0000),
      accentColor: Color(0xFFFFE4C4),
    ),
  };

  static CulturalItemMeta getMeta(String key) {
    return items[key] ??
        CulturalItemMeta(
          key: key,
          nameAs: key,
          nameEn: key.replaceAll('_', ' '),
          description: '',
          icon: Icons.category_rounded,
          primaryColor: const Color(0xFF8B6B4D),
          accentColor: const Color(0xFFD4A373),
        );
  }
}

/// Visual card widget for displaying cultural items with large icons & typography
class CulturalVisualCard extends StatelessWidget {
  final String itemKey;
  final double size;
  final bool showLabel;
  final bool isSelected;
  final VoidCallback? onTap;

  const CulturalVisualCard({
    super.key,
    required this.itemKey,
    this.size = 110,
    this.showLabel = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final meta = CulturalVisualHelper.getMeta(itemKey);

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected ? meta.primaryColor.withValues(alpha: 0.25) : meta.accentColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? meta.primaryColor : meta.primaryColor.withValues(alpha: 0.4),
          width: isSelected ? 3.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: meta.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: meta.primaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              meta.icon,
              size: size * 0.42,
              color: meta.primaryColor,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                meta.nameAs,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: meta.primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                meta.nameEn.split(' ').first,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }
    return content;
  }
}
