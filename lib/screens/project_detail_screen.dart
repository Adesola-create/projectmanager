import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/project_service.dart';
import '../models/phase.dart';
import 'create_phase_screen.dart';
import 'create_task_screen.dart';
import '../models/task.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Employee employee;
  final Project project;
  const ProjectDetailScreen({super.key, required this.employee, required this.project});

  @override
  _ProjectDetailScreenState createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<Map<String, dynamic>>> _phasesFuture;
  final Map<int, bool> _expanded = {};
  final ProjectService _ps = ProjectService();
  bool _canManage = false;

  @override
  void initState() {
    super.initState();
    _loadPhases();
    _checkPermissions();
  }

  void _loadPhases() {
    _phasesFuture = _db.getPhasesForProject(widget.project.id!);
  }

  Future<void> _checkPermissions() async {
    try {
      final ok = await _ps.canManageProject(
        widget.employee.id,
        widget.project.id!,
      );
      setState(() => _canManage = ok);
    } catch (e) {
      // ignore
    }
  }

  Future<void> _openCreatePhase() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => CreatePhaseScreen(projectId: widget.project.id!),
      ),
    );
    if (res == true) setState(() => _loadPhases());
  }

  Future<void> _openTasks(Phase phase) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => CreateTaskScreen(
          projectId: widget.project.id!,
          phase: phase,
          employee: widget.employee,
        ),
      ),
    );
    if (res == true) setState(() => _loadPhases());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.project.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePhase,
        icon: Icon(Icons.add),
        label: Text('Add Phase'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _phasesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final phases = snap.data ?? [];
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.project.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          if ((widget.project.description ?? '').isNotEmpty)
                            Text(widget.project.description ?? ''),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    label: Text(
                                      widget.project.status ?? 'status',
                                    ),
                                  ),
                                  if (widget.project.startDate != null)
                                    Chip(
                                      label: Text(
                                        'Start ${widget.project.startDate}',
                                      ),
                                    ),
                                  if (widget.project.endDate != null)
                                    Chip(
                                      label: Text(
                                        'End ${widget.project.endDate}',
                                      ),
                                    ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _openCreatePhase(),
                                icon: Icon(Icons.playlist_add),
                                label: Text('New Phase'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (phases.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text('No phases yet — add your first phase.'),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final ph = Phase.fromMap(phases[idx]);
                    final expanded = _expanded[ph.id ?? idx] ?? false;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          key: ValueKey(ph.id),
                          initiallyExpanded: expanded,
                          onExpansionChanged: (v) =>
                              setState(() => _expanded[ph.id ?? idx] = v),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ph.name,
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              SizedBox(width: 8),
                              Chip(label: Text(ph.status ?? 'active')),
                            ],
                          ),
                          subtitle:
                              ph.description != null &&
                                  ph.description!.isNotEmpty
                              ? Text(ph.description!)
                              : null,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                                vertical: 8.0,
                              ),
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: _db.getTasksForPhase(ph.id!),
                                builder: (c, s) {
                                  if (s.connectionState != ConnectionState.done) {
                                    return Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final tasks = s.data ?? [];
                                  if (tasks.isEmpty) {
                                    return ListTile(
                                      title: Text('No tasks for this phase'),
                                      trailing: TextButton(
                                        onPressed: () => _openTasks(ph),
                                        child: Text('Add Task'),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: tasks.map((t) {
                                      final task = Task.fromMap(t);
                                      return ListTile(
                                        leading: CircleAvatar(
                                          child: Icon(Icons.task_alt, size: 18),
                                        ),
                                        title: Text(
                                          task.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(task.description ?? ''),
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (task.dueDate != null)
                                              Text(
                                                task.dueDate!,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            SizedBox(height: 6),
                                            Text(
                                              task.status ?? '',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                            OverflowBar(
                              alignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _openTasks(ph),
                                  icon: Icon(Icons.add),
                                  label: Text('Add Task'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: phases.length),
                ),
            ],
          );
        },
      ),
    );
  }
}
