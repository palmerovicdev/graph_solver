import 'package:flutter/material.dart';

List<String> parseMemberCsv(String raw) {
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}

Map<String, List<String>> cloneGroupMap(Map<String, List<String>> source) {
  return Map<String, List<String>>.fromEntries(
    source.entries.map((e) => MapEntry(e.key, List<String>.from(e.value))),
  );
}

class RuleGroupsEditor extends StatelessWidget {
  const RuleGroupsEditor({
    super.key,
    required this.groups,
    required this.onChanged,
  });

  final Map<String, List<String>> groups;
  final ValueChanged<Map<String, List<String>>> onChanged;

  Future<void> _editMembers(
    BuildContext context,
    String groupKey,
    List<String> current,
  ) async {
    final textController = TextEditingController(text: current.join(', '));
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit $groupKey'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Members (comma-separated)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, textController.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    textController.dispose();
    if (saved == null || !context.mounted) {
      return;
    }
    final next = cloneGroupMap(groups);
    final members = parseMemberCsv(saved);
    if (members.isEmpty) {
      next.remove(groupKey);
    } else {
      next[groupKey] = members;
    }
    onChanged(next);
  }

  Future<void> _addGroup(BuildContext context) async {
    final idController = TextEditingController();
    final membersController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('New group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'Group id',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: membersController,
                decoration: const InputDecoration(
                  labelText: 'Members (comma-separated)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    final id = idController.text.trim();
    idController.dispose();
    final membersRaw = membersController.text;
    membersController.dispose();
    if (ok != true || id.isEmpty || !context.mounted) {
      return;
    }
    final members = parseMemberCsv(membersRaw);
    if (members.isEmpty) {
      return;
    }
    final next = cloneGroupMap(groups);
    next[id] = members;
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rule groups', style: titleStyle),
        const SizedBox(height: 4),
        Text(
          'Each named group is a clique.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.white,
          elevation: 0.5,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (groups.isEmpty)
                  Text(
                    'No groups',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )
                else
                  ...groups.entries.map((e) {
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        e.value.join(', '),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _editMembers(context, e.key, e.value),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            tooltip: 'Remove group',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              final next = cloneGroupMap(groups);
                              next.remove(e.key);
                              onChanged(next);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _addGroup(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add group', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
