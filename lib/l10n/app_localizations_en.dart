// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SMART Student';

  @override
  String get appDesc => 'Student Academic Information System';

  @override
  String get home => 'Home';

  @override
  String get news => 'News';

  @override
  String get notifications => 'Notifications';

  @override
  String get account => 'Account';

  @override
  String get welcome => 'Welcome';

  @override
  String get loginInstruction => 'Please log in with your SIAKAD account';

  @override
  String get login => 'Login';

  @override
  String get nim => 'NIM';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get forgotPassInstruction =>
      'Enter your NIM and Email to reset your password';

  @override
  String get email => 'Email';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Invalid email format';

  @override
  String get btnResetPassword => 'Reset Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm New Password';

  @override
  String get newPassRequired => 'New password is required';

  @override
  String get confPassRequired => 'Confirm password is required';

  @override
  String get passNotMatch => 'Passwords do not match';

  @override
  String get changePassInstruction =>
      'Please enter your new password, The new password is at least 8 characters long.';

  @override
  String get successChangePass => 'Password successfully updated';

  @override
  String get otpResetPassInstruction =>
      'Enter the OTP code sent to your registered email';

  @override
  String get resendOtpSuccess => 'OTP code successfully resent';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'My Profile';

  @override
  String get security => 'Security';

  @override
  String get help => 'Help Center';

  @override
  String get about => 'About App';

  @override
  String get ipk => 'Cumulative GPA';

  @override
  String get sks => 'Credits Earned';

  @override
  String get semester => 'Semester';

  @override
  String get status => 'Student Status';

  @override
  String get checkKrs => 'KRS Checking';

  @override
  String get examine => 'Examine';

  @override
  String get announcements => 'Announcements';

  @override
  String get showMore => 'Show More';

  @override
  String get mainMenu => 'Main Menu';

  @override
  String get showAll => 'Show All';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get ok => 'Yes';

  @override
  String get cancel => 'Cancel';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get goodNight => 'Good Night';

  @override
  String get statusActive => 'Active';

  @override
  String get statusLeave => 'Leave';

  @override
  String get statusGraduated => 'Graduated';

  @override
  String get statusNonActive => 'Not Registered';

  @override
  String get statusOut => 'Out';

  @override
  String get statusMove => 'Move';

  @override
  String get statusDeath => 'Death';

  @override
  String get emailVerif => 'Email Verification';

  @override
  String get examineLater => 'Verify Later';

  @override
  String get otpVerif => 'OTP Verification';

  @override
  String get enterOtp => 'Enter the OTP code sent to:';

  @override
  String get resendOtp => 'Resend';

  @override
  String get wait => 'Wait';

  @override
  String get nimRequired => 'NIM is required';

  @override
  String get passRequired => 'Password is required';

  @override
  String get connError => 'Connection error occurred';

  @override
  String get termsConditions => 'Terms and Conditions';

  @override
  String get agreeAndContinue => 'Agree';

  @override
  String get termsContent =>
      'By using this application I have read and agree to the applicable terms and conditions from';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get schedule => 'Schedule';

  @override
  String get bills => 'Bills';

  @override
  String get presence => 'Presence';

  @override
  String get attendance => 'Attendance';

  @override
  String get edom => 'EDOM';

  @override
  String get ipHistory => 'IP History';

  @override
  String get offers => 'Offers';

  @override
  String get krs => 'KRS';

  @override
  String get khs => 'KHS';

  @override
  String get programStudy => 'Program Study';

  @override
  String get faculty => 'Faculty';

  @override
  String get rateApp => 'Rate App';

  @override
  String get pembayaran => 'Payment';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String monthsAgo(int count) {
    return '$count months ago';
  }

  @override
  String yearsAgo(int count) {
    return '$count years ago';
  }

  @override
  String get credit => 'Credits';

  @override
  String get room => 'Room';

  @override
  String get lecturer => 'Lecturer';

  @override
  String get today => 'Today';

  @override
  String get noSchedule => 'No class schedule';

  @override
  String get scheduleTitle => 'Class Schedule';
}
