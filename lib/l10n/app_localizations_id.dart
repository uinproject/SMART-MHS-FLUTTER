// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'SMART Mahasiswa';

  @override
  String get appDesc => 'Sistem Informasi Akademik Mahasiswa';

  @override
  String get home => 'Beranda';

  @override
  String get news => 'Berita';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get account => 'Akun';

  @override
  String get welcome => 'Selamat Datang';

  @override
  String get loginInstruction => 'Silakan masuk dengan akun SIAKAD Anda';

  @override
  String get login => 'Masuk';

  @override
  String get nim => 'NIM';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Lupa Password?';

  @override
  String get forgotPassInstruction =>
      'Masukkan NIM dan Email Anda untuk mengatur ulang kata sandi';

  @override
  String get email => 'Email';

  @override
  String get emailRequired => 'Email tidak boleh kosong';

  @override
  String get invalidEmail => 'Format email tidak valid';

  @override
  String get btnResetPassword => 'Atur Ulang Kata Sandi';

  @override
  String get newPassword => 'Password Baru';

  @override
  String get confirmPassword => 'Konfirmasi Password Baru';

  @override
  String get newPassRequired => 'Password baru wajib diisi';

  @override
  String get confPassRequired => 'Konfirmasi password wajib diisi';

  @override
  String get passNotMatch => 'Password tidak cocok';

  @override
  String get changePassInstruction =>
      'Silahkan masukan password baru anda, Password baru minimal 8 Karakter.';

  @override
  String get successChangePass => 'Password berhasil diperbarui';

  @override
  String get otpResetPassInstruction =>
      'Masukkan kode OTP yang dikirim ke email terdaftar Anda';

  @override
  String get resendOtpSuccess => 'Kode OTP berhasil dikirim ulang';

  @override
  String get accountSettings => 'Pengaturan Akun';

  @override
  String get language => 'Bahasa';

  @override
  String get logout => 'Keluar';

  @override
  String get settings => 'Pengaturan';

  @override
  String get profile => 'Profil Saya';

  @override
  String get security => 'Keamanan';

  @override
  String get help => 'Pusat Bantuan';

  @override
  String get about => 'Tentang Aplikasi';

  @override
  String get ipk => 'IP Kumulatif';

  @override
  String get sks => 'SKS Ditempuh';

  @override
  String get semester => 'Semester';

  @override
  String get status => 'Status Mahasiswa';

  @override
  String get checkKrs => 'Pengecekan KRS';

  @override
  String get examine => 'Periksa';

  @override
  String get announcements => 'Pengumuman';

  @override
  String get showMore => 'Lihat Lebih';

  @override
  String get showLess => 'Tutup';

  @override
  String get mainMenu => 'Menu Utama';

  @override
  String get showAll => 'Lihat Semua';

  @override
  String get logoutConfirm => 'Apakah Anda yakin ingin keluar?';

  @override
  String get ok => 'Ya';

  @override
  String get cancel => 'Batal';

  @override
  String get goodMorning => 'Selamat Pagi';

  @override
  String get goodAfternoon => 'Selamat Siang';

  @override
  String get goodEvening => 'Selamat Sore';

  @override
  String get goodNight => 'Selamat Malam';

  @override
  String get statusActive => 'Aktif';

  @override
  String get statusLeave => 'Cuti';

  @override
  String get statusGraduated => 'Lulus';

  @override
  String get statusNonActive => 'Belum Registrasi';

  @override
  String get statusOut => 'Keluar';

  @override
  String get statusMove => 'Pindah';

  @override
  String get statusDeath => 'Meninggal Dunia';

  @override
  String get emailVerif => 'Verifikasi Email';

  @override
  String get examineLater => 'Verifikasi Nanti';

  @override
  String get otpVerif => 'Verifikasi OTP';

  @override
  String get enterOtp => 'Masukkan kode OTP yang dikirim ke:';

  @override
  String get resendOtp => 'Kirim Ulang';

  @override
  String get wait => 'Tunggu';

  @override
  String get nimRequired => 'NIM tidak boleh kosong';

  @override
  String get passRequired => 'Password tidak boleh kosong';

  @override
  String get connError => 'Terjadi kesalahan koneksi';

  @override
  String get termsConditions => 'Syarat dan Ketentuan';

  @override
  String get agreeAndContinue => 'Setuju';

  @override
  String get termsContent =>
      'Dengan menggunakan aplikasi ini saya telah membaca dan menyetujui syarat dan ketentuan yang berlaku dari';

  @override
  String get pleaseWait => 'Mohon tunggu...';

  @override
  String get schedule => 'Jadwal';

  @override
  String get bills => 'Tagihan';

  @override
  String get presence => 'Presensi';

  @override
  String get attendance => 'Kehadiran';

  @override
  String get edom => 'EDOM';

  @override
  String get academicHistory => 'Riwayat IP';

  @override
  String get offers => 'Penawaran';

  @override
  String get krs => 'KRS';

  @override
  String get khs => 'KHS';

  @override
  String get programStudy => 'Program Studi';

  @override
  String get faculty => 'Fakultas';

  @override
  String get rateApp => 'Beri Rating';

  @override
  String get pembayaran => 'Pembayaran';

  @override
  String get justNow => 'baru saja';

  @override
  String minutesAgo(int count) {
    return '$count menit yang lalu';
  }

  @override
  String hoursAgo(int count) {
    return '$count jam yang lalu';
  }

  @override
  String daysAgo(int count) {
    return '$count hari yang lalu';
  }

  @override
  String monthsAgo(int count) {
    return '$count bulan yang lalu';
  }

  @override
  String yearsAgo(int count) {
    return '$count tahun yang lalu';
  }

  @override
  String get credit => 'SKS';

  @override
  String get room => 'Ruang';

  @override
  String get lecturer => 'Dosen';

  @override
  String get today => 'Hari Ini';

  @override
  String get noSchedule => 'Tidak ada jadwal kuliah';

  @override
  String get scheduleTitle => 'Jadwal Kuliah';

  @override
  String get chooseLanguage => 'Pilih Bahasa';

  @override
  String get indonesian => 'Indonesia';

  @override
  String get english => 'Inggris';

  @override
  String get arabic => 'Arab';

  @override
  String get paymentHistory => 'Riwayat Pembayaran';

  @override
  String get tuitionFee => 'Biaya Kuliah';

  @override
  String get paymentInstructions => 'Petunjuk Pembayaran';

  @override
  String get receipt => 'Kuitansi';

  @override
  String get copySuccess => 'Berhasil disalin';

  @override
  String get proceed => 'Lanjutkan';

  @override
  String get billLabel => 'Tagihan';

  @override
  String get totalBills => 'Total Tagihan';

  @override
  String get noActiveBills => 'Tidak ada tagihan yang harus dibayar';

  @override
  String get billStatusUnpaid => 'BELUM LUNAS';

  @override
  String get billStatusPaid => 'LUNAS';

  @override
  String get noPaymentHistoryFound => 'Riwayat Pembayaran Tidak Ditemukan';

  @override
  String get paymentMethod => 'Metode Pembayaran';

  @override
  String get noPaymentMethods => 'Tidak ada metode pembayaran tersedia';

  @override
  String get paymentNumber => 'Nomor Pembayaran';

  @override
  String get copy => 'Salin';

  @override
  String get adminFee => 'Biaya Admin';

  @override
  String get totalPay => 'Total Bayar';

  @override
  String get automaticVerification => 'Verifikasi Otomatis';

  @override
  String get paymentNumberCopied => 'Nomor pembayaran berhasil disalin';

  @override
  String get via => 'Melalui';

  @override
  String get downloadReceipt => 'Unduh Kuitansi';

  @override
  String get downloadingReceipt =>
      'Mengunduh kuitansi... Periksa di folder Download';

  @override
  String get cantOpenReceipt => 'Tidak dapat membuka kuitansi';

  @override
  String get checkConnection =>
      'Periksa koneksimu, Tidak dapat terhubung ke jaringan';

  @override
  String historyItemDetail(String name, String semester) {
    return '$name (Semester $semester)';
  }

  @override
  String get offersTitle => 'Penawaran MK';

  @override
  String get inputOfferTitle => 'Input Penawaran Mata Kuliah';

  @override
  String get offerHistoryTitle => 'Riwayat Input PMK';

  @override
  String get semesterPackage => 'Paket Semester';

  @override
  String get sksQuota => 'Jatah SKS';

  @override
  String get offerStartLabel => 'Tanggal mulai input PMK';

  @override
  String get offerEndLabel => 'Tanggal akhir input PMK';

  @override
  String get information => 'Informasi';

  @override
  String get noOfferings => 'Tidak ada penawaran mata kuliah yang tersedia';

  @override
  String get noOfferHistory => 'Riwayat input penawaran tidak ditemukan';

  @override
  String selectedCoursesCount(int count, int sks) {
    return '$count Mata Kuliah ($sks SKS)';
  }

  @override
  String sksLimitExceeded(int sks) {
    return 'Tidak dapat input PMK melebihi $sks sks';
  }

  @override
  String khsYear(String year) {
    return 'KHS TA: $year';
  }

  @override
  String get save => 'Simpan';

  @override
  String get okButton => 'Ok';

  @override
  String get evalRequiredMessage =>
      'Untuk melanjutkan silahkan lengkapi penilaian evaluasi dosen pada seluruh semester yang telah dilalui';

  @override
  String get completeLecturerEval => 'Isi Penilaian Dosen';

  @override
  String get krsSubmenuTitle => 'Sub Menu KRS';

  @override
  String get viewKrsTitle => 'Kartu Rencana Studi';

  @override
  String get inputKrsTitle => 'Input KRS';

  @override
  String get krsSemesterLabel => 'KRS Semester';

  @override
  String get approvedSksLabel => 'Jumlah SKS disetujui';

  @override
  String get krsNote =>
      'Untuk melihat KRS semester sebelumnya silahkan akses menu KHS';

  @override
  String get krsInputStartLabel => 'Tanggal mulai pengisian KRS';

  @override
  String get krsInputEndLabel => 'Tanggal akhir pengisian KRS';

  @override
  String get krsInputWarning =>
      'KRS yang sudah di setujui oleh dosen wali tidak dapat diubah kembali!';

  @override
  String scheduleConflict(String course) {
    return 'Gagal, terjadi benturan jadwal dengan mata kuliah $course';
  }

  @override
  String get notScheduled => 'Tidak Dijadwalkan';

  @override
  String get classLabel => 'Kelas';

  @override
  String get quotaLabel => 'Kuota';

  @override
  String get remainingLabel => 'Sisa';

  @override
  String get approvedBadge => 'Disetujui';

  @override
  String get courseCode => 'Kode MK';

  @override
  String get krsTotalLabel => 'Jumlah KRS Mata Kuliah';

  @override
  String get noKrsData => 'Tidak ada data KRS yang tersedia';

  @override
  String get noKrsOfferings =>
      'Tidak ada mata kuliah yang tersedia untuk input KRS';

  @override
  String get subscriptionRequiredMessage =>
      'Fitur ini memerlukan langganan. Silakan berlangganan untuk dapat menggunakan fitur ini sepenuhnya';

  @override
  String get sessionExpired =>
      'Sesi Anda telah berakhir, silakan login kembali';

  @override
  String get preparingPdf => 'Menyiapkan dokumen PDF...';

  @override
  String get cantOpenPdf => 'Tidak dapat membuka PDF';

  @override
  String get failedSavePdf => 'Gagal menyimpan PDF';

  @override
  String get edomSemestersTitle => 'Semester Evaluasi';

  @override
  String get edomCoursesTitle => 'Mata Kuliah Evaluasi';

  @override
  String get edomStatusDone => 'Selesai';

  @override
  String get edomStatusProgress => 'Proses Pengisian';

  @override
  String get edomStatusNotFilled => 'Belum Mengisi';

  @override
  String get edomOpenDetail => 'Isi / Detail Evaluasi';

  @override
  String get edomSemestersSubtitle =>
      'Pilih semester untuk mengisi evaluasi dosen';

  @override
  String edomProgressSummary(int done, int total) {
    return '$done dari $total semester selesai';
  }

  @override
  String get edomSemestersEmpty => 'Tidak ada semester evaluasi yang tersedia';

  @override
  String edomCoursesProgressSummary(int done, int total) {
    return '$done dari $total mata kuliah dievaluasi';
  }

  @override
  String get edomCoursesEmpty => 'Tidak ada mata kuliah evaluasi yang tersedia';

  @override
  String get edomHistoryButton => 'Riwayat';

  @override
  String get edomFillButton => 'Isi Penilaian';

  @override
  String edomFillAllQuestionsError(String indicator, int number) {
    return 'Silahkan lengkapi jawaban pada indikator $indicator nomor $number';
  }

  @override
  String get edomImpressionTitle => 'Kesan Pesan';

  @override
  String get edomImpressionInstruction =>
      'Tuliskan komentar,kesan pesan atau saran minimal 8 karakter. Nama anda tidak akan ditampilkan di dashboard dosen';

  @override
  String get edomImpressionMinError => 'Kesan Pesan minimal 8 karakter';

  @override
  String get edomSaving => 'Menyimpan jawaban anda';

  @override
  String get edomExitConfirmTitle => 'Apakah anda yakin?';

  @override
  String get edomExitConfirmMessage =>
      'Jika anda keluar sekarang jawaban tidak akan disimpan';

  @override
  String get errorResponseApi =>
      'Periksa koneksimu, Tidak dapat terhubung ke server';

  @override
  String get tryAgain => 'Coba Lagi';
}
