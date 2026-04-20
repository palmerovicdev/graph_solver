import 'package:flutter/material.dart';

class NodeListEditor extends StatefulWidget {
  const NodeListEditor({
    super.key,
    required this.nodes,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> nodes;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<NodeListEditor> createState() => _NodeListEditorState();
}

class _NodeListEditorState extends State<NodeListEditor> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    widget.onAdd(name);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nodes', style: titleStyle),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  hintText: 'Name',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: _submit,
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'Add node',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        if (widget.nodes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No nodes',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final n in widget.nodes)
                  InputChip(
                    label: Text(n, style: const TextStyle(fontSize: 13)),
                    onDeleted: () => widget.onRemove(n),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
