import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';

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
  String _selectedTitle = 'Urban Explorer';

  // Títulos disponibles
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
    // TODO: Cargar título guardado del perfil cuando lo implementes en el modelo
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
      // Actualizar perfil
      final updatedProfile = widget.profile.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        displayName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
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
            content: Text('Error updating profile: $e'),
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

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 8),

              // Banner Section (placeholder)
              _buildBannerSection(),

              const SizedBox(height: 16),

              // Profile Picture Section
              _buildProfilePictureSection(),

              const SizedBox(height: 32),

              // Personal Info Section
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

              const SizedBox(height: 24),

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

  // Banner Section
  Widget _buildBannerSection() {
    return Stack(
      children: [
        // Banner placeholder
        Container(
          height: 160,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepOrange.shade200,
                Colors.orange.shade200,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.landscape_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),

        // Edit button
        Positioned(
          right: 28,
          bottom: 12,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Banner upload coming soon!'),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Profile Picture Section
  Widget _buildProfilePictureSection() {
    return Center(
      child: Stack(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.profile.firstName.isNotEmpty
                    ? widget.profile.firstName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),

          // Edit button
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile picture upload coming soon!'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Personal Info Card
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
          // First Name
          TextFormField(
            controller: _firstNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'First Name',
              labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Last Name
          TextFormField(
            controller: _lastNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Last Name',
              labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.deepOrange, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Username (read-only)
          TextFormField(
            initialValue: '@${widget.profile.username}',
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Username',
              labelStyle: const TextStyle(color: Color(0xFF9E9E9E)),
              prefixIcon: const Icon(Icons.alternate_email, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }

  // Title Selection Card
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
          const SizedBox(height: 4),
          const Text(
            'This will be displayed on your profile',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 16),

          // Title chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTitles.map((title) {
              final isSelected = title == _selectedTitle;
              return ChoiceChip(
                label: Text(title),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTitle = title;
                  });
                },
                selectedColor: Colors.deepOrange.shade100,
                backgroundColor: Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.deepOrange : const Color(0xFF5A5A5A),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? Colors.deepOrange : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}