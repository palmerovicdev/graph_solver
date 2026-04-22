import 'package:collection/collection.dart';
import 'package:graph_solver/core/coloring_run_logger.dart';

class _NodeState {
  _NodeState({
    required this.degree,
    required this.priority,
    required this.tieBreakId,
  });

  int saturation = 0;
  int degree;
  int priority;
  int version = 0;
  int tieBreakId;
  int? color;
  final Set<int> seenColors = <int>{};
}

class ColorateWithDsaturDsiOptimized<T> {
  const ColorateWithDsaturDsiOptimized();

  static const int _defaultPriority = 1 << 30;

  /// [trace]: when `true`, logs a step-by-step trace to stdout (avoid on huge graphs).
  Map<T, int> call(
    Map<T, Set<T>> adjacency, {
    List<T>? visitOrder,
    bool trace = false,
  }) {
    final sw = startColoringRun('DSATUR-DSI');

    void emitTrace(String message) {
      if (trace) {
        // ignore: avoid_print
        print('[DSATUR-DSI] $message');
      }
    }

    final normalized = _normalizeUndirectedAdjacency(adjacency);
    if (normalized.isEmpty) {
      emitTrace('Empty graph after normalization; nothing to color.');
      finishColoringRun('DSATUR-DSI', sw, <T, int>{});
      return <T, int>{};
    }

    var undirectedEdges = 0;
    for (final entry in normalized.entries) {
      undirectedEdges += entry.value.length;
    }
    undirectedEdges ~/= 2;

    emitTrace(
      'Start: |V|=${normalized.length}, |E|=$undirectedEdges (undirected, after normalization).',
    );

    if (visitOrder != null && visitOrder.isNotEmpty) {
      emitTrace(
        'Tie-break visit order (lower index = higher priority): $visitOrder',
      );
    } else {
      emitTrace(
        'No visit order: tie-break by node id string only (optimized to numeric ID internally).',
      );
    }

    final states = <T, _NodeState>{};
    final priorityByNode = _buildPriorityByNode(normalized, visitOrder);

    int tieBreakCounter = 0;
    for (final node in normalized.keys) {
      states[node] = _NodeState(
        degree: normalized[node]!.length,
        priority: priorityByNode[node] ?? _defaultPriority,
        tieBreakId: tieBreakCounter++,
      );
    }

    final uncolored = normalized.keys.toSet();
    final heap = HeapPriorityQueue<_NodeEntry<T>>(_compareNodeEntries);

    void pushNode(T node, _NodeState state) {
      heap.add(
        _NodeEntry<T>(
          node: node,
          saturation: state.saturation,
          degree: state.degree,
          priority: state.priority,
          version: state.version,
          tieBreakId: state.tieBreakId,
        ),
      );
    }

    for (final entry in states.entries) {
      pushNode(entry.key, entry.value);
    }

    var currentMaxColor = -1;
    var stepIndex = 0;

    while (uncolored.isNotEmpty) {
      stepIndex++;
      emitTrace('--- Step $stepIndex: ${uncolored.length} uncolored ---');

      final node = _extractBestNode(
        heap: heap,
        uncolored: uncolored,
        states: states,
        emitTrace: emitTrace,
      );

      final state = states[node]!;
      final sat = state.saturation;
      final deg = state.degree;
      final pri = state.priority;
      final priLabel = pri == _defaultPriority
          ? '(default $_defaultPriority)'
          : pri.toString();

      emitTrace(
        'Pick node: $node | saturation=$sat degree=$deg priority=$priLabel',
      );

      final usedColorsForTrace = <int>{};
      for (final neighbor in normalized[node]!) {
        final c = states[neighbor]!.color;
        if (c != null) usedColorsForTrace.add(c);
      }
      final usedSorted = usedColorsForTrace.toList()..sort();
      emitTrace('  Colors used by colored neighbors: $usedSorted');

      int? selectedColor = _findSmallestAvailableColorFast(
        node,
        normalized,
        states,
        currentMaxColor,
      );

      if (selectedColor != null) {
        emitTrace(
          '  Smallest feasible color in [0..$currentMaxColor] '
          'not blocked by neighbors: $selectedColor',
        );
      } else {
        emitTrace(
          '  No hole in [0..$currentMaxColor]; trying Kempe interchange '
          'before introducing color ${currentMaxColor + 1}.',
        );

        selectedColor = _tryKempeInterchange(
          targetNode: node,
          adjacency: normalized,
          states: states,
          uncolored: uncolored,
          heap: heap,
          currentMaxColor: currentMaxColor,
          emitTrace: emitTrace,
        );

        if (selectedColor != null) {
          emitTrace(
            '  Kempe succeeded: can use color $selectedColor for $node.',
          );
        } else {
          emitTrace(
            '  Kempe did not free a color; will allocate a new color index.',
          );
        }
      }

      selectedColor ??= currentMaxColor + 1;
      if (selectedColor > currentMaxColor) {
        emitTrace(
          '  New maximum color index: $selectedColor (was $currentMaxColor).',
        );
        currentMaxColor = selectedColor;
      }

      state.color = selectedColor;
      uncolored.remove(node);
      emitTrace('  ASSIGN $node <- color $selectedColor');

      _updateNeighborsAfterColoring(
        node: node,
        color: selectedColor,
        adjacency: normalized,
        states: states,
        uncolored: uncolored,
        heap: heap,
        emitTrace: emitTrace,
      );
    }

    final colorByNode = <T, int>{};
    for (final entry in states.entries) {
      colorByNode[entry.key] = entry.value.color!;
    }

    final distinctColorCount = currentMaxColor + 1;
    emitTrace(
      'Done. Colored ${colorByNode.length} nodes; '
      'max color index = $currentMaxColor '
      '=> $distinctColorCount color classes (indices 0..$currentMaxColor).',
    );
    if (colorByNode.length <= 128) {
      emitTrace('Final color map: $colorByNode');
    } else {
      emitTrace(
        'Final color map omitted (${colorByNode.length} entries); '
        'keep trace off or |V|<=128 to print the full map.',
      );
    }

    finishColoringRun('DSATUR-DSI', sw, colorByNode);
    return colorByNode;
  }

