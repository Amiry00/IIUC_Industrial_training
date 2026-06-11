import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/user.dart';
import '../../models/exam.dart';
import '../login_screen.dart';
import 'create_exam.dart';
import 'add_question.dart';

class AdminDashboard extends StatefulWidget {
  final User user;

  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DBHelper _dbHelper = DBHelper();
  List<Exam> _exams = [];
  Map<int, int> _questionCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  // Load all exams created by this admin and their respective question counts
  Future<void> _loadExams() async {
    setState(() => _isLoading = true);

    final exams = await _dbHelper.getExamsByAdmin(widget.user.id!);
    final counts = <int, int>{};
    for (final exam in exams) {
      counts[exam.id!] = await _dbHelper.getQuestionCount(exam.id!);
    }

    setState(() {
      _exams = exams;
      _questionCounts = counts;
      _isLoading = false;
    });
  }

  Future<void> _deleteExam(int examId) async {
    await _dbHelper.deleteExam(examId);
    _loadExams();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exam deleted'),
        backgroundColor: Color(0xFFE53935),
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${widget.user.name}'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _exams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F51B5).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: Color(0xFF3F51B5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No exams yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap + to create your first exam',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];
                    final qCount = _questionCounts[exam.id] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF3F51B5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exam.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A2E),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$qCount question${qCount != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded),
                              color: const Color(0xFF3F51B5),
                              tooltip: 'Add Questions',
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddQuestion(
                                      examId: exam.id!,
                                      examTitle: exam.title,
                                    ),
                                  ),
                                );
                                _loadExams();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: const Color(0xFFE53935),
                              tooltip: 'Delete Exam',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Exam'),
                                    content: Text(
                                      'Delete "${exam.title}" and all its questions?',
                                      style: const TextStyle(color: Color(0xFF6B7280)),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _deleteExam(exam.id!);
                                        },
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Color(0xFFE53935)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(
              builder: (_) => CreateExam(adminId: widget.user.id!),
            ),
          );
          if (result != null) {
            final examId = result['examId'] as int;
            final examTitle = result['examTitle'] as String;
            if (context.mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddQuestion(
                    examId: examId,
                    examTitle: examTitle,
                  ),
                ),
              );
            }
          }
          _loadExams();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
