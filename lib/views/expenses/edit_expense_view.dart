import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../viewmodels/category_view_model.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../utils/ui_utils.dart';

class EditExpensePage extends StatefulWidget {
  final Expense expense;
  
  const EditExpensePage({super.key, required this.expense});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  Category? _selectedCategory;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.expense.amount.toString());
    _descCtrl = TextEditingController(text: widget.expense.description ?? '');
    _selectedDate = widget.expense.date;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final catVM = context.read<CategoryViewModel>();
      if (catVM.categories.isEmpty) {
        catVM.loadCategories();
      } else {
        _initCategory(catVM.categories);
      }
    });
  }

  void _initCategory(List<Category> categories) {
    try {
      setState(() {
        _selectedCategory = categories.firstWhere((c) => c.id == widget.expense.categoryId);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catVM = context.watch<CategoryViewModel>();
    final expVM = context.watch<ExpenseViewModel>();
    
    if (!catVM.isLoading && catVM.categories.isNotEmpty && _selectedCategory == null) {
      _initCategory(catVM.categories);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Expense'),
        centerTitle: true,
      ),
      body: catVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (€)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: catVM.categories.map((cat) {
                      final catIcon = UIUtils.getIcon(cat.icon);
                      final catColor = UIUtils.parseColor(cat.color);
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(catIcon, color: catColor),
                            const SizedBox(width: 8),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                  ),
                  const SizedBox(height: 32),
                  if (expVM.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: () async {
                        final amountText = _amountCtrl.text.replaceAll(',', '.');
                        final amount = double.tryParse(amountText);

                        if (amount == null || amount <= 0 || _selectedCategory == null) return;

                        final updatedExpense = Expense(
                          id: widget.expense.id,
                          userId: widget.expense.userId,
                          categoryId: _selectedCategory!.id,
                          amount: amount,
                          date: _selectedDate,
                          description: _descCtrl.text.trim(),
                        );

                        final success = await expVM.updateExpense(updatedExpense);
                        
                        if (!mounted) return;
                        if (success) Navigator.pop(context);
                      },
                      child: const Text('Update Changes'),
                    ),
                ],
              ),
            ),
    );
  }
}