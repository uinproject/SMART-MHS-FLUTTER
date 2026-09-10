import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/riwayat_akademik_response.dart';
import '../widgets/academic_chart_card.dart';
import '../widgets/registration_history_dialog.dart';
import '../../../bills/presentation/widgets/error_state_widget.dart';

enum _AcademicHistoryState { loading, success, serverError }

class AcademicHistoryPage extends StatefulWidget {
  const AcademicHistoryPage({super.key});

  @override
  State<AcademicHistoryPage> createState() => _AcademicHistoryPageState();
}

class _AcademicHistoryPageState extends State<AcademicHistoryPage> {
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
  int get _totalSks => _history?.data?.riwayatSks.fold(0, (sum, e) => sum! + e.sks) ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const mainGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF003D82), Color(0xFF0056B3)],
    );

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
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: mainGradient),
        ),
        actions: [
          if (_state == _AcademicHistoryState.success)
            IconButton(
              icon: const Icon(Icons.history_edu_rounded, color: Colors.white),
              onPressed: () => showRegistrationHistoryDialog(
                context: context,
                registrations: _history!.data!.riwayatRegistrasi,
              ),
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    switch (_state) {
      case _AcademicHistoryState.loading:
        return const Center(
          child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
        );
      case _AcademicHistoryState.serverError:
        return ErrorStateWidget(
          type: ErrorStateType.serverError,
          serverMessage: _history?.message ?? l10n.failedLoadData,
        );
      case _AcademicHistoryState.success:
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSummaryCard(l10n),
            const SizedBox(height: 10),
            _buildIpkChart(l10n),
            _buildIpsChart(l10n),
            _buildSksChart(l10n),
            const SizedBox(height: 40),
          ],
        );
    }
  }

  Widget _buildSummaryCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryItem(
              l10n.lastGpa.toUpperCase(),
              _latestIpk.toStringAsFixed(2),
              Icons.star_rounded,
              Colors.amber,
            ),
          ),
          Container(height: 40, width: 1, color: const Color(0xFFF1F5F9)),
          Expanded(
            child: _summaryItem(
              l10n.totalCredits.toUpperCase(),
              _totalSks.toString(),
              Icons.school_rounded,
              AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildIpkChart(AppLocalizations l10n) {
    final spots = _history!.data!.riwayatIpk.map((e) => FlSpot(e.semester.toDouble(), e.ipk)).toList();

    return AcademicChartCard(
      title: l10n.ipkChart,
      chart: LineChart(
        LineChartData(
          minY: 0,
          maxY: 4.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
          titlesData: _buildTitlesData(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildIpsChart(AppLocalizations l10n) {
    final spots = _history!.data!.riwayatIps.map((e) => FlSpot(e.semester.toDouble(), e.ips)).toList();

    return AcademicChartCard(
      title: l10n.ipsChart,
      chart: LineChart(
        LineChartData(
          minY: 0,
          maxY: 4.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.secondary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.secondary.withValues(alpha: 0.1),
              ),
            ),
          ],
          titlesData: _buildTitlesData(),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildSksChart(AppLocalizations l10n) {
    final barGroups = _history!.data!.riwayatSks.map((e) {
      return BarChartGroupData(
        x: e.semester,
        barRods: [
          BarChartRodData(
            toY: e.sks.toDouble(),
            color: AppColors.success,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return AcademicChartCard(
      title: l10n.sksLoadChart,
      chart: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: _buildTitlesData(isBar: true),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  FlTitlesData _buildTitlesData({bool isBar = false}) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              value.toInt().toString(),
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) => Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}
