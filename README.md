# GraphSolver

Flutter app to **visualize undirected graphs** and experiment with **vertex coloring** algorithms. Nodes and edges come from editable **rule groups** (each group is a clique). The graph is laid out with a **force-directed** simulation (`flutter_force_directed_graph`).

## Features

- **Coloring methods**
  - Greedy, DSATUR, classic backtracking
  - Greedy / backtracking **for list coloring** (allowed color sets per node, merged with defaults from `lib/core/utils/colors.dart` when using those buttons without custom constraints)
- **Graph editor (sidebar)**  
  Add/remove nodes, edit rule groups (group id → members). Adjacency is the union of all cliques.
- **Allowed colors panel (right)**  
  Optional per-node **multi-select** of palette indices. If at least one node has a non-empty selection, the app switches to **list-only** mode: only Greedy and Backtracking run, using your constraints; nodes without a selection receive the full index range `0 … N−1` (see `GraphViewPage` in `lib/presentation/graph_view_page.dart`).
- **Live graph**  
  Node colors reflect the chosen method; errors from impossible colorings are shown on screen.

## Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK `^3.10.0` as in `pubspec.yaml`)

## Run

```bash
cd graph_solver
flutter pub get
flutter run
```

## Project layout

| Path | Role |
|------|------|
| `lib/main.dart` | App entry, `MaterialApp` |
| `lib/presentation/graph_view_page.dart` | Main screen: methods, graph, editors |
| `lib/presentation/widget/` | UI pieces (`custom_graph`, editors, buttons, node widget) |
| `lib/use_cases/` | Coloring algorithms |
| `lib/domain/enums.dart` | `ColoringMethod` |
| `lib/core/utils/colors.dart` | Default allowed color indices per node for list methods |

## Tests / analysis

```bash
flutter test
dart analyze
```

## License

See `pubspec.yaml` (`publish_to: 'none'` for this academic / local project).
