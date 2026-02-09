import 'package:flutter/material.dart';
import '../map/map_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _bg = Color(0xFFF6F6F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _Header(),
              SizedBox(height: 16),
              _CityProgressCard(progress: 0.42, xp: 1250, xpGoal: 2000),
              SizedBox(height: 16),
              _MapPreviewCard(),
              SizedBox(height: 16),
              _QuickActionsRow(),
              SizedBox(height: 16),
              _RecommendationCard(),
              SizedBox(height: 80), 
            ],
          ),
        ),
      ),
      
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFFFB74D),
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Hola, Alex',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.flag, size: 14, color: Colors.grey),
                SizedBox(width: 6),
                Text('Milán · Exploración activa',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: null, // luego lo conectamos
        ),
      ],
    );
  }
}

class _CityProgressCard extends StatelessWidget {
  final double progress;
  final int xp;
  final int xpGoal;

  const _CityProgressCard({
    required this.progress,
    required this.xp,
    required this.xpGoal,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.deepOrange),
                const SizedBox(width: 8),
                const Text(
                  'Progreso de la ciudad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('$pct%', style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                const Text('Explorador Urbano',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('XP: $xp / $xpGoal',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                _CategoryIcon(icon: Icons.account_balance),
                SizedBox(width: 8),
                _CategoryIcon(icon: Icons.icecream),
                SizedBox(width: 8),
                _CategoryIcon(icon: Icons.restaurant),
                SizedBox(width: 8),
                _CategoryIcon(icon: Icons.camera_alt),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  const _CategoryIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.grey.shade700, size: 20),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 220,
          color: Colors.grey.shade300,
          child: Stack(
            children: [
              // Placeholder visual (más adelante aquí meteremos Google Maps o una imagen)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.35,
                  child: Icon(Icons.map, size: 180, color: Colors.grey.shade700),
                ),
              ),
              const Center(
                child: Icon(Icons.my_location, size: 36, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Explorar\ncerca',
            icon: Icons.place,
            color: Colors.deepOrange,
            onTap: () {
              // luego: ir al mapa y centrar en el usuario
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Crear\nruta',
            icon: Icons.add,
            color: Colors.blue,
            onTap: () {
              // luego: ir a rutas/crear ruta
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Ver\nlugares',
            icon: Icons.account_balance,
            color: Colors.green,
            onTap: () {
              // luego: ir a lista de POIs
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Recomendado para hoy',
                      style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 6),
                  Text('Ruta histórica por Brera',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('2 h · 1,4 km · 5 lugares',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: null, // luego: abrir detalle de ruta
              style: ButtonStyle(
                backgroundColor:
                    WidgetStatePropertyAll<Color>(Colors.deepOrange),
                foregroundColor: WidgetStatePropertyAll<Color>(Colors.white),
              ),
              child: const Text('Ver ruta'),
            )
          ],
        ),
      ),
    );
  }

}
