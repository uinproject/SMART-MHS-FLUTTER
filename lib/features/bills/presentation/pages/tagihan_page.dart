import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/session_manager.dart';
import '../../data/models/tagihan_response.dart';
import '../widgets/panduan_pembayaran.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TagihanPage extends StatefulWidget {
  const TagihanPage({super.key});

  @override
  State<TagihanPage> createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  final _apiService = ApiService();
  final _sessionManager = SessionManager();
  
  TagihanResponse? _tagihan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTagihan();
  }

  Future<void> _loadTagihan() async {
    setState(() => _isLoading = true);
    try {
      final user = _sessionManager.getUser();
      if (user != null) {
        final result = await _apiService.getTagihanmhs(
          nim: user.nim ?? '',
          language: Localizations.localeOf(context).languageCode,
        );
        if (mounted) {
          setState(() {
            _tagihan = result;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generatePdf() async {
    if (_tagihan == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menyiapkan dokumen PDF...'), duration: Duration(seconds: 1)),
    );

    final pdf = pw.Document();
    final user = _sessionManager.getUser();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('TAGIHAN KULIAH', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('NIM: ${user?.nim ?? "-"}'),
                  pw.Text('Nama: ${user?.nama ?? "-"}'),
                  pw.Text('Semester: ${_tagihan?.semester ?? "-"}'),
                  pw.Divider(),
                ],
              ),
            ),
            pw.TableHelper.fromTextArray(
              headers: ['Uraian', 'Nominal', 'Status'],
              data: _tagihan!.itemTagihan!.map((item) => [
                item.uraian,
                'Rp ${item.nominal}',
                item.status,
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total Tagihan: ${currencyFormat.format(_calculateTotal())}',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  int _calculateTotal() {
    if (_tagihan?.itemTagihan == null) return 0;
    return _tagihan!.itemTagihan!.fold(0, (sum, item) => sum + item.nominalInt);
  }

  void _showPaymentInstructions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PaymentInstructionsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    const mainGradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [Color(0xFF003D82), Color(0xFF0056B3)],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 70,
            backgroundColor: const Color(0xFF003D82),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              l10n.bills,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            centerTitle: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: mainGradient),
            ),
            actions: [
              IconButton(
                onPressed: _generatePdf,
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.download_rounded, color: Color(0xFF003D82), size: 20),
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: SpinKitThreeBounce(color: AppColors.primary, size: 30)),
            )
          else if (_tagihan?.itemTagihan == null || _tagihan!.itemTagihan!.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Tidak ada tagihan yang harus dibayar')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _tagihan!.itemTagihan![index];
                    return _buildBillCard(item);
                  },
                  childCount: _tagihan!.itemTagihan!.length,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isLoading || _tagihan == null ? null : _buildBottomBar(currencyFormat),
    );
  }

  Widget _buildBillCard(ItemTagihan item) {
    final isLunas = item.status.toLowerCase().contains('lunas') && !item.status.toLowerCase().contains('belum');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: isLunas ? null : _showPaymentInstructions,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isLunas ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status.toUpperCase(),
                    style: TextStyle(
                      color: isLunas ? Colors.green : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.uraian,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Rp ${item.nominal}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(NumberFormat format) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Tagihan', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                format.format(_calculateTotal()),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _showPaymentInstructions,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Cara Bayar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PaymentInstructionsSheet extends StatelessWidget {
  const _PaymentInstructionsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Panduan Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const TabBar(
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'BNI'),
                Tab(text: 'Tokopedia'),
                Tab(text: 'Indomaret'),
                Tab(text: 'ATM Bersama'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildInstructionList(PanduanPembayaran.bni),
                  _buildInstructionList(PanduanPembayaran.tokopedia),
                  _buildInstructionList(PanduanPembayaran.indomaret),
                  _buildInstructionList(PanduanPembayaran.atmBersama),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionList(List<Instruction> instructions) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: instructions.length,
      itemBuilder: (context, index) {
        final section = instructions[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...section.steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: Text('${entry.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(entry.value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary))),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
