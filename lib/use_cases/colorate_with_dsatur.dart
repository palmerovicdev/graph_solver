class ColorateWithDsatur<T> {
  const ColorateWithDsatur();

  Map<T, int> call(Map<T, Set<T>> adjacency, {List<T>? visitOrder}) {
    final normalized = _normalizeUndirectedAdjacency(adjacency);
    if (normalized.isEmpty) {
      return <T, int>{};
    }

    print('visitOrder: $visitOrder');
    print('normalized: $normalized');

    final priorityByNode = _buildPriorityByNode(normalized, visitOrder);
    final colorByNode = <T, int>{};
    final uncolored = normalized.keys.toSet();
    final saturationByNode = <T, Set<int>>{
      for (final node in normalized.keys) node: <int>{},
    };

    while (uncolored.isNotEmpty) {
      final node = _pickNextNode(
        uncolored,
        normalized,
        saturationByNode,
        priorityByNode,
      );
      final usedColors = <int>{};

      for (final neighbor in normalized[node] ?? <T>{}) {
        final color = colorByNode[neighbor];
        if (color != null) {
          usedColors.add(color);
        }
      }

      var selectedColor = 0;
      while (usedColors.contains(selectedColor)) {
        selectedColor++;
      }

      colorByNode[node] = selectedColor;
      uncolored.remove(node);

      for (final neighbor in normalized[node] ?? <T>{}) {
        if (uncolored.contains(neighbor)) {
          saturationByNode[neighbor]!.add(selectedColor);
        }
      }
    }

    return colorByNode;
  }

  /// Pick the next node to color based on saturation and degree.
  T _pickNextNode(
    Set<T> uncolored,
    Map<T, Set<T>> adjacency,
    Map<T, Set<int>> saturationByNode,
    Map<T, int> priorityByNode,
  ) {
    final nodes = uncolored.toList()
      ..sort((a, b) {
        final saturationComparison = saturationByNode[b]!.length.compareTo(
          saturationByNode[a]!.length,
        );
        if (saturationComparison != 0) {
          return saturationComparison;
        }

        final degreeComparison = adjacency[b]!.length.compareTo(
          adjacency[a]!.length,
        );
        if (degreeComparison != 0) {
          return degreeComparison;
        }

        final priorityA = priorityByNode[a];
        final priorityB = priorityByNode[b];
        if (priorityA != null && priorityB != null) {
          final priorityComparison = priorityA.compareTo(priorityB);
          if (priorityComparison != 0) {
            return priorityComparison;
          }
        } else if (priorityA != null) {
          return -1;
        } else if (priorityB != null) {
          return 1;
        }

        return a.toString().compareTo(b.toString());
      });

    return nodes.first;
  }

  Map<T, int> _buildPriorityByNode(
    Map<T, Set<T>> adjacency,
    List<T>? visitOrder,
  ) {
    if (visitOrder == null) {
      return <T, int>{};
    }

    final priorityByNode = <T, int>{};
    for (var i = 0; i < visitOrder.length; i++) {
      final node = visitOrder[i];
      if (!adjacency.containsKey(node)) {
        continue;
      }
      priorityByNode.putIfAbsent(node, () => i);
    }

    return priorityByNode;
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
