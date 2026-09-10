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
  String get showLess => 'Show Less';

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
  String get academicHistory => 'Academic History';

  @override
  String get offers => 'Course Offers';

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
  String get noScheduleSubtitle =>
      'The schedule for this semester is not yet available or is still being updated';

  @override
  String get scheduleLoadFailed =>
      'Failed to load the schedule. Swipe down to try again';

  @override
  String get pdfScheduleTitle => 'CLASS SCHEDULE';

  @override
  String get pdfPrintedAt => 'Printed on:';

  @override
  String get pdfName => 'Name';

  @override
  String get pdfYear => 'Year';

  @override
  String get pdfCourse => 'Course';

  @override
  String get pdfTimeRoom => 'Time/Room';

  @override
  String get pdfLecturer => 'Lecturer';

  @override
  String get scheduleTitle => 'Class Schedule';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get indonesian => 'Indonesian';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get tuitionFee => 'Tuition Fee';

  @override
  String get paymentInstructions => 'Payment Instructions';

  @override
  String get receipt => 'Receipt';

  @override
  String get copySuccess => 'Copied successfully';

  @override
  String get proceed => 'Proceed';

  @override
  String get billLabel => 'Bill';

  @override
  String get totalBills => 'Total Bills';

  @override
  String get noActiveBills => 'There are no bills to pay';

  @override
  String get billStatusUnpaid => 'UNPAID';

  @override
  String get billStatusPaid => 'PAID';

  @override
  String get noPaymentHistoryFound => 'Payment History Not Found';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get noPaymentMethods => 'No payment methods available';

  @override
  String get paymentNumber => 'Payment Number';

  @override
  String get copy => 'Copy';

  @override
  String get adminFee => 'Admin fee';

  @override
  String get totalPay => 'Total Payment';

  @override
  String get automaticVerification => 'Automatic Verification';

  @override
  String get paymentNumberCopied => 'Payment number successfully copied';

  @override
  String get via => 'Via';

  @override
  String get downloadReceipt => 'Download Receipt';

  @override
  String get downloadingReceipt =>
      'Downloading receipt... Check the Download folder';

  @override
  String get cantOpenReceipt => 'Cannot open receipt';

  @override
  String get checkConnection =>
      'Check your connection, Unable connect to network';

  @override
  String historyItemDetail(String name, String semester) {
    return '$name (Semester $semester)';
  }

  @override
  String get offersTitle => 'Course Offers';

  @override
  String get inputOfferTitle => 'Enter Course Offers';

  @override
  String get offerHistoryTitle => 'Course Offers Entry History';

  @override
  String get semesterPackage => 'Semester Package';

  @override
  String get sksQuota => 'Credits Quota';

  @override
  String get offerStartLabel => 'Start date input course offer';

  @override
  String get offerEndLabel => 'End date input course offer';

  @override
  String get information => 'Information';

  @override
  String get noOfferings => 'No course offerings available';

  @override
  String get noOfferHistory => 'Offer input history not found';

  @override
  String selectedCoursesCount(int count, int sks) {
    return '$count Courses ($sks Credits)';
  }

  @override
  String sksLimitExceeded(int sks) {
    return 'Cannot enter Course Offers exceeding $sks credits';
  }

  @override
  String khsYear(String year) {
    return 'Academic Year: $year';
  }

  @override
  String get save => 'Save';

  @override
  String get okButton => 'Ok';

  @override
  String get evalRequiredMessage =>
      'To continue, please complete the lecturer evaluation assessment for all semesters that have passed';

  @override
  String get completeLecturerEval => 'Complete';

  @override
  String get krsSubmenuTitle => 'CSS Sub Menu';

  @override
  String get viewKrsTitle => 'Course Selection Sheet';

  @override
  String get inputKrsTitle => 'Entry CSS';

  @override
  String get krsSemesterLabel => 'CSS Semester';

  @override
  String get approvedSksLabel => 'Approved Credits';

  @override
  String get krsNote =>
      'To view the previous semester CSS, please access the Study Result menu';

  @override
  String get krsInputStartLabel => 'Start date input CSS';

  @override
  String get krsInputEndLabel => 'End date input CSS';

  @override
  String get krsInputWarning =>
      'CSS that has been approved by the guardian lecturer cannot be changed again!';

  @override
  String scheduleConflict(String course) {
    return 'Failed, there was a schedule conflict with the $course courses';
  }

  @override
  String get notScheduled => 'Not Scheduled';

  @override
  String get classLabel => 'Class';

  @override
  String get quotaLabel => 'Quota';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String get approvedBadge => 'Approved';

  @override
  String get courseCode => 'Course Code';

  @override
  String get krsTotalLabel => 'Total KRS Courses';

  @override
  String get noKrsData => 'No CSS data available';

  @override
  String get noKrsOfferings => 'No courses available for CSS entry';

  @override
  String get subscriptionRequiredMessage =>
      'This feature requires a subscription. Please subscribe to fully use this feature';

  @override
  String get sessionExpired => 'Your session has expired, please log in again';

  @override
  String get preparingPdf => 'Preparing PDF document...';

  @override
  String get cantOpenPdf => 'Cannot open the PDF';

  @override
  String get failedSavePdf => 'Failed to save the PDF';

  @override
  String get edomSemestersTitle => 'Semester Evaluation';

  @override
  String get edomCoursesTitle => 'Evaluation Course';

  @override
  String get edomStatusDone => 'Finish';

  @override
  String get edomStatusProgress => 'Filling Process';

  @override
  String get edomStatusNotFilled => 'Not Completed';

  @override
  String get edomOpenDetail => 'Form filling / Evaluation Details';

  @override
  String get edomSemestersSubtitle =>
      'Select a semester to fill in the lecturer evaluation';

  @override
  String edomProgressSummary(int done, int total) {
    return '$done of $total semesters completed';
  }

  @override
  String get edomSemestersEmpty => 'No evaluation semesters available';

  @override
  String edomCoursesProgressSummary(int done, int total) {
    return '$done of $total courses evaluated';
  }

  @override
  String get edomCoursesEmpty => 'No evaluation courses available';

  @override
  String get edomHistoryButton => 'History';

  @override
  String get edomFillButton => 'Rating';

  @override
  String edomFillAllQuestionsError(String indicator, int number) {
    return 'Please complete the answers in indicator $indicator number $number';
  }

  @override
  String get edomImpressionTitle => 'Impression';

  @override
  String get edomImpressionInstruction =>
      'Write comments, impressions, messages or suggestions of at least 8 characters. Your name will not be displayed on the lecturer dashboard';

  @override
  String get edomImpressionMinError => 'Impression of at least 8 characters';

  @override
  String get edomSaving => 'Save your answer';

  @override
  String get edomExitConfirmTitle => 'Are you sure?';

  @override
  String get edomExitConfirmMessage =>
      'If you exit now the answer will not be saved';

  @override
  String get errorResponseApi =>
      'Check your connection, Unable connect to server';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get ips => 'GPA Semester';

  @override
  String get khsTitle => 'Study Result';

  @override
  String get khsSemesterSks => 'Credits Course Semester';

  @override
  String get khsGradeWeight => 'Value';

  @override
  String get khsGradeIndex => 'Grade Index';

  @override
  String get khsNotFound => 'Study Result Not Found';

  @override
  String get khsPdfTitle => 'STUDY RESULT';

  @override
  String get khsWaitUntilLoaded => 'Wait until the KHS has finished loading';

  @override
  String get evalNotCompletedMessage =>
      'You have not completed the lecturer evaluation assessment.';

  @override
  String get lastGpa => 'Last GPA';

  @override
  String get lastIps => 'Last Semester GPA';

  @override
  String get totalCredits => 'Total Credits Load';

  @override
  String get ipkChart => 'Cumulative GPA Chart';

  @override
  String get ipsChart => 'Semester GPA Chart (IPS)';

  @override
  String get sksLoadChart => 'Credits Load Per Semester';

  @override
  String get registrationHistory => 'Registration History';

  @override
  String get failedLoadData => 'Failed to load data';
}
