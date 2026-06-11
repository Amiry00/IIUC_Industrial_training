import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/user.dart';
import '../../models/exam.dart';
import '../../models/result.dart';
import '../login_screen.dart';
import 'quiz_screen.dart';

class StudentDashboard extends StatefulWidget {
  final User user;

  const StudentDashboard({super.key, required this.user});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with SingleTickerProviderStateMixin {
  final DBHelper _dbHelper = DBHelper();
  late TabController _tabController;

  List<Exam> _exams = [];
  List<Result> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final exams = await _dbHelper.getAllExams();
    final results = await _dbHelper.getResultsByUser(widget.user.id!);
    setState(() {
      _exams = exams;
      _results = results;
      _isLoading = false;
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${widget.user.name}'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.quiz_outlined), text: 'Exams'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Results'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildExamsTab(),
                _buildResultsTab(),
              ],
            ),
    );
  }

  Widget _buildExamsTab() {
    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.quiz_outlined,
                  size: 64, color: Color(0xFF3F51B5)),
            ),
            const SizedBox(height: 20),
            const Text('No exams available',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            const Text('Check back later for new exams',
                style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.assignment_outlined,
                        color: Color(0xFF3F51B5), size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(exam.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E),
                          fontSize: 16)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () async {
                      final count =
                          await _dbHelper.getQuestionCount(exam.id!);
                      if (!context.mounted) return;
                      if (count == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('This exam has no questions yet'),
                            backgroundColor: Color(0xFFFFC107),
                          ),
                        );
                        return;
                      }
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            user: widget.user,
                            examId: exam.id!,
                            examTitle: exam.title,
                          ),
                        ),
                      );
                      _loadData();
                    },
                    child: const Text('Start'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsTab() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.history_rounded,
                  size: 64, color: Color(0xFF3F51B5)),
            ),
            const SizedBox(height: 20),
            const Text('No results yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            const Text('Take an exam to see your results',
                style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final percentage =
            ((result.score / result.total) * 100).toStringAsFixed(0);
        final passed = int.parse(percentage) >= 50;
        final statusColor =
            passed ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('$percentage%',
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Exam?>(
                        future: _dbHelper.getExamById(result.examId),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data?.title ?? 'Exam #${result.examId}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                                fontSize: 16),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(result.date,
                          style: const TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${result.score}/${result.total}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
