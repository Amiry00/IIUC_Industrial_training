import 'dart:io';

void main() {
  print("=== SIMPLE CALCULATOR ===");
  print("Type 'exit' to quit\n");

  while (true) {
    stdout.write("> "); // show prompt without newline

    String? input = stdin.readLineSync(); // wait for user input

    // If nothing was typed (Ctrl + D), stop
    if (input == null) {
      print("No input. Exiting...");
      break;
    }

    input = input.trim().replaceAll(" ", ""); // remove spaces

    // Exit condition
    if (input.toLowerCase() == "exit") {
      print("Calculator closed.");
      break;
    }

    // Pattern: number operator number (e.g. 2+2)
    RegExp pattern =
        RegExp(r'^(-?\d+\.?\d*)([\+\-\*\/])(-?\d+\.?\d*)$');

    Match? match = pattern.firstMatch(input);

    if (match == null) {
      print("Invalid format. Try: 2+2 or 10/5");
      continue;
    }

    double num1 = double.parse(match.group(1)!);
    String op = match.group(2)!;
    double num2 = double.parse(match.group(3)!);

    double result;

    switch (op) {
      case "+":
        result = num1 + num2;
        break;

      case "-":
        result = num1 - num2;
        break;

      case "*":
        result = num1 * num2;
        break;

      case "/":
        if (num2 == 0) {
          print("Cannot divide by zero");
          continue;
        }
        result = num1 / num2;
        break;

      default:
        print("Unknown operator");
        continue;
    }

    // Show result (3 decimal places)
    print("= ${result.toStringAsFixed(3)}\n");
  }
}