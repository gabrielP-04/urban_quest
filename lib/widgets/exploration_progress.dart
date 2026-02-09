import 'package:flutter/material.dart';

class ExplorationProgress extends StatelessWidget {
  final int visited;
  final int total;
  final bool compact;

  const ExplorationProgress({
    super.key,
    required this.visited,
    required this.total,
    this.compact = false,
  });

  double get _progress => total == 0 ? 0 : visited / total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exploration progress',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: compact ? 14 : 18,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            minHeight: compact ? 6 : 10,
            backgroundColor: Colors.grey.shade200,
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 12),
          Text(
            '$visited / $total places visited',
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
