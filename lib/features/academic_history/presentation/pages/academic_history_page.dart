import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/riwayat_akademik_response.dart';
import '../widgets/registration_history_dialog.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';

enum _AcademicHistoryState { loading, success, serverError }

class AcademicHistoryPage extends StatefulWidget {
  const AcademicHistoryPage({super.key});

  @override
  State<AcademicHistoryPage> createState() => _AcademicHistoryPageState();
}

class _AcademicHistoryPageState extends State<AcademicHistoryPage> {
  static const LinearGradient _mainGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF003D82), Color(0xFF0056B3)],
  );

  final _apiService = ApiService();
  final _sessionManager = SessionManager();

  RiwayatAkademikResponse? _history;
  _AcademicHistoryState _state = _AcademicHistoryState.loading;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _state = _AcademicHistoryState.loading);

    final user = _sessionManager.getUser();
    if (user == null) {
      if (mounted) setState(() => _state = _AcademicHistoryState.serverError);
      return;
    }

    try {
      final result = await _apiService.getAcademicHistory(nim: user.nim ?? '');
      if (!mounted) return;
      setState(() {
        _history = result;
        if (result.success && result.data != null) {
          _state = _AcademicHistoryState.success;
        } else {
          _state = _AcademicHistoryState.serverError;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _state = _AcademicHistoryState.serverError);
    }
  }

  double get _latestIpk => _history?.data?.riwayatIpk.lastOrNull?.ipk ?? 0.0;

  /// IPS diambil dari semester terakhir yang sudah selesai (ips > 0),
  /// karena semester aktif biasanya belum memiliki nilai IPS.
  double get _latestIps {
    final list = _history?.data?.riwayatIps;
    if (list == null || list.isEmpty) return 0.0;
    return list.lastWhere((e) => e.ips > 0, orElse: () => list.last).ips;
  }

  int get _totalSks =>
      _history?.data?.riwayatSks.fold(0, (sum, e) => sum! + e.sks) ?? 0;
  int get _totalSemesters => _history?.data?.riwayatIpk.length ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: const Color(0xFF003D82),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.academicHistory,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _mainGradient),
        ),
        actions: [
          if (_state == _AcademicHistoryState.success)
            IconButton(
              icon: const Icon(Icons.history_edu_rounded, color: Colors.white),
              tooltip: l10n.registrationHistory,
              onPressed: () => showRegistrationHistoryDialog(
                context: context,
                registrations: _history!.data!.riwayatRegistrasi,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _buildBody(l10n),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_state) {
      case _AcademicHistoryState.loading:
        return ListView(
          key: const ValueKey('academic-loading'),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.32),
            const Center(
              child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
            ),
          ],
        );
      case _AcademicHistoryState.serverError:
        return ErrorStateWidget(
          key: const ValueKey('academic-error'),
          type: ErrorStateType.serverError,
          serverMessage: _history?.message ?? l10n.failedLoadData,
        );
      case _AcademicHistoryState.success:
        return ListView(
          key: const ValueKey('academic-success'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _buildHeroCard(l10n),
            const SizedBox(height: 24),
            _buildSectionLabel(
              l10n.ipkChart,
              Icons.trending_up_rounded,
              AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildIpkChart(),
            const SizedBox(height: 20),
            _buildSectionLabel(
              l10n.ipsChart,
              Icons.bar_chart_rounded,
              AppColors.secondary,
            ),
            const SizedBox(height: 12),
            _buildIpsChart(),
            const SizedBox(height: 20),
            _buildSectionLabel(
              l10n.sksLoadChart,
              Icons.layers_rounded,
              AppColors.success,
            ),
            const SizedBox(height: 12),
            _buildSksChart(),
          ],
        );
    }
  }

  Widget _buildHeroCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _mainGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.academicHistory,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalSemesters ${l10n.semester.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _heroStat(
                  label: l10n.lastGpa.toUpperCase(),
                  value: _latestIpk.toStringAsFixed(2),
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFFFD54F),
                ),
              ),
              Container(
                width: 1,
                height: 52,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _heroStat(
                  label: l10n.lastIps.toUpperCase(),
                  value: _latestIps.toStringAsFixed(2),
                  icon: Icons.auto_graph_rounded,
                  iconColor: const Color(0xFF80D8FF),
                ),
              ),
              Container(
                width: 1,
                height: 52,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _heroStat(
                  label: l10n.totalCredits.toUpperCase(),
                  value: _totalSks.toString(),
                  icon: Icons.school_rounded,
                  iconColor: const Color(0xFFA5D6A7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _chartCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SizedBox(height: 200, child: child),
    );
  }

  Widget _buildIpkChart() {
    final spots = _history!.data!.riwayatIpk
        .map((e) => FlSpot(e.semester.toDouble(), e.ipk))
        .toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    return _chartCard(
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 4.0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: AppColors.primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
          titlesData: _lineTitlesData(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFEDF2F7), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.primary,
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      s.y.toStringAsFixed(2),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIpsChart() {
    final spots = _history!.data!.riwayatIps
        .map((e) => FlSpot(e.semester.toDouble(), e.ips))
        .toList();

    if (spots.isEmpty) return const SizedBox.shrink();

    return _chartCard(
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 4.0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.secondary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: AppColors.secondary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.18),
                    AppColors.secondary.withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
          titlesData: _lineTitlesData(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: Color(0xFFEDF2F7), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.secondary,
              getTooltipItems: (spots) => spots
                  .map(
                    (s) => LineTooltipItem(
                      s.y.toStringAsFixed(2),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSksChart() {
    final barGroups = _history!.data!.riwayatSks.map((e) {
      return BarChartGroupData(
        x: e.semester,
        barRods: [
          BarChartRodData(
            toY: e.sks.toDouble(),
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppColors.success, Color(0xFF64FFDA)],
            ),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    if (barGroups.isEmpty) return const SizedBox.shrink();

    return _chartCard(
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          maxY: 24,
          titlesData: _barTitlesData(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.success,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  FlTitlesData _lineTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          getTitlesWidget: (value, meta) => Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  FlTitlesData _barTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              value.toInt().toString(),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 34,
          getTitlesWidget: (value, meta) => Text(
            value.toInt().toString(),
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}
