import 'package:graph_solver/core/coloring_run_logger.dart';

class ColorateWithDsatur<T> {
  const ColorateWithDsatur();

  Map<T, int> call(
    Map<T, Set<T>> adjacency, {
    List<T>? visitOrder,
    bool trace = false,
  }) {
    final sw = startColoringRun('DSATUR');

    void emitTrace(String message) {
      if (trace) {
        // ignore: avoid_print
        print('[DSATUR] $message');
      }
    }

    final normalized = _normalizeUndirectedAdjacency(adjacency);
    if (normalized.isEmpty) {
      emitTrace('Empty graph after normalization.');
      finishColoringRun('DSATUR', sw, <T, int>{});
      return <T, int>{};
    }

    var edgeCount = 0;
    for (final e in normalized.entries) {
      edgeCount += e.value.length;
    }
    edgeCount ~/= 2;
    emitTrace('Graph |V|=${normalized.length} |E|=$edgeCount (undirected).');
    emitTrace('visitOrder=$visitOrder');

    final priorityByNode = _buildPriorityByNode(normalized, visitOrder);
    emitTrace(
      'priorityByNode (lower = higher tie-break): $priorityByNode',
    );

    final colorByNode = <T, int>{};
    final uncolored = normalized.keys.toSet();
    final saturationByNode = <T, Set<int>>{
      for (final node in normalized.keys) node: <int>{},
    };

    var step = 0;
    while (uncolored.isNotEmpty) {
      step++;
      final node = _pickNextNode(
        uncolored,
        normalized,
        saturationByNode,
        priorityByNode,
      );
      final satSize = saturationByNode[node]?.length ?? 0;
      final deg = normalized[node]?.length ?? 0;
      final pri = priorityByNode[node];
      emitTrace(
        '--- step $step / ${uncolored.length} uncolored --- '
        'pick node=$node saturation=$satSize degree=$deg priority=$pri',
      );

      final usedColors = <int>{};

      for (final neighbor in normalized[node] ?? <T>{}) {
        final color = colorByNode[neighbor];
        if (color != null) {
          usedColors.add(color);
        }
      }
      final usedSorted = usedColors.toList()..sort();
      emitTrace('  neighbor colors used: $usedSorted');

      var selectedColor = 0;
      while (usedColors.contains(selectedColor)) {
        selectedColor++;
      }
      emitTrace('  assign color index $selectedColor');

      colorByNode[node] = selectedColor;
      uncolored.remove(node);

      final updatedNeighbors = <T>[];
      for (final neighbor in normalized[node] ?? <T>{}) {
        if (uncolored.contains(neighbor)) {
          saturationByNode[neighbor]!.add(selectedColor);
          updatedNeighbors.add(neighbor);
        }
      }
      emitTrace('  saturation++ for uncolored neighbors: $updatedNeighbors');
    }

    emitTrace('Final coloring: $colorByNode');
    finishColoringRun('DSATUR', sw, colorByNode);
    return colorByNode;
  }

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
