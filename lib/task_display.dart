import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final taskDisplaySchema = S.object(
  properties: {
    'component': S.string(enumValues: ['TaskDisplay']),
    'title': S.string(description: 'The title of the task list'),
    'tasks': S.list(
      description: 'A list of tasks to be completed today',
      items: S.object(
        properties: {
          'name': S.string(description: 'The name of the task to be completed'),
          'isCompleted': S.boolean(
            description: 'Whether the task is completed',
          ),
          'completeAction': A2uiSchemas.action(
            description:
                'The action performed when the user has completed the task.',
          ),
        },
        required: ['name', 'isCompleted', 'completeAction'],
      ),
    ),
  },
  required: ['title', 'tasks'],
);

class _TaskData {
  final String name;
  final bool isCompleted;
  final String actionName;
  final JsonMap actionContext;

  _TaskData({
    required this.name,
    required this.isCompleted,
    required this.actionName,
    required this.actionContext,
  });

  factory _TaskData.fromJson(Map<String, Object?> json) {
    try {
      final action = json['completeAction']! as JsonMap;
      final event = action['event']! as JsonMap;

      return _TaskData(
        name: json['name'] as String,
        isCompleted: json['isCompleted'] as bool,
        actionName: event['name'] as String,
        actionContext: event['context'] as JsonMap,
      );
    } catch (e) {
      throw Exception('Invalid JSON for _TaskData: $e');
    }
  }
}

class _TaskDisplayData {
  final String title;
  final List<_TaskData> tasks;

  _TaskDisplayData({required this.title, required this.tasks});

  factory _TaskDisplayData.fromJson(Map<String, Object?> json) {
    try {
      return _TaskDisplayData(
        title: (json['title'] as String?) ?? 'Tasks',
        tasks: (json['tasks'] as List<Object?>)
            .map((e) => _TaskData.fromJson(e as Map<String, Object?>))
            .toList(),
      );
    } catch (e) {
      throw Exception('Invalid JSON for _TaskDisplayData: $e');
    }
  }
}

class _TaskDisplay extends StatelessWidget {
  final _TaskDisplayData data;
  final void Function(_TaskData) onCompleteTask;

  const _TaskDisplay({required this.data, required this.onCompleteTask});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final completed = data.tasks.where((t) => t.isCompleted).length;
    final total = data.tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        // ── Header row ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: .w700,
                  ),
                ),
              ),
              // Task count badge
              Container(
                padding: const .symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: completed == total && total > 0
                      ? cs.secondaryContainer
                      : cs.primaryContainer,
                  borderRadius: .circular(20),
                ),
                child: Text(
                  '$completed / $total',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: completed == total && total > 0
                        ? cs.onSecondaryContainer
                        : cs.onPrimaryContainer,
                    fontWeight: .w700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Progress bar ─────────────────────────────────────────
        if (total > 0)
          Padding(
            padding: const .fromLTRB(4, 0, 4, 8),
            child: ClipRRect(
              borderRadius: .circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: cs.outlineVariant.withAlpha(60),
                valueColor: AlwaysStoppedAnimation(
                  progress == 1.0 ? cs.secondary : cs.primary,
                ),
              ),
            ),
          ),

        // ── Task items ───────────────────────────────────────────
        if (data.tasks.isEmpty)
          Padding(
            padding: const .symmetric(vertical: 8, horizontal: 4),
            child: Text(
              'No tasks yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontStyle: .italic,
              ),
            ),
          )
        else
          ...data.tasks.map(
            (task) => _TaskTile(
              task: task,
              cs: cs,
              theme: theme,
              onComplete: () => onCompleteTask(task),
            ),
          ),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.cs,
    required this.theme,
    required this.onComplete,
  });

  final _TaskData task;
  final ColorScheme cs;
  final ThemeData theme;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: .circular(12),
        child: InkWell(
          borderRadius: .circular(12),
          onTap: task.isCompleted ? null : onComplete,
          child: Container(
            decoration: BoxDecoration(
              color: task.isCompleted
                  ? cs.surfaceContainerHighest.withAlpha(60)
                  : cs.surface,
              borderRadius: .circular(12),
              border: .all(
                color: task.isCompleted
                    ? cs.outlineVariant.withAlpha(60)
                    : cs.outlineVariant.withAlpha(120),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Checkbox
                Padding(
                  padding: const .all(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: task.isCompleted ? cs.primary : Colors.transparent,
                      borderRadius: .circular(6),
                      border: task.isCompleted
                          ? null
                          : .all(color: cs.outline, width: 1.5),
                    ),
                    child: task.isCompleted
                        ? Icon(
                            Icons.check_rounded,
                            color: cs.onPrimary,
                            size: 14,
                          )
                        : null,
                  ),
                ),
                // Task name
                Expanded(
                  child: Text(
                    task.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: task.isCompleted
                          ? cs.onSurfaceVariant
                          : cs.onSurface,
                      decoration: task.isCompleted ? .lineThrough : .none,
                      decorationColor: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                // Status chip for completed
                if (task.isCompleted)
                  Padding(
                    padding: const .only(right: 12),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: cs.secondary,
                      size: 18,
                    ),
                  ),
                if (!task.isCompleted) const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final taskDisplay = CatalogItem(
  name: 'TaskDisplay',
  dataSchema: taskDisplaySchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _TaskDisplayData.fromJson(json);

    return _TaskDisplay(
      data: data,
      onCompleteTask: (task) async {
        // A data context is a reference to a location in the data model. This line
        // turns that reference into a concrete data object that the agent can use.
        // It's kind of like taking a pointer and replacing it with the value it
        // points to.
        final JsonMap resolvedContext = await resolveContext(
          itemContext.dataContext,
          task.actionContext,
        );

        // Dispatch an event back to the agent, letting it know a task was completed.
        // This will be sent to the agent in an A2UI message that includes the name
        // of the action, the surface ID, and the resolved data context.
        itemContext.dispatchEvent(
          UserActionEvent(
            name: task.actionName,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      },
    );
  },
);
