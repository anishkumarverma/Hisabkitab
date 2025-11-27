
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(ShopkeeperApp());
}

class ShopkeeperApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopkeeper Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Models
class Customer {
  String id;
  String name;
  String phone;
  double balance; // Positive = customer owes you, Negative = you owe customer

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.balance = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'balance': balance,
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'],
        name: json['name'],
        phone: json['phone'],
        balance: json['balance'],
      );
}

class Transaction {
  String id;
  String customerId;
  String customerName;
  double amount;
  String type; // 'given' or 'received'
  DateTime date;
  String note;

  Transaction({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.type,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'customerName': customerName,
        'amount': amount,
        'type': type,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        customerId: json['customerId'],
        customerName: json['customerName'],
        amount: json['amount'],
        type: json['type'],
        date: DateTime.parse(json['date']),
        note: json['note'] ?? '',
      );
}

class Expense {
  String id;
  String description;
  double amount;
  DateTime date;
  String category;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.category = 'General',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'category': category,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'],
        description: json['description'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
        category: json['category'] ?? 'General',
      );
}

// Data Manager
class DataManager {
  static const String customersKey = 'customers';
  static const String transactionsKey = 'transactions';
  static const String expensesKey = 'expenses';

  Future<List<Customer>> getCustomers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(customersKey);
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Customer.fromJson(e)).toList();
  }

  Future<void> saveCustomers(List<Customer> customers) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(customers.map((e) => e.toJson()).toList());
    await prefs.setString(customersKey, data);
  }

  Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(transactionsKey);
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Transaction.fromJson(e)).toList();
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final String data =
        json.encode(transactions.map((e) => e.toJson()).toList());
    await prefs.setString(transactionsKey, data);
  }

  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(expensesKey);
    if (data == null) return [];
    final List<dynamic> jsonList = json.decode(data);
    return jsonList.map((e) => Expense.fromJson(e)).toList();
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = json.encode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(expensesKey, data);
  }
}

// Home Page
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final DataManager _dataManager = DataManager();

  List<Customer> customers = [];
  List<Transaction> transactions = [];
  List<Expense> expenses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    customers = await _dataManager.getCustomers();
    transactions = await _dataManager.getTransactions();
    expenses = await _dataManager.getExpenses();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(
        transactions: transactions,
        expenses: expenses,
        customers: customers,
      ),
      CustomersPage(
        customers: customers,
        transactions: transactions,
        onCustomerAdded: (customer) async {
          customers.add(customer);
          await _dataManager.saveCustomers(customers);
          setState(() {});
        },
        onTransactionAdded: (transaction) async {
          transactions.add(transaction);
          await _dataManager.saveTransactions(transactions);
          // Update customer balance
          final customer =
              customers.firstWhere((c) => c.id == transaction.customerId);
          if (transaction.type == 'given') {
            customer.balance += transaction.amount;
          } else {
            customer.balance -= transaction.amount;
          }
          await _dataManager.saveCustomers(customers);
          setState(() {});
        },
      ),
      ExpensesPage(
        expenses: expenses,
        onExpenseAdded: (expense) async {
          expenses.add(expense);
          await _dataManager.saveExpenses(expenses);
          setState(() {});
        },
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Expenses'),
        ],
      ),
    );
  }
}

// Dashboard Page
class DashboardPage extends StatelessWidget {
  final List<Transaction> transactions;
  final List<Expense> expenses;
  final List<Customer> customers;

  DashboardPage({
    required this.transactions,
    required this.expenses,
    required this.customers,
  });

