import 'dart:io';

void main() {
  print("=== Simple Calculator ===");
  print("Type 'exit' to quit.\n");

  while (true) {
    stdout.write("> ");

    String? input = stdin.readLineSync();

    // Handle null input (important fix)
    if (input == null) {
      print("No input detected. Exiting...");
      break;
    }

    input = input.trim();

    if (input.toLowerCase() == "exit") {
      break;
    }

    List<String> parts = input.split(" ");

    if (parts.length != 3) {
      print("Invalid format. Use: number operator number");
      continue;
    }

    double num1;
    double num2;

    // Handle invalid number input safely
    try {
      num1 = double.parse(parts[0]);
      num2 = double.parse(parts[2]);
    } catch (e) {
      print("Invalid numbers. Please enter valid numeric values.");
      continue;
    }

    String op = parts[1];
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
        print("Invalid operator. Use +, -, *, /");
        continue;
    }

    print("= $result\n");
  }

  print("Calculator closed.");
}