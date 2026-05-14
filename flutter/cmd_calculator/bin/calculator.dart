import 'dart:io';

void main() {
  print("=== DART CMD CALCULATOR ===");
  print("Type 'exit' to quit\n");

  while (true) {
    stdout.write("> ");
    String? input = stdin.readLineSync();

    if (input == null) {
      print("No input detected. Exiting...");
      break;
    }

    input = input.trim();

    if (input.toLowerCase() == "exit") {
      print("Calculator closed.");
      break;
    }

    // Remove spaces so both formats work
    input = input.replaceAll(" ", "");

    // Regex to match expressions like 2+2, -3.5*4, etc.
    RegExp reg = RegExp(r'^(-?\d+\.?\d*)([\+\-\*\/])(-?\d+\.?\d*)$');
    Match? match = reg.firstMatch(input);

    if (match == null) {
      print("❌ Invalid format. Use like 2+2 or 2 + 2");
      continue;
    }

    double num1;
    double num2;

    try {
      num1 = double.parse(match.group(1)!);
      num2 = double.parse(match.group(3)!);
    } catch (e) {
      print("❌ Invalid numbers");
      continue;
    }

    String op = match.group(2)!;
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
          print("❌ Cannot divide by zero");
          continue;
        }
        result = num1 / num2;
        break;

      default:
        print("❌ Invalid operator");
        continue;
    }

    // Limit to 3 decimal places
    print("= ${result.toStringAsFixed(3)}\n");
  }
}