  @override
  Widget build(BuildContext context) {
    double totalGiven = transactions
        .where((t) => t.type == 'given')
        .fold(0.0, (sum, t) => sum + t.amount);
    double totalReceived = transactions
        .where((t) => t.type == 'received')
        .fold(0.0, (sum, t) => sum + t.amount);
    double totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            SummaryCard(
              title: 'Total Expenses',
              amount: totalExpenses,
              color: Colors.red,
              icon: Icons.shopping_cart,
            ),
            SizedBox(height: 16),
            SummaryCard(
              title: 'Money Given (उधार)',
              amount: totalGiven,
              color: Colors.orange,
              icon: Icons.arrow_upward,
            ),
            SizedBox(height: 16),
            SummaryCard(
              title: 'Money Received',
              amount: totalReceived,
              color: Colors.green,
              icon: Icons.arrow_downward,
            ),
            SizedBox(height: 24),
            Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Expanded(
              child: transactions.isEmpty
                  ? Center(child: Text('No transactions yet'))
                  : ListView.builder(
                      itemCount: transactions.length > 5 ? 5 : transactions.length,
                      itemBuilder: (context, index) {
                        final sortedTransactions = transactions.toList()
                          ..sort((a, b) => b.date.compareTo(a.date));
                        final t = sortedTransactions[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              t.type == 'given'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: t.type == 'given'
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                            title: Text(t.customerName),
                            subtitle: Text(DateFormat('dd/MM/yyyy').format(t.date)),
                            trailing: Text(
                              '₹${t.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Customers Page
class CustomersPage extends StatefulWidget {
  final List<Customer> customers;
  final List<Transaction> transactions;
  final Function(Customer) onCustomerAdded;
  final Function(Transaction) onTransactionAdded;

  CustomersPage({
    required this.customers,
    required this.transactions,
    required this.onCustomerAdded,
    required this.onTransactionAdded,
  });

  @override
  _CustomersPageState createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    List<Customer> filteredCustomers = widget.customers
        .where((c) => c.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Customers'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddCustomerDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: filteredCustomers.isEmpty
                ? Center(child: Text('No customers found'))
                : ListView.builder(
                    itemCount: filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(customer.name[0].toUpperCase()),
                          ),
                          title: Text(customer.name),
                          subtitle: Text(customer.phone),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${customer.balance.abs().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: customer.balance >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              Text(
                                customer.balance >= 0 ? 'To Receive' : 'To Pay',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () => _showCustomerDetails(context, customer),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Customer Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final customer = Customer(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  phone: phoneController.text,
                );
                widget.onCustomerAdded(customer);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsPage(
          customer: customer,
          transactions: widget.transactions
              .where((t) => t.customerId == customer.id)
              .toList(),
          onTransactionAdded: widget.onTransactionAdded,
        ),
      ),
    );
  }
}

// Customer Details Page
class CustomerDetailsPage extends StatelessWidget {
  final Customer customer;
  final List<Transaction> transactions;
  final Function(Transaction) onTransactionAdded;

  CustomerDetailsPage({
    required this.customer,
    required this.transactions,
    required this.onTransactionAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            color: customer.balance >= 0 ? Colors.green[100] : Colors.red[100],
            child: Column(
              children: [
                Text(
                  'Current Balance',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '₹${customer.balance.abs().toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: customer.balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  customer.balance >= 0 ? 'To Receive' : 'To Pay',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddTransactionDialog(context, 'given'),
                    icon: Icon(Icons.arrow_upward),
                    label: Text('Money Given'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showAddTransactionDialog(context, 'received'),
                    icon: Icon(Icons.arrow_downward),
                    label: Text('Money Received'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Transaction History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: transactions.isEmpty
                ? Center(child: Text('No transactions yet'))
                : ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final sortedTransactions = transactions.toList()
                        ..sort((a, b) => b.date.compareTo(a.date));
                      final t = sortedTransactions[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Icon(
                            t.type == 'given'
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color:
                                t.type == 'given' ? Colors.orange : Colors.green,
                          ),
                          title: Text(
                            t.type == 'given' ? 'Money Given' : 'Money Received',
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('dd/MM/yyyy HH:mm').format(t.date)),
                              if (t.note.isNotEmpty) Text(t.note),
                            ],
                          ),
                          trailing: Text(
                            '₹${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, String type) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type == 'given' ? 'Money Given (उधार)' : 'Money Received'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: 'Note (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final transaction = Transaction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  customerId: customer.id,
                  customerName: customer.name,
                  amount: double.parse(amountController.text),
                  type: type,
                  date: DateTime.now(),
                  note: noteController.text,
                );
                onTransactionAdded(transaction);
                Navigator.pop(context);
                Navigator.pop(context); // Go back to customers list
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

// Expenses Page
class ExpensesPage extends StatefulWidget {
  final List<Expense> expenses;
  final Function(Expense) onExpenseAdded;

  ExpensesPage({required this.expenses, required this.onExpenseAdded});

  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  @override
  Widget build(BuildContext context) {
    double totalExpenses = widget.expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text('Expenses'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddExpenseDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            color: Colors.red[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total Expenses: ',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  '₹${totalExpenses.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.expenses.isEmpty
                ? Center(child: Text('No expenses yet'))
                : ListView.builder(
                    itemCount: widget.expenses.length,
                    itemBuilder: (context, index) {
                      final sortedExpenses = widget.expenses.toList()
                        ..sort((a, b) => b.date.compareTo(a.date));
                      final expense = sortedExpenses[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.shopping_cart, color: Colors.white),
                          ),
                          title: Text(expense.description),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('dd/MM/yyyy').format(expense.date)),
                              Text(expense.category,
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          trailing: Text(
                            '₹${expense.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'General';
    final categories = [
      'General',
      'Supplies',
      'Rent',
      'Utilities',
      'Transport',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: amountController,
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(labelText: 'Category'),
                items: categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedCategory = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (descriptionController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final expense = Expense(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    description: descriptionController.text,
                    amount: double.parse(amountController.text),
                    date: DateTime.now(),
                    category: selectedCategory,
                  );
                  widget.onExpenseAdded(expense);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}