import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/ranking/ranking_screen.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  
  const BottomNav({
    super.key, 
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFFFF9A56), // Deep Orange
        unselectedItemColor: const Color(0xFFBDBDBD), // Gray
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    // Evitar navegar a la misma pantalla
    if (index == currentIndex) return;

    // Navegar a la pantalla correspondiente
    Widget destination;
    
    switch (index) {
      case 0:
        destination = const HomeScreen();
        break;
      case 1:
        destination = const MapScreen();
        break;
      case 2:
        destination = const RankingScreen(); // Progress/Ranking
        break;
      case 3:
        destination = const ProfileScreen();
        break;
      default:
        return;
    }

    // Reemplazar la ruta actual (sin apilar pantallas)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}