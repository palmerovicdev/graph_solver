import 'package:flutter/material.dart';

class NodeColorConstraintsEditor extends StatelessWidget {
  const NodeColorConstraintsEditor({
    super.key,
    required this.nodes,
    required this.slotCount,
    required this.slotColors,
    required this.constraints,
    required this.onChanged,
  });

  final List<String> nodes;
  final int slotCount;
  final List<Color> slotColors;
  final Map<String, List<int>> constraints;
  final ValueChanged<Map<String, List<int>>> onChanged;

  void _toggleIndex(String node, int index) {
    final next = _cloneConstraints();
    final current = List<int>.from(next[node] ?? []);
    if (current.contains(index)) {
      current.remove(index);
    } else {
      current.add(index);
      current.sort();
    }
    if (current.isEmpty) {
      next.remove(node);
    } else {
      next[node] = current;
    }
    onChanged(next);
  }

  void _clearNode(String node) {
    final next = _cloneConstraints();
    next.remove(node);
    onChanged(next);
  }

  Map<String, List<int>> _cloneConstraints() {
    return {
      for (final e in constraints.entries)
        e.key: List<int>.from(e.value),
    };
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Allowed colors', style: titleStyle),
        const SizedBox(height: 10),
        if (nodes.isEmpty)
          Text(
            'No nodes',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          )
        else
          ...nodes.map((node) {
            final selected = constraints[node] ?? const <int>[];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          node,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (selected.isNotEmpty)
                        TextButton(
                          onPressed: () => _clearNode(node),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < slotCount; i++)
                        FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: i < slotColors.length
                                      ? slotColors[i]
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black26,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('$i', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          selected: selected.contains(i),
                          onSelected: (_) => _toggleIndex(node, i),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          showCheckmark: false,
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
