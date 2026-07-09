import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/expense.dart';
import '../../models/category.dart';
import '../../viewmodels/category_view_model.dart';
import '../../viewmodels/expense_viewmodel.dart';
import '../../utils/ui_utils.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryViewModel>().loadCategories();
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
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
                      labelText: 'Importo (€)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.euro),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione (Opzionale)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
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
                        final user = Supabase.instance.client.auth.currentUser;

                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Inserisci un importo valido')),
                          );
                          return;
                        }
                        if (_selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Seleziona una categoria')),
                          );
                          return;
                        }
                        if (user == null) return;

                        final newExpense = Expense(
                          id: '',
                          userId: user.id,
                          categoryId: _selectedCategory!.id,
                          amount: amount,
                          date: _selectedDate,
                          description: _descCtrl.text.trim(),
                        );

                        final success = await expVM.addExpense(newExpense);
                        
                        if (!mounted) return;

                        if (success) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Errore nell\'aggiunta della spesa')),
                          );
                        }
                      },
                      child: const Text('Salva Spesa'),
                    ),
                ],
              ),
            ),
    );
  }
}