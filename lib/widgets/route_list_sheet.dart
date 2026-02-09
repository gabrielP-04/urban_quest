import 'package:flutter/material.dart';
import 'package:urban_quest/models/route.dart';

class RouteListSheet extends StatelessWidget {
  final List<RouteModel> routes;
  final void Function(RouteModel route) onSelect;

  const RouteListSheet({
    super.key,
    required this.routes,
    required this.onSelect,
  });

  IconData _iconForType(RouteType type) {
    switch (type) {
      case RouteType.historic:
        return Icons.account_balance;
      case RouteType.food:
        return Icons.restaurant;
      case RouteType.cultural:
        return Icons.museum;
      case RouteType.scenic:
        return Icons.visibility;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Choose a route',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final route = routes[index];

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.grey.shade100,
                leading: Icon(
                  _iconForType(route.type),
                  color: Colors.deepOrange,
                ),
                title: Text(route.name),
                subtitle: Text('${route.pois.length} places'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  onSelect(route);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
