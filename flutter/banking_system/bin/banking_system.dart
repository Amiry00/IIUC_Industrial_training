import 'package:banking_system/savings_account.dart';
import 'package:banking_system/current_account.dart';

void main() {
  print("=== Banking System Using OOP ===");

  // Savings Account Object
  SavingsAccount user1 =
      SavingsAccount(
        "S101",
        "Amirul Hoque",
        1000,
        5,
      );

  user1.displayInfo();

  user1.deposit(500);

  user1.withdraw(200);

  user1.addInterest();

  user1.displayInfo();

  // Current Account Object
  CurrentAccount user2 =
      CurrentAccount(
        "C201",
        "Rivan",
        2000,
        500,
      );

  user2.displayInfo();

  user2.deposit(2000);

  user2.withdraw(2300);

  user2.displayInfo();
}