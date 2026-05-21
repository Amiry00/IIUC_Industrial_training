abstract class BankAccount {
  String accountNumber;
  String accountHolder;
  double _balance;

  BankAccount(
    this.accountNumber,
    this.accountHolder,
    this._balance,
  );

  // Getter
  double get balance => _balance;

  // Setter
  set balance(double value) => _balance = value;

  // Deposit
  void deposit(double amount) {
    if (amount > 0) {
      balance += amount;

      print("Deposited: \$${amount}");
    } else {
      print("Invalid deposit amount");
    }
  }

  // Abstract Withdraw
  void withdraw(double amount);

  // Display
  void displayInfo() {
    print("\n===== Account Info =====");
    print("Account Number : $accountNumber");
    print("Account Holder : $accountHolder");
    print("Balance        : \$${balance}\n");
  }
}