class ColorateWithBacktrackingForLists<T> {
  const ColorateWithBacktrackingForLists();

  Map<T, int> call(
    Map<T, Set<T>> adjacency, {
    required Map<T, List<int>> allowedColorsByNode,
    List<T>? visitOrder,
  }) {
    final normalized = _normalizeUndirectedAdjacency(adjacency);
    if (normalized.isEmpty) {
      return <T, int>{};
    }

    final order = _buildVisitOrder(normalized, visitOrder);
    final missingAllowedColors = order
        .where((node) => !allowedColorsByNode.containsKey(node))
        .toList();

    if (missingAllowedColors.isNotEmpty) {
      throw ArgumentError(
        'Missing allowed colors for nodes: ${missingAllowedColors.join(', ')}.',
      );
    }

    final colorByNode = <T, int>{};
    final solved = _search(
      nodeIndex: 0,
      order: order,
      adjacency: normalized,
      allowedColorsByNode: allowedColorsByNode,
      colorByNode: colorByNode,
    );

    if (solved) {
      return Map<T, int>.from(colorByNode);
    }

    throw StateError('No valid list-coloring found.');
  }

  bool _search({
    required int nodeIndex,
    required List<T> order,
    required Map<T, Set<T>> adjacency,
    required Map<T, List<int>> allowedColorsByNode,
    required Map<T, int> colorByNode,
  }) {
    if (nodeIndex >= order.length) {
      return true;
    }

    final node = order[nodeIndex];
    final allowedColors = allowedColorsByNode[node]!;

    for (final color in allowedColors) {
      if (!_canUseColor(node, color, adjacency, colorByNode)) {
        continue;
      }

      colorByNode[node] = color;

      if (_search(
        nodeIndex: nodeIndex + 1,
        order: order,
        adjacency: adjacency,
        allowedColorsByNode: allowedColorsByNode,
        colorByNode: colorByNode,
      )) {
        return true;
      }

      colorByNode.remove(node);
    }

    return false;
  }

  bool _canUseColor(
    T node,
    int color,
    Map<T, Set<T>> adjacency,
    Map<T, int> colorByNode,
  ) {
    for (final neighbor in adjacency[node] ?? <T>{}) {
      if (colorByNode[neighbor] == color) {
        return false;
      }
    }
    return true;
  }

  List<T> _buildVisitOrder(Map<T, Set<T>> adjacency, List<T>? customOrder) {
    final order = <T>[];
    final seen = <T>{};

    if (customOrder != null) {
      for (final node in customOrder) {
        if (!adjacency.containsKey(node)) {
          continue;
        }
        if (seen.add(node)) {
          order.add(node);
        }
      }
    }

    final remaining =
        adjacency.keys.where((node) => !seen.contains(node)).toList()
          ..sort((a, b) {
            final degreeComparison = adjacency[b]!.length.compareTo(
              adjacency[a]!.length,
            );
            if (degreeComparison != 0) {
              return degreeComparison;
            }
            return a.toString().compareTo(b.toString());
          });

    order.addAll(remaining);
    return order;
  }

  /// Normalize undirected adjacency graph to ensure all nodes are connected.
  Map<T, Set<T>> _normalizeUndirectedAdjacency(Map<T, Set<T>> adjacency) {
    final normalized = <T, Set<T>>{};

    for (final entry in adjacency.entries) {
      normalized.putIfAbsent(entry.key, () => <T>{});
      for (final neighbor in entry.value) {
        if (neighbor == entry.key) {
          continue;
        }
        normalized.putIfAbsent(neighbor, () => <T>{});
        normalized[entry.key]!.add(neighbor);
        normalized[neighbor]!.add(entry.key);
      }
    }

    return normalized;
  }
}
