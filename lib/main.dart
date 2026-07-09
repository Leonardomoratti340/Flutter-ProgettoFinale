import 'package:aullet/viewmodels/expense_viewmodel.dart';
import 'package:aullet/viewmodels/profile_view_model.dart';
import 'package:aullet/views/expenses/add_expense_view.dart';
import 'package:aullet/views/profile/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'viewmodels/auth_view_model.dart';
import 'views/auth/login_view.dart';
import 'views/auth/signup_view.dart';
import 'views/home_view.dart';
import 'viewmodels/category_view_model.dart';
import 'views/categories/categories_view.dart';
import 'models/expense.dart';
import 'views/expenses/edit_expense_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Error in .env file: SUPABASE_URL or SUPABASE_ANON_KEY is missing!',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => CategoryViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, child) {
          return MaterialApp(
            title: 'Aullet',
            theme: ThemeData(useMaterial3: true),
            home: authVM.isLoggedIn ? const HomeView() : const LoginPage(),
            routes: {
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignUpPage(),
              '/home': (context) => const HomeView(),
              '/profile': (context) => const ProfilePage(),
              '/categories': (context) => const CategoriesPage(),
              '/add-expense': (context) => const AddExpensePage(),
              '/edit-expense': (context) {
                final expense =
                    ModalRoute.of(context)!.settings.arguments as Expense;
                return EditExpensePage(expense: expense);
              },
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
