import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/exam.dart';

class CreateExam extends StatefulWidget {
  final int teacherId;

  const CreateExam({super.key, required this.teacherId});

  @override
  State<CreateExam> createState() => _CreateExamState();
}

class _CreateExamState extends State<CreateExam> {
  final TextEditingController titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Inserts the new exam and redirects immediately to the question creation view.
  Future<void> _createExam() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final exam = Exam(
      title: titleController.text.trim(),
      createdBy: widget.teacherId,
    );

    final dbHelper = DBHelper();
    final examId = await dbHelper.insertExam(exam);

    setState(() => _isLoading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exam created! Now add questions.'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );

    Navigator.pop(context, {
      'examId': examId,
      'examTitle': titleController.text.trim(),
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exam'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.note_add_rounded,
                  size: 56,
                  color: Color(0xFF3F51B5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'New Exam',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Give your exam a title to get started',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Exam Title',
                            hintText: 'e.g. Midterm Exam 2026',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an exam title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _createExam,
                            icon: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Create & Add Questions'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
