import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/family_repository.dart';

/// Screen for managing family member memories and photos for personal memory games.
class FamilyMemberScreen extends StatefulWidget {
  const FamilyMemberScreen({super.key});

  @override
  State<FamilyMemberScreen> createState() => _FamilyMemberScreenState();
}

class _FamilyMemberScreenState extends State<FamilyMemberScreen> {
  late final FamilyRepository _repository;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _repository = FamilyRepository(DatabaseProvider.instance);
  }

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    String selectedRelation = 'Daughter (কন্যা)';
    String? pickedImagePath;

    final relations = [
      'Daughter (কন্যা)',
      'Son (পুত্ৰ)',
      'Granddaughter (নাতিনী)',
      'Grandson (নাতি)',
      'Spouse (জীৱনসংগী)',
      'Sibling (ভাই/ভনী)',
      'Friend (বন্ধু)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'আপোনজনৰ চিনাকি যোগ কৰক',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 28),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Photo picker box
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        final XFile? image = await _picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        if (image != null) {
                          setSheetState(() {
                            pickedImagePath = image.path;
                          });
                        }
                      } catch (e) {
                        debugPrint('Error picking image: $e');
                      }
                    },
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryColor, width: 2),
                      ),
                      child: pickedImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                File(pickedImagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_circle_rounded,
                                  size: 64,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 40, color: AppTheme.primaryColor),
                                SizedBox(height: 6),
                                Text(
                                  'ফটো বাছক\n(Pick photo)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 13, color: AppTheme.subtitleColor),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Name field (22sp as required)
                TextField(
                  controller: nameController,
                  style: const TextStyle(fontSize: 22, color: AppTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'নাম (Full Name)',
                    labelStyle: const TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),

                // Relation dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedRelation,
                  style: const TextStyle(fontSize: 18, color: AppTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'সম্পৰ্ক (Relation)',
                    labelStyle: const TextStyle(fontSize: 18, color: AppTheme.subtitleColor),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  items: relations
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedRelation = val);
                  },
                ),
                const SizedBox(height: 16),

                // Optional notes
                TextField(
                  controller: notesController,
                  style: const TextStyle(fontSize: 18, color: AppTheme.textColor),
                  decoration: InputDecoration(
                    labelText: 'মনত থকা কথা (Notes - optional)',
                    labelStyle: const TextStyle(fontSize: 16, color: AppTheme.subtitleColor),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button (80dp)
                SizedBox(
                  height: 80,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 32),
                    label: const Text(
                      'সংৰক্ষণ কৰক (Save Member)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);

                      await _repository.addMember(
                        name: name,
                        relation: selectedRelation.split(' ').first,
                        photoPath: pickedImagePath,
                        notes: notesController.text.trim(),
                      );

                      if (mounted) {
                        navigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('আপোনজনক সফলতাৰে যোগ কৰা হ\'ল (Family member added)'),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('মোৰ আপোনজন (My Family Memories)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 32),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Consent Message Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, color: Colors.purple, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add family photos only if you are comfortable. They stay private on this device and your account.\n(আপোনাৰ সুবিধা অনুসৰিহে ফটো যোগ কৰক। এইবোৰ আপোনাৰ ডিভাইচতে সম্পূৰ্ণ গোপনীয় হৈ থাকিব।)',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4A148C),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Members Stream List
            Expanded(
              child: StreamBuilder<List<FamilyMember>>(
                stream: _repository.watchMembers(),
                builder: (context, snapshot) {
                  final members = snapshot.data ?? [];

                  if (members.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'এতিয়ালৈকে কোনো সদস্য যোগ কৰা হোৱা নাই',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Family quiz আৰু স্মৃতিকথা খেলিবলৈ আপোনজনৰ ফটো আৰু নাম যোগ কৰক।',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: AppTheme.subtitleColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: member.photoPath != null
                                ? ClipOval(
                                    child: Image.file(
                                      File(member.photoPath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person_rounded,
                                        size: 36,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    size: 36,
                                    color: AppTheme.primaryColor,
                                  ),
                          ),
                          title: Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            member.relation,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.subtitleColor,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => _repository.deleteMember(member.id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Add Member Bottom Button (80dp height)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 36),
                  label: const Text(
                    'নতুন সদস্য যোগ কৰক (Add Family Member)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _showAddMemberDialog,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
