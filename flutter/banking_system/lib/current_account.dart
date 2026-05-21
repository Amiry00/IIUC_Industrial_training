import 'bank_account.dart';

class CurrentAccount extends BankAccount {
  double overdraftLimit;

  CurrentAccount(
    String accountNumber,
    String accountHolder,
    double balance,
    this.overdraftLimit,
  ) : super(accountNumber, accountHolder, balance);

  @override
  void withdraw(double amount) {
    if (amount > 0 && amount <= balance + overdraftLimit) {
      balance -= amount;

      print("Withdrawn: \$${amount}");
    } else {
      print("Overdraft limit exceeded!");
    }
  }
}