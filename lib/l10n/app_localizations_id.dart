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
  String get room => 'Ruangan';

  @override
  String get lecturer => 'Dosen';

  @override
  String get today => 'Hari Ini';

  @override
  String get noSchedule => 'Tidak ada jadwal kuliah';

  @override
  String get noScheduleSubtitle =>
      'Jadwal untuk semester ini belum tersedia atau masih dalam proses pemutakhiran';

  @override
  String get scheduleLoadFailed =>
      'Gagal memuat jadwal. Tarik ke bawah untuk mencoba lagi';

  @override
  String get pdfScheduleTitle => 'JADWAL KULIAH';

  @override
  String get pdfPrintedAt => 'Dicetak pada:';

  @override
  String get pdfName => 'Nama';

  @override
  String get pdfYear => 'Tahun';

  @override
  String get pdfCourse => 'Mata Kuliah';

  @override
  String get pdfTimeRoom => 'Waktu/Ruang';

  @override
  String get pdfLecturer => 'Dosen';

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
  String get completeLecturerEval => 'Isi';

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

  @override
  String get ips => 'IP Semester';

  @override
  String get khsTitle => 'KHS';

  @override
  String get khsSemesterSks => 'SKS Semester';

  @override
  String get khsGradeWeight => 'Bobot Nilai';

  @override
  String get khsGradeIndex => 'Index Nilai';

  @override
  String get khsNotFound => 'Data KHS tidak ditemukan';

  @override
  String get khsPdfTitle => 'KARTU HASIL STUDI';

  @override
  String get khsWaitUntilLoaded => 'Tunggu sampai KHS selesai dimuat';

  @override
  String get evalNotCompletedMessage =>
      'Anda belum melengkapi penilaian evaluasi dosen';

  @override
  String get lastGpa => 'IPK Terakhir';

  @override
  String get lastIps => 'IPS Terakhir';

  @override
  String get totalCredits => 'Total Beban SKS';

  @override
  String get ipkChart => 'Grafik IPK Kumulatif';

  @override
  String get ipsChart => 'Grafik IP Semester (IPS)';

  @override
  String get sksLoadChart => 'Beban SKS Per Semester';

  @override
  String get registrationHistory => 'Riwayat Registrasi';

  @override
  String get failedLoadData => 'Gagal memuat data';

  @override
  String get loginFailed => 'Login Gagal';

  @override
  String get close => 'Tutup';

  @override
  String get deviceSync => 'Sinkronisasi Perangkat';

  @override
  String get enterNim => 'Masukkan NIM';

  @override
  String get enterPassword => 'Masukkan Password';

  @override
  String get version => 'Versi';

  @override
  String get systemError =>
      'Terjadi kesalahan koneksi atau sistem. Silakan coba lagi nanti.';

  @override
  String get pageLoadFailed => 'Halaman tidak dapat dimuat';

  @override
  String get checkInternetConnection =>
      'Periksa koneksi internet Anda kemudian coba lagi.';

  @override
  String get linkActiveEmailInstruction =>
      'Tautkan email aktif Anda untuk mendapatkan kode verifikasi keamanan.';

  @override
  String get getOtpCode => 'Dapatkan Kode OTP';

  @override
  String get didNotReceiveCode => 'Tidak menerima kode?';

  @override
  String get resendOtpFailed => 'Gagal mengirim ulang kode.';

  @override
  String get verify => 'Verifikasi';

  @override
  String get otpVerifyFailed => 'Gagal memverifikasi OTP.';

  @override
  String get success => 'Berhasil';

  @override
  String get enterEmail => 'Masukkan Email';

  @override
  String get serverConnectionFailed => 'Gagal menghubungi server.';

  @override
  String get passMinLength => 'Password minimal 8 karakter';

  @override
  String get confirmNewPasswordHint => 'Konfirmasi Password Baru';

  @override
  String get savePassword => 'Simpan Password';

  @override
  String get goToLoginPage => 'Ke Halaman Login';

  @override
  String get updatePasswordFailed => 'Gagal memperbarui password.';

  @override
  String get enterNewPassword => 'Masukkan Password Baru';

  @override
  String get scanQrTitle => 'Pindai QR Presensi';

  @override
  String get scanQrInstruction =>
      'Arahkan kamera ke QR Code presensi yang ditampilkan oleh dosen';

  @override
  String get flashOn => 'Nyalakan Flash';

  @override
  String get flashOff => 'Matikan Flash';

  @override
  String get switchCamera => 'Ganti Kamera';

  @override
  String get useShortCode => 'Gunakan Short Code';

  @override
  String get inputShortCodeHint => 'Masukkan Kode Presensi';

  @override
  String get shortCodeEmpty => 'Kode presensi tidak boleh kosong';

  @override
  String get cantScanQrQuestion =>
      'Kamera bermasalah atau tidak bisa memindai?';

  @override
  String get presenceProcessTitle => 'Verifikasi Presensi';

  @override
  String get validatingPresenceCode => 'Memvalidasi Kode Presensi...';

  @override
  String get recordingPresence => 'Mencatat Kehadiran...';

  @override
  String get presenceSuccess => 'Presensi Berhasil!';

  @override
  String get presenceAlreadyRecorded =>
      'Anda sudah tercatat hadir pada perkuliahan ini.';

  @override
  String get presenceSuccessDetail =>
      'Kehadiran Anda berhasil dicatat dalam sistem perkuliahan.';

  @override
  String get presenceFailed => 'Presensi Gagal';

  @override
  String get courseInfo => 'Informasi Perkuliahan';

  @override
  String meetingNumber(String number) {
    return 'Pertemuan ke-$number';
  }

  @override
  String get lectureTopic => 'Topik Perkuliahan';

  @override
  String get lectureDescription => 'Deskripsi Perkuliahan';

  @override
  String get time => 'Waktu';

  @override
  String get retryPresence => 'Coba Lagi';

  @override
  String get backToHome => 'Kembali ke Beranda';

  @override
  String get submit => 'Kirim';

  @override
  String get cameraPermissionDenied =>
      'Izin kamera diperlukan untuk memindai QR code presensi.';

  @override
  String get attendanceTitle => 'Riwayat Kehadiran';

  @override
  String get searchCourseHint => 'Cari mata kuliah atau dosen...';

  @override
  String get overallAttendanceSummary => 'Ringkasan Kehadiran';

  @override
  String get totalCourses => 'Total Mata Kuliah';

  @override
  String get totalMeetings => 'Total Pertemuan';

  @override
  String get totalAttendance => 'Total Kehadiran';

  @override
  String get attendancePercentage => 'Persentase Kehadiran';

  @override
  String get attendanceDetailTitle => 'Rincian Kehadiran';

  @override
  String get meetingDetailTitle => 'Detail Pertemuan';

  @override
  String get present => 'Hadir';

  @override
  String get absent => 'Tidak Hadir';

  @override
  String get lectureMaterials => 'Materi Perkuliahan';

  @override
  String get noMaterials => 'Tidak ada materi yang diunggah';

  @override
  String get downloadMaterial => 'Unduh Materi';

  @override
  String get downloadingMaterial => 'Mengunduh materi...';

  @override
  String get downloadSuccess => 'Materi berhasil diunduh';

  @override
  String get downloadFailed => 'Gagal mengunduh materi';

  @override
  String get openFile => 'Buka File';

  @override
  String get noCoursesFound => 'Tidak ada mata kuliah ditemukan';

  @override
  String get announcementDetail => 'Detail Pengumuman';

  @override
  String get searchAnnouncementHint => 'Cari judul pengumuman...';

  @override
  String maxNewsLoaded(int count) {
    return 'Maksimal berita yang dapat dimuat adalah $count Baris';
  }

  @override
  String get noAnnouncementsFound => 'Tidak ada pengumuman ditemukan';

  @override
  String get publisher => 'Penerbit';

  @override
  String get category => 'Kategori';

  @override
  String get viewImage => 'Lihat Gambar';

  @override
  String get openInBrowser => 'Buka di Browser';

  @override
  String get facultyNews => 'Berita Fakultas';

  @override
  String get rectorateNews => 'Berita Rektorat';

  @override
  String get newsDetail => 'Detail Berita';

  @override
  String get searchNewsHint => 'Cari judul berita...';

  @override
  String get noNewsFound => 'Tidak ada berita ditemukan';

  @override
  String get qiblaDirection => 'Arah Kiblat';

  @override
  String get qiblaCompass => 'Kompas Kiblat';

  @override
  String get deviceNotSupported => 'Perangkat Tidak Mendukung';

  @override
  String get deviceNotSupportedDesc =>
      'Perangkat Anda tidak memiliki sensor kompas/magnetometer yang diperlukan untuk menentukan arah kiblat.';

  @override
  String get locationPermissionRequired => 'Izin Lokasi Diperlukan';

  @override
  String get locationPermissionDesc =>
      'Aplikasi memerlukan izin lokasi untuk menentukan arah kiblat yang akurat dari posisi Anda.';

  @override
  String get enableLocation => 'Aktifkan Lokasi';

  @override
  String get grantPermission => 'Izinkan Akses Lokasi';

  @override
  String get locationDisabled => 'GPS / Lokasi Tidak Aktif';

  @override
  String get locationDisabledDesc =>
      'Silakan aktifkan GPS atau layanan lokasi pada perangkat Anda.';

  @override
  String get facingQibla => 'Tepat Menghadap Kiblat';

  @override
  String get alignWithQibla =>
      'Arahkan ponsel hingga jarum sejajar dengan Ka\'bah';

  @override
  String get distanceToKaaba => 'Jarak ke Ka\'bah';

  @override
  String get qiblaAngle => 'Arah Kiblat';

  @override
  String get currentHeading => 'Arah Saat Ini';

  @override
  String get calibrateCompassHint =>
      'Jika jarum kompas tidak akurat, kalibrasi dengan menggerakkan ponsel membentuk angka 8.';

  @override
  String get openSettings => 'Buka Pengaturan';

  @override
  String get prayerSchedule => 'Jadwal Sholat';

  @override
  String get prayerTimes => 'Jadwal Sholat';

  @override
  String get fajr => 'Subuh';

  @override
  String get sunrise => 'Terbit';

  @override
  String get dhuhr => 'Dzuhur';

  @override
  String get asr => 'Ashar';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isya';

  @override
  String get imsak => 'Imsak';

  @override
  String get nextPrayer => 'Sholat Berikutnya';

  @override
  String get inCountdown => 'dalam';

  @override
  String get tomorrowFajr => 'Besok';

  @override
  String get fastingSchedule => 'Jadwal Puasa';

  @override
  String get fastingToday => 'Jadwal Puasa Hari Ini';

  @override
  String get fastingRamadhan => 'Puasa Ramadhan';

  @override
  String get fastingMondayThursday => 'Puasa Sunnah Senin - Kamis';

  @override
  String get fastingAyyamulBidh => 'Puasa Sunnah Ayyamul Bidh';

  @override
  String get fastingArafah => 'Puasa Sunnah Arafah';

  @override
  String get fastingAsyura => 'Puasa Sunnah Asyura';

  @override
  String get fastingTasuah => 'Puasa Sunnah Tasu\'a';

  @override
  String get breakFasting => 'Buka Puasa';

  @override
  String get startFasting => 'Mulai Puasa';

  @override
  String get timeUntilIftar => 'Menuju Buka Puasa';

  @override
  String get timeUntilImsak => 'Menuju Imsak';

  @override
  String get showingCachedData => 'Menampilkan data tersimpan (Offline)';

  @override
  String get refreshSchedule => 'Perbarui Jadwal';

  @override
  String get kemenagMethod => 'Kementerian Agama RI';

  @override
  String get prayerLocationPermissionDesc =>
      'Aplikasi memerlukan izin lokasi untuk menampilkan jadwal sholat yang akurat sesuai lokasi Anda.';

  @override
  String get prayerShortLabel => 'Sholat';

  @override
  String get csListTitle => 'Daftar Layanan';

  @override
  String get csSubtitle =>
      'Kami Siap Membantu, pilih layanan sesuai dengan masalahmu..';

  @override
  String get csReadyToServe => 'Siap Melayani';

  @override
  String get csServiceClosed => 'Pelayanan Tutup';

  @override
  String get csChatWa => 'Chat WhatsApp';

  @override
  String get csClosedReasonPrefix =>
      '* Mungkin pesan anda tidak segera dibalas karena';

  @override
  String get csClosedReasonSuffix =>
      'Tinggalkan pesan dan kami akan membalas pada jam kerja.';

  @override
  String get whatsappNotFound => 'Aplikasi WhatsApp tidak ditemukan';

  @override
  String get emptyCsList => 'Belum ada daftar layanan yang tersedia';

  @override
  String get aiChatTitle => 'Asisten AI';

  @override
  String get aiChatHelpdeskOption => 'Chat dengan Asisten AI';

  @override
  String get aiChatHelpdeskSubtitle =>
      'Tanya AI respon lebih cepat dari wa helpdesk';

  @override
  String get aiChatDisclaimer =>
      'Asisten ini adalah robot virtual, jawaban mungkin bisa salah.';

  @override
  String aiChatGreeting(String name) {
    return 'Halo $name 👋, ada yang bisa saya bantu?';
  }

  @override
  String get aiChatInputHint => 'Tulis pertanyaan...';

  @override
  String get aiChatWaitLonger =>
      'Asisten AI sedang memproses, mohon tunggu sebentar...';

  @override
  String get aiChatTimeout =>
      'Koneksi timeout. Server membutuhkan waktu terlalu lama untuk merespon.';

  @override
  String get aiChatError => 'Gagal mengirim pesan. Silakan coba lagi.';

  @override
  String get aiChatRetry => 'Coba Lagi';

  @override
  String aiChatContactCs(String label) {
    return 'Hubungi $label via WhatsApp';
  }

  @override
  String get aiChatFeedbackTitle => 'Berikan Penilaian';

  @override
  String get aiChatFeedbackPositive => 'Apa yang membuat jawaban ini membantu?';

  @override
  String get aiChatFeedbackNegative => 'Apa kendala pada jawaban ini?';

  @override
  String get aiChatFeedbackThankYou =>
      'Terima kasih atas penilaian dan masukan Anda!';

  @override
  String get aiChatFeedbackAccurate => 'Jawaban akurat dan lengkap';

  @override
  String get aiChatFeedbackEasyToUnderstand => 'Mudah dipahami';

  @override
  String get aiChatFeedbackVeryHelpful => 'Sangat membantu';

  @override
  String get aiChatFeedbackNotRelevant => 'Jawaban tidak sesuai pertanyaan';

  @override
  String get aiChatFeedbackIncomplete => 'Informasi kurang lengkap';

  @override
  String get aiChatFeedbackTooSlow => 'Respon terlalu lama';

  @override
  String get aiChatFeedbackHardToUnderstand => 'Jawaban sulit dipahami';

  @override
  String get aiChatFeedbackCustomPlaceholder =>
      'Tulis komentar lainnya (opsional, maks 50 karakter)...';

  @override
  String get aiChatFeedbackSubmit => 'Kirim Penilaian';

  @override
  String get aiChatQuickQuestions => 'Pertanyaan Cepat';

  @override
  String get aiChatQuickQuestion1 => 'Bagaimana cara reset password SIAKAD?';

  @override
  String get aiChatQuickQuestion2 =>
      'Saya lupa melakukan input penawaran mata kuliah?';

  @override
  String get aiChatQuickQuestion3 => 'Saya lupa melakukan input KRS?';

  @override
  String get aiChatQuickQuestion4 => 'Berapa jumlah SKS yang bisa saya ambil?';
}
