import 'dart:async';
import 'package:flutter/material.dart';
import 'data/questions.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String userName;

  const QuizScreen({
    super.key,
    required this.userName,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestion = 0;
  int score = 0;

  int timeLeft = 10;
  Timer? timer;

  int? selectedIndex;
  bool answerChecked = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();

    setState(() {
      timeLeft = 10;
    });

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (timeLeft > 0) {
          setState(() {
            timeLeft--;
          });
        } else {
          nextQuestion();
        }
      },
    );
  }

  void checkAnswer(int index) {
    if (answerChecked) return; // prevent double tap

    timer?.cancel();

    setState(() {
      selectedIndex = index;
      answerChecked = true;
    });

    if (index == questions[currentQuestion].correctIndex) {
      score++;
    }

    // Wait 1.5 seconds so user can see the color feedback
    Future.delayed(const Duration(milliseconds: 800), () {
      nextQuestion();
    });
  }

  void nextQuestion() {
    timer?.cancel();

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedIndex = null;
        answerChecked = false;
      });

      startTimer();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            score: score,
            total: questions.length,
            userName: widget.userName,
          ),
        ),
      );
    }
  }

  Color? _getButtonColor(int index) {
    if (!answerChecked || index != selectedIndex) return null;

    final correctIndex = questions[currentQuestion].correctIndex;
    return selectedIndex == correctIndex ? Colors.green : Colors.red;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestion];

    return Scaffold(
      backgroundColor: const Color(0xFFC5CAE9),
      appBar: AppBar(
        title: Text("Welcome ${widget.userName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
            Text(
              "Time Left: $timeLeft",
              style: const TextStyle(
                fontSize: 22,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              question.question,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            ...List.generate(
              question.options.length,
              (index) {
                final btnColor = _getButtonColor(index);

                return Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(vertical: 5),
                  child: ElevatedButton(
                    onPressed: answerChecked
                        ? null
                        : () => checkAnswer(index),
                    style: btnColor != null
                        ? ElevatedButton.styleFrom(
                            disabledBackgroundColor: btnColor,
                            disabledForegroundColor: Colors.white,
                          )
                        : ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                          ),
                    child: Text(
                      question.options[index],
                    ),
                  ),
                );
              },
            ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}