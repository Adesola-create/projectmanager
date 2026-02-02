import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../models/project.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

// A more polished project list UI with search, status chips and cards

class ProjectListScreen extends StatefulWidget {
  final Employee employee;
  const ProjectListScreen({super.key, required this.employee});

  @override
  _ProjectListScreenState createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<Map<String, dynamic>>> _projectsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    _projectsFuture = _db.getProjectsForEmployee(widget.employee.id);
  }

  Future<void> _openCreate() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => CreateProjectScreen(owner: widget.employee),
      ),
    );
    if (res == true) setState(() => _loadProjects());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Projects'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() => _loadProjects()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreate,
        icon: Icon(Icons.add),
        label: Text('New Project'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _projectsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final projects = snap.data ?? [];
          if (projects.isEmpty) return Center(child: Text('No projects yet'));

          // simple search filter in memory
          final filtered = _query.isEmpty
              ? projects
              : projects.where((m) {
                  final p = Project.fromMap(m);
                  return p.name.toLowerCase().contains(_query.toLowerCase()) ||
                      (p.description ?? '').toLowerCase().contains(
                        _query.toLowerCase(),
                      );
                }).toList();

          return RefreshIndicator(
            onRefresh: () async => setState(() => _loadProjects()),
            child: ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search projects...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  );
                }

                final m = filtered[index - 1];
                final p = Project.fromMap(m);
                final initials = p.name.trim().isNotEmpty
                    ? p.name.trim().split(' ').map((s) => s[0]).take(2).join()
                    : '?';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade700,
                      child: Text(
                        initials,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          p.description ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(p.status ?? 'unknown'),
                              backgroundColor: Colors.grey.shade100,
                            ),
                            if (p.startDate != null)
                              Chip(label: Text('Start ${p.startDate}')),
                            if (p.endDate != null)
                              Chip(label: Text('End ${p.endDate}')),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'open') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => ProjectDetailScreen(
                                employee: widget.employee,
                                project: p,
                              ),
                            ),
                          ).then((v) {
                            if (v == true) setState(() => _loadProjects());
                          });
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'open',
                          child: Text('Open Project'),
                        ),
                      ],
                    ),
                    onTap: () =>
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => ProjectDetailScreen(
                              employee: widget.employee,
                              project: p,
                            ),
                          ),
                        ).then((v) {
                          if (v == true) setState(() => _loadProjects());
                        }),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
