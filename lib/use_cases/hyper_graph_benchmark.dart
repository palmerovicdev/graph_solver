import 'package:graph_solver/core/super_graph_adjacency.dart';
import 'package:graph_solver/use_cases/colorate_with_dsatur.dart';
import 'package:graph_solver/use_cases/colorate_with_dsatur_dsi_optimized.dart';
import 'package:graph_solver/use_cases/colorate_with_greedy.dart';

class HyperGraphBenchmarkRequest {
  const HyperGraphBenchmarkRequest({
    required this.baseSeed,
    this.runs = 20,
    this.vertices = SuperGraphAdjacency.defaultVertexCount,
    this.desiredDensity = SuperGraphAdjacency.defaultDesiredDensity,
  });

  final int runs;
  final int vertices;
  final double desiredDensity;
  final int baseSeed;

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'runs': runs,
      'vertices': vertices,
      'desiredDensity': desiredDensity,
      'baseSeed': baseSeed,
    };
  }
}

class HyperGraphBenchmarkResult {
  const HyperGraphBenchmarkResult({
    required this.markdownTable,
    required this.runs,
    required this.vertices,
    required this.desiredDensity,
    required this.baseSeed,
  });

  factory HyperGraphBenchmarkResult.fromPayload(Map<String, dynamic> payload) {
    return HyperGraphBenchmarkResult(
      markdownTable: payload['markdownTable'] as String? ?? '',
      runs: (payload['runs'] as num?)?.toInt() ?? 0,
      vertices: (payload['vertices'] as num?)?.toInt() ?? 0,
      desiredDensity: (payload['desiredDensity'] as num?)?.toDouble() ?? 0,
      baseSeed: (payload['baseSeed'] as num?)?.toInt() ?? 0,
    );
  }

  final String markdownTable;
  final int runs;
  final int vertices;
  final double desiredDensity;
  final int baseSeed;
}

Map<String, dynamic> runHyperGraphBenchmarkInIsolate(
  Map<String, dynamic> payload,
) {
  final runs = (payload['runs'] as num?)?.toInt() ?? 20;
  final vertices =
      (payload['vertices'] as num?)?.toInt() ??
      SuperGraphAdjacency.defaultVertexCount;
  final desiredDensity =
      (payload['desiredDensity'] as num?)?.toDouble() ??
      SuperGraphAdjacency.defaultDesiredDensity;
  final baseSeed =
      (payload['baseSeed'] as num?)?.toInt() ??
      DateTime.now().microsecondsSinceEpoch;

  if (runs <= 0) {
    throw ArgumentError.value(runs, 'runs', 'must be >= 1');
  }
  if (vertices < 2) {
    throw ArgumentError.value(vertices, 'vertices', 'must be >= 2');
  }
  if (desiredDensity <= 0 || desiredDensity > 1) {
    throw ArgumentError.value(
      desiredDensity,
      'desiredDensity',
      'must be in (0, 1].',
    );
  }

  final greedy = const ColorateWithGreedy<String>();
  final dsatur = const ColorateWithDsatur<String>();
  final dsaturDsi = const ColorateWithDsaturDsiOptimized<String>();

  final detailRows = <_BenchmarkRow>[];
  final greedyStats = _AlgorithmStats();
  final dsaturStats = _AlgorithmStats();
  final dsaturDsiStats = _AlgorithmStats();

  for (var i = 0; i < runs; i++) {
    final runNumber = i + 1;
    final seed = baseSeed + i;
    final adjacency = SuperGraphAdjacency.build(
      vertices: vertices,
      desiredDensity: desiredDensity,
      seed: seed,
    );
    final edgeCount = _countUndirectedEdges(adjacency);

    final greedyRun = _runAlgorithm(() => greedy(adjacency));
    final dsaturRun = _runAlgorithm(() => dsatur(adjacency));
    final dsaturDsiRun = _runAlgorithm(() => dsaturDsi(adjacency));

    greedyStats.add(greedyRun);
    dsaturStats.add(dsaturRun);
    dsaturDsiStats.add(dsaturDsiRun);

    detailRows.add(
      _BenchmarkRow(
        run: runNumber,
        seed: seed,
        edgeCount: edgeCount,
        greedy: greedyRun,
        dsatur: dsaturRun,
        dsaturDsi: dsaturDsiRun,
      ),
    );
  }

  final markdownTable = _buildMarkdownTable(
    runs: runs,
    vertices: vertices,
    desiredDensity: desiredDensity,
    baseSeed: baseSeed,
    detailRows: detailRows,
    greedyStats: greedyStats,
    dsaturStats: dsaturStats,
    dsaturDsiStats: dsaturDsiStats,
  );

  return <String, dynamic>{
    'markdownTable': markdownTable,
    'runs': runs,
    'vertices': vertices,
    'desiredDensity': desiredDensity,
    'baseSeed': baseSeed,
  };
}

