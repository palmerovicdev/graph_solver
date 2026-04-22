
Stopwatch startColoringRun(String algorithmTag) {
  final sw = Stopwatch()..start();
  // ignore: avoid_print
  print(
    '[$algorithmTag] START wall=${DateTime.now().toIso8601String()} '
    'stopwatch=running',
  );
  return sw;
}

void finishColoringRun<T>(
  String algorithmTag,
  Stopwatch sw,
  Map<T, int> colorByNode,
) {
  sw.stop();
  final wall = DateTime.now().toIso8601String();
  final elapsed = sw.elapsed;
  if (colorByNode.isEmpty) {
    // ignore: avoid_print
    print(
      '[$algorithmTag] END wall=$wall elapsed=$elapsed |V|=0 (empty coloring).',
    );
    return;
  }
  final maxColorIndex = colorByNode.values.fold<int>(
    -1,
    (m, c) => c > m ? c : m,
  );
  final colorsUsed = maxColorIndex < 0 ? 0 : maxColorIndex + 1;
  // ignore: avoid_print
  print(
    '[$algorithmTag] END wall=$wall elapsed=$elapsed '
    '|V|=${colorByNode.length} maxColorIndex=$maxColorIndex colorsUsed=$colorsUsed',
  );
}
