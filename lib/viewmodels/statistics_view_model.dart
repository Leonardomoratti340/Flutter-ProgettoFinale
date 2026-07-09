import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../repositories/expense_repository.dart';
import '../repositories/category_repository.dart';

class StatisticsViewModel extends ChangeNotifier {
  final ExpenseRepository _expRepo = ExpenseRepository();
  final CategoryRepository _catRepo = CategoryRepository();

  List<Expense> _allExpenses = [];
  List<Category> _allCategories = [];
  bool _isLoading = false;
  String? _errorMessage;
  int? _monthFilter;

  List<Expense> get allExpenses => _allExpenses;
  List<Category> get allCategories => _allCategories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get monthFilter => _monthFilter;

  Future<void> loadExpenses() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Utente non autenticato');

      final results = await Future.wait([
        _expRepo.fetchExpenses(user.id),
        _catRepo.fetchCategories(),
      ]);

      _allExpenses = results[0] as List<Expense>;
      _allCategories = results[1] as List<Category>;
      
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setMonthFilter(int? month) {
    _monthFilter = month;
    notifyListeners();
  }

  Map<int, double> calculateMonthlyExpenses(int year) {
    final Map<int, double> totals = {for (var m = 1; m <= 12; m++) m: 0.0};
    
    for (final exp in _allExpenses) {
      if (exp.date.year == year) {
        totals[exp.date.month] = totals[exp.date.month]! + exp.amount;
      }
    }
    return totals;
  }

  Map<Category, double> calculateExpensesByCategory(int year) {
    final Map<String, double> temp = {};
    
    for (final exp in _allExpenses) {
      if (exp.date.year == year && (_monthFilter == null || exp.date.month == _monthFilter)) {
        temp.update(
          exp.categoryId,
          (v) => v + exp.amount,
          ifAbsent: () => exp.amount,
        );
      }
    }

    final result = <Category, double>{};
    for (final cat in _allCategories) {
      final val = temp[cat.id] ?? 0.0;
      if (val > 0) {
        result[cat] = val;
      }
    }
    return result;
  }
  
  double computeMax(int year) {
    final totals = calculateMonthlyExpenses(year);
    double maxVal = 0.0;
    for (final v in totals.values) {
      if (v > maxVal) maxVal = v;
    }
    return maxVal == 0.0 ? 10.0 : maxVal * 1.2; 
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  double? _period1Total;
  double? _period2Total;

  double? get period1Total => _period1Total;
  double? get period2Total => _period2Total;

  void comparePeriods(int year1, int? month1, int year2, int? month2) {
    _period1Total = _calculateTotalForPeriod(year1, month1);
    _period2Total = _calculateTotalForPeriod(year2, month2);
    notifyListeners();
  }

  double _calculateTotalForPeriod(int year, int? month) {
    double total = 0.0;
    for (final exp in _allExpenses) {
      if (exp.date.year == year && (month == null || exp.date.month == month)) {
        total += exp.amount;
      }
    }
    return total;
  }
  
  void resetComparison() {
    _period1Total = null;
    _period2Total = null;
    notifyListeners();
  }
}