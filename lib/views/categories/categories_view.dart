import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/category_view_model.dart';
import '../../utils/ui_utils.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  bool _didScheduleLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_didScheduleLoad) {
      _didScheduleLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CategoryViewModel>().loadCategories();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CategoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
      ),
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(CategoryViewModel vm) {
    if (vm.isLoading && vm.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null && vm.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${vm.errorMessage}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CategoryViewModel>().loadCategories(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Grid layout for categories
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: vm.categories.length,
      itemBuilder: (context, index) {
        final category = vm.categories[index];
        final catColor = UIUtils.parseColor(category.color);
        final catIcon = UIUtils.getIcon(category.icon);

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: catColor.withOpacity(0.2),
                radius: 28,
                child: Icon(catIcon, color: catColor, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}