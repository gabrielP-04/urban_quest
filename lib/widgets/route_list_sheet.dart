import 'package:flutter/material.dart';
import 'package:urban_quest/models/route.dart';

class RouteListSheet extends StatefulWidget {
  final List<RouteModel> routes;
  final void Function(RouteModel route) onSelect;
  final void Function(RouteModel route) onDelete;
  final Future<String?> Function(RouteModel route) onEdit;

  const RouteListSheet({
    super.key,
    required this.routes,
    required this.onSelect,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<RouteListSheet> createState() => _RouteListSheetState();
}

class _RouteListSheetState extends State<RouteListSheet> {
  late List<RouteModel> _routes;

  @override
  void initState() {
    super.initState();
    // Copia local para permitir updates en caliente
    _routes = List.from(widget.routes);
  }

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
            itemCount: _routes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final route = _routes[index];

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.grey.shade100,
                leading: Icon(
                  _iconForType(route.type),
                  color: Colors.deepOrange,
                ),
                title: Row(
                  children: [
                    Expanded(child: Text(route.name)),
                    if (route.isCustom)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'CUSTOM',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text('${route.pois.length} places'),
                trailing: route.isCustom
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () async {
                              final newName = await widget.onEdit(route);

                              if (newName == null) return;

                              setState(() {
                                final i =
                                    _routes.indexWhere((r) => r.id == route.id);
                                if (i != -1) {
                                  _routes[i] =
                                      _routes[i].copyWith(name: newName);
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _routes.removeWhere(
                                  (r) => r.id == route.id,
                                );
                              });
                              widget.onDelete(route);
                            },
                          ),
                        ],
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () {
                  widget.onSelect(route);
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
