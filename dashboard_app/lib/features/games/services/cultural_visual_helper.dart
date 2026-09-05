import 'package:flutter/material.dart';

/// Representation of an authentic cultural wellness item with multilingual support
class CulturalItemMeta {
  final String key;
  final String nameEn;
  final String nameTe;
  final String nameHi;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color accentColor;

  const CulturalItemMeta({
    required this.key,
    required this.nameEn,
    required this.nameTe,
    required this.nameHi,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.accentColor,
  });

  /// Backward compatibility getter
  String get nameAs => nameEn;

  /// Get localized name based on language code ('en', 'te', 'hi')
  String getLocalizedName(String langCode) {
    switch (langCode.toLowerCase().trim()) {
      case 'te':
        return nameTe;
      case 'hi':
        return nameHi;
      case 'en':
      default:
        return nameEn;
    }
  }
}

/// Helper providing metadata and rich illustrated widgets for cultural game items
class CulturalVisualHelper {
  static const Map<String, CulturalItemMeta> items = {
    'japi': CulturalItemMeta(
      key: 'japi',
      nameEn: 'Japi (Conical Hat)',
      nameTe: 'జాపి (టోపీ)',
      nameHi: 'जापी (टोपी)',
      description: 'Traditional woven conical bamboo and palm hat',
      icon: Icons.shield_rounded,
      primaryColor: Color(0xFFD9381E),
      accentColor: Color(0xFFFFF8E7),
    ),
    'gamosa': CulturalItemMeta(
      key: 'gamosa',
      nameEn: 'Gamosa (Handwoven Towel)',
      nameTe: 'గమోసా (తువ్వాలు)',
      nameHi: 'गमोसा (तौलिया)',
      description: 'White woven cloth with intricate red floral motifs',
      icon: Icons.dry_cleaning_rounded,
      primaryColor: Color(0xFFC41E3A),
      accentColor: Color(0xFFFFFFFF),
    ),
    'dhol': CulturalItemMeta(
      key: 'dhol',
      nameEn: 'Dhol (Rhythm Drum)',
      nameTe: 'ధోల్ (డప్పు)',
      nameHi: 'ढोल',
      description: 'Traditional two-sided rhythm drum',
      icon: Icons.album_rounded,
      primaryColor: Color(0xFF8B4513),
      accentColor: Color(0xFFDEB887),
    ),
    'pepa': CulturalItemMeta(
      key: 'pepa',
      nameEn: 'Pepa (Horn Pipe)',
      nameTe: 'పెపా (కొమ్ము బాజా)',
      nameHi: 'पेपा (बांसुरी)',
      description: 'Horn pipe musical instrument with bamboo reed',
      icon: Icons.music_note_rounded,
      primaryColor: Color(0xFF2F4F4F),
      accentColor: Color(0xFFDAA520),
    ),
    'xorai': CulturalItemMeta(
      key: 'xorai',
      nameEn: 'Xorai (Offering Tray)',
      nameTe: 'షోరై (పూజా పళ్లెం)',
      nameHi: 'शोराई (थाली)',
      description: 'Bell-metal offering tray on a raised pedestal',
      icon: Icons.emoji_events_rounded,
      primaryColor: Color(0xFFB8860B),
      accentColor: Color(0xFFFFD700),
    ),
    'king_chili': CulturalItemMeta(
      key: 'king_chili',
      nameEn: 'King Chili',
      nameTe: 'మిరపకాయ',
      nameHi: 'राजा मिर्च',
      description: 'Fragrant fiery red chili',
      icon: Icons.local_fire_department_rounded,
      primaryColor: Color(0xFFD2143A),
      accentColor: Color(0xFFFF6347),
    ),
    'bamboo_shoot': CulturalItemMeta(
      key: 'bamboo_shoot',
      nameEn: 'Bamboo Shoot',
      nameTe: 'వెదురు చిగురు',
      nameHi: 'बांस के अंकुर',
      description: 'Tender bamboo shoot delicacy',
      icon: Icons.spa_rounded,
      primaryColor: Color(0xFF556B2F),
      accentColor: Color(0xFF9ACD32),
    ),
    'assam_tea': CulturalItemMeta(
      key: 'assam_tea',
      nameEn: 'Tea Leaves',
      nameTe: 'టీ ఆకులు',
      nameHi: 'चाय की पत्तियाँ',
      description: 'World renowned rich black aromatic tea',
      icon: Icons.coffee_rounded,
      primaryColor: Color(0xFF4A2C11),
      accentColor: Color(0xFF8B5A2B),
    ),
    'muga_silk': CulturalItemMeta(
      key: 'muga_silk',
      nameEn: 'Golden Silk',
      nameTe: 'బంగారు పట్టు',
      nameHi: 'सुनहरा रेशम',
      description: 'Rare shimmering golden wild silk',
      icon: Icons.auto_awesome_rounded,
      primaryColor: Color(0xFFDAA520),
      accentColor: Color(0xFFFFFDD0),
    ),
    'malbhog_banana': CulturalItemMeta(
      key: 'malbhog_banana',
      nameEn: 'Sweet Banana',
      nameTe: 'అరటిపండు',
      nameHi: 'मीठा केला',
      description: 'Aromatic sweet local banana',
      icon: Icons.lunch_dining_rounded,
      primaryColor: Color(0xFFCC8800),
      accentColor: Color(0xFFFFFFE0),
    ),
    'tamol_paan': CulturalItemMeta(
      key: 'tamol_paan',
      nameEn: 'Betel Nut & Leaf',
      nameTe: 'తమలపాకు వక్క',
      nameHi: 'पान और सुपारी',
      description: 'Sacred hospitality offering of betel nut and leaf',
      icon: Icons.eco_rounded,
      primaryColor: Color(0xFF228B22),
      accentColor: Color(0xFFE0EEE0),
    ),
    'masor_tenga': CulturalItemMeta(
      key: 'masor_tenga',
      nameEn: 'Tangy Fish Curry',
      nameTe: 'చేపల పులుసు',
      nameHi: 'मछली का शोरबा',
      description: 'Light tangy fish curry with elephant apple',
      icon: Icons.set_meal_rounded,
      primaryColor: Color(0xFFE65100),
      accentColor: Color(0xFFFFCC80),
    ),
    'joha_rice': CulturalItemMeta(
      key: 'joha_rice',
      nameEn: 'Aromatic Rice',
      nameTe: 'సువాసన బియ్యం',
      nameHi: 'सुगंधित चावल',
      description: 'Naturally fragrant short-grain winter rice',
      icon: Icons.grain_rounded,
      primaryColor: Color(0xFF708090),
      accentColor: Color(0xFFF5F5F5),
    ),
    'bihu_dance': CulturalItemMeta(
      key: 'bihu_dance',
      nameEn: 'Spring Folk Dance',
      nameTe: 'జానపద నృత్యం',
      nameHi: 'लोक नृत्य',
      description: 'Exuberant celebration of youth and springtime',
      icon: Icons.accessibility_new_rounded,
      primaryColor: Color(0xFFC71585),
      accentColor: Color(0xFFFFB6C1),
    ),
    'brahmaputra': CulturalItemMeta(
      key: 'brahmaputra',
      nameEn: 'Sacred River',
      nameTe: 'పవిత్ర నది',
      nameHi: 'पवित्र नदी',
      description: 'Mighty trans-Himalayan lifeline river',
      icon: Icons.water_rounded,
      primaryColor: Color(0xFF1E90FF),
      accentColor: Color(0xFFE0FFFF),
    ),
    'rhino': CulturalItemMeta(
      key: 'rhino',
      nameEn: 'One-Horned Rhino',
      nameTe: 'ఖడ్గమృగం',
      nameHi: 'एक सींग वाला गैंडा',
      description: 'Majestic great Indian rhinoceros',
      icon: Icons.pets_rounded,
      primaryColor: Color(0xFF696969),
      accentColor: Color(0xFFDCDCDC),
    ),
    'kopou_flower': CulturalItemMeta(
      key: 'kopou_flower',
      nameEn: 'Foxtail Orchid',
      nameTe: 'ఆర్కిడ్ పువ్వు',
      nameHi: 'आर्किड फूल',
      description: 'Delicate pink-purple wild seasonal orchid',
      icon: Icons.local_florist_rounded,
      primaryColor: Color(0xFFBA55D3),
      accentColor: Color(0xFFE6E6FA),
    ),
    'gogona': CulturalItemMeta(
      key: 'gogona',
      nameEn: 'Bamboo Jaw Harp',
      nameTe: 'దవడ వాయిద్యం',
      nameHi: 'जॉ हार्प',
      description: 'Slender vibrating bamboo instrument played by women',
      icon: Icons.music_video_rounded,
      primaryColor: Color(0xFF8B7355),
      accentColor: Color(0xFFF5DEB3),
    ),
    'tokari': CulturalItemMeta(
      key: 'tokari',
      nameEn: 'String Lute',
      nameTe: 'తంత్రీ వాయిద్యం',
      nameHi: 'तंतु वाद्य',
      description: 'Ancient plucked string instrument of devotional music',
      icon: Icons.audiotrack_rounded,
      primaryColor: Color(0xFF8B4500),
      accentColor: Color(0xFFFFE4B5),
    ),
    'til_pitha': CulturalItemMeta(
      key: 'til_pitha',
      nameEn: 'Sesame Rice Roll',
      nameTe: 'నువ్వుల తీపి',
      nameHi: 'तिल की मिठाई',
      description: 'Crisp rolled rice pancake with black sesame and jaggery',
      icon: Icons.cookie_rounded,
      primaryColor: Color(0xFF2F4F4F),
      accentColor: Color(0xFFFAF0E6),
    ),
    'tat_xal': CulturalItemMeta(
      key: 'tat_xal',
      nameEn: 'Village Loom',
      nameTe: 'మగ్గం',
      nameHi: 'हथकरघा',
      description: 'Traditional wooden domestic handloom',
      icon: Icons.grid_on_rounded,
      primaryColor: Color(0xFF8B5A2B),
      accentColor: Color(0xFFD2B48C),
    ),
    'majuli': CulturalItemMeta(
      key: 'majuli',
      nameEn: 'River Island',
      nameTe: 'నది ద్వీపం',
      nameHi: 'नदी द्वीप',
      description: 'Cradle of neo-Vaishnavite culture and monastic sattras',
      icon: Icons.landscape_rounded,
      primaryColor: Color(0xFF2E8B57),
      accentColor: Color(0xFFE0F2E9),
    ),
    'kamakhya': CulturalItemMeta(
      key: 'kamakhya',
      nameEn: 'Hilltop Temple',
      nameTe: 'దేవాలయం',
      nameHi: 'मंदिर',
      description: 'Ancient sacred shrine on Nilachal Hill',
      icon: Icons.temple_hindu_rounded,
      primaryColor: Color(0xFFB22222),
      accentColor: Color(0xFFFFDAB9),
    ),
    'rang_ghar': CulturalItemMeta(
      key: 'rang_ghar',
      nameEn: 'Royal Pavilion',
      nameTe: 'ప్రాసాదం',
      nameHi: 'रंग घर',
      description: 'Historic two-storey royal amphitheatre',
      icon: Icons.account_balance_rounded,
      primaryColor: Color(0xFF8B0000),
      accentColor: Color(0xFFFFE4C4),
    ),
  };

  static CulturalItemMeta getMeta(String key) {
    return items[key] ??
        CulturalItemMeta(
          key: key,
          nameEn: key.replaceAll('_', ' '),
          nameTe: key.replaceAll('_', ' '),
          nameHi: key.replaceAll('_', ' '),
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
    final locale = Localizations.localeOf(context).languageCode;
    final localizedTitle = meta.getLocalizedName(locale);

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isSelected
            ? meta.primaryColor.withValues(alpha: 0.25)
            : meta.accentColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? meta.primaryColor
              : meta.primaryColor.withValues(alpha: 0.4),
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
                localizedTitle,
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
