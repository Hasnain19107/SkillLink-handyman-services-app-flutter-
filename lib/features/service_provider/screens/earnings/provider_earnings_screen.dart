import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ProviderEarningsScreen extends StatefulWidget {
  const ProviderEarningsScreen({Key? key}) : super(key: key);

  @override
  State<ProviderEarningsScreen> createState() => _ProviderEarningsScreenState();
}

class _ProviderEarningsScreenState extends State<ProviderEarningsScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  bool _isLoading = true;

  // Earnings data
  double _totalEarnings = 0.0;
  double _thisMonthEarnings = 0.0;
  double _thisWeekEarnings = 0.0;
  double _todayEarnings = 0.0;
  int _totalJobs = 0;
  double _averageJobValue = 0.0;

  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _monthlyData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEarningsData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get all completed bookings for this provider
      final completedBookings = await _firestore
          .collection('booking_service')
          .where('providerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('createdAt', descending: true)
          .get();

      double totalEarnings = 0.0;
      double thisMonthEarnings = 0.0;
      double thisWeekEarnings = 0.0;
      double todayEarnings = 0.0;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfDay = DateTime(now.year, now.month, now.day);

      List<Map<String, dynamic>> transactions = [];
      Map<String, double> monthlyEarnings = {};

      for (var doc in completedBookings.docs) {
        final data = doc.data();

        // Use budget field from your booking model
        final price = (data['budget'] as num?)?.toDouble() ??
            (data['servicePrice'] as num?)?.toDouble() ??
            0.0;

        // Use different possible date fields
        final completedAt = (data['completedAt'] as Timestamp?)?.toDate() ??
            (data['updatedAt'] as Timestamp?)?.toDate() ??
            (data['createdAt'] as Timestamp?)?.toDate();

        totalEarnings += price;

        if (completedAt != null) {
          // This month
          if (completedAt.year == now.year && completedAt.month == now.month) {
            thisMonthEarnings += price;
          }

          // This week
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekStartDate =
              DateTime(weekStart.year, weekStart.month, weekStart.day);
          if (completedAt
              .isAfter(weekStartDate.subtract(const Duration(seconds: 1)))) {
            thisWeekEarnings += price;
          }

          // Today
          if (completedAt.year == now.year &&
              completedAt.month == now.month &&
              completedAt.day == now.day) {
            todayEarnings += price;
          }

          // Monthly data for chart
          final monthKey = DateFormat('MMM yyyy').format(completedAt);
          monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + price;

          // Recent transactions
          transactions.add({
            'id': doc.id,
            'amount': price,
            'serviceName': data['serviceName'] ?? 'Service',
            'seekerName': data['seekerName'] ?? 'Customer',
            'date': completedAt,
            'status': 'completed',
            'jobDescription': data['jobDescription'] ?? '',
            'address': data['address'] ?? '',
          });
        } else {
          // If no completion date, still add to transactions with created date
          final createdAt =
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
          transactions.add({
            'id': doc.id,
            'amount': price,
            'serviceName': data['serviceName'] ?? 'Service',
            'seekerName': data['seekerName'] ?? 'Customer',
            'date': createdAt,
            'status': 'completed',
            'jobDescription': data['jobDescription'] ?? '',
            'address': data['address'] ?? '',
          });
        }
      }

      // Also get pending_confirmation bookings as potential earnings
      final pendingConfirmationBookings = await _firestore
          .collection('booking_service')
          .where('providerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending_confirmation')
          .get();

      for (var doc in pendingConfirmationBookings.docs) {
        final data = doc.data();
        final price = (data['budget'] as num?)?.toDouble() ??
            (data['servicePrice'] as num?)?.toDouble() ??
            0.0;

        final completedAt =
            (data['providerCompletedAt'] as Timestamp?)?.toDate() ??
                (data['updatedAt'] as Timestamp?)?.toDate() ??
                (data['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now();

        transactions.add({
          'id': doc.id,
          'amount': price,
          'serviceName': data['serviceName'] ?? 'Service',
          'seekerName': data['seekerName'] ?? 'Customer',
          'date': completedAt,
          'status': 'pending_confirmation',
          'jobDescription': data['jobDescription'] ?? '',
          'address': data['address'] ?? '',
        });
      }

      // Sort monthly data
      final sortedMonthly = monthlyEarnings.entries.toList()
        ..sort((a, b) {
          try {
            final dateA = DateFormat('MMM yyyy').parse(a.key);
            final dateB = DateFormat('MMM yyyy').parse(b.key);
            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        });

      // Sort transactions by date
      transactions.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _totalEarnings = totalEarnings;
          _thisMonthEarnings = thisMonthEarnings;
          _thisWeekEarnings = thisWeekEarnings;
          _todayEarnings = todayEarnings;
          _totalJobs = completedBookings.docs.length;
          _averageJobValue = _totalJobs > 0 ? _totalEarnings / _totalJobs : 0.0;
          _recentTransactions = transactions.take(20).toList();
          _monthlyData = sortedMonthly
              .map((e) => {'month': e.key, 'amount': e.value})
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading earnings data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading earnings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Earnings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadEarningsData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2A9D8F)),
                  SizedBox(height: 16),
                  Text('Loading earnings data...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                setState(() => _isLoading = true);
                await _loadEarningsData();
              },
              child: Column(
                children: [
                  // Summary Cards
                  _buildSummaryCards(isDark),

                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: const Color(0xFF2A9D8F),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor:
                          isDark ? Colors.white70 : Colors.black54,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Analytics'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(isDark),
                        _buildAnalyticsTab(isDark),
                        _buildHistoryTab(isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total Earnings Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A9D8F), Color(0xFF21847A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A9D8F).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Earnings',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\Rs${_totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.trending_up,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'From $_totalJobs completed jobs',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'This Month',
                  '\Rs${_thisMonthEarnings.toStringAsFixed(2)}',
                  Icons.calendar_today,
                  Colors.blue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'This Week',
                  '\Rs${_thisWeekEarnings.toStringAsFixed(2)}',
                  Icons.date_range,
                  Colors.orange,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'Today',
                  '\Rs${_todayEarnings.toStringAsFixed(2)}',
                  Icons.today,
                  Colors.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Avg per Job',
                  '\Rs${_averageJobValue.toStringAsFixed(2)}',
                  Icons.analytics,
                  Colors.purple,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (_recentTransactions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete some bookings to see your earnings here',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              itemBuilder: (context, index) {
                final transaction = _recentTransactions[index];
                return _buildTransactionItem(transaction, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Earnings Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          if (_monthlyData.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete more bookings to see trends',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\Rs${value.toInt()}',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < _monthlyData.length) {
                            return Text(
                              _monthlyData[value.toInt()]['month']
                                  .toString()
                                  .split(' ')[0],
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _monthlyData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['amount'].toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: const Color(0xFF2A9D8F),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2A9D8F).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Performance Stats
          Text(
            'Performance Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildPerformanceCard(
                  'Jobs Completed',
                  _totalJobs.toString(),
                  Icons.check_circle,
                  Colors.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceCard(
                  'Average Rating',
                  '4.8', // You can calculate this from ratings
                  Icons.star,
                  Colors.amber,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement export functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export feature coming soon')),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentTransactions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transaction history',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              itemBuilder: (context, index) {
                final transaction = _recentTransactions[index];
                return _buildTransactionItem(transaction, isDark);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction, bool isDark) {
    final bool isPendingConfirmation =
        transaction['status'] == 'pending_confirmation';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPendingConfirmation
            ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isPendingConfirmation
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPendingConfirmation ? Icons.pending : Icons.attach_money,
              color: isPendingConfirmation ? Colors.orange : Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['serviceName'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Customer: ${transaction['seekerName']}',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (transaction['address'] != null &&
                    transaction['address'].isNotEmpty)
                  Text(
                    'Location: ${transaction['address']}',
                    style: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm')
                      .format(transaction['date']),
                  style: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPendingConfirmation ? '~' : '+'}\Rs${transaction['amount'].toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPendingConfirmation ? Colors.orange : Colors.green,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPendingConfirmation
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPendingConfirmation ? 'Pending' : 'Completed',
                  style: TextStyle(
                    color: isPendingConfirmation ? Colors.orange : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
