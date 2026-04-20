import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/model/graph.dart';
import 'package:flutter_force_directed_graph/widget/force_directed_graph_controller.dart';
import 'package:flutter_force_directed_graph/widget/force_directed_graph_widget.dart';
import 'package:graph_solver/domain/enums.dart';

import 'node_widget.dart';

class CustomGraph extends StatefulWidget {
  const CustomGraph({
    super.key,
    required this.graph,
    required this.colors,
    required this.coloringMethod,
    required this.simulationEnabled,
  });

  final ForceDirectedGraph<String> graph;
  final Map<String, Color> colors;
  final ColoringMethod coloringMethod;
  final bool simulationEnabled;

  @override
  State<CustomGraph> createState() => _CustomGraphState();
}

class _CustomGraphState extends State<CustomGraph> {
  late final ForceDirectedGraphController<String> _controller =
      ForceDirectedGraphController<String>(
        graph: widget.graph,
        minScale: 0.4,
        maxScale: 3.0,
      );

  void _kickSimulation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _controller.needUpdate();
    });
  }

  @override
  void initState() {
    super.initState();
    _kickSimulation();
  }

  @override
  void didUpdateWidget(covariant CustomGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.graph != oldWidget.graph) {
      _controller.graph = widget.graph;
    }
    final becameVisible =
        !oldWidget.simulationEnabled && widget.simulationEnabled;
    final methodChanged = oldWidget.coloringMethod != widget.coloringMethod;
    if (becameVisible || methodChanged || widget.graph != oldWidget.graph) {
      _kickSimulation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ForceDirectedGraphWidget<String>(
      controller: _controller,
      edgeAlwaysUp: false,
      onDraggingEnd: (_) => _controller.needUpdate(),
      nodesBuilder: (context, data) => CustomNodeWidget(
        data: data,
        color: widget.colors[data] ?? Colors.grey,
      ),
      edgesBuilder: (context, source, target, distance) {
        return Container(
          width: distance,
          height: 2,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade300,
            borderRadius: BorderRadius.circular(1),
          ),
        );
      },
    );
  }
}
