import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../widgets/common/app_loading.dart';

class CourseAnalyticsScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const CourseAnalyticsScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<CourseAnalyticsScreen> createState() => _CourseAnalyticsScreenState();
}

class _CourseAnalyticsScreenState extends State<CourseAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    final data = await _analyticsService.getCourseAnalytics(widget.courseId);
    setState(() {
      _analytics = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thống Kê: ${widget.courseName}'),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? AppLoading.fullScreen(message: 'Đang tải thống kê...')
          : _analytics.isEmpty
              ? const Center(child: Text('Chưa có dữ liệu thống kê'))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewCards(),
                        const SizedBox(height: 24),
                        _buildGradeDistributionChart(),
                        const SizedBox(height: 24),
                        _buildRatesChart(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng Quan Khóa Học',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Học Sinh',
                '${_analytics['totalStudents'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Bài Tập',
                '${_analytics['totalAssignments'] ?? 0}',
                Icons.assignment,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Bài Kiểm Tra',
                '${_analytics['totalQuizzes'] ?? 0}',
                Icons.quiz,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Bài Nộp',
                '${_analytics['totalSubmissions'] ?? 0}',
                Icons.upload_file,
                Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'ĐTB Khóa Học',
                '${(_analytics['avgGrade'] ?? 0).toStringAsFixed(1)}',
                Icons.grade,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Tỷ Lệ Nộp',
                '${(_analytics['submissionRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeDistributionChart() {
    final distribution =
        _analytics['gradeDistribution'] as Map<String, int>? ?? {};

    if (distribution.isEmpty ||
        distribution.values.every((count) => count == 0)) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân Bố Điểm',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Chưa có dữ liệu điểm',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân Bố Điểm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: distribution.values
                          .reduce((a, b) => a > b ? a : b)
                          .toDouble() +
                      2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final labels = [
                          'A (90-100)',
                          'B (80-89)',
                          'C (70-79)',
                          'D (60-69)',
                          'F (<60)'
                        ];
                        return BarTooltipItem(
                          '${labels[group.x.toInt()]}\n${rod.toY.toInt()} học sinh',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = ['A', 'B', 'C', 'D', 'F'];
                          if (value.toInt() >= 0 &&
                              value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[value.toInt()],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarGroups(distribution),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(Map<String, int> distribution) {
    final colors = [
      Colors.green,
      Colors.lightGreen,
      Colors.orange,
      Colors.deepOrange,
      Colors.red
    ];
    final keys = [
      'A (90-100)',
      'B (80-89)',
      'C (70-79)',
      'D (60-69)',
      'F (<60)'
    ];

    return List.generate(keys.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (distribution[keys[index]] ?? 0).toDouble(),
            color: colors[index],
            width: 30,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });
  }

  Widget _buildRatesChart() {
    final submissionRate = (_analytics['submissionRate'] ?? 0).toDouble();
    final quizCompletionRate =
        (_analytics['quizCompletionRate'] ?? 0).toDouble();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tỷ Lệ Tham Gia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final labels = ['Tỷ Lệ Nộp Bài', 'Tỷ Lệ Làm Quiz'];
                        return BarTooltipItem(
                          '${labels[group.x.toInt()]}\n${rod.toY.toStringAsFixed(1)}%',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Nộp Bài', textAlign: TextAlign.center),
                            );
                          }
                          if (value == 1) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Làm Quiz', textAlign: TextAlign.center),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%');
                        },
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: submissionRate,
                          color: Colors.blue,
                          width: 50,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: quizCompletionRate,
                          color: Colors.purple,
                          width: 50,
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
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
}
