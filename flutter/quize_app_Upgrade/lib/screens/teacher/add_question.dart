import 'package:flutter/material.dart';
import '../../database/db_helper.dart';
import '../../models/question.dart';

class AddQuestion extends StatefulWidget {
  final int examId;
  final String examTitle;

  const AddQuestion({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<AddQuestion> createState() => _AddQuestionState();
}

class _AddQuestionState extends State<AddQuestion> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();

  String _correctOption = 'A';
  int _questionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    final count = await DBHelper().getQuestionCount(widget.examId);
    setState(() => _questionCount = count);
  }

  Future<void> _addQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    final question = Question(
      examId: widget.examId,
      question: questionController.text.trim(),
      optionA: optionAController.text.trim(),
      optionB: optionBController.text.trim(),
      optionC: optionCController.text.trim(),
      optionD: optionDController.text.trim(),
      correctOption: _correctOption,
    );

    await DBHelper().insertQuestion(question);

    questionController.clear();
    optionAController.clear();
    optionBController.clear();
    optionCController.clear();
    optionDController.clear();
    setState(() => _correctOption = 'A');

    await _loadCount();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Question $_questionCount added!'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Future<void> _saveAndClose() async {
    final hasInput = questionController.text.trim().isNotEmpty ||
        optionAController.text.trim().isNotEmpty ||
        optionBController.text.trim().isNotEmpty ||
        optionCController.text.trim().isNotEmpty ||
        optionDController.text.trim().isNotEmpty;

    if (hasInput) {
      if (!_formKey.currentState!.validate()) return;

      final question = Question(
        examId: widget.examId,
        question: questionController.text.trim(),
        optionA: optionAController.text.trim(),
        optionB: optionBController.text.trim(),
        optionC: optionCController.text.trim(),
        optionD: optionDController.text.trim(),
        correctOption: _correctOption,
      );

      await DBHelper().insertQuestion(question);
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3F51B5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Color(0xFF3F51B5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_questionCount question${_questionCount != 1 ? 's' : ''} added',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F51B5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: questionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Question',
                          hintText: 'Type your question here',
                          prefixIcon: Icon(Icons.help_outline_rounded),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Question Options',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5C6BC0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: optionAController,
                        decoration: const InputDecoration(
                          labelText: 'Option A',
                          prefixIcon: Icon(Icons.looks_one_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: optionBController,
                        decoration: const InputDecoration(
                          labelText: 'Option B',
                          prefixIcon: Icon(Icons.looks_two_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: optionCController,
                        decoration: const InputDecoration(
                          labelText: 'Option C',
                          prefixIcon: Icon(Icons.looks_3_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: optionDController,
                        decoration: const InputDecoration(
                          labelText: 'Option D',
                          prefixIcon: Icon(Icons.looks_4_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Text(
                            'Select Correct Answer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5C6BC0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8EAF6)),
                        ),
                        child: Row(
                          children: ['A', 'B', 'C', 'D'].map((option) {
                            final bool isSelected = _correctOption == option;
                            final bool isLast = option == 'D';
                            return Expanded(
                              child: InkWell(
                                onTap: () => setState(() => _correctOption = option),
                                borderRadius: BorderRadius.horizontal(
                                  left: option == 'A'
                                      ? const Radius.circular(11)
                                      : Radius.zero,
                                  right: option == 'D'
                                      ? const Radius.circular(11)
                                      : Radius.zero,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF4CAF50)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.horizontal(
                                      left: option == 'A'
                                          ? const Radius.circular(11)
                                          : Radius.zero,
                                      right: option == 'D'
                                          ? const Radius.circular(11)
                                          : Radius.zero,
                                    ),
                                    border: isLast
                                        ? null
                                        : const Border(
                                            right: BorderSide(
                                              color: Color(0xFFE8EAF6),
                                            ),
                                          ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected) ...[
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          'Option $option',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFF5C6BC0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Another'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                      onPressed: _saveAndClose,
                      icon: const Icon(Icons.done_rounded),
                      label: const Text('Done'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
