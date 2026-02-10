import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../core/utils/profile_assets.dart';

class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;

  const EditProfileScreen({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  late String _selectedTitle;
  late String _selectedAvatarId;
  late String _selectedBannerId;

  final List<String> _availableTitles = [
    'Urban Explorer',
    'City Wanderer',
    'Adventure Seeker',
    'Cultural Enthusiast',
    'Food Hunter',
    'History Buff',
    'Photography Lover',
    'Travel Addict',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.profile.firstName;
    _lastNameController.text = widget.profile.lastName;
    _selectedTitle = widget.profile.profileTitle;  // ✅ Inicializar con el título del perfil
    _selectedAvatarId = widget.profile.avatarId;
    _selectedBannerId = widget.profile.bannerId;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = widget.profile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        displayName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        avatarId: _selectedAvatarId,
        bannerId: _selectedBannerId,
        profileTitle: _selectedTitle,  // ✅ Guardar el título seleccionado
      );

      await _firestoreService.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectAvatar() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _AvatarPickerDialog(currentId: _selectedAvatarId),
    );
    if (selected != null) {
      setState(() => _selectedAvatarId = selected);
    }
  }

  void _selectBanner() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => _BannerPickerDialog(currentId: _selectedBannerId),
    );
    if (selected != null) {
      setState(() => _selectedBannerId = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = ProfileAssets.getAvatar(_selectedAvatarId);
    final currentBanner = ProfileAssets.getBanner(_selectedBannerId);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF5A5A5A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color(0xFF5A5A5A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.deepOrange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner + Avatar Section
              _buildBannerAvatarSection(currentAvatar, currentBanner),

              const SizedBox(height: 80), // Espacio para el avatar que sobresale

              // Personal Info
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              _buildPersonalInfoCard(),

              const SizedBox(height: 60),

              // Title Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Profile Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9E9E),
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              _buildTitleCard(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerAvatarSection(AvatarOption avatar, BannerOption banner) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Banner
        InkWell(
          onTap: _selectBanner,
          child: Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: banner.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Edit button banner
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Avatar
        Positioned(
          bottom: -50,
          left: 0,
          right: 0,
          child: Center(
            child: InkWell(
              onTap: _selectAvatar,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: avatar.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFAF3ED),
                    width: 6,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        avatar.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                    // Edit button avatar
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'First Name',
              labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
              ),
            ),
            validator: (value) =>
                value?.trim().isEmpty ?? true ? 'Enter your first name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Last Name',
              labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: '@${widget.profile.username}',
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.alternate_email, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose your title',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTitles.map((title) {
              final isSelected = title == _selectedTitle;
              return ChoiceChip(
                label: Text(title),
                selected: isSelected,
                onSelected: (selected) => setState(() => _selectedTitle = title),
                selectedColor: Colors.deepOrange.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.deepOrange : const Color(0xFF5A5A5A),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Avatar Picker Dialog
class _AvatarPickerDialog extends StatelessWidget {
  final String currentId;

  const _AvatarPickerDialog({required this.currentId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Avatar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: ProfileAssets.avatars.length,
              itemBuilder: (context, index) {
                final avatar = ProfileAssets.avatars[index];
                final isSelected = avatar.id == currentId;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, avatar.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: avatar.color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.deepOrange, width: 3)
                          : null,
                    ),
                    child: Center(
                      child: Text(avatar.emoji, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Banner Picker Dialog
class _BannerPickerDialog extends StatelessWidget {
  final String currentId;

  const _BannerPickerDialog({required this.currentId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Banner',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2,
              ),
              itemCount: ProfileAssets.banners.length,
              itemBuilder: (context, index) {
                final banner = ProfileAssets.banners[index];
                final isSelected = banner.id == currentId;
                return GestureDetector(
                  onTap: () => Navigator.pop(context, banner.id),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: banner.gradient,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: Colors.deepOrange, width: 3)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}