String _buildMarkdownTable({
  required int runs,
  required int vertices,
  required double desiredDensity,
  required int baseSeed,
  required List<_BenchmarkRow> detailRows,
  required _AlgorithmStats greedyStats,
  required _AlgorithmStats dsaturStats,
  required _AlgorithmStats dsaturDsiStats,
}) {
  final sb = StringBuffer();
  sb.writeln('# Hyper graph benchmark');
  sb.writeln('');
  sb.writeln(
    'Scenario: $vertices vertex(es), density ${desiredDensity.toStringAsFixed(3)}, '
    'runs $runs, base seed $baseSeed.',
  );
  sb.writeln(
    'Per-run seed rule: `seed = baseSeed + (run - 1)` to guarantee unique graph generation.',
  );
  sb.writeln('');
  sb.writeln('## Summary');
  sb.writeln('');
  sb.writeln(
    '| Algorithm | Avg time (ms) | Avg colors | Min colors | Max colors |',
  );
  sb.writeln('|---|---:|---:|---:|---:|');
  sb.writeln(
    '| Greedy | ${_formatMilliseconds(greedyStats.averageMicroseconds)} | '
    '${greedyStats.averageColors.toStringAsFixed(2)} | '
    '${greedyStats.minColors} | ${greedyStats.maxColors} |',
  );
  sb.writeln(
    '| DSATUR | ${_formatMilliseconds(dsaturStats.averageMicroseconds)} | '
    '${dsaturStats.averageColors.toStringAsFixed(2)} | '
    '${dsaturStats.minColors} | ${dsaturStats.maxColors} |',
  );
  sb.writeln(
    '| DSATUR-DSI | ${_formatMilliseconds(dsaturDsiStats.averageMicroseconds)} | '
    '${dsaturDsiStats.averageColors.toStringAsFixed(2)} | '
    '${dsaturDsiStats.minColors} | ${dsaturDsiStats.maxColors} |',
  );
  sb.writeln('');
  sb.writeln('## Detail by run');
  sb.writeln('');
  sb.writeln(
    '| Run | Seed | Edges | Greedy time | Greedy colors | DSATUR time | DSATUR colors | DSATUR-DSI time | DSATUR-DSI colors |',
  );
  sb.writeln('|---:|---:|---:|---:|---:|---:|---:|---:|---:|');

  for (final row in detailRows) {
    sb.writeln(
      '| ${row.run} | ${row.seed} | ${row.edgeCount} | '
      '${_formatDuration(row.greedy.elapsedMicroseconds)} | ${row.greedy.colorsUsed} | '
      '${_formatDuration(row.dsatur.elapsedMicroseconds)} | ${row.dsatur.colorsUsed} | '
      '${_formatDuration(row.dsaturDsi.elapsedMicroseconds)} | ${row.dsaturDsi.colorsUsed} |',
    );
  }

  return sb.toString();
}

int _countUndirectedEdges(Map<String, Set<String>> adjacency) {
  var edgeCount = 0;
  for (final neighbors in adjacency.values) {
    edgeCount += neighbors.length;
  }
  return edgeCount ~/ 2;
}

_AlgorithmRun _runAlgorithm(Map<String, int> Function() run) {
  final stopwatch = Stopwatch()..start();
  final coloring = run();
  stopwatch.stop();
  return _AlgorithmRun(
    elapsedMicroseconds: stopwatch.elapsedMicroseconds,
    colorsUsed: _countColorsUsed(coloring),
  );
}

int _countColorsUsed(Map<String, int> coloring) {
  if (coloring.isEmpty) {
    return 0;
  }
  var maxColorIndex = -1;
  for (final color in coloring.values) {
    if (color > maxColorIndex) {
      maxColorIndex = color;
    }
  }
  return maxColorIndex + 1;
}

String _formatDuration(int microseconds) {
  return Duration(microseconds: microseconds).toString();
}

String _formatMilliseconds(double microseconds) {
  return (microseconds / 1000).toStringAsFixed(3);
}

final class _BenchmarkRow {
  const _BenchmarkRow({
    required this.run,
    required this.seed,
    required this.edgeCount,
    required this.greedy,
    required this.dsatur,
    required this.dsaturDsi,
  });

  final int run;
  final int seed;
  final int edgeCount;
  final _AlgorithmRun greedy;
  final _AlgorithmRun dsatur;
  final _AlgorithmRun dsaturDsi;
}

final class _AlgorithmRun {
  const _AlgorithmRun({
    required this.elapsedMicroseconds,
    required this.colorsUsed,
  });

  final int elapsedMicroseconds;
  final int colorsUsed;
}

final class _AlgorithmStats {
  int _runCount = 0;
  int _totalMicroseconds = 0;
  int _totalColors = 0;
  int _minColors = 1 << 30;
  int _maxColors = -1;

  void add(_AlgorithmRun run) {
    _runCount++;
    _totalMicroseconds += run.elapsedMicroseconds;
    _totalColors += run.colorsUsed;
    if (run.colorsUsed < _minColors) {
      _minColors = run.colorsUsed;
    }
    if (run.colorsUsed > _maxColors) {
      _maxColors = run.colorsUsed;
    }
  }

  double get averageMicroseconds {
    if (_runCount == 0) {
      return 0;
    }
    return _totalMicroseconds / _runCount;
  }

  double get averageColors {
    if (_runCount == 0) {
      return 0;
    }
    return _totalColors / _runCount;
  }

  int get minColors => _runCount == 0 ? 0 : _minColors;
  int get maxColors => _runCount == 0 ? 0 : _maxColors;
}
