import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _bestSellingProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper();
      final analytics = await db.getSalesAnalytics(_startDate, _endDate);
      final bestSelling = await db.getBestSellingProducts(_startDate, _endDate);

      setState(() {
        _analytics = analytics;
        _bestSellingProducts = bestSelling;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading reports')),
      );
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range selector
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Period: ${_startDate.toString().split(' ')[0]} - ${_endDate.toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: const Text('Change Period'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Key metrics cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Total Sales',
                          'Rp ${(_analytics['total_sales'] ?? 0).toStringAsFixed(0)}',
                          Icons.attach_money,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Total Profit',
                          'Rp ${(_analytics['total_profit'] ?? 0).toStringAsFixed(0)}',
                          Icons.trending_up,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Transactions',
                          '${_analytics['total_transactions'] ?? 0}',
                          Icons.receipt,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMetricCard(
                          'Avg Transaction',
                          'Rp ${(_analytics['average_transaction'] ?? 0).toStringAsFixed(0)}',
                          Icons.analytics,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Best selling products
                  const Text(
                    'Best Selling Products',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _bestSellingProducts.isEmpty
                          ? const Text('No sales data available')
                          : Column(
                              children: _bestSellingProducts.map((product) {
                                return ListTile(
                                  title: Text(product['name']),
                                  subtitle: Text('${product['total_quantity']} units sold'),
                                  trailing: Text(
                                    'Rp ${product['total_sales'].toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sales chart placeholder
                  const Text(
                    'Sales Trend',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 200,
                        child: _bestSellingProducts.isNotEmpty
                            ? BarChart(
                                BarChartData(
                                  barGroups: _bestSellingProducts.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final product = entry.value;
                                    return BarChartGroupData(
                                      x: index,
                                      barRods: [
                                        BarChartRodData(
                                          toY: (product['total_quantity'] as num).toDouble(),
                                          color: Colors.blue,
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          if (value.toInt() < _bestSellingProducts.length) {
                                            return Text(
                                              _bestSellingProducts[value.toInt()]['name'].substring(0, 8) + '...',
                                              style: const TextStyle(fontSize: 10),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                ),
                              )
                            : const Center(child: Text('No data to display')),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent transactions
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Placeholder for recent transactions
                          const Text('Recent transaction history will be displayed here'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to detailed transaction history
                            },
                            child: const Text('View All Transactions'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}