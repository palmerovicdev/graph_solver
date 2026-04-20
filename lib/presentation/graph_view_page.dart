import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
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
  late ForceDirectedGraph<String> _layoutGraph;
  late Map<String, Color> _colors;
  String _errorMessage = '';
  ColoringMethod _selectedColoringMethod = ColoringMethod.greedy;

  static Map<String, List<String>> _cloneGroupMap(Map<String, List<String>> m) {
    return m.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  @override
  void initState() {
    super.initState();
    _ruleGroups = {
      ..._cloneGroupMap(_gGroups),
      ..._cloneGroupMap(_tGroups),
    };
    _recomputeAdjacencyAndGraph();
    _refreshColors(firstTime: true);
  }

  void _recomputeAdjacencyAndGraph() {
    _adjacency = _buildAdjacencyFromRuleGroups(_ruleGroups);
    for (final n in _standaloneNodes) {
      _adjacency.putIfAbsent(n, () => <String>{});
    }
    _nodeColorConstraints.removeWhere((k, _) => !_adjacency.containsKey(k));
    _layoutGraph = _buildGraph();
  }

  bool get _usesListColoringConstraints =>
      _nodeColorConstraints.values.any((list) => list.isNotEmpty);

  void _normalizeSelectedMethodForListConstraints() {
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
      _errorMessage = '';
      return;
    }
    _normalizeSelectedMethodForListConstraints();
    try {
      _colors = _buildColors(_selectedColoringMethod);
      _errorMessage = '';
    } catch (e) {
      _colors = <String, Color>{};
      _errorMessage = e.toString();
    }
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

  ForceDirectedGraph<String> _buildGraph() {
    final graph = ForceDirectedGraph<String>(
      config: const GraphConfig(
        length: 90,
        repulsion: 120,
        repulsionRange: 370,
        elasticity: 0.9,
        scaling: 0.02,
        damping: 0.92,
        minVelocity: 2.5,
      ),
    );

    final labels = _adjacency.keys.toList()..sort();
    final nodes = <String, Node<String>>{};

    final radius = 120.0;

    for (var i = 0; i < labels.length; i++) {
      final label = labels[i];
      final angle = labels.length <= 1
          ? 0.0
          : 2 * math.pi * i / labels.length;
      final node = Node<String>(label);
      node.position.x = radius * math.cos(angle);
      node.position.y = radius * math.sin(angle);
      graph.addNode(node);
      nodes[label] = node;
    }

    final addedEdges = <String>{};

    for (final source in labels) {
      final targets = (_adjacency[source] ?? const <String>{}).toList()..sort();
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

  Map<String, Color> _buildColors(ColoringMethod method) {
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
      return colorIndexByNode.map((node, colorIndex) {
        final color = _colorForIndex(colorIndex);
        return MapEntry(node, color);
      });
    }

    final colorIndexByNode = switch (method) {
      ColoringMethod.greedy => _colorateWithGreedy(_adjacency, visitOrder: ['B', 'A', 'H', 'F', 'I', 'E', 'D', 'C', 'G']),
      ColoringMethod.dsatur => _colorateWithDsatur(_adjacency),
      ColoringMethod.backtracking => _colorateWithBacktracking(_adjacency),
      ColoringMethod.greedyForLists => _colorateWithGreedyForLists(
        _adjacency,
        allowedColorsByNode: _allowedColorsByNode(),
      ),
      ColoringMethod.backtrackingForLists => _colorateWithBacktrackingForLists(
        _adjacency,
        allowedColorsByNode: _allowedColorsByNode(),
      ),
    };

    return colorIndexByNode.map((node, colorIndex) {
      final color = _colorForIndex(colorIndex);
      return MapEntry(node, color);
    });
  }

  Color _colorForIndex(int colorIndex) {
    if (colorIndex < _palette.length) {
      return _palette[colorIndex];
    }

    final hue = (colorIndex * 47) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.72, 0.52).toColor();
  }

  void _changeColoringMethod(ColoringMethod method) {
    if (_selectedColoringMethod == method) {
      return;
    }
    if (_usesListColoringConstraints &&
        method != ColoringMethod.greedyForLists &&
        method != ColoringMethod.backtrackingForLists) {
      return;
    }

    setState(() {
      _selectedColoringMethod = method;
      try {
        _colors = _buildColors(method);
        _errorMessage = '';
      } catch (e) {
        _errorMessage = e.toString();
      }
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
                    if (_usesListColoringConstraints) ...[
                      MethodButton(
                        label: 'Greedy',
                        selected: _selectedColoringMethod ==
                            ColoringMethod.greedyForLists,
                        onPressed: () => _changeColoringMethod(
                          ColoringMethod.greedyForLists,
                        ),
                      ),
                      MethodButton(
                        label: 'Backtracking',
                        selected: _selectedColoringMethod ==
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
                        label: 'Backtracking',
                        selected: _selectedColoringMethod ==
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
