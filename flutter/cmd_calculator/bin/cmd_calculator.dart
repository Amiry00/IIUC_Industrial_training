import 'dart:io';

void main() {
  print("Dart CMD Calculator");
  print("Type 'exit' to quit.\n");

  while (true) {
    stdout.write("Enter expression (e.g. 2+3*4): ");
    String? input = stdin.readLineSync();

    if (input == null || input.toLowerCase() == 'exit') {
      print("Goodbye!");
      break;
    }

    try {
      double result = evaluate(input);
      print("Result: $result\n");
    } catch (e) {
      print("Invalid expression\n");
    }
  }
}

/// Simple evaluator (supports + - * / only, no brackets)
double evaluate(String expr) {
  expr = expr.replaceAll(' ', '');

  List<double> numbers = [];
  List<String> ops = [];

  int i = 0;

  while (i < expr.length) {
    String char = expr[i];

    if (isDigit(char)) {
      String num = '';
      while (i < expr.length && (isDigit(expr[i]) || expr[i] == '.')) {
        num += expr[i];
        i++;
      }
      numbers.add(double.parse(num));
      continue;
    }

    if (isOperator(char)) {
      while (ops.isNotEmpty && precedence(ops.last) >= precedence(char)) {
        compute(numbers, ops.removeLast());
      }
      ops.add(char);
    }

    i++;
  }

  while (ops.isNotEmpty) {
    compute(numbers, ops.removeLast());
  }

  return numbers.single;
}

void compute(List<double> numbers, String op) {
  double b = numbers.removeLast();
  double a = numbers.removeLast();

  switch (op) {
    case '+':
      numbers.add(a + b);
      break;
    case '-':
      numbers.add(a - b);
      break;
    case '*':
      numbers.add(a * b);
      break;
    case '/':
      numbers.add(a / b);
      break;
  }
}

bool isDigit(String c) => RegExp(r'[0-9.]').hasMatch(c);

bool isOperator(String c) => '+-*/'.contains(c);

int precedence(String op) {
  if (op == '+' || op == '-') return 1;
  if (op == '*' || op == '/') return 2;
  return 0;
}