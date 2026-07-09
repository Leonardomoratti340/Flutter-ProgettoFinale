import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../repositories/expense_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _repo = ExpenseRepository();
  
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadExpenses() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utente non autenticato');

      _expenses = await _repo.fetchExpenses(user.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> addExpense(Expense expense) async {
    _setLoading(true);
    bool success = false;
    try {
      final insertedExpense = await _repo.insertExpense(expense);
      _expenses.insert(0, insertedExpense);
      success = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> updateExpense(Expense expense) async {
    _setLoading(true);
    bool success = false;
    try {
      await _repo.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
      }
      success = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> deleteExpense(String id) async {
    bool success = false;
    try {
      await _repo.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
      success = true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
    return success;
  }
}