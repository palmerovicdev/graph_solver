import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:graph_solver/core/super_graph_adjacency.dart';
import 'package:graph_solver/core/utils/colors.dart';
import 'package:graph_solver/domain/enums.dart';
import 'package:graph_solver/presentation/widget/custom_graph.dart';
import 'package:graph_solver/presentation/widget/method_button.dart';
import 'package:graph_solver/presentation/widget/node_color_constraints_editor.dart';
import 'package:graph_solver/presentation/widget/node_list_editor.dart';
import 'package:graph_solver/presentation/widget/rule_groups_editor.dart';
import 'package:graph_solver/use_cases/colorate_with_backtracking.dart';
import 'package:graph_solver/use_cases/colorate_with_backtracking_for_lists.dart';
import 'package:graph_solver/use_cases/colorate_with_dsatur.dart';
import 'package:graph_solver/use_cases/colorate_with_dsatur_dsi_optimized.dart';
import 'package:graph_solver/use_cases/colorate_with_greedy.dart';
import 'package:graph_solver/use_cases/colorate_with_greedy_for_lists.dart';

class GraphViewPage extends StatefulWidget {
  const GraphViewPage({super.key});

  @override
  State<GraphViewPage> createState() => _GraphViewPageState();
}

class _GraphViewPageState extends State<GraphViewPage> {
  static const Map<String, List<String>> _gGroups = {
    'G1': ['A', 'B', 'C'],
    'G2': ['D', 'E', 'F'],
    'G3': ['G', 'H', 'I'],
  };

  static const Map<String, List<String>> _tGroups = {
    'T1': ['A', 'D', 'G'],
    'T2': ['B', 'E', 'H'],
    'T3': ['C', 'F', 'I'],
  };

  static const ColorateWithGreedy<String> _colorateWithGreedy =
      ColorateWithGreedy<String>();
  static const ColorateWithDsatur<String> _colorateWithDsatur =
      ColorateWithDsatur<String>();
  static const ColorateWithBacktracking<String> _colorateWithBacktracking =
      ColorateWithBacktracking<String>();
  static const ColorateWithGreedyForLists<String> _colorateWithGreedyForLists =
      ColorateWithGreedyForLists<String>();
  static const ColorateWithBacktrackingForLists<String>
  _colorateWithBacktrackingForLists =
      ColorateWithBacktrackingForLists<String>();

  static const ColorateWithDsaturDsiOptimized<String>
  _colorateWithDsaturDsiOptimized = ColorateWithDsaturDsiOptimized<String>();

