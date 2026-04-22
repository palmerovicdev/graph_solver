import 'package:graph_solver/core/coloring_run_logger.dart';

class ColorateWithGreedy<T> {
  const ColorateWithGreedy();

  /// [trace]: when `true`, logs a step-by-step trace to stdout.
  Map<T, int> call(
    Map<T, Set<T>> adjacency, {
    List<T>? visitOrder,
    bool trace = false,
  }) {
    final sw = startColoringRun('Greedy');

    void emitTrace(String message) {
      if (trace) {
        // ignore: avoid_print
        print('[Greedy] $message');
      }
    }

    final normalized = _normalizeUndirectedAdjacency(adjacency);
    if (normalized.isEmpty) {
      emitTrace('Empty graph after normalization.');
      finishColoringRun('Greedy', sw, <T, int>{});
      return <T, int>{};
    }

    var edgeCount = 0;
    for (final e in normalized.entries) {
      edgeCount += e.value.length;
    }
    edgeCount ~/= 2;
    emitTrace('Graph |V|=${normalized.length} |E|=$edgeCount (undirected).');
    emitTrace('visitOrder input=$visitOrder');

    final order = _buildVisitOrder(normalized, visitOrder);
    emitTrace('visit sequence (${order.length} nodes): $order');

    final colorByNode = <T, int>{};
    var step = 0;

    for (final node in order) {
      step++;
      final usedColors = <int>{};
      for (final neighbor in normalized[node] ?? <T>{}) {
        final neighborColor = colorByNode[neighbor];
        if (neighborColor != null) {
          usedColors.add(neighborColor);
        }
      }
      final usedSorted = usedColors.toList()..sort();
      emitTrace(
        '--- step $step/${order.length} node=$node --- '
        'blocked colors: $usedSorted',
      );

      var selectedColor = 0;
      while (usedColors.contains(selectedColor)) {
        selectedColor++;
      }
      emitTrace('  assign smallest free color index: $selectedColor');

      colorByNode[node] = selectedColor;
    }

    emitTrace('Final coloring: $colorByNode');
    finishColoringRun('Greedy', sw, colorByNode);
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
