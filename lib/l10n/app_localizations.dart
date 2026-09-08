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

  /// No description provided for @ipHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat IP'**
  String get ipHistory;

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
  /// **'Ruang'**
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

  /// No description provided for @scheduleTitle.
  ///
  /// In id, this message translates to:
  /// **'Jadwal Kuliah'**
  String get scheduleTitle;
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