  static const List<Color> _palette = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
  ];

  static const int _minColorUniverseSize = 8;
  static const int _maxColorUniverseSize = 64;

  final Set<String> _standaloneNodes = {};
  final Map<String, List<int>> _nodeColorConstraints = {};

  late Map<String, List<String>> _ruleGroups;
  late Map<String, Set<String>> _adjacency;
  late Map<String, Set<String>> _hyperPopulatedAdjacency;
  late ForceDirectedGraph<String> _layoutGraph;
  late Map<String, Color> _colors;
  String _errorMessage = '';
  ColoringMethod _selectedColoringMethod = ColoringMethod.greedy;
  /// When true, coloring runs on the stress graph; the canvas still shows the course graph only.
  bool _hyperGraphMode = false;
  String _hyperColoringSummary = '';

  static Map<String, List<String>> _cloneGroupMap(Map<String, List<String>> m) {
    return m.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  @override
  void initState() {
    super.initState();
    _ruleGroups = {..._cloneGroupMap(_gGroups), ..._cloneGroupMap(_tGroups)};
    _recomputeAdjacencyAndGraph();
    _refreshColors(firstTime: true);
  }

  void _recomputeAdjacencyAndGraph() {
    _adjacency = _buildAdjacencyFromRuleGroups(_ruleGroups);
    _hyperPopulatedAdjacency = SuperGraphAdjacency.build();
    for (final n in _standaloneNodes) {
      _adjacency.putIfAbsent(n, () => <String>{});
    }
    _nodeColorConstraints.removeWhere((k, _) => !_adjacency.containsKey(k));
    _layoutGraph = _buildGraph(_adjacency);
  }

  bool get _usesListColoringConstraints =>
      _nodeColorConstraints.values.any((list) => list.isNotEmpty);

  void _normalizeSelectedMethodForListConstraints() {
    if (_usesListColoringConstraints) {
      _hyperGraphMode = false;
    }
    if (!_usesListColoringConstraints) {
      _selectedColoringMethod = ColoringMethod.greedy;
      return;
    }
    if (_selectedColoringMethod == ColoringMethod.greedy ||
        _selectedColoringMethod == ColoringMethod.dsatur ||
        _selectedColoringMethod == ColoringMethod.backtracking) {
      _selectedColoringMethod = ColoringMethod.greedyForLists;
    }
  }

  int get _colorUniverseSize {
    var maxIndex = _palette.length - 1;
    for (final list in _nodeColorConstraints.values) {
      for (final i in list) {
        if (i > maxIndex) {
          maxIndex = i;
        }
      }
    }
    final n = math.max(_minColorUniverseSize, maxIndex + 1);
    return n > _maxColorUniverseSize ? _maxColorUniverseSize : n;
  }

  Map<String, List<int>> _effectiveAllowedColorsByNode() {
    final universe = List.generate(_colorUniverseSize, (i) => i);
    final out = <String, List<int>>{};
    for (final node in _adjacency.keys) {
      final explicit = _nodeColorConstraints[node];
      if (explicit != null && explicit.isNotEmpty) {
        out[node] = [...explicit.toSet()]..sort();
      } else {
        out[node] = List<int>.from(universe);
      }
    }
    return out;
  }

  void _refreshColors({bool firstTime = false}) {
    if (firstTime) {
      _colors = <String, Color>{};
      _hyperColoringSummary = '';
      _errorMessage = '';
      return;
    }
    _normalizeSelectedMethodForListConstraints();
    _applyColoringOrError();
  }

  void _applyColoringOrError() {
    try {
      final bundle = _buildColoringDisplay(_selectedColoringMethod);
      _colors = bundle.displayColors;
      _hyperColoringSummary = bundle.hyperSummary;
      _errorMessage = '';
    } catch (e) {
      _colors = <String, Color>{};
      _hyperColoringSummary = '';
      _errorMessage = e.toString();
    }
  }

  Map<String, Set<String>> get _coloringAdjacency =>
      _hyperGraphMode ? _hyperPopulatedAdjacency : _adjacency;

  List<String>? get _visitOrderForColoring =>
      _hyperGraphMode ? null : _buildCustomVisitOrder;

  /// Colors for the force-directed canvas plus an optional stress-run summary line.
  ({Map<String, Color> displayColors, String hyperSummary}) _buildColoringDisplay(
    ColoringMethod method,
  ) {
    if (_usesListColoringConstraints) {
      final allowed = _effectiveAllowedColorsByNode();
      final colorIndexByNode = method == ColoringMethod.backtrackingForLists
          ? _colorateWithBacktrackingForLists(
              _adjacency,
              allowedColorsByNode: allowed,
            )
          : _colorateWithGreedyForLists(
              _adjacency,
              allowedColorsByNode: allowed,
            );
      final displayColors = colorIndexByNode.map((node, colorIndex) {
        return MapEntry(node, _colorForIndex(colorIndex));
      });
      return (displayColors: displayColors, hyperSummary: '');
    }

    final adj = _coloringAdjacency;
    final visitOrder = _visitOrderForColoring;

    final colorIndexByNode = switch (method) {
      ColoringMethod.greedy => _colorateWithGreedy(
        adj,
        visitOrder: visitOrder,
      ),
      ColoringMethod.dsatur => _colorateWithDsatur(
        adj,
        visitOrder: visitOrder,
      ),
      ColoringMethod.backtracking => _colorateWithBacktracking(adj),
      ColoringMethod.greedyForLists => _colorateWithGreedyForLists(
        _adjacency,
        allowedColorsByNode: _allowedColorsByNode(),
      ),
      ColoringMethod.backtrackingForLists => _colorateWithBacktrackingForLists(
        _adjacency,
        allowedColorsByNode: _allowedColorsByNode(),
      ),
      ColoringMethod.dsaturDsiOptimized => _colorateWithDsaturDsiOptimized(
        adj,
        visitOrder: visitOrder,
      ),
    };

    if (_hyperGraphMode) {
      final maxColorIndex = colorIndexByNode.values.fold<int>(
        -1,
        (m, c) => c > m ? c : m,
      );
      final colorCount = maxColorIndex < 0 ? 0 : maxColorIndex + 1;
      final summary =
          'Stress graph coloring: |V|=${colorIndexByNode.length}, '
          'used $colorCount color index(es)'
          '${maxColorIndex >= 0 ? ' (0..$maxColorIndex)' : ''}. '
          'Canvas shows the course graph only.';
      final displayColors = <String, Color>{
        for (final id in _adjacency.keys) id: const Color(0xFFB0BEC5),
      };
      return (displayColors: displayColors, hyperSummary: summary);
    }

    final displayColors = colorIndexByNode.map((node, colorIndex) {
      return MapEntry(node, _colorForIndex(colorIndex));
    });
    return (displayColors: displayColors, hyperSummary: '');
  }

  Map<String, List<int>> _allowedColorsByNode() {
    final merged = <String, List<int>>{
      for (final e in colorsByGroup.entries) e.key: List<int>.from(e.value),
    };
    for (final node in _adjacency.keys) {
      merged.putIfAbsent(node, () => [0, 1, 2, 3]);
    }
    return merged;
  }

  void _addStandaloneNode(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      return;
    }
    if (_adjacency.containsKey(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That node already exists.')),
      );
      return;
    }
    setState(() {
      _standaloneNodes.add(name);
      _recomputeAdjacencyAndGraph();
      _refreshColors();
    });
  }

  void _removeNodeEverywhere(String name) {
    setState(() {
      _standaloneNodes.remove(name);
      _ruleGroups = () {
        final next = <String, List<String>>{};
        for (final e in _ruleGroups.entries) {
          final filtered = e.value.where((n) => n != name).toList();
          if (filtered.isNotEmpty) {
            next[e.key] = filtered;
          }
        }
        return next;
      }();
      _recomputeAdjacencyAndGraph();
      _refreshColors();
    });
  }

  void _onRuleGroupsChanged(Map<String, List<String>> next) {
    setState(() {
      _ruleGroups = next;
      _recomputeAdjacencyAndGraph();
      _refreshColors();
    });
  }

  void _onNodeColorConstraintsChanged(Map<String, List<int>> next) {
    setState(() {
      _nodeColorConstraints
        ..clear()
        ..addAll(next);
      _refreshColors();
    });
  }

  ForceDirectedGraph<String> _buildGraph(Map<String, Set<String>> adjacency) {
    final graph = ForceDirectedGraph<String>(
      config: GraphConfig(
        length: 90,
        repulsion: adjacency.length > 200 ? 40 : 120,
        repulsionRange: adjacency.length > 200 ? 120 : 370,
        elasticity: 0.9,
        scaling: adjacency.length > 200 ? 0.008 : 0.02,
        damping: 0.92,
        minVelocity: adjacency.length > 200 ? 0.8 : 2.5,
      ),
    );

    final labels = adjacency.keys.toList()..sort();
    final nodes = <String, Node<String>>{};

    final radius = 120.0;

    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final angle = labels.length <= 1 ? 0.0 : 2 * math.pi * i / labels.length;
      final node = Node<String>(label);
      node.position.x = radius * math.cos(angle);
      node.position.y = radius * math.sin(angle);
      graph.addNode(node);
      nodes[label] = node;
    }

    final addedEdges = <String>{};

    for (final source in labels) {
      final targets = (adjacency[source] ?? const <String>{}).toList()..sort();
      for (final target in targets) {
        final sourceNode = nodes[source];
        final targetNode = nodes[target];
        if (sourceNode == null || targetNode == null) {
          continue;
        }

        final edgeKey = source.compareTo(target) < 0
            ? '$source-$target'
            : '$target-$source';

        if (addedEdges.add(edgeKey)) {
          graph.addEdge(Edge(sourceNode, targetNode));
        }
      }
    }

    return graph;
  }

  Map<String, Set<String>> _buildAdjacencyFromRuleGroups(
    Map<String, List<String>> groups,
  ) {
    final adjacency = <String, Set<String>>{};
    for (final members in groups.values) {
      for (final member in members) {
        adjacency.putIfAbsent(member, () => <String>{});
      }
      for (var i = 0; i < members.length; i++) {
        for (var j = i + 1; j < members.length; j++) {
          final a = members[i];
          final b = members[j];
          adjacency[a]!.add(b);
          adjacency[b]!.add(a);
        }
      }
    }
    return adjacency;
  }

  List<String> get _buildCustomVisitOrder {
    final order = {'B', 'A', 'H', 'F', 'I', 'E', 'D', 'C', 'G'};
    final nodes = _adjacency.keys.toSet();
    // If the order has the same nodes as the selected ones, return the order, otherwise return an empty list.
    return order.intersection(nodes).length == nodes.length
        ? order.toList()
        : [];
  }

  Color _colorForIndex(int colorIndex) {
    if (colorIndex < _palette.length) {
      return _palette[colorIndex];
    }

    final hue = (colorIndex * 47) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.72, 0.52).toColor();
  }

  void _changeColoringMethod(ColoringMethod method) {
    if (_usesListColoringConstraints &&
        method != ColoringMethod.greedyForLists &&
        method != ColoringMethod.backtrackingForLists) {
      return;
    }

    if (_selectedColoringMethod == method) {
      return;
    }

    setState(() {
      _selectedColoringMethod = method;
      _layoutGraph = _buildGraph(_adjacency);
      _applyColoringOrError();
    });
  }

  void _toggleHyperGraphMode() {
    if (_usesListColoringConstraints) {
      return;
    }
    setState(() {
      _hyperGraphMode = !_hyperGraphMode;
      _layoutGraph = _buildGraph(_adjacency);
      _applyColoringOrError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedNodes = _adjacency.keys.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                width: 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    MethodButton(
                      label: 'Stress graph (color only)',
                      selected: _hyperGraphMode,
                      onPressed: _toggleHyperGraphMode,
                    ),
                    const SizedBox(height: 12),
                    if (_usesListColoringConstraints) ...[
                      MethodButton(
                        label: 'Greedy',
                        selected:
                            _selectedColoringMethod ==
                            ColoringMethod.greedyForLists,
                        onPressed: () => _changeColoringMethod(
                          ColoringMethod.greedyForLists,
                        ),
                      ),
                      MethodButton(
                        label: 'Backtracking',
                        selected:
                            _selectedColoringMethod ==
                            ColoringMethod.backtrackingForLists,
                        onPressed: () => _changeColoringMethod(
                          ColoringMethod.backtrackingForLists,
                        ),
                      ),
                    ] else ...[
                      MethodButton(
                        label: 'Greedy',
                        selected:
                            _selectedColoringMethod == ColoringMethod.greedy,
                        onPressed: () =>
                            _changeColoringMethod(ColoringMethod.greedy),
                      ),
                      MethodButton(
                        label: 'DSATUR',
                        selected:
                            _selectedColoringMethod == ColoringMethod.dsatur,
                        onPressed: () =>
                            _changeColoringMethod(ColoringMethod.dsatur),
                      ),
                      MethodButton(
                        label: 'DSATUR DSI Optimized',
                        selected: _selectedColoringMethod ==
                            ColoringMethod.dsaturDsiOptimized,
                        onPressed: () => _changeColoringMethod(
                          ColoringMethod.dsaturDsiOptimized,
                        ),
                      ),
                      MethodButton(
                        label: 'Backtracking',
                        selected:
                            _selectedColoringMethod ==
                            ColoringMethod.backtracking,
                        onPressed: () =>
                            _changeColoringMethod(ColoringMethod.backtracking),
                      ),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 16,
                          children: [
                            NodeListEditor(
                              nodes: sortedNodes,
                              onAdd: _addStandaloneNode,
                              onRemove: _removeNodeEverywhere,
                            ),
                            RuleGroupsEditor(
                              groups: _ruleGroups,
                              onChanged: _onRuleGroupsChanged,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Offstage(
                        offstage: _errorMessage.isNotEmpty,
                        child: TickerMode(
                          enabled: _errorMessage.isEmpty,
                          child: CustomGraph(
                            graph: _layoutGraph,
                            colors: _colors,
                            coloringMethod: _selectedColoringMethod,
                            simulationEnabled: _errorMessage.isEmpty,
                          ),
                        ),
                      ),
                      if (_hyperGraphMode &&
                          _hyperColoringSummary.isNotEmpty &&
                          _errorMessage.isEmpty)
                        Positioned(
                          left: 12,
                          top: 12,
                          right: 12,
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withValues(alpha: 0.94),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Text(
                                _hyperColoringSummary,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade800,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_errorMessage.isNotEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SafeArea(
                  left: false,
                  bottom: false,
                  child: Material(
                    color: const Color(0xFFF8FAFC),
                    elevation: 0,
                    child: Container(
                      width: 268,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                        child: NodeColorConstraintsEditor(
                          nodes: sortedNodes,
                          slotCount: _colorUniverseSize,
                          slotColors: List.generate(
                            _colorUniverseSize,
                            _colorForIndex,
                          ),
                          constraints: Map<String, List<int>>.from(
                            _nodeColorConstraints,
                          ),
                          onChanged: _onNodeColorConstraintsChanged,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
