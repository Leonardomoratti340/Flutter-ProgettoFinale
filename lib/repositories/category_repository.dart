import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

class CategoryRepository {
  final _client = Supabase.instance.client;

  Future<List<Category>> fetchCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name', ascending: true);

    return (response as List)
        .map((e) => Category.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}