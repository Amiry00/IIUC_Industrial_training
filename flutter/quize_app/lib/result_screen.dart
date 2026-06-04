import 'package:flutter/material.dart';
import 'login_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final String userName;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC5CAE9),
      appBar: AppBar(
        title: const Text("Result"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
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
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
            Text(
              "Congratulations $userName",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Score: $score / $total",
              style: const TextStyle(
                fontSize: 28,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text("Play Again",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  )),
            )
          ],
        ),
          ),
        ),
      ),
    );
  }
}