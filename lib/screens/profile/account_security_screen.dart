import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';

class AccountSecurityScreen extends StatelessWidget {
  const AccountSecurityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final userId = authService.currentUserId;
    final email = authService.currentUserEmail;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3ED),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5A5A5A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account & Security',
          style: TextStyle(
            color: Color(0xFF5A5A5A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF5A5A5A)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Account Data Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Account Data',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Account Data Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  // Phone (placeholder)
                  _buildAccountItem(
                    icon: Icons.phone_outlined,
                    iconColor: Colors.deepOrange,
                    title: '+34 6XX XXX XXX',
                    subtitle: 'Phone +34',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phone management coming soon!'),
                        ),
                      );
                    },
                    isFirst: true,
                  ),
                  _buildDivider(),

                  // Email
                  _buildAccountItem(
                    icon: Icons.email_outlined,
                    iconColor: Colors.blue,
                    title: email ?? 'No email',
                    subtitle: 'Email',
                    onTap: () {
                      _showEmailDialog(context, email);
                    },
                  ),
                  _buildDivider(),

                  // Password
                  _buildAccountItem(
                    icon: Icons.lock_outline,
                    iconColor: Colors.green,
                    title: '••••••••',
                    subtitle: 'Password',
                    trailing: TextButton(
                      onPressed: () {
                        _showChangePasswordDialog(context, authService);
                      },
                      child: const Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () {
                      _showChangePasswordDialog(context, authService);
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'Security',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9E9E9E),
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Security Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  // Two-Factor Authentication
                  _buildSecurityItem(
                    icon: Icons.verified_user_outlined,
                    iconColor: Colors.green,
                    title: 'Two-Factor Authentication',
                    subtitle: 'Organize then rest assured',
                    hasSwitch: true,
                    switchValue: false,
                    onSwitchChanged: (value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? '2FA will be enabled soon!'
                                : '2FA disabled',
                          ),
                        ),
                      );
                    },
                    isFirst: true,
                  ),
                  _buildDivider(),

                  // Linked Sessions
                  _buildSecurityItem(
                    icon: Icons.devices_outlined,
                    iconColor: Colors.purple,
                    title: 'Linked Sessions',
                    subtitle: 'Link them to your users',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Session management coming soon!'),
                        ),
                      );
                    },
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Delete Account
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
              child: InkWell(
                onTap: () => _showDeleteAccountDialog(context, authService),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Account Item
  Widget _buildAccountItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A5A5A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFBDBDBD),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  // Security Item
  Widget _buildSecurityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool hasSwitch = false,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
    VoidCallback? onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: hasSwitch ? null : onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(20) : Radius.zero,
        bottom: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A5A5A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: Colors.deepOrange,
              )
            else
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFBDBDBD),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey.shade200,
      ),
    );
  }

  // Show Email Info Dialog
  void _showEmailDialog(BuildContext context, String? email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email ?? 'No email found',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email cannot be changed. Contact support if needed.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  // Show Change Password Dialog
  void _showChangePasswordDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: const Text(
          'Password reset functionality coming soon!\n\nYou will receive a password reset email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset email sent!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send Email', style: TextStyle(color: Colors.deepOrange)),
          ),
        ],
      ),
    );
  }

  // Show Delete Account Confirmation
  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete your account?\n\nThis action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await authService.deleteAccount();
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}