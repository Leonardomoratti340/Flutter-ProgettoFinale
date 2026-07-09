import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/statistics_view_model.dart';
import '../../utils/ui_utils.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _selectedYear = DateTime.now().year;

  late int _compYear1;
  int? _compMonth1;
  late int _compYear2;
  int? _compMonth2;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _compYear1 = currentYear;
    _compYear2 = currentYear;
  }

  bool _didScheduleLoad = false;

  // Generates a list of available years for the dropdown (current year and past 9 years)
  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(10, (index) => currentYear - index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Safely load data and apply initial filters after layout
    if (!_didScheduleLoad) {
      _didScheduleLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final vm = context.read<StatisticsViewModel>();
        vm.loadExpenses();
        // Set the pie chart filter to the current month by default
        vm.setMonthFilter(DateTime.now().month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche'),
        centerTitle: true,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(vm),
    );
  }

  Widget _buildContent(StatisticsViewModel vm) {
    if (vm.errorMessage != null && vm.allExpenses.isEmpty) {
      return Center(child: Text('Error: ${vm.errorMessage}'));
    }

    if (vm.allExpenses.isEmpty) {
      return const Center(
        child: Text('Nessuna spesa registrata per il periodo selezionato.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildYearSelector(),
          const SizedBox(height: 24),
          const Text(
            'Spese Mensili',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: _buildBarChart(vm),
          ),
          _buildPieChartLegend(vm),
          
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 24),
          
          // New Comparison Section
          _buildComparisonSection(vm),
          
          const SizedBox(height: 40),
          
          const Text(
            'Spese per Categoria',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildMonthSelector(vm),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: _buildPieChart(vm),
          ),
          const SizedBox(height: 24),
          _buildPieChartLegend(vm),
          const SizedBox(height: 40),
        ],
      ),
    );
  }


  Widget _buildYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Seleziona Anno: ', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: _selectedYear,
          items: _availableYears.map((year) {
            return DropdownMenuItem(
              value: year,
              child: Text(year.toString()),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedYear = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildMonthSelector(StatisticsViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Filtra per Mese: ', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          value: vm.monthFilter,
          items: [
            const DropdownMenuItem(value: null, child: Text('Tutti i Mesi')),
            ...List.generate(12, (index) {
              final monthNum = index + 1;
              return DropdownMenuItem(
                value: monthNum,
                child: Text(monthNum.toString().padLeft(2, '0')),
              );
            }),
          ],
          onChanged: (val) => vm.setMonthFilter(val),
        ),
      ],
    );
  }

  Widget _buildBarChart(StatisticsViewModel vm) {
    final monthlyData = vm.calculateMonthlyExpenses(_selectedYear);
    final maxY = vm.computeMax(_selectedYear);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '€${rod.toY.toStringAsFixed(2)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    months[value.toInt() - 1],
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: monthlyData.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Theme.of(context).primaryColor,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(StatisticsViewModel vm) {
    final categoryData = vm.calculateExpensesByCategory(_selectedYear);

    if (categoryData.isEmpty) {
      return const Center(child: Text('Nessuna spesa per categoria nel periodo selezionato.'));
    }

    final List<PieChartSectionData> sections = [];
    categoryData.forEach((category, amount) {
      final color = UIUtils.parseColor(category.color);
      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '€${amount.toStringAsFixed(0)}',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
          ),
        ),
      );
    });

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  Widget _buildPieChartLegend(StatisticsViewModel vm) {
    final categoryData = vm.calculateExpensesByCategory(_selectedYear);

    if (categoryData.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: categoryData.entries.map((entry) {
        final category = entry.key;
        final color = UIUtils.parseColor(category.color);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(category.name, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildComparisonSection(StatisticsViewModel vm) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Compare Periods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildPeriodSelector(1)),
                const SizedBox(width: 16),
                Expanded(child: _buildPeriodSelector(2)),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _doCompare,
              child: const Text('Compare'),
            ),
            if (vm.period1Total != null && vm.period2Total != null) ...[
              const Divider(height: 32),
              _buildComparisonResults(vm),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(int periodNumber) {
    final isPeriod1 = periodNumber == 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Period $periodNumber',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButton<int>(
          isExpanded: true,
          value: isPeriod1 ? _compYear1 : _compYear2,
          items: _availableYears.map((year) {
            return DropdownMenuItem(value: year, child: Text(year.toString()));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                if (isPeriod1) _compYear1 = val;
                else _compYear2 = val;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        DropdownButton<int?>(
          isExpanded: true,
          value: isPeriod1 ? _compMonth1 : _compMonth2,
          items: [
            const DropdownMenuItem(value: null, child: Text('All Year')),
            ...List.generate(12, (index) {
              final monthNum = index + 1;
              return DropdownMenuItem(
                value: monthNum,
                child: Text(monthNum.toString().padLeft(2, '0')),
              );
            }),
          ],
          onChanged: (val) {
            setState(() {
              if (isPeriod1) _compMonth1 = val;
              else _compMonth2 = val;
            });
          },
        ),
      ],
    );
  }

  void _doCompare() {
    context.read<StatisticsViewModel>().comparePeriods(
      _compYear1, _compMonth1, 
      _compYear2, _compMonth2,
    );
  }

  Widget _buildComparisonResults(StatisticsViewModel vm) {
    final diff = vm.period2Total! - vm.period1Total!;
    final diffColor = diff > 0 ? Colors.red : Colors.green;
    final diffText = diff > 0 ? '+€${diff.abs().toStringAsFixed(2)}' : '-€${diff.abs().toStringAsFixed(2)}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('Total P1'),
                Text('€${vm.period1Total!.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              children: [
                const Text('Total P2'),
                Text('€${vm.period2Total!.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Difference: $diffText',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: diffColor),
        ),
      ],
    );
  }
}