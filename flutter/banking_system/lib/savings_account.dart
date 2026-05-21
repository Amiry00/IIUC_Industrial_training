import 'bank_account.dart';

class SavingsAccount extends BankAccount {
  double interestRate;

  SavingsAccount(
    String accountNumber,
    String accountHolder,
    double balance,
    this.interestRate,
  ) : super(accountNumber, accountHolder, balance);

  @override
  void withdraw(double amount) {
    if (amount > 0 && amount <= balance) {
      balance -= amount;

      print("Withdrawn: \$${amount}");
    } else {
      print("Insufficient balance");
    }
  }

  // Add Interest
  void addInterest() {
    double interest = balance * interestRate / 100;

    balance += interest;

    print("Interest Added: \$${interest}");
  }
}