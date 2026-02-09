import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'ranking/ranking_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/bottom_nav.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreenContent(),
          MapScreenContent(),
          RankingScreenContent(),
          ProfileScreenContent(),
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }
}

// Wrappers sin Scaffold (solo contenido)
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const HomeScreen(showBottomNav: false);
  }
}

class MapScreenContent extends StatelessWidget {
  const MapScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MapScreen(showBottomNav: false);
  }
}

class RankingScreenContent extends StatelessWidget {
  const RankingScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const RankingScreen(showBottomNav: false);
  }
}

class ProfileScreenContent extends StatelessWidget {
  const ProfileScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen(showBottomNav: false);
  }
}