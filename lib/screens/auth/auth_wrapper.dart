import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../main_scaffold.dart';
import '../../services/firestore_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _lastSyncedEmail;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
                    
          if (user.email != null && 
              user.emailVerified && 
              user.email != _lastSyncedEmail) {
            _syncEmailWithFirestore(user);
          }

          return const MainScaffold();
        }

        
        return const LoginScreen();
      },
    );
  }

  
  Future<void> _syncEmailWithFirestore(User user) async {
    try {
      
      final profile = await _firestoreService.getUserProfile(user.uid);

      
      if (profile != null && profile.email != user.email) {
        await _firestoreService.updateUserEmail(
          userId: user.uid,
          email: user.email!,
        );
        
        
        setState(() {
          _lastSyncedEmail = user.email;
        });
        
        debugPrint('✅ Email sincronizado en Firestore: ${user.email}');
      } else {
        
        setState(() {
          _lastSyncedEmail = user.email;
        });
      }
    } catch (e) {
      debugPrint('❌ Error al sincronizar email: $e');
    }
  }
}