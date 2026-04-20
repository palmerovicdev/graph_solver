class ColorateWithGreedyForLists<T> {
  const ColorateWithGreedyForLists();

  Map<T, int> call(
    Map<T, Set<T>> adjacency, {
    required Map<T, List<int>> allowedColorsByNode,
    List<T>? visitOrder,
  }) {
    final normalized = _normalizeUndirectedAdjacency(adjacency);
    final order = visitOrder ?? _defaultVisitOrder(normalized);
    final orderSet = order.toSet();

    if (orderSet.length != order.length) {
      throw ArgumentError('visitOrder must not contain duplicated nodes.');
    }

    final unknownInOrder = order.where((node) => !normalized.containsKey(node));
    if (unknownInOrder.isNotEmpty) {
      throw ArgumentError(
        'visitOrder contains unknown nodes: ${unknownInOrder.join(', ')}.',
      );
    }

    final missingInOrder = normalized.keys
        .where((node) => !orderSet.contains(node))
        .toList();
    if (missingInOrder.isNotEmpty) {
      throw ArgumentError(
        'visitOrder is missing nodes: ${missingInOrder.join(', ')}.',
      );
    }

    final missingAllowedColors = normalized.keys
        .where((node) => !allowedColorsByNode.containsKey(node))
        .toList();
    if (missingAllowedColors.isNotEmpty) {
      throw ArgumentError(
        'Missing allowed colors for nodes: ${missingAllowedColors.join(', ')}.',
      );
    }

    final colorByNode = <T, int>{};

    for (final node in order) {
      final usedColors = <int>{};
      for (final neighbor in normalized[node] ?? <T>{}) {
        final neighborColor = colorByNode[neighbor];
        if (neighborColor != null) {
          usedColors.add(neighborColor);
        }
      }

      final listForNode = allowedColorsByNode[node]!;
      int? selectedColor;

      for (final candidateColor in listForNode) {
        if (!usedColors.contains(candidateColor)) {
          selectedColor = candidateColor;
          break;
        }
      }

      if (selectedColor == null) {
        throw StateError('No valid list-coloring found.');
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
  List<T> _defaultVisitOrder(Map<T, Set<T>> adjacency) {
    final order = adjacency.keys.toList();

    order.sort((a, b) {
      final degreeComparison = adjacency[b]!.length.compareTo(
        adjacency[a]!.length,
      );
      if (degreeComparison != 0) {
        return degreeComparison;
      }
      return a.toString().compareTo(b.toString());
    });

    return order;
  }
}