  int _compareNodeEntries(_NodeEntry<T> a, _NodeEntry<T> b) {
    final sat = b.saturation.compareTo(a.saturation);
    if (sat != 0) return sat;

    final deg = b.degree.compareTo(a.degree);
    if (deg != 0) return deg;

    final pri = a.priority.compareTo(b.priority);
    if (pri != 0) return pri;

    return a.tieBreakId.compareTo(b.tieBreakId);
  }

  T _extractBestNode({
    required HeapPriorityQueue<_NodeEntry<T>> heap,
    required Set<T> uncolored,
    required Map<T, _NodeState> states,
    required void Function(String) emitTrace,
  }) {
    var discardedPops = 0;
    while (heap.isNotEmpty) {
      final entry = heap.removeFirst();
      final node = entry.node;

      if (!uncolored.contains(node)) {
        discardedPops++;
        continue;
      }

      final state = states[node]!;
      if (entry.version != state.version ||
          entry.saturation != state.saturation) {
        discardedPops++;
        continue;
      }

      if (discardedPops > 0) {
        emitTrace(
          '  Heap: discarded $discardedPops stale/outdated heap entries '
          'before accepting top candidate.',
        );
      }
      return node;
    }
    throw StateError('No valid node found in heap.');
  }

  int? _findSmallestAvailableColorFast(
    T node,
    Map<T, Set<T>> adjacency,
    Map<T, _NodeState> states,
    int currentMaxColor,
  ) {
    if (currentMaxColor < 0) return null;

    final used = List<bool>.filled(currentMaxColor + 1, false);
    for (final neighbor in adjacency[node]!) {
      final color = states[neighbor]!.color;
      if (color != null && color <= currentMaxColor) {
        used[color] = true;
      }
    }

    for (var i = 0; i <= currentMaxColor; i++) {
      if (!used[i]) return i;
    }
    return null;
  }

