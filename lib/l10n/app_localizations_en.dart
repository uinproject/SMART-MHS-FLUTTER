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

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get close => 'Close';

  @override
  String get deviceSync => 'Device Synchronization';

  @override
  String get enterNim => 'Enter NIM';

  @override
  String get enterPassword => 'Enter Password';

  @override
  String get version => 'Version';

  @override
  String get systemError =>
      'A connection or system error occurred. Please try again later.';

  @override
  String get pageLoadFailed => 'Page could not be loaded';

  @override
  String get checkInternetConnection =>
      'Please check your internet connection and try again.';

  @override
  String get linkActiveEmailInstruction =>
      'Link your active email to receive a security verification code.';

  @override
  String get getOtpCode => 'Get OTP Code';

  @override
  String get didNotReceiveCode => 'Didn\'t receive the code?';

  @override
  String get resendOtpFailed => 'Failed to resend code.';

  @override
  String get verify => 'Verify';

  @override
  String get otpVerifyFailed => 'Failed to verify OTP.';

  @override
  String get success => 'Success';

  @override
  String get enterEmail => 'Enter Email';

  @override
  String get serverConnectionFailed => 'Failed to connect to server.';

  @override
  String get passMinLength => 'Password must be at least 8 characters';

  @override
  String get confirmNewPasswordHint => 'Confirm New Password';

  @override
  String get savePassword => 'Save Password';

  @override
  String get goToLoginPage => 'Go to Login Page';

  @override
  String get updatePasswordFailed => 'Failed to update password.';

  @override
  String get enterNewPassword => 'Enter New Password';

  @override
  String get scanQrTitle => 'Scan Presence QR';

  @override
  String get scanQrInstruction =>
      'Point camera at the attendance QR Code displayed by lecturer';

  @override
  String get flashOn => 'Turn on Flash';

  @override
  String get flashOff => 'Turn off Flash';

  @override
  String get switchCamera => 'Switch Camera';

  @override
  String get useShortCode => 'Use Short Code';

  @override
  String get inputShortCodeHint => 'Enter Presence Code';

  @override
  String get shortCodeEmpty => 'Presence code cannot be empty';

  @override
  String get cantScanQrQuestion => 'Camera issue or cannot scan QR?';

  @override
  String get presenceProcessTitle => 'Presence Verification';

  @override
  String get validatingPresenceCode => 'Validating Presence Code...';

  @override
  String get recordingPresence => 'Recording Attendance...';

  @override
  String get presenceSuccess => 'Attendance Successful!';

  @override
  String get presenceAlreadyRecorded =>
      'You have already been recorded present for this lecture.';

  @override
  String get presenceSuccessDetail =>
      'Your attendance has been successfully recorded in the lecture system.';

  @override
  String get presenceFailed => 'Attendance Failed';

  @override
  String get courseInfo => 'Lecture Information';

  @override
  String meetingNumber(String number) {
    return 'Meeting $number';
  }

  @override
  String get lectureTopic => 'Lecture Topic';

  @override
  String get lectureDescription => 'Lecture Description';

  @override
  String get time => 'Time';

  @override
  String get retryPresence => 'Try Again';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get submit => 'Submit';

  @override
  String get cameraPermissionDenied =>
      'Camera permission is required to scan attendance QR code.';

  @override
  String get attendanceTitle => 'Attendance History';

  @override
  String get searchCourseHint => 'Search course or lecturer...';

  @override
  String get overallAttendanceSummary => 'Attendance Summary';

  @override
  String get totalCourses => 'Total Courses';

  @override
  String get totalMeetings => 'Total Meetings';

  @override
  String get totalAttendance => 'Total Attendance';

  @override
  String get attendancePercentage => 'Attendance Percentage';

  @override
  String get attendanceDetailTitle => 'Attendance Details';

  @override
  String get meetingDetailTitle => 'Meeting Details';

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get lectureMaterials => 'Lecture Materials';

  @override
  String get noMaterials => 'No materials uploaded';

  @override
  String get downloadMaterial => 'Download Material';

  @override
  String get downloadingMaterial => 'Downloading material...';

  @override
  String get downloadSuccess => 'Material downloaded successfully';

  @override
  String get downloadFailed => 'Failed to download material';

  @override
  String get openFile => 'Open File';

  @override
  String get noCoursesFound => 'No courses found';

  @override
  String get announcementDetail => 'Announcement Detail';

  @override
  String get searchAnnouncementHint => 'Search announcement...';

  @override
  String maxNewsLoaded(int count) {
    return 'The maximum news that can be loaded is $count Lines';
  }

  @override
  String get noAnnouncementsFound => 'No announcements found';

  @override
  String get publisher => 'Publisher';

  @override
  String get category => 'Category';

  @override
  String get viewImage => 'View Image';

  @override
  String get openInBrowser => 'Open in Browser';

  @override
  String get facultyNews => 'Faculty News';

  @override
  String get rectorateNews => 'Rectorate News';

  @override
  String get newsDetail => 'News Detail';

  @override
  String get searchNewsHint => 'Search news...';

  @override
  String get noNewsFound => 'No news found';

  @override
  String get qiblaDirection => 'Qibla Direction';

  @override
  String get qiblaCompass => 'Qibla Compass';

  @override
  String get deviceNotSupported => 'Device Not Supported';

  @override
  String get deviceNotSupportedDesc =>
      'Your device does not have the compass/magnetometer sensor required to determine Qibla direction.';

  @override
  String get locationPermissionRequired => 'Location Permission Required';

  @override
  String get locationPermissionDesc =>
      'The app requires location permission to accurately determine the Qibla direction from your position.';

  @override
  String get enableLocation => 'Enable Location';

  @override
  String get grantPermission => 'Grant Location Permission';

  @override
  String get locationDisabled => 'Location Services Disabled';

  @override
  String get locationDisabledDesc =>
      'Please enable GPS or location services on your device.';

  @override
  String get facingQibla => 'Facing Qibla';

  @override
  String get alignWithQibla =>
      'Rotate device until the compass aligns with the Kaaba';

  @override
  String get distanceToKaaba => 'Distance to Kaaba';

  @override
  String get qiblaAngle => 'Qibla Direction';

  @override
  String get currentHeading => 'Current Heading';

  @override
  String get calibrateCompassHint =>
      'If the compass seems inaccurate, calibrate by moving your phone in a figure 8 motion.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get prayerSchedule => 'Prayer Times';

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get imsak => 'Imsak';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get inCountdown => 'in';

  @override
  String get tomorrowFajr => 'Tomorrow';

  @override
  String get fastingSchedule => 'Fasting Schedule';

  @override
  String get fastingToday => 'Today\'s Fasting Schedule';

  @override
  String get fastingRamadhan => 'Ramadan Fasting';

  @override
  String get fastingMondayThursday => 'Monday - Thursday Fasting';

  @override
  String get fastingAyyamulBidh => 'Ayyamul Bidh Fasting';

  @override
  String get fastingArafah => 'Arafah Fasting';

  @override
  String get fastingAsyura => 'Ashura Fasting';

  @override
  String get fastingTasuah => 'Tasu\'a Fasting';

  @override
  String get breakFasting => 'Iftar';

  @override
  String get startFasting => 'Start Fasting';

  @override
  String get timeUntilIftar => 'Time Until Iftar';

  @override
  String get timeUntilImsak => 'Time Until Imsak';

  @override
  String get showingCachedData => 'Showing saved data (Offline)';

  @override
  String get refreshSchedule => 'Refresh Schedule';

  @override
  String get kemenagMethod => 'Ministry of Religious Affairs RI';

  @override
  String get prayerLocationPermissionDesc =>
      'The app requires location permission to display accurate prayer times based on your location.';

  @override
  String get prayerShortLabel => 'Prayer';

  @override
  String get csListTitle => 'CS List';

  @override
  String get csSubtitle =>
      'We are ready to help, choose the service according to your problem..';

  @override
  String get csReadyToServe => 'Ready to Serve';

  @override
  String get csServiceClosed => 'Service Closed';

  @override
  String get csChatWa => 'Chat WhatsApp';

  @override
  String get csClosedReasonPrefix =>
      '* Maybe your message was not answered immediately because';

  @override
  String get csClosedReasonSuffix =>
      'Leave a message and we will reply during business hours.';

  @override
  String get whatsappNotFound => 'WhatsApp application not found';

  @override
  String get emptyCsList => 'No service list available yet';
}
