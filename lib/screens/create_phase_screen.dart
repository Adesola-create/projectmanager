import 'package:flutter/material.dart';
import '../services/database_service.dart';

class CreatePhaseScreen extends StatefulWidget {
  final int projectId;
  const CreatePhaseScreen({super.key, required this.projectId});

  @override
  _CreatePhaseScreenState createState() => _CreatePhaseScreenState();
}

class _CreatePhaseScreenState extends State<CreatePhaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _seqCtrl = TextEditingController();
  final DatabaseService _db = DatabaseService();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _db.createPhase({
      'projectId': widget.projectId,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'sequence': int.tryParse(_seqCtrl.text) ?? 0,
      'status': 'active',
    });
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Phase')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New Phase',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Phase name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _seqCtrl,
                    decoration: InputDecoration(
                      labelText: 'Sequence (0..)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Create Phase'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
