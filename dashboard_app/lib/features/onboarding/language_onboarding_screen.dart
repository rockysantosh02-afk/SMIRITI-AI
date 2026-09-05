import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_languages.dart';
import '../../core/localization/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/firebase/firebase_service.dart';

/// First-time Language Selection Onboarding Screen.
///
/// Designed with high-contrast, oversized touch targets (min 80dp), and clear
/// typography tailored for elderly accessibility.
class LanguageOnboardingScreen extends StatefulWidget {
  const LanguageOnboardingScreen({super.key});

  @override
  State<LanguageOnboardingScreen> createState() =>
      _LanguageOnboardingScreenState();
}

class _LanguageOnboardingScreenState extends State<LanguageOnboardingScreen> {
  AppLanguage _selected = AppLanguages.defaultLanguage;
  bool _isSaving = false;

  final List<({AppLanguage lang, String title, String subtitle, String iconText})>
      _options = const [
    (
      lang: AppLanguage.english,
      title: 'English',
      subtitle: 'English (US)',
      iconText: 'A',
    ),
    (
      lang: AppLanguage.telugu,
      title: 'తెలుగు',
      subtitle: 'Telugu (తెలుగు)',
      iconText: 'తె',
    ),
    (
      lang: AppLanguage.hindi,
      title: 'हिन्दी',
      subtitle: 'Hindi (हिन्दी)',
      iconText: 'अ',
    ),
  ];

  Future<void> _handleContinue() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final langProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      await langProvider.completeOnboarding(_selected);

      if (!mounted) return;

      // Navigate to Login (or Dashboard if already authenticated)
      String targetRoute = '/login';
      try {
        final currentUser = FirebaseService.instance.currentUser;
        if (currentUser != null) {
          targetRoute = '/dashboard';
        }
      } catch (_) {}

      try {
        Navigator.of(context).pushReplacementNamed(targetRoute);
      } catch (_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('[LanguageOnboardingScreen] Error saving language: $e');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        try {
          Navigator.of(context).pushReplacementNamed('/login');
        } catch (_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Warm App Logo / Icon Header
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    size: 48,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title
              const Text(
                'WELCOME TO SMRITI AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 10),

              // Prompt
              const Text(
                'Please choose your preferred language',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.4,
                  color: AppTheme.subtitleColor,
                ),
              ),

              const SizedBox(height: 32),

              // Language Option Cards
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _options[index];
                    final isSelected = _selected == item.lang;

                    return Semantics(
                      selected: isSelected,
                      button: true,
                      label: '${item.title}, ${item.subtitle}',
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selected = item.lang;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                              width: isSelected ? 3.0 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isSelected ? 0.08 : 0.03,
                                ),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Distinct visual script badge
                              Container(
                                width: 56,
                                height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  item.iconText,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textColor,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 18),

                              // Labels
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : AppTheme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.subtitle,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Checkmark Icon
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 34,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Large tactile Continue button (min 80dp)
              SizedBox(
                height: 80,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              switch (_selected) {
                                AppLanguage.telugu => 'కొనసాగించండి',
                                AppLanguage.hindi => 'आगे बढ़ें',
                                _ => 'Continue',
                              },
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_forward_rounded, size: 28),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
