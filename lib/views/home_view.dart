import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../viewmodels/category_view_model.dart';
import '../utils/ui_utils.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _didScheduleLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_didScheduleLoad) {
      _didScheduleLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ExpenseViewModel>().loadExpenses();
        context.read<CategoryViewModel>().loadCategories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expVM = context.watch<ExpenseViewModel>();
    final catVM = context.watch<CategoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: _buildBody(expVM, catVM),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-expense'),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              color: Theme.of(context).primaryColor,
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () => Navigator.pushNamed(context, '/categories'),
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: const Icon(Icons.bar_chart),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.pushNamed(context, '/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ExpenseViewModel expVM, CategoryViewModel catVM) {
    if (expVM.isLoading && expVM.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (expVM.expenses.isEmpty) {
      return const Center(child: Text('Nessuna spesa registrata. Aggiungi una spesa per iniziare.'));
    }

    return ListView.builder(
      itemCount: expVM.expenses.length,
      itemBuilder: (context, index) {
        final expense = expVM.expenses[index];
        
        final category = catVM.categories.firstWhere(
          (c) => c.id == expense.categoryId,
          orElse: () => catVM.categories.first,
        );

        final catIcon = UIUtils.getIcon(category.icon);
        final catColor = UIUtils.parseColor(category.color);

        return Dismissible(
          key: Key(expense.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) async {
            await context.read<ExpenseViewModel>().deleteExpense(expense.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Spesa eliminata con successo.')),
            );
          },
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: catColor.withOpacity(0.2),
              child: Icon(catIcon, color: catColor),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              expense.description?.isNotEmpty == true 
                  ? expense.description! 
                  : DateFormat('dd MMM yyyy').format(expense.date),
            ),
            trailing: Text(
              '- €${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(
                context, 
                '/edit-expense', 
                arguments: expense,
              );
            },
          ),
        );
      },
    );
  }
}