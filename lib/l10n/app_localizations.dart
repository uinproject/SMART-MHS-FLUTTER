import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'SMART Mahasiswa'**
  String get appTitle;

  /// No description provided for @appDesc.
  ///
  /// In id, this message translates to:
  /// **'Sistem Informasi Akademik Mahasiswa'**
  String get appDesc;

  /// No description provided for @home.
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get home;

  /// No description provided for @news.
  ///
  /// In id, this message translates to:
  /// **'Berita'**
  String get news;

  /// No description provided for @notifications.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get notifications;

  /// No description provided for @account.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get account;

  /// No description provided for @welcome.
  ///
  /// In id, this message translates to:
  /// **'Selamat Datang'**
  String get welcome;

  /// No description provided for @loginInstruction.
  ///
  /// In id, this message translates to:
  /// **'Silakan masuk dengan akun SIAKAD Anda'**
  String get loginInstruction;

  /// No description provided for @login.
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get login;

  /// No description provided for @nim.
  ///
  /// In id, this message translates to:
  /// **'NIM'**
  String get nim;

  /// No description provided for @password.
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In id, this message translates to:
  /// **'Lupa Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPassInstruction.
  ///
  /// In id, this message translates to:
  /// **'Masukkan NIM dan Email Anda untuk mengatur ulang kata sandi'**
  String get forgotPassInstruction;

  /// No description provided for @email.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailRequired.
  ///
  /// In id, this message translates to:
  /// **'Email tidak boleh kosong'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get invalidEmail;

  /// No description provided for @btnResetPassword.
  ///
  /// In id, this message translates to:
  /// **'Atur Ulang Kata Sandi'**
  String get btnResetPassword;

  /// No description provided for @newPassword.
  ///
  /// In id, this message translates to:
  /// **'Password Baru'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Password Baru'**
  String get confirmPassword;

  /// No description provided for @newPassRequired.
  ///
  /// In id, this message translates to:
  /// **'Password baru wajib diisi'**
  String get newPassRequired;

  /// No description provided for @confPassRequired.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password wajib diisi'**
  String get confPassRequired;

  /// No description provided for @passNotMatch.
  ///
  /// In id, this message translates to:
  /// **'Password tidak cocok'**
  String get passNotMatch;

  /// No description provided for @changePassInstruction.
  ///
  /// In id, this message translates to:
  /// **'Silahkan masukan password baru anda, Password baru minimal 8 Karakter.'**
  String get changePassInstruction;

  /// No description provided for @successChangePass.
  ///
  /// In id, this message translates to:
  /// **'Password berhasil diperbarui'**
  String get successChangePass;

  /// No description provided for @otpResetPassInstruction.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kode OTP yang dikirim ke email terdaftar Anda'**
  String get otpResetPassInstruction;

  /// No description provided for @resendOtpSuccess.
  ///
  /// In id, this message translates to:
  /// **'Kode OTP berhasil dikirim ulang'**
  String get resendOtpSuccess;

  /// No description provided for @accountSettings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Akun'**
  String get accountSettings;

  /// No description provided for @language.
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In id, this message translates to:
  /// **'Profil Saya'**
  String get profile;

  /// No description provided for @security.
  ///
  /// In id, this message translates to:
  /// **'Keamanan'**
  String get security;

  /// No description provided for @help.
  ///
  /// In id, this message translates to:
  /// **'Pusat Bantuan'**
  String get help;

  /// No description provided for @about.
  ///
  /// In id, this message translates to:
  /// **'Tentang Aplikasi'**
  String get about;

  /// No description provided for @ipk.
  ///
  /// In id, this message translates to:
  /// **'IP Kumulatif'**
  String get ipk;

  /// No description provided for @sks.
  ///
  /// In id, this message translates to:
  /// **'SKS Ditempuh'**
  String get sks;

  /// No description provided for @semester.
  ///
  /// In id, this message translates to:
  /// **'Semester'**
  String get semester;

  /// No description provided for @status.
  ///
  /// In id, this message translates to:
  /// **'Status Mahasiswa'**
  String get status;

  /// No description provided for @checkKrs.
  ///
  /// In id, this message translates to:
  /// **'Pengecekan KRS'**
  String get checkKrs;

  /// No description provided for @examine.
  ///
  /// In id, this message translates to:
  /// **'Periksa'**
  String get examine;

  /// No description provided for @announcements.
  ///
  /// In id, this message translates to:
  /// **'Pengumuman'**
  String get announcements;

  /// No description provided for @showMore.
  ///
  /// In id, this message translates to:
  /// **'Lihat Lebih'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get showLess;

  /// No description provided for @mainMenu.
  ///
  /// In id, this message translates to:
  /// **'Menu Utama'**
  String get mainMenu;

  /// No description provided for @showAll.
  ///
  /// In id, this message translates to:
  /// **'Lihat Semua'**
  String get showAll;

  /// No description provided for @logoutConfirm.
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin keluar?'**
  String get logoutConfirm;

  /// No description provided for @ok.
  ///
  /// In id, this message translates to:
  /// **'Ya'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @goodMorning.
  ///
  /// In id, this message translates to:
  /// **'Selamat Pagi'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In id, this message translates to:
  /// **'Selamat Siang'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In id, this message translates to:
  /// **'Selamat Sore'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In id, this message translates to:
  /// **'Selamat Malam'**
  String get goodNight;

  /// No description provided for @statusActive.
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get statusActive;

  /// No description provided for @statusLeave.
  ///
  /// In id, this message translates to:
  /// **'Cuti'**
  String get statusLeave;

  /// No description provided for @statusGraduated.
  ///
  /// In id, this message translates to:
  /// **'Lulus'**
  String get statusGraduated;

  /// No description provided for @statusNonActive.
  ///
  /// In id, this message translates to:
  /// **'Belum Registrasi'**
  String get statusNonActive;

  /// No description provided for @statusOut.
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get statusOut;

  /// No description provided for @statusMove.
  ///
  /// In id, this message translates to:
  /// **'Pindah'**
  String get statusMove;

  /// No description provided for @statusDeath.
  ///
  /// In id, this message translates to:
  /// **'Meninggal Dunia'**
  String get statusDeath;

  /// No description provided for @emailVerif.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi Email'**
  String get emailVerif;

  /// No description provided for @examineLater.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi Nanti'**
  String get examineLater;

  /// No description provided for @otpVerif.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi OTP'**
  String get otpVerif;

  /// No description provided for @enterOtp.
  ///
  /// In id, this message translates to:
  /// **'Masukkan kode OTP yang dikirim ke:'**
  String get enterOtp;

  /// No description provided for @resendOtp.
  ///
  /// In id, this message translates to:
  /// **'Kirim Ulang'**
  String get resendOtp;

  /// No description provided for @wait.
  ///
  /// In id, this message translates to:
  /// **'Tunggu'**
  String get wait;

  /// No description provided for @nimRequired.
  ///
  /// In id, this message translates to:
  /// **'NIM tidak boleh kosong'**
  String get nimRequired;

  /// No description provided for @passRequired.
  ///
  /// In id, this message translates to:
  /// **'Password tidak boleh kosong'**
  String get passRequired;

  /// No description provided for @connError.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan koneksi'**
  String get connError;

  /// No description provided for @termsConditions.
  ///
  /// In id, this message translates to:
  /// **'Syarat dan Ketentuan'**
  String get termsConditions;

  /// No description provided for @agreeAndContinue.
  ///
  /// In id, this message translates to:
  /// **'Setuju'**
  String get agreeAndContinue;

  /// No description provided for @termsContent.
  ///
  /// In id, this message translates to:
  /// **'Dengan menggunakan aplikasi ini saya telah membaca dan menyetujui syarat dan ketentuan yang berlaku dari'**
  String get termsContent;

  /// No description provided for @pleaseWait.
  ///
  /// In id, this message translates to:
  /// **'Mohon tunggu...'**
  String get pleaseWait;

  /// No description provided for @schedule.
  ///
  /// In id, this message translates to:
  /// **'Jadwal'**
  String get schedule;

  /// No description provided for @bills.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get bills;

  /// No description provided for @presence.
  ///
  /// In id, this message translates to:
  /// **'Presensi'**
  String get presence;

  /// No description provided for @attendance.
  ///
  /// In id, this message translates to:
  /// **'Kehadiran'**
  String get attendance;

  /// No description provided for @edom.
  ///
  /// In id, this message translates to:
  /// **'EDOM'**
  String get edom;

  /// No description provided for @academicHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat IP'**
  String get academicHistory;

  /// No description provided for @offers.
  ///
  /// In id, this message translates to:
  /// **'Penawaran'**
  String get offers;

  /// No description provided for @krs.
  ///
  /// In id, this message translates to:
  /// **'KRS'**
  String get krs;

  /// No description provided for @khs.
  ///
  /// In id, this message translates to:
  /// **'KHS'**
  String get khs;

  /// No description provided for @programStudy.
  ///
  /// In id, this message translates to:
  /// **'Program Studi'**
  String get programStudy;

  /// No description provided for @faculty.
  ///
  /// In id, this message translates to:
  /// **'Fakultas'**
  String get faculty;

  /// No description provided for @rateApp.
  ///
  /// In id, this message translates to:
  /// **'Beri Rating'**
  String get rateApp;

  /// No description provided for @pembayaran.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get pembayaran;

  /// No description provided for @justNow.
  ///
  /// In id, this message translates to:
  /// **'baru saja'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In id, this message translates to:
  /// **'{count} menit yang lalu'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In id, this message translates to:
  /// **'{count} jam yang lalu'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In id, this message translates to:
  /// **'{count} hari yang lalu'**
  String daysAgo(int count);

  /// No description provided for @monthsAgo.
  ///
  /// In id, this message translates to:
  /// **'{count} bulan yang lalu'**
  String monthsAgo(int count);

  /// No description provided for @yearsAgo.
  ///
  /// In id, this message translates to:
  /// **'{count} tahun yang lalu'**
  String yearsAgo(int count);

  /// No description provided for @credit.
  ///
  /// In id, this message translates to:
  /// **'SKS'**
  String get credit;

  /// No description provided for @room.
  ///
  /// In id, this message translates to:
  /// **'Ruangan'**
  String get room;

  /// No description provided for @lecturer.
  ///
  /// In id, this message translates to:
  /// **'Dosen'**
  String get lecturer;

  /// No description provided for @today.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get today;

  /// No description provided for @noSchedule.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada jadwal kuliah'**
  String get noSchedule;

  /// No description provided for @noScheduleSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwal untuk semester ini belum tersedia atau masih dalam proses pemutakhiran'**
  String get noScheduleSubtitle;

  /// No description provided for @scheduleLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat jadwal. Tarik ke bawah untuk mencoba lagi'**
  String get scheduleLoadFailed;

  /// No description provided for @pdfScheduleTitle.
  ///
  /// In id, this message translates to:
  /// **'JADWAL KULIAH'**
  String get pdfScheduleTitle;

  /// No description provided for @pdfPrintedAt.
  ///
  /// In id, this message translates to:
  /// **'Dicetak pada:'**
  String get pdfPrintedAt;

  /// No description provided for @pdfName.
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get pdfName;

  /// No description provided for @pdfYear.
  ///
  /// In id, this message translates to:
  /// **'Tahun'**
  String get pdfYear;

  /// No description provided for @pdfCourse.
  ///
  /// In id, this message translates to:
  /// **'Mata Kuliah'**
  String get pdfCourse;

  /// No description provided for @pdfTimeRoom.
  ///
  /// In id, this message translates to:
  /// **'Waktu/Ruang'**
  String get pdfTimeRoom;

  /// No description provided for @pdfLecturer.
  ///
  /// In id, this message translates to:
  /// **'Dosen'**
  String get pdfLecturer;

  /// No description provided for @scheduleTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Kuliah'**
  String get scheduleTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In id, this message translates to:
  /// **'Pilih Bahasa'**
  String get chooseLanguage;

  /// No description provided for @indonesian.
  ///
  /// In id, this message translates to:
  /// **'Indonesia'**
  String get indonesian;

  /// No description provided for @english.
  ///
  /// In id, this message translates to:
  /// **'Inggris'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In id, this message translates to:
  /// **'Arab'**
  String get arabic;

  /// No description provided for @paymentHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pembayaran'**
  String get paymentHistory;

  /// No description provided for @tuitionFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya Kuliah'**
  String get tuitionFee;

  /// No description provided for @paymentInstructions.
  ///
  /// In id, this message translates to:
  /// **'Petunjuk Pembayaran'**
  String get paymentInstructions;

  /// No description provided for @receipt.
  ///
  /// In id, this message translates to:
  /// **'Kuitansi'**
  String get receipt;

  /// No description provided for @copySuccess.
  ///
  /// In id, this message translates to:
  /// **'Berhasil disalin'**
  String get copySuccess;

  /// No description provided for @proceed.
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get proceed;

  /// No description provided for @billLabel.
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get billLabel;

  /// No description provided for @totalBills.
  ///
  /// In id, this message translates to:
  /// **'Total Tagihan'**
  String get totalBills;

  /// No description provided for @noActiveBills.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada tagihan yang harus dibayar'**
  String get noActiveBills;

  /// No description provided for @billStatusUnpaid.
  ///
  /// In id, this message translates to:
  /// **'BELUM LUNAS'**
  String get billStatusUnpaid;

  /// No description provided for @billStatusPaid.
  ///
  /// In id, this message translates to:
  /// **'LUNAS'**
  String get billStatusPaid;

  /// No description provided for @noPaymentHistoryFound.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Pembayaran Tidak Ditemukan'**
  String get noPaymentHistoryFound;

  /// No description provided for @paymentMethod.
  ///
  /// In id, this message translates to:
  /// **'Metode Pembayaran'**
  String get paymentMethod;

  /// No description provided for @noPaymentMethods.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada metode pembayaran tersedia'**
  String get noPaymentMethods;

  /// No description provided for @paymentNumber.
  ///
  /// In id, this message translates to:
  /// **'Nomor Pembayaran'**
  String get paymentNumber;

  /// No description provided for @copy.
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get copy;

  /// No description provided for @adminFee.
  ///
  /// In id, this message translates to:
  /// **'Biaya Admin'**
  String get adminFee;

  /// No description provided for @totalPay.
  ///
  /// In id, this message translates to:
  /// **'Total Bayar'**
  String get totalPay;

  /// No description provided for @automaticVerification.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi Otomatis'**
  String get automaticVerification;

  /// No description provided for @paymentNumberCopied.
  ///
  /// In id, this message translates to:
  /// **'Nomor pembayaran berhasil disalin'**
  String get paymentNumberCopied;

  /// No description provided for @via.
  ///
  /// In id, this message translates to:
  /// **'Melalui'**
  String get via;

  /// No description provided for @downloadReceipt.
  ///
  /// In id, this message translates to:
  /// **'Unduh Kuitansi'**
  String get downloadReceipt;

  /// No description provided for @downloadingReceipt.
  ///
  /// In id, this message translates to:
  /// **'Mengunduh kuitansi... Periksa di folder Download'**
  String get downloadingReceipt;

  /// No description provided for @cantOpenReceipt.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat membuka kuitansi'**
  String get cantOpenReceipt;

  /// No description provided for @checkConnection.
  ///
  /// In id, this message translates to:
  /// **'Periksa koneksimu, Tidak dapat terhubung ke jaringan'**
  String get checkConnection;

  /// No description provided for @historyItemDetail.
  ///
  /// In id, this message translates to:
  /// **'{name} (Semester {semester})'**
  String historyItemDetail(String name, String semester);

  /// No description provided for @offersTitle.
  ///
  /// In id, this message translates to:
  /// **'Penawaran MK'**
  String get offersTitle;

  /// No description provided for @inputOfferTitle.
  ///
  /// In id, this message translates to:
  /// **'Input Penawaran Mata Kuliah'**
  String get inputOfferTitle;

  /// No description provided for @offerHistoryTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Input PMK'**
  String get offerHistoryTitle;

  /// No description provided for @semesterPackage.
  ///
  /// In id, this message translates to:
  /// **'Paket Semester'**
  String get semesterPackage;

  /// No description provided for @sksQuota.
  ///
  /// In id, this message translates to:
  /// **'Jatah SKS'**
  String get sksQuota;

  /// No description provided for @offerStartLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal mulai input PMK'**
  String get offerStartLabel;

  /// No description provided for @offerEndLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal akhir input PMK'**
  String get offerEndLabel;

  /// No description provided for @information.
  ///
  /// In id, this message translates to:
  /// **'Informasi'**
  String get information;

  /// No description provided for @noOfferings.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada penawaran mata kuliah yang tersedia'**
  String get noOfferings;

  /// No description provided for @noOfferHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat input penawaran tidak ditemukan'**
  String get noOfferHistory;

  /// No description provided for @selectedCoursesCount.
  ///
  /// In id, this message translates to:
  /// **'{count} Mata Kuliah ({sks} SKS)'**
  String selectedCoursesCount(int count, int sks);

  /// No description provided for @sksLimitExceeded.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat input PMK melebihi {sks} sks'**
  String sksLimitExceeded(int sks);

  /// No description provided for @khsYear.
  ///
  /// In id, this message translates to:
  /// **'KHS TA: {year}'**
  String khsYear(String year);

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @okButton.
  ///
  /// In id, this message translates to:
  /// **'Ok'**
  String get okButton;

  /// No description provided for @evalRequiredMessage.
  ///
  /// In id, this message translates to:
  /// **'Untuk melanjutkan silahkan lengkapi penilaian evaluasi dosen pada seluruh semester yang telah dilalui'**
  String get evalRequiredMessage;

  /// No description provided for @completeLecturerEval.
  ///
  /// In id, this message translates to:
  /// **'Isi'**
  String get completeLecturerEval;

  /// No description provided for @krsSubmenuTitle.
  ///
  /// In id, this message translates to:
  /// **'Sub Menu KRS'**
  String get krsSubmenuTitle;

  /// No description provided for @viewKrsTitle.
  ///
  /// In id, this message translates to:
  /// **'Kartu Rencana Studi'**
  String get viewKrsTitle;

  /// No description provided for @inputKrsTitle.
  ///
  /// In id, this message translates to:
  /// **'Input KRS'**
  String get inputKrsTitle;

  /// No description provided for @krsSemesterLabel.
  ///
  /// In id, this message translates to:
  /// **'KRS Semester'**
  String get krsSemesterLabel;

  /// No description provided for @approvedSksLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah SKS disetujui'**
  String get approvedSksLabel;

  /// No description provided for @krsNote.
  ///
  /// In id, this message translates to:
  /// **'Untuk melihat KRS semester sebelumnya silahkan akses menu KHS'**
  String get krsNote;

  /// No description provided for @krsInputStartLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal mulai pengisian KRS'**
  String get krsInputStartLabel;

  /// No description provided for @krsInputEndLabel.
  ///
  /// In id, this message translates to:
  /// **'Tanggal akhir pengisian KRS'**
  String get krsInputEndLabel;

  /// No description provided for @krsInputWarning.
  ///
  /// In id, this message translates to:
  /// **'KRS yang sudah di setujui oleh dosen wali tidak dapat diubah kembali!'**
  String get krsInputWarning;

  /// No description provided for @scheduleConflict.
  ///
  /// In id, this message translates to:
  /// **'Gagal, terjadi benturan jadwal dengan mata kuliah {course}'**
  String scheduleConflict(String course);

  /// No description provided for @notScheduled.
  ///
  /// In id, this message translates to:
  /// **'Tidak Dijadwalkan'**
  String get notScheduled;

  /// No description provided for @classLabel.
  ///
  /// In id, this message translates to:
  /// **'Kelas'**
  String get classLabel;

  /// No description provided for @quotaLabel.
  ///
  /// In id, this message translates to:
  /// **'Kuota'**
  String get quotaLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get remainingLabel;

  /// No description provided for @approvedBadge.
  ///
  /// In id, this message translates to:
  /// **'Disetujui'**
  String get approvedBadge;

  /// No description provided for @courseCode.
  ///
  /// In id, this message translates to:
  /// **'Kode MK'**
  String get courseCode;

  /// No description provided for @krsTotalLabel.
  ///
  /// In id, this message translates to:
  /// **'Jumlah KRS Mata Kuliah'**
  String get krsTotalLabel;

  /// No description provided for @noKrsData.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada data KRS yang tersedia'**
  String get noKrsData;

  /// No description provided for @noKrsOfferings.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada mata kuliah yang tersedia untuk input KRS'**
  String get noKrsOfferings;

  /// No description provided for @subscriptionRequiredMessage.
  ///
  /// In id, this message translates to:
  /// **'Fitur ini memerlukan langganan. Silakan berlangganan untuk dapat menggunakan fitur ini sepenuhnya'**
  String get subscriptionRequiredMessage;

  /// No description provided for @sessionExpired.
  ///
  /// In id, this message translates to:
  /// **'Sesi Anda telah berakhir, silakan login kembali'**
  String get sessionExpired;

  /// No description provided for @preparingPdf.
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan dokumen PDF...'**
  String get preparingPdf;

  /// No description provided for @cantOpenPdf.
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat membuka PDF'**
  String get cantOpenPdf;

  /// No description provided for @failedSavePdf.
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan PDF'**
  String get failedSavePdf;

  /// No description provided for @edomSemestersTitle.
  ///
  /// In id, this message translates to:
  /// **'Semester Evaluasi'**
  String get edomSemestersTitle;

  /// No description provided for @edomCoursesTitle.
  ///
  /// In id, this message translates to:
  /// **'Mata Kuliah Evaluasi'**
  String get edomCoursesTitle;

  /// No description provided for @edomStatusDone.
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get edomStatusDone;

  /// No description provided for @edomStatusProgress.
  ///
  /// In id, this message translates to:
  /// **'Proses Pengisian'**
  String get edomStatusProgress;

  /// No description provided for @edomStatusNotFilled.
  ///
  /// In id, this message translates to:
  /// **'Belum Mengisi'**
  String get edomStatusNotFilled;

  /// No description provided for @edomOpenDetail.
  ///
  /// In id, this message translates to:
  /// **'Isi / Detail Evaluasi'**
  String get edomOpenDetail;

  /// No description provided for @edomSemestersSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pilih semester untuk mengisi evaluasi dosen'**
  String get edomSemestersSubtitle;

  /// No description provided for @edomProgressSummary.
  ///
  /// In id, this message translates to:
  /// **'{done} dari {total} semester selesai'**
  String edomProgressSummary(int done, int total);

  /// No description provided for @edomSemestersEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada semester evaluasi yang tersedia'**
  String get edomSemestersEmpty;

  /// No description provided for @edomCoursesProgressSummary.
  ///
  /// In id, this message translates to:
  /// **'{done} dari {total} mata kuliah dievaluasi'**
  String edomCoursesProgressSummary(int done, int total);

  /// No description provided for @edomCoursesEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada mata kuliah evaluasi yang tersedia'**
  String get edomCoursesEmpty;

  /// No description provided for @edomHistoryButton.
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get edomHistoryButton;

  /// No description provided for @edomFillButton.
  ///
  /// In id, this message translates to:
  /// **'Isi Penilaian'**
  String get edomFillButton;

  /// No description provided for @edomFillAllQuestionsError.
  ///
  /// In id, this message translates to:
  /// **'Silahkan lengkapi jawaban pada indikator {indicator} nomor {number}'**
  String edomFillAllQuestionsError(String indicator, int number);

  /// No description provided for @edomImpressionTitle.
  ///
  /// In id, this message translates to:
  /// **'Kesan Pesan'**
  String get edomImpressionTitle;

  /// No description provided for @edomImpressionInstruction.
  ///
  /// In id, this message translates to:
  /// **'Tuliskan komentar,kesan pesan atau saran minimal 8 karakter. Nama anda tidak akan ditampilkan di dashboard dosen'**
  String get edomImpressionInstruction;

  /// No description provided for @edomImpressionMinError.
  ///
  /// In id, this message translates to:
  /// **'Kesan Pesan minimal 8 karakter'**
  String get edomImpressionMinError;

  /// No description provided for @edomSaving.
  ///
  /// In id, this message translates to:
  /// **'Menyimpan jawaban anda'**
  String get edomSaving;

  /// No description provided for @edomExitConfirmTitle.
  ///
  /// In id, this message translates to:
  /// **'Apakah anda yakin?'**
  String get edomExitConfirmTitle;

  /// No description provided for @edomExitConfirmMessage.
  ///
  /// In id, this message translates to:
  /// **'Jika anda keluar sekarang jawaban tidak akan disimpan'**
  String get edomExitConfirmMessage;

  /// No description provided for @errorResponseApi.
  ///
  /// In id, this message translates to:
  /// **'Periksa koneksimu, Tidak dapat terhubung ke server'**
  String get errorResponseApi;

  /// No description provided for @tryAgain.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get tryAgain;

  /// No description provided for @ips.
  ///
  /// In id, this message translates to:
  /// **'IP Semester'**
  String get ips;

  /// No description provided for @khsTitle.
  ///
  /// In id, this message translates to:
  /// **'KHS'**
  String get khsTitle;

  /// No description provided for @khsSemesterSks.
  ///
  /// In id, this message translates to:
  /// **'SKS Semester'**
  String get khsSemesterSks;

  /// No description provided for @khsGradeWeight.
  ///
  /// In id, this message translates to:
  /// **'Bobot Nilai'**
  String get khsGradeWeight;

  /// No description provided for @khsGradeIndex.
  ///
  /// In id, this message translates to:
  /// **'Index Nilai'**
  String get khsGradeIndex;

  /// No description provided for @khsNotFound.
  ///
  /// In id, this message translates to:
  /// **'Data KHS tidak ditemukan'**
  String get khsNotFound;

  /// No description provided for @khsPdfTitle.
  ///
  /// In id, this message translates to:
  /// **'KARTU HASIL STUDI'**
  String get khsPdfTitle;

  /// No description provided for @khsWaitUntilLoaded.
  ///
  /// In id, this message translates to:
  /// **'Tunggu sampai KHS selesai dimuat'**
  String get khsWaitUntilLoaded;

  /// No description provided for @evalNotCompletedMessage.
  ///
  /// In id, this message translates to:
  /// **'Anda belum melengkapi penilaian evaluasi dosen'**
  String get evalNotCompletedMessage;

  /// No description provided for @lastGpa.
  ///
  /// In id, this message translates to:
  /// **'IPK Terakhir'**
  String get lastGpa;

  /// No description provided for @lastIps.
  ///
  /// In id, this message translates to:
  /// **'IPS Terakhir'**
  String get lastIps;

  /// No description provided for @totalCredits.
  ///
  /// In id, this message translates to:
  /// **'Total Beban SKS'**
  String get totalCredits;

  /// No description provided for @ipkChart.
  ///
  /// In id, this message translates to:
  /// **'Grafik IPK Kumulatif'**
  String get ipkChart;

  /// No description provided for @ipsChart.
  ///
  /// In id, this message translates to:
  /// **'Grafik IP Semester (IPS)'**
  String get ipsChart;

  /// No description provided for @sksLoadChart.
  ///
  /// In id, this message translates to:
  /// **'Beban SKS Per Semester'**
  String get sksLoadChart;

  /// No description provided for @registrationHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Registrasi'**
  String get registrationHistory;

  /// No description provided for @failedLoadData.
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat data'**
  String get failedLoadData;

  /// No description provided for @loginFailed.
  ///
  /// In id, this message translates to:
  /// **'Login Gagal'**
  String get loginFailed;

  /// No description provided for @close.
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get close;

  /// No description provided for @deviceSync.
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi Perangkat'**
  String get deviceSync;

  /// No description provided for @enterNim.
  ///
  /// In id, this message translates to:
  /// **'Masukkan NIM'**
  String get enterNim;

  /// No description provided for @enterPassword.
  ///
  /// In id, this message translates to:
  /// **'Masukkan Password'**
  String get enterPassword;

  /// No description provided for @version.
  ///
  /// In id, this message translates to:
  /// **'Versi'**
  String get version;

  /// No description provided for @systemError.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan koneksi atau sistem. Silakan coba lagi nanti.'**
  String get systemError;

  /// No description provided for @pageLoadFailed.
  ///
  /// In id, this message translates to:
  /// **'Halaman tidak dapat dimuat'**
  String get pageLoadFailed;

  /// No description provided for @checkInternetConnection.
  ///
  /// In id, this message translates to:
  /// **'Periksa koneksi internet Anda kemudian coba lagi.'**
  String get checkInternetConnection;

  /// No description provided for @linkActiveEmailInstruction.
  ///
  /// In id, this message translates to:
  /// **'Tautkan email aktif Anda untuk mendapatkan kode verifikasi keamanan.'**
  String get linkActiveEmailInstruction;

  /// No description provided for @getOtpCode.
  ///
  /// In id, this message translates to:
  /// **'Dapatkan Kode OTP'**
  String get getOtpCode;

  /// No description provided for @didNotReceiveCode.
  ///
  /// In id, this message translates to:
  /// **'Tidak menerima kode?'**
  String get didNotReceiveCode;

  /// No description provided for @resendOtpFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengirim ulang kode.'**
  String get resendOtpFailed;

  /// No description provided for @verify.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi'**
  String get verify;

  /// No description provided for @otpVerifyFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memverifikasi OTP.'**
  String get otpVerifyFailed;

  /// No description provided for @success.
  ///
  /// In id, this message translates to:
  /// **'Berhasil'**
  String get success;

  /// No description provided for @enterEmail.
  ///
  /// In id, this message translates to:
  /// **'Masukkan Email'**
  String get enterEmail;

  /// No description provided for @serverConnectionFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal menghubungi server.'**
  String get serverConnectionFailed;

  /// No description provided for @passMinLength.
  ///
  /// In id, this message translates to:
  /// **'Password minimal 8 karakter'**
  String get passMinLength;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Password Baru'**
  String get confirmNewPasswordHint;

  /// No description provided for @savePassword.
  ///
  /// In id, this message translates to:
  /// **'Simpan Password'**
  String get savePassword;

  /// No description provided for @goToLoginPage.
  ///
  /// In id, this message translates to:
  /// **'Ke Halaman Login'**
  String get goToLoginPage;

  /// No description provided for @updatePasswordFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui password.'**
  String get updatePasswordFailed;

  /// No description provided for @enterNewPassword.
  ///
  /// In id, this message translates to:
  /// **'Masukkan Password Baru'**
  String get enterNewPassword;

  /// No description provided for @scanQrTitle.
  ///
  /// In id, this message translates to:
  /// **'Pindai QR Presensi'**
  String get scanQrTitle;

  /// No description provided for @scanQrInstruction.
  ///
  /// In id, this message translates to:
  /// **'Arahkan kamera ke QR Code presensi yang ditampilkan oleh dosen'**
  String get scanQrInstruction;

  /// No description provided for @flashOn.
  ///
  /// In id, this message translates to:
  /// **'Nyalakan Flash'**
  String get flashOn;

  /// No description provided for @flashOff.
  ///
  /// In id, this message translates to:
  /// **'Matikan Flash'**
  String get flashOff;

  /// No description provided for @switchCamera.
  ///
  /// In id, this message translates to:
  /// **'Ganti Kamera'**
  String get switchCamera;

  /// No description provided for @useShortCode.
  ///
  /// In id, this message translates to:
  /// **'Gunakan Short Code'**
  String get useShortCode;

  /// No description provided for @inputShortCodeHint.
  ///
  /// In id, this message translates to:
  /// **'Masukkan Kode Presensi'**
  String get inputShortCodeHint;

  /// No description provided for @shortCodeEmpty.
  ///
  /// In id, this message translates to:
  /// **'Kode presensi tidak boleh kosong'**
  String get shortCodeEmpty;

  /// No description provided for @cantScanQrQuestion.
  ///
  /// In id, this message translates to:
  /// **'Kamera bermasalah atau tidak bisa memindai?'**
  String get cantScanQrQuestion;

  /// No description provided for @presenceProcessTitle.
  ///
  /// In id, this message translates to:
  /// **'Verifikasi Presensi'**
  String get presenceProcessTitle;

  /// No description provided for @validatingPresenceCode.
  ///
  /// In id, this message translates to:
  /// **'Memvalidasi Kode Presensi...'**
  String get validatingPresenceCode;

  /// No description provided for @recordingPresence.
  ///
  /// In id, this message translates to:
  /// **'Mencatat Kehadiran...'**
  String get recordingPresence;

  /// No description provided for @presenceSuccess.
  ///
  /// In id, this message translates to:
  /// **'Presensi Berhasil!'**
  String get presenceSuccess;

  /// No description provided for @presenceAlreadyRecorded.
  ///
  /// In id, this message translates to:
  /// **'Anda sudah tercatat hadir pada perkuliahan ini.'**
  String get presenceAlreadyRecorded;

  /// No description provided for @presenceSuccessDetail.
  ///
  /// In id, this message translates to:
  /// **'Kehadiran Anda berhasil dicatat dalam sistem perkuliahan.'**
  String get presenceSuccessDetail;

  /// No description provided for @presenceFailed.
  ///
  /// In id, this message translates to:
  /// **'Presensi Gagal'**
  String get presenceFailed;

  /// No description provided for @courseInfo.
  ///
  /// In id, this message translates to:
  /// **'Informasi Perkuliahan'**
  String get courseInfo;

  /// No description provided for @meetingNumber.
  ///
  /// In id, this message translates to:
  /// **'Pertemuan ke-{number}'**
  String meetingNumber(String number);

  /// No description provided for @lectureTopic.
  ///
  /// In id, this message translates to:
  /// **'Topik Perkuliahan'**
  String get lectureTopic;

  /// No description provided for @lectureDescription.
  ///
  /// In id, this message translates to:
  /// **'Deskripsi Perkuliahan'**
  String get lectureDescription;

  /// No description provided for @time.
  ///
  /// In id, this message translates to:
  /// **'Waktu'**
  String get time;

  /// No description provided for @retryPresence.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get retryPresence;

  /// No description provided for @backToHome.
  ///
  /// In id, this message translates to:
  /// **'Kembali ke Beranda'**
  String get backToHome;

  /// No description provided for @submit.
  ///
  /// In id, this message translates to:
  /// **'Kirim'**
  String get submit;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin kamera diperlukan untuk memindai QR code presensi.'**
  String get cameraPermissionDenied;

  /// No description provided for @attendanceTitle.
  ///
  /// In id, this message translates to:
  /// **'Riwayat Kehadiran'**
  String get attendanceTitle;

  /// No description provided for @searchCourseHint.
  ///
  /// In id, this message translates to:
  /// **'Cari mata kuliah atau dosen...'**
  String get searchCourseHint;

  /// No description provided for @overallAttendanceSummary.
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Kehadiran'**
  String get overallAttendanceSummary;

  /// No description provided for @totalCourses.
  ///
  /// In id, this message translates to:
  /// **'Total Mata Kuliah'**
  String get totalCourses;

  /// No description provided for @totalMeetings.
  ///
  /// In id, this message translates to:
  /// **'Total Pertemuan'**
  String get totalMeetings;

  /// No description provided for @totalAttendance.
  ///
  /// In id, this message translates to:
  /// **'Total Kehadiran'**
  String get totalAttendance;

  /// No description provided for @attendancePercentage.
  ///
  /// In id, this message translates to:
  /// **'Persentase Kehadiran'**
  String get attendancePercentage;

  /// No description provided for @attendanceDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Rincian Kehadiran'**
  String get attendanceDetailTitle;

  /// No description provided for @meetingDetailTitle.
  ///
  /// In id, this message translates to:
  /// **'Detail Pertemuan'**
  String get meetingDetailTitle;

  /// No description provided for @present.
  ///
  /// In id, this message translates to:
  /// **'Hadir'**
  String get present;

  /// No description provided for @absent.
  ///
  /// In id, this message translates to:
  /// **'Tidak Hadir'**
  String get absent;

  /// No description provided for @lectureMaterials.
  ///
  /// In id, this message translates to:
  /// **'Materi Perkuliahan'**
  String get lectureMaterials;

  /// No description provided for @noMaterials.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada materi yang diunggah'**
  String get noMaterials;

  /// No description provided for @downloadMaterial.
  ///
  /// In id, this message translates to:
  /// **'Unduh Materi'**
  String get downloadMaterial;

  /// No description provided for @downloadingMaterial.
  ///
  /// In id, this message translates to:
  /// **'Mengunduh materi...'**
  String get downloadingMaterial;

  /// No description provided for @downloadSuccess.
  ///
  /// In id, this message translates to:
  /// **'Materi berhasil diunduh'**
  String get downloadSuccess;

  /// No description provided for @downloadFailed.
  ///
  /// In id, this message translates to:
  /// **'Gagal mengunduh materi'**
  String get downloadFailed;

  /// No description provided for @openFile.
  ///
  /// In id, this message translates to:
  /// **'Buka File'**
  String get openFile;

  /// No description provided for @noCoursesFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada mata kuliah ditemukan'**
  String get noCoursesFound;

  /// No description provided for @announcementDetail.
  ///
  /// In id, this message translates to:
  /// **'Detail Pengumuman'**
  String get announcementDetail;

  /// No description provided for @searchAnnouncementHint.
  ///
  /// In id, this message translates to:
  /// **'Cari judul pengumuman...'**
  String get searchAnnouncementHint;

  /// No description provided for @maxNewsLoaded.
  ///
  /// In id, this message translates to:
  /// **'Maksimal berita yang dapat dimuat adalah {count} Baris'**
  String maxNewsLoaded(int count);

  /// No description provided for @noAnnouncementsFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pengumuman ditemukan'**
  String get noAnnouncementsFound;

  /// No description provided for @publisher.
  ///
  /// In id, this message translates to:
  /// **'Penerbit'**
  String get publisher;

  /// No description provided for @category.
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get category;

  /// No description provided for @viewImage.
  ///
  /// In id, this message translates to:
  /// **'Lihat Gambar'**
  String get viewImage;

  /// No description provided for @openInBrowser.
  ///
  /// In id, this message translates to:
  /// **'Buka di Browser'**
  String get openInBrowser;

  /// No description provided for @facultyNews.
  ///
  /// In id, this message translates to:
  /// **'Berita Fakultas'**
  String get facultyNews;

  /// No description provided for @rectorateNews.
  ///
  /// In id, this message translates to:
  /// **'Berita Rektorat'**
  String get rectorateNews;

  /// No description provided for @newsDetail.
  ///
  /// In id, this message translates to:
  /// **'Detail Berita'**
  String get newsDetail;

  /// No description provided for @searchNewsHint.
  ///
  /// In id, this message translates to:
  /// **'Cari judul berita...'**
  String get searchNewsHint;

  /// No description provided for @noNewsFound.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada berita ditemukan'**
  String get noNewsFound;

  /// No description provided for @qiblaDirection.
  ///
  /// In id, this message translates to:
  /// **'Arah Kiblat'**
  String get qiblaDirection;

  /// No description provided for @qiblaCompass.
  ///
  /// In id, this message translates to:
  /// **'Kompas Kiblat'**
  String get qiblaCompass;

  /// No description provided for @deviceNotSupported.
  ///
  /// In id, this message translates to:
  /// **'Perangkat Tidak Mendukung'**
  String get deviceNotSupported;

  /// No description provided for @deviceNotSupportedDesc.
  ///
  /// In id, this message translates to:
  /// **'Perangkat Anda tidak memiliki sensor kompas/magnetometer yang diperlukan untuk menentukan arah kiblat.'**
  String get deviceNotSupportedDesc;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In id, this message translates to:
  /// **'Izin Lokasi Diperlukan'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionDesc.
  ///
  /// In id, this message translates to:
  /// **'Aplikasi memerlukan izin lokasi untuk menentukan arah kiblat yang akurat dari posisi Anda.'**
  String get locationPermissionDesc;

  /// No description provided for @enableLocation.
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Lokasi'**
  String get enableLocation;

  /// No description provided for @grantPermission.
  ///
  /// In id, this message translates to:
  /// **'Izinkan Akses Lokasi'**
  String get grantPermission;

  /// No description provided for @locationDisabled.
  ///
  /// In id, this message translates to:
  /// **'GPS / Lokasi Tidak Aktif'**
  String get locationDisabled;

  /// No description provided for @locationDisabledDesc.
  ///
  /// In id, this message translates to:
  /// **'Silakan aktifkan GPS atau layanan lokasi pada perangkat Anda.'**
  String get locationDisabledDesc;

  /// No description provided for @facingQibla.
  ///
  /// In id, this message translates to:
  /// **'Tepat Menghadap Kiblat'**
  String get facingQibla;

  /// No description provided for @alignWithQibla.
  ///
  /// In id, this message translates to:
  /// **'Arahkan ponsel hingga jarum sejajar dengan Ka\'bah'**
  String get alignWithQibla;

  /// No description provided for @distanceToKaaba.
  ///
  /// In id, this message translates to:
  /// **'Jarak ke Ka\'bah'**
  String get distanceToKaaba;

  /// No description provided for @qiblaAngle.
  ///
  /// In id, this message translates to:
  /// **'Arah Kiblat'**
  String get qiblaAngle;

  /// No description provided for @currentHeading.
  ///
  /// In id, this message translates to:
  /// **'Arah Saat Ini'**
  String get currentHeading;

  /// No description provided for @calibrateCompassHint.
  ///
  /// In id, this message translates to:
  /// **'Jika jarum kompas tidak akurat, kalibrasi dengan menggerakkan ponsel membentuk angka 8.'**
  String get calibrateCompassHint;

  /// No description provided for @openSettings.
  ///
  /// In id, this message translates to:
  /// **'Buka Pengaturan'**
  String get openSettings;

  /// No description provided for @prayerSchedule.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Sholat'**
  String get prayerSchedule;

  /// No description provided for @prayerTimes.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Sholat'**
  String get prayerTimes;

  /// No description provided for @fajr.
  ///
  /// In id, this message translates to:
  /// **'Subuh'**
  String get fajr;

  /// No description provided for @sunrise.
  ///
  /// In id, this message translates to:
  /// **'Terbit'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In id, this message translates to:
  /// **'Dzuhur'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In id, this message translates to:
  /// **'Ashar'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In id, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In id, this message translates to:
  /// **'Isya'**
  String get isha;

  /// No description provided for @imsak.
  ///
  /// In id, this message translates to:
  /// **'Imsak'**
  String get imsak;

  /// No description provided for @nextPrayer.
  ///
  /// In id, this message translates to:
  /// **'Sholat Berikutnya'**
  String get nextPrayer;

  /// No description provided for @inCountdown.
  ///
  /// In id, this message translates to:
  /// **'dalam'**
  String get inCountdown;

  /// No description provided for @tomorrowFajr.
  ///
  /// In id, this message translates to:
  /// **'Subuh Besok'**
  String get tomorrowFajr;

  /// No description provided for @fastingSchedule.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Puasa'**
  String get fastingSchedule;

  /// No description provided for @fastingToday.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Puasa Hari Ini'**
  String get fastingToday;

  /// No description provided for @fastingRamadhan.
  ///
  /// In id, this message translates to:
  /// **'Puasa Ramadhan'**
  String get fastingRamadhan;

  /// No description provided for @fastingMondayThursday.
  ///
  /// In id, this message translates to:
  /// **'Puasa Sunnah Senin - Kamis'**
  String get fastingMondayThursday;

  /// No description provided for @fastingAyyamulBidh.
  ///
  /// In id, this message translates to:
  /// **'Puasa Sunnah Ayyamul Bidh'**
  String get fastingAyyamulBidh;

  /// No description provided for @fastingArafah.
  ///
  /// In id, this message translates to:
  /// **'Puasa Sunnah Arafah'**
  String get fastingArafah;

  /// No description provided for @fastingAsyura.
  ///
  /// In id, this message translates to:
  /// **'Puasa Sunnah Asyura'**
  String get fastingAsyura;

  /// No description provided for @fastingTasuah.
  ///
  /// In id, this message translates to:
  /// **'Puasa Sunnah Tasu\'a'**
  String get fastingTasuah;

  /// No description provided for @breakFasting.
  ///
  /// In id, this message translates to:
  /// **'Buka Puasa'**
  String get breakFasting;

  /// No description provided for @startFasting.
  ///
  /// In id, this message translates to:
  /// **'Mulai Puasa'**
  String get startFasting;

  /// No description provided for @timeUntilIftar.
  ///
  /// In id, this message translates to:
  /// **'Menuju Buka Puasa'**
  String get timeUntilIftar;

  /// No description provided for @timeUntilImsak.
  ///
  /// In id, this message translates to:
  /// **'Menuju Imsak'**
  String get timeUntilImsak;

  /// No description provided for @showingCachedData.
  ///
  /// In id, this message translates to:
  /// **'Menampilkan data tersimpan (Offline)'**
  String get showingCachedData;

  /// No description provided for @refreshSchedule.
  ///
  /// In id, this message translates to:
  /// **'Perbarui Jadwal'**
  String get refreshSchedule;

  /// No description provided for @kemenagMethod.
  ///
  /// In id, this message translates to:
  /// **'Kementerian Agama RI'**
  String get kemenagMethod;

  /// No description provided for @prayerLocationPermissionDesc.
  ///
  /// In id, this message translates to:
  /// **'Aplikasi memerlukan izin lokasi untuk menampilkan jadwal sholat yang akurat sesuai lokasi Anda.'**
  String get prayerLocationPermissionDesc;

  /// No description provided for @prayerShortLabel.
  ///
  /// In id, this message translates to:
  /// **'Sholat'**
  String get prayerShortLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