  int? _tryKempeInterchange({
    required T targetNode,
    required Map<T, Set<T>> adjacency,
    required Map<T, _NodeState> states,
    required Set<T> uncolored,
    required HeapPriorityQueue<_NodeEntry<T>> heap,
    required int currentMaxColor,
    required void Function(String) emitTrace,
  }) {
    if (currentMaxColor < 0) {
      emitTrace('    Kempe: currentMaxColor < 0 => return color 0.');
      return 0;
    }

    final neighborsByColor = <int, List<T>>{};
    for (final neighbor in adjacency[targetNode]!) {
      final color = states[neighbor]!.color;
      if (color != null) {
        neighborsByColor.putIfAbsent(color, () => <T>[]).add(neighbor);
      }
    }

    if (neighborsByColor.isEmpty) {
      emitTrace('    Kempe: no colored neighbors => return color 0.');
      return 0;
    }

    final blockedColors = neighborsByColor.keys.toList()..sort();
    emitTrace(
      '    Kempe: target=$targetNode, neighbor colors (blocked): $blockedColors '
      '| detail: ${neighborsByColor.map((k, v) => MapEntry(k, v.toList()))}',
    );

    for (final colorA in blockedColors) {
      final aNeighbors = neighborsByColor[colorA]!;
      if (aNeighbors.isEmpty) continue;

      for (var colorB = 0; colorB <= currentMaxColor; colorB++) {
        if (colorA == colorB) continue;

        emitTrace('    Kempe: try swap palette ($colorA <-> $colorB) ...');

        final bNeighbors = (neighborsByColor[colorB] ?? <T>[]).toSet();
        final visitedAStarts = <T>{};
        final componentsToSwap = <Set<T>>[];
        var validPair = true;

        for (final start in aNeighbors) {
          if (visitedAStarts.contains(start)) continue;

          final searchResult = _searchTwoColorComponentDFS(
            start: start,
            colorA: colorA,
            colorB: colorB,
            adjacency: adjacency,
            states: states,
            forbiddenTargets: bNeighbors,
          );

          if (searchResult.hitForbidden) {
            emitTrace(
              '      Component from start=$start hit forbidden B-neighbor; '
              'pair ($colorA,$colorB) rejected.',
            );
            validPair = false;
            break;
          }

          emitTrace(
            '      DFS 2-color subgraph from start=$start: '
            '|V|=${searchResult.component.length}, hitForbidden=false',
          );

          componentsToSwap.add(searchResult.component);

          for (final vertex in searchResult.component) {
            if (states[vertex]!.color == colorA &&
                aNeighbors.contains(vertex)) {
              visitedAStarts.add(vertex);
            }
          }
        }

        if (!validPair || componentsToSwap.isEmpty) continue;

        final unionComponent = <T>{};
        for (final component in componentsToSwap) {
          unionComponent.addAll(component);
        }

        emitTrace(
          '    Kempe: swapping colors $colorA <-> $colorB on '
          '${unionComponent.length} vertices; then $targetNode may take $colorA.',
        );

        for (final node in unionComponent) {
          final state = states[node]!;
          if (state.color == colorA) {
            state.color = colorB;
          } else if (state.color == colorB) {
            state.color = colorA;
          }
        }

        _refreshAffectedUncoloredNeighborsAfterSwap(
          swappedNodes: unionComponent,
          adjacency: adjacency,
          states: states,
          uncolored: uncolored,
          heap: heap,
          emitTrace: emitTrace,
        );

        return colorA;
      }
    }

    emitTrace(
      '    Kempe: exhausted all (colorA, colorB) pairs without success.',
    );
    return null;
  }

  _TwoColorSearchResult<T> _searchTwoColorComponentDFS({
    required T start,
    required int colorA,
    required int colorB,
    required Map<T, Set<T>> adjacency,
    required Map<T, _NodeState> states,
    required Set<T> forbiddenTargets,
  }) {
    final component = <T>{};
    final stack = <T>[start];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      if (!component.add(current)) continue;

      if (forbiddenTargets.contains(current) && current != start) {
        return _TwoColorSearchResult<T>(
          component: component,
          hitForbidden: true,
        );
      }

      for (final neighbor in adjacency[current]!) {
        final color = states[neighbor]!.color;
        if ((color == colorA || color == colorB) &&
            !component.contains(neighbor)) {
          stack.add(neighbor);
        }
      }
    }

