class ColorateWithGreedy<T> {
  const ColorateWithGreedy();

  Map<T, int> call(Map<T, Set<T>> adjacency, {List<T>? visitOrder}) {
    final normalized = _normalizeUndirectedAdjacency(adjacency);
    if (normalized.isEmpty) {
      return <T, int>{};
    }

    print('visitOrder: $visitOrder');
    print('normalized: $normalized');

    final order = _buildVisitOrder(normalized, visitOrder);
    final colorByNode = <T, int>{};

    for (final node in order) {
      final usedColors = <int>{};
      for (final neighbor in normalized[node] ?? <T>{}) {
        final neighborColor = colorByNode[neighbor];
        if (neighborColor != null) {
          usedColors.add(neighborColor);
        }
      }

      var selectedColor = 0;
      while (usedColors.contains(selectedColor)) {
        selectedColor++;
      }

      colorByNode[node] = selectedColor;
    }

    return colorByNode;
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

  /// Order graph nodes by degree in descending order.
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

    final remaining = adjacency.keys
        .where((node) => !seen.contains(node))
        .toList();

    remaining.sort((a, b) {
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
}