    return _TwoColorSearchResult<T>(component: component, hitForbidden: false);
  }

  void _updateNeighborsAfterColoring({
    required T node,
    required int color,
    required Map<T, Set<T>> adjacency,
    required Map<T, _NodeState> states,
    required Set<T> uncolored,
    required HeapPriorityQueue<_NodeEntry<T>> heap,
    required void Function(String) emitTrace,
  }) {
    final bumped = <String>[];
    for (final neighbor in adjacency[node]!) {
      if (!uncolored.contains(neighbor)) continue;

      final state = states[neighbor]!;
      if (state.seenColors.add(color)) {
        state.saturation = state.seenColors.length;
        state.version++;

        heap.add(
          _NodeEntry<T>(
            node: neighbor,
            saturation: state.saturation,
            degree: state.degree,
            priority: state.priority,
            version: state.version,
            tieBreakId: state.tieBreakId,
          ),
        );

        final seenList = state.seenColors.toList()..sort();
        bumped.add(
          '$neighbor -> saturation=${state.saturation} '
          '(seen colors: $seenList)',
        );
      }
    }

    if (bumped.isEmpty) {
      emitTrace(
        '  Neighbor update: no uncolored neighbor gained a new seen color.',
      );
    } else {
      emitTrace(
        '  Neighbor update: ${bumped.length} uncolored neighbor(s) '
        'increased saturation / re-queued:\n    ${bumped.join('\n    ')}',
      );
    }
  }

  void _refreshAffectedUncoloredNeighborsAfterSwap({
    required Set<T> swappedNodes,
    required Map<T, Set<T>> adjacency,
    required Map<T, _NodeState> states,
    required Set<T> uncolored,
    required HeapPriorityQueue<_NodeEntry<T>> heap,
    required void Function(String) emitTrace,
  }) {
    final affectedUncolored = <T>{};

    for (final swapped in swappedNodes) {
      for (final neighbor in adjacency[swapped]!) {
        if (uncolored.contains(neighbor)) {
          affectedUncolored.add(neighbor);
        }
      }
    }

    emitTrace(
      '    Kempe after-swap: recompute saturation for '
      '${affectedUncolored.length} uncolored neighbor(s) of swapped set.',
    );

    for (final node in affectedUncolored) {
      final state = states[node]!;
      state.seenColors.clear();

      for (final neighbor in adjacency[node]!) {
        final color = states[neighbor]!.color;
        if (color != null) {
          state.seenColors.add(color);
        }
      }

      state.saturation = state.seenColors.length;
      state.version++;

      heap.add(
        _NodeEntry<T>(
          node: node,
          saturation: state.saturation,
          degree: state.degree,
          priority: state.priority,
          version: state.version,
          tieBreakId: state.tieBreakId,
        ),
      );

      final seenSorted = state.seenColors.toList()..sort();
      emitTrace(
        '      refresh $node: saturation=${state.saturation} '
        'seen=$seenSorted',
      );
    }
  }

  Map<T, int> _buildPriorityByNode(
    Map<T, Set<T>> adjacency,
    List<T>? visitOrder,
  ) {
    if (visitOrder == null) return <T, int>{};
    final priorityByNode = <T, int>{};
    for (var index = 0; index < visitOrder.length; index++) {
      final node = visitOrder[index];
      if (adjacency.containsKey(node)) priorityByNode[node] = index;
    }
    return priorityByNode;
  }

  Map<T, Set<T>> _normalizeUndirectedAdjacency(Map<T, Set<T>> adjacency) {
    final normalized = <T, Set<T>>{};
    for (final entry in adjacency.entries) {
      normalized.putIfAbsent(entry.key, () => <T>{});
      for (final neighbor in entry.value) {
        if (neighbor == entry.key) continue;
        normalized.putIfAbsent(neighbor, () => <T>{});
        normalized[entry.key]!.add(neighbor);
        normalized[neighbor]!.add(entry.key);
      }
    }
    return normalized;
  }
}

class _NodeEntry<T> {
  const _NodeEntry({
    required this.node,
    required this.saturation,
    required this.degree,
    required this.priority,
    required this.version,
    required this.tieBreakId,
  });

  final T node;
  final int saturation;
  final int degree;
  final int priority;
  final int version;
  final int tieBreakId;
}

class _TwoColorSearchResult<T> {
  const _TwoColorSearchResult({
    required this.component,
    required this.hitForbidden,
  });

  final Set<T> component;
  final bool hitForbidden;
}
