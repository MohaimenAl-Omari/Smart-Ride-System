import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LangController {
  LangController._();
  static final LangController instance = LangController._();

  static const String _kKey = 'smart_ride.language';
  static const String defaultCode = 'en';
  static const List<String> supported = ['en', 'ar'];

  final ValueNotifier<String> code = ValueNotifier<String>(defaultCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kKey);
    if (saved != null && supported.contains(saved)) {
      code.value = saved;
    }
  }

  Future<void> setLanguage(String c) async {
    if (!supported.contains(c) || c == code.value) return;
    code.value = c;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, c);
  }

  Locale get locale => Locale(code.value);
  bool get isArabic => code.value == 'ar';
}

class LangScope extends InheritedWidget {
  final String code;
  const LangScope({super.key, required this.code, required super.child});

  static String codeOf(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<LangScope>();
    return w?.code ?? LangController.defaultCode;
  }

  @override
  bool updateShouldNotify(covariant LangScope oldWidget) =>
      oldWidget.code != code;
}

class S {
  final String code;
  const S(this.code);

  static S of(BuildContext context) => S(LangScope.codeOf(context));

  bool get isAr => code == 'ar';
  String _t(String en, String ar) => isAr ? ar : en;

  // Brand
  String get appName => _t('Smart Ride', 'سمارت رايد');
  String get appTagline =>
      _t('Smart carpool · Flexible stops', 'كاربول ذكي · محطات مرنة');

  // Common
  String get ok => _t('OK', 'حسناً');
  String get cancel => _t('Cancel', 'إلغاء');
  String get confirm => _t('Confirm', 'تأكيد');
  String get keep => _t('Keep', 'الإبقاء');
  String get save => _t('Save', 'حفظ');
  String get edit => _t('Edit', 'تعديل');
  String get delete => _t('Delete', 'حذف');
  String get back => _t('Back', 'رجوع');
  String get next => _t('Next', 'التالي');
  String get loading => _t('Loading…', 'جارٍ التحميل…');
  String get failed => _t('Failed', 'فشل');
  String get retry => _t('Retry', 'إعادة المحاولة');
  String get and => _t('and', 'و');
  String get or => _t('or', 'أو');
  String get yes => _t('Yes', 'نعم');
  String get no => _t('No', 'لا');
  String get done => _t('Done', 'تم');
  String get search => _t('Search', 'بحث');
  String get justNow => _t('Just now', 'الآن');
  String get currency => _t('JD', 'د.أ');

  // Auth
  String get welcomeBack => _t('Welcome back', 'مرحبًا بعودتك');
  String get welcomeSub => _t(
      'Sign in to find a ride or post your next trip.',
      'سجّل الدخول للبحث عن رحلة أو لنشر رحلتك القادمة.');
  String get email => _t('Email address', 'البريد الإلكتروني');
  String get password => _t('Password', 'كلمة المرور');
  String get forgotPassword => _t('Forgot password?', 'نسيت كلمة المرور؟');
  String get signIn => _t('Sign in', 'تسجيل الدخول');
  String get newHere => _t('New here?  ', 'حسابك جديد؟  ');
  String get createAccount => _t('Create an account', 'أنشئ حسابًا');
  String get pleaseEnterCredentials => _t(
      'Please enter your email and password',
      'يرجى إدخال البريد الإلكتروني وكلمة المرور');
  String get invalidCredentials =>
      _t('Invalid email or password', 'بريد إلكتروني أو كلمة مرور غير صحيحة');
  String get adminWebOnly => _t('Admins must sign in via the web dashboard.',
      'يجب على المسؤولين تسجيل الدخول عبر لوحة التحكم على الويب.');
  String get resetSoon => _t(
      'Password reset will be available in the next release.',
      'إعادة تعيين كلمة المرور ستتوفر في الإصدار القادم.');

  // Signup
  String get joinSmartRide => _t('Join Smart Ride', 'انضم إلى سمارت رايد');
  String get joinSub => _t(
      'Flexible stops, fair pricing, and reliable carpools.',
      'محطات مرنة، تسعير عادل، ومشاركة موثوقة للرحلات.');
  String get fullName => _t('Full name', 'الاسم الكامل');
  String get phone => _t('Phone number', 'رقم الهاتف');
  String get iWantToJoinAs => _t('I want to join as', 'أرغب بالانضمام كـ');
  String get passenger => _t('Passenger', 'راكب');
  String get driver => _t('Driver', 'سائق');
  String get passengerCaption =>
      _t('Book rides on flexible routes', 'احجز رحلاتك على مسارات مرنة');
  String get driverCaption =>
      _t('Post trips & earn fares', 'انشر الرحلات واحصل على الأجور');
  String get driverVerification =>
      _t('Driver verification', 'توثيق السائق');
  String get driverDocsHelp => _t(
      'Upload all 3 documents. Your account stays inactive until an admin approves them.',
      'يرجى رفع جميع المستندات الثلاثة. يبقى حسابك غير مفعّل حتى يوافق عليها المسؤول.');
  String get drivingLicense => _t('Driving License', 'رخصة القيادة');
  String get nonConviction =>
      _t('Non-Conviction Certificate', 'شهادة عدم محكومية');
  String get medicalCert => _t('Medical Certificate', 'الشهادة الطبية');
  String get docHint =>
      _t('PDF, JPG or PNG · Tap to upload', 'PDF أو JPG أو PNG · اضغط للرفع');
  String get termsNote => _t(
      'By signing up you agree to our Terms of Service and Privacy Policy.',
      'بالتسجيل أنت توافق على شروط الخدمة وسياسة الخصوصية.');
  String get applicationSubmitted =>
      _t('Application submitted', 'تم إرسال الطلب');
  String get applicationSubmittedBody => _t(
      'Your driver account is under review. We\'ll notify you as soon as an admin approves your documents.',
      'حساب السائق قيد المراجعة. سنبلغك فور موافقة المسؤول على مستنداتك.');
  String get fillAllFields =>
      _t('Please fill in all fields', 'يرجى ملء جميع الحقول');
  String get driverDocsRequired => _t(
      'Drivers must upload all 3 documents',
      'يجب على السائقين رفع جميع المستندات الثلاثة');
  String get signupFailedDocs => _t(
      'Account created but document upload failed. Please contact support.',
      'تم إنشاء الحساب لكن فشل رفع المستندات. يرجى التواصل مع الدعم.');
  String get signupFailed =>
      _t('Signup failed. Try again.', 'فشل إنشاء الحساب. حاول مجددًا.');

  // Passenger home
  String greeting(String name) =>
      _t('Hi, $name 👋', 'أهلاً، $name 👋');
  String get whereToToday =>
      _t('Where are you headed today?', 'إلى أين أنت ذاهب اليوم؟');
  String get findARide => _t('Find a ride', 'ابحث عن رحلة');
  String get myBookings => _t('My bookings', 'حجوزاتي');
  String get from => _t('From', 'من');
  String get to => _t('To', 'إلى');
  String get searchTrips => _t('Search trips', 'ابحث عن رحلات');
  String tripsAvailable(int n) => isAr
      ? '$n ${n == 1 ? 'رحلة متاحة' : 'رحلات متاحة'}'
      : '$n ${n == 1 ? 'trip' : 'trips'} available';
  String get updatedJustNow => _t('Updated just now', 'تم التحديث للتو');
  String get noTripsYet => _t('No trips yet', 'لا توجد رحلات بعد');
  String get noTripsBody => _t(
      'Try a different route or check again soon — drivers post trips throughout the day.',
      'جرّب مسارًا آخر أو عُد لاحقًا — يقوم السائقون بنشر الرحلات على مدار اليوم.');
  String get upcoming => _t('Upcoming', 'القادمة');
  String get upcomingSub =>
      _t('Trips you have booked', 'الرحلات التي حجزتها');
  String get pastTrips => _t('Past trips', 'الرحلات السابقة');
  String get pastTripsSub =>
      _t('Completed or cancelled', 'مكتملة أو ملغاة');
  String get noBookingsYet => _t('No bookings yet', 'لا توجد حجوزات بعد');
  String get noBookingsBody => _t(
      'Search for a trip and book your first ride.',
      'ابحث عن رحلة واحجز أول رحلة لك.');
  String get cancelBooking => _t('Cancel booking', 'إلغاء الحجز');
  String get cancelBookingQ => _t('Cancel booking?', 'إلغاء الحجز؟');
  String get cancelBookingBody => _t(
      'Your seat will be released. If payment was held it will be refunded.',
      'سيتم تحرير مقعدك. إذا كان قد تم احتجاز الدفعة فستُستردّ.');
  String get bookingCancelled => _t('Booking cancelled', 'تم إلغاء الحجز');
  String get failedToCancel => _t('Failed to cancel', 'فشل الإلغاء');

  // Driver home
  String driverHeader(String name) =>
      _t('Driver · $name', 'السائق · $name');
  String get manageTripsSub => _t(
      'Manage your trips & passengers', 'إدارة رحلاتك وركّابك');
  String get accountUnderReview =>
      _t('Account under review', 'الحساب قيد المراجعة');
  String get accountUnderReviewBody => _t(
      'An admin is reviewing your driver documents. You\'ll be able to start posting trips as soon as you\'re approved.',
      'يقوم المسؤول بمراجعة مستندات السائق. ستتمكن من نشر الرحلات بمجرد الموافقة.');
  String get supportContact => _t(
      'Need help? Contact support@smartride.example.',
      'بحاجة لمساعدة؟ راسلنا على support@smartride.example.');
  String get scheduled => _t('Scheduled', 'مجدولة');
  String get active => _t('Active', 'نشطة');
  String get earnings => _t('Earnings', 'الأرباح');
  String get myTrips => _t('My trips', 'رحلاتي');
  String get requests => _t('Requests', 'الطلبات');
  String get newTrip => _t('New trip', 'رحلة جديدة');
  String get noTripsBodyDriver => _t(
      'Tap "New trip" to post your first carpool route. Drivers earn more by adding multiple stops.',
      'اضغط "رحلة جديدة" لنشر أول مسار لك. تزداد أرباح السائقين بإضافة محطات متعددة.');
  String get start => _t('Start', 'ابدأ');
  String get complete => _t('Complete', 'إكمال');
  String get cancelTrip => _t('Cancel', 'إلغاء');
  String get cancelTripQ => _t('Cancel trip?', 'إلغاء الرحلة؟');
  String get cancelTripBody => _t(
      'All accepted bookings will be cancelled and refunded automatically.',
      'سيتم إلغاء جميع الحجوزات المقبولة وإعادة المبالغ تلقائيًا.');
  String get noBookingRequests =>
      _t('No booking requests', 'لا توجد طلبات حجز');
  String get noBookingRequestsBody => _t(
      'When passengers book your trips, you\'ll see their requests here.',
      'عندما يحجز الركّاب رحلاتك ستظهر طلباتهم هنا.');
  String get accept => _t('Accept', 'قبول');
  String get reject => _t('Reject', 'رفض');
  String get bookingAccepted => _t('Booking accepted', 'تم قبول الحجز');
  String get bookingRejected => _t('Booking rejected', 'تم رفض الحجز');
  String get tripStarted => _t('Trip started', 'بدأت الرحلة');
  String get tripCompleted => _t('Trip completed', 'اكتملت الرحلة');
  String get tripCancelled => _t('Trip cancelled', 'تم إلغاء الرحلة');
  String get acceptFail =>
      _t('Could not accept (seats may be full)', 'تعذّر القبول (قد تكون المقاعد ممتلئة)');

  // Trip details (passenger)
  String get tripDetails => _t('Trip details', 'تفاصيل الرحلة');
  String get departure => _t('Departure', 'وقت الانطلاق');
  String get seats => _t('Seats', 'المقاعد');
  String get perSeat => _t('Per seat', 'لكل مقعد');
  String get driverNotes => _t('Driver notes', 'ملاحظات السائق');
  String get yourBooking => _t('Your booking', 'حجزك');
  String get yourBookingSub => _t(
      'Pick stops for accurate segment pricing',
      'اختر المحطات للحصول على تسعير دقيق للمقاطع');
  String get pickupAt => _t('Pickup at', 'الالتقاط من');
  String get dropoffAt => _t('Drop-off at', 'النزول عند');
  String get total => _t('Total', 'الإجمالي');
  String get confirmAndBook =>
      _t('Confirm & request booking', 'أكّد واطلب الحجز');
  String get soldOut => _t('Sold out', 'ممتلئة');
  String tripStatusLabel(String s) {
    switch (s) {
      case 'scheduled':
        return _t('Trip scheduled', 'الرحلة مجدولة');
      case 'in_progress':
        return _t('Trip in progress', 'الرحلة جارية');
      case 'completed':
        return _t('Trip completed', 'الرحلة مكتملة');
      case 'cancelled':
        return _t('Trip cancelled', 'الرحلة ملغاة');
      default:
        return _t('Trip $s', 'الرحلة $s');
    }
  }

  String get tripUnavailable =>
      _t('Trip unavailable', 'الرحلة غير متاحة');
  String get goBack => _t('Go back', 'العودة');

  // Booking details
  String get bookingDetailsTitle =>
      _t('Booking details', 'تفاصيل الحجز');
  String bookingNo(int id) => _t('Booking #$id', 'الحجز رقم $id');
  String get yourSegment => _t('Your segment', 'مقطعك');
  String get yourSegmentSub =>
      _t('Where you board and get off', 'مكان الصعود والنزول');
  String get pickup => _t('Pickup', 'الالتقاط');
  String get dropoff => _t('Drop-off', 'النزول');
  String get payment => _t('Payment', 'الدفع');
  String get paymentSub => _t(
      'Held in escrow until trip completes',
      'محتجزة كأمانة حتى اكتمال الرحلة');
  String get escrowExplain => _t(
      'Funds release to the driver only after trip completion. Refunds are automatic on cancellation or no-show.',
      'تُحرّر الأموال للسائق فقط بعد اكتمال الرحلة. الاستردادات تلقائية عند الإلغاء أو عدم الحضور.');
  String get checkInBtn =>
      _t('Check in for this trip', 'سجّل وصولك للرحلة');
  String get checkedInOk => _t(
      'Checked in. Waiting for driver to confirm minimum passengers.',
      'تم تسجيل الوصول. بانتظار تأكيد السائق للحد الأدنى من الركّاب.');
  String get checkedInBanner => _t(
      'You\'re checked in. Hold tight — the trip starts once the driver confirms minimum passengers.',
      'تم تسجيل وصولك. تستهل الرحلة بمجرد تأكيد السائق للحد الأدنى من الركّاب.');
  String get rateYourDriver =>
      _t('Rate your driver', 'قيّم السائق');
  String get rateYourDriverSub => _t(
      'Help other passengers ride with confidence',
      'ساعد الركّاب الآخرين بثقة');
  String get submitRating => _t('Submit rating', 'إرسال التقييم');
  String ratingThanks(int r) =>
      _t('Thanks for rating your driver $r/5 ⭐',
          'شكرًا لتقييم السائق $r/5 ⭐');
  String get bookingCancelledRefund =>
      _t('Booking cancelled · refund queued',
          'تم إلغاء الحجز · سيتم الاسترداد');

  // Create trip
  String get newTripTitle => _t('New trip', 'رحلة جديدة');
  String get route => _t('Route', 'المسار');
  String get routeSub =>
      _t('Origin and destination', 'الانطلاق والوجهة');
  String get origin => _t('Origin city / address', 'مدينة / عنوان الانطلاق');
  String get destination =>
      _t('Destination city / address', 'مدينة / عنوان الوجهة');
  String get stopsAlongTheWay =>
      _t('Stops along the way', 'محطات على الطريق');
  String get stopsSub => _t(
      'Add intermediate stops so passengers can join mid-route',
      'أضف محطات وسيطة ليتمكن الركّاب من الانضمام في منتصف الطريق');
  String get stopName => _t('Stop name', 'اسم المحطة');
  String get pickDateTime => _t('Pick date & time', 'اختر التاريخ والوقت');
  String get seatsAndPrice => _t('Seats & price', 'المقاعد والسعر');
  String get seatsAndPriceSub => _t(
      'Min passengers must check in for the trip to start',
      'يجب تسجيل وصول الحد الأدنى من الركّاب لبدء الرحلة');
  String get totalSeats => _t('Total seats', 'إجمالي المقاعد');
  String get minSeats => _t('Min seats', 'الحد الأدنى للمقاعد');
  String get pricePerSeat =>
      _t('Price per seat (JD)', 'السعر لكل مقعد (د.أ)');
  String get vehicle => _t('Vehicle', 'المركبة');
  String get vehicleSub => _t(
      'Optional, helps passengers find your car',
      'اختياري، يساعد الركّاب على إيجاد سيارتك');
  String get carModel =>
      _t('Car model (e.g. Toyota Camry)', 'موديل السيارة (مثلاً تويوتا كامري)');
  String get plateNumber => _t('Plate number', 'رقم اللوحة');
  String get notes => _t('Notes', 'ملاحظات');
  String get notesSub =>
      _t('Optional message to passengers', 'رسالة اختيارية للركّاب');
  String get notesHint => _t(
      'e.g. AC, women only, no luggage…',
      'مثلاً: مكيف، للنساء فقط، بدون أمتعة…');
  String get publishTrip => _t('Publish trip', 'نشر الرحلة');
  String get tripPublished => _t('Trip published', 'تم نشر الرحلة');
  String get failedCreateTrip =>
      _t('Failed to create trip', 'فشل إنشاء الرحلة');
  String get tripFormError => _t(
      'Origin, destination, seats, price and departure are required.',
      'الانطلاق والوجهة والمقاعد والسعر ووقت الانطلاق حقول مطلوبة.');
  String get seatsPriceError => _t(
      'Seats must be > 0 and price >= 0.',
      'المقاعد يجب أن تكون أكبر من 0 والسعر >= 0.');

  // Trip passengers (driver)
  String get passengers => _t('Passengers', 'الركّاب');
  String passengersOnTrip(int n) => _t(
      '$n ${n == 1 ? 'booking' : 'bookings'} on this trip',
      '$n ${n == 1 ? 'حجز' : 'حجوزات'} على هذه الرحلة');
  String get noPassengers =>
      _t('No bookings yet', 'لا توجد حجوزات بعد');
  String get noPassengersBody => _t(
      'Once passengers book this trip, they\'ll appear here.',
      'بمجرد أن يحجز الركّاب هذه الرحلة، سيظهرون هنا.');
  String get checkInProgress =>
      _t('Check-in progress', 'تقدم تسجيل الوصول');
  String checkInRatio(int now, int min) => _t(
      '$now/$min checked in', '$now/$min سجّلوا وصولهم');
  String get minReached => _t(
      'Minimum reached — you can start the trip whenever you\'re ready.',
      'تم بلوغ الحد الأدنى — يمكنك بدء الرحلة في أي وقت.');
  String minRequired(int n) => _t(
      'Trip will start once at least $n passenger${n == 1 ? '' : 's'} ${n == 1 ? 'has' : 'have'} checked in.',
      'ستبدأ الرحلة عند تسجيل وصول $n ${n == 1 ? 'راكب' : 'ركّاب'} على الأقل.');
  String get checkIn => _t('Check in', 'تسجيل الوصول');
  String checkedInPassenger(String name) => _t(
      'Checked in $name',
      'تم تسجيل وصول $name');
  String get checkedIn => _t('Checked in', 'تم تسجيل الوصول');
  String get tripStartFailed =>
      _t('Failed to start', 'فشل البدء');
  String get tripCompleteFailed =>
      _t('Failed to complete', 'فشل الإكمال');
  String get tripCancelFailed =>
      _t('Failed to cancel', 'فشل الإلغاء');

  // Profile
  String get profile => _t('Profile', 'الملف الشخصي');
  String get account => _t('Account', 'الحساب');
  String get city => _t('City', 'المدينة');
  String get role => _t('Role', 'الدور');
  String get verifiedDriver =>
      _t('Verified driver', 'سائق موثّق');
  String get docsInReview =>
      _t('Documents in review', 'المستندات قيد المراجعة');
  String get docsApprovedBody => _t(
      'Your license, non-conviction and medical certificates were approved.',
      'تمت الموافقة على رخصتك وشهادة عدم المحكومية والشهادة الطبية.');
  String get docsPendingBody => _t(
      'An admin is reviewing your uploaded documents.',
      'يقوم المسؤول بمراجعة مستنداتك المرفوعة.');
  String get docLicense => _t('License', 'الرخصة');
  String get docNonConv => _t('Non-conviction', 'عدم محكومية');
  String get docMedical => _t('Medical', 'طبية');
  String get approved => _t('Approved', 'موافق عليها');
  String get pending => _t('Pending', 'قيد الانتظار');
  String get preferences => _t('Preferences', 'التفضيلات');
  String get pushNotifications =>
      _t('Push notifications', 'إشعارات التطبيق');
  String get emailReceipts => _t('Email receipts', 'إيصالات البريد');
  String get darkMode => _t('Dark mode', 'الوضع الداكن');
  String get language => _t('Language', 'اللغة');
  String get languageEn => _t('English', 'الإنجليزية');
  String get languageAr => _t('العربية', 'العربية');
  String get support => _t('Support', 'الدعم');
  String get helpCenter => _t('Help center', 'مركز المساعدة');
  String get termsPrivacy =>
      _t('Terms & privacy', 'الشروط والخصوصية');
  String get aboutSmartRide =>
      _t('About Smart Ride', 'حول سمارت رايد');
  String get logOut => _t('Log out', 'تسجيل الخروج');
  String get signingOut => _t('Signing out…', 'جارٍ تسجيل الخروج…');
  String comingSoon(String name) =>
      _t('$name coming soon.', '$name قريبًا.');

  // Notifications
  String get notifications => _t('Notifications', 'الإشعارات');
  String get noNotifications =>
      _t('No notifications yet', 'لا توجد إشعارات بعد');
  String get noNotificationsBody => _t(
      'You\'ll see booking confirmations, refunds and trip updates here.',
      'ستظهر هنا تأكيدات الحجوزات والمستردّات وتحديثات الرحلات.');
  String get markedAllRead => _t('Marked all as read', 'تم وضع الكل كمقروء');

  // Notification feed (driver)
  String get nMinReachedTitle => _t(
      'Minimum passengers reached',
      'تم بلوغ الحد الأدنى من الركّاب');
  String get nMinReachedBody => _t(
      'Your trip Amman → Irbid hit the minimum passenger threshold and is ready to start.',
      'رحلتك عمّان → إربد بلغت الحد الأدنى من الركّاب وجاهزة للبدء.');
  String get nNewBookingTitle => _t(
      'New booking accepted', 'تم قبول حجز جديد');
  String get nNewBookingBody => _t(
      'A passenger booked 2 seats on your Zarqa → Amman trip tomorrow at 09:00.',
      'حجز راكب مقعدين على رحلتك الزرقاء → عمّان غدًا في 09:00.');
  String get nPaymentTitle =>
      _t('Payment released', 'تم تحرير الدفعة');
  String get nPaymentBody => _t(
      'Funds for last week\'s completed trip have been released to your wallet.',
      'تم تحويل أرباح الرحلة المكتملة الأسبوع الماضي إلى محفظتك.');
  String get nDocsTitle =>
      _t('Documents verified', 'تم توثيق المستندات');
  String get nDocsBody => _t(
      'Your license, non-conviction and medical certificates were approved.',
      'تمت الموافقة على رخصتك وشهادة عدم المحكومية والشهادة الطبية.');

  // Notification feed (passenger)
  String get nBookingConfirmedTitle =>
      _t('Booking confirmed', 'تم تأكيد الحجز');
  String get nBookingConfirmedBody => _t(
      'Your booking from Amman → Irbid was accepted. Check in 30 min before departure.',
      'تم قبول حجزك من عمّان → إربد. سجّل وصولك قبل 30 دقيقة من الانطلاق.');
  String get nTripStartingTitle =>
      _t('Trip starting soon', 'الرحلة ستبدأ قريبًا');
  String get nTripStartingBody => _t(
      'Your driver is on the way. Be ready at your selected pickup stop.',
      'سائقك في الطريق. كن مستعدًا عند محطة الالتقاط المختارة.');
  String get nRefundTitle =>
      _t('Refund issued', 'تم إصدار استرداد');
  String get nRefundBody => _t(
      'A previous cancellation was refunded to your wallet (3.50 JD).',
      'تم إعادة مبلغ إلغاء سابق إلى محفظتك (3.50 د.أ).');
  String get nRateTitle =>
      _t('Rate your last driver', 'قيّم سائقك الأخير');
  String get nRateBody => _t(
      'Help the community by leaving a rating for Mohammed.',
      'ساهم في المجتمع بتقييم محمد.');
  String agoMinutes(int n) => _t('${n}m ago', 'قبل ${n}د');
  String agoHours(int n) => _t('${n}h ago', 'قبل ${n}س');
  String agoDays(int n) => _t('${n}d ago', 'قبل ${n}ي');

  // ---------------------------------------------------------------
  // Edit profile
  // ---------------------------------------------------------------
  String get editProfile => _t('Edit profile', 'تعديل الملف الشخصي');
  String get editProfileSub =>
      _t('Update your personal info', 'حدّث بياناتك الشخصية');
  String get changePhoto => _t('Change photo', 'تغيير الصورة');
  String get newPassword => _t('New password', 'كلمة المرور الجديدة');
  String get newPasswordHint =>
      _t('Leave blank to keep current', 'اتركها فارغة للإبقاء على الحالية');
  String get currentPassword =>
      _t('Current password', 'كلمة المرور الحالية');
  String get currentPasswordRequired => _t(
      'Enter your current password to change it.',
      'أدخل كلمة المرور الحالية لتغييرها.');
  String get profileUpdated =>
      _t('Profile updated successfully', 'تم تحديث الملف بنجاح');
  String get pickFromGallery =>
      _t('Choose from gallery', 'اختيار من المعرض');
  String get takePhoto => _t('Take a photo', 'التقاط صورة');
  String get removePhoto => _t('Remove photo', 'إزالة الصورة');
  String get saveChanges => _t('Save changes', 'حفظ التغييرات');

  // ---------------------------------------------------------------
  // Contact us
  // ---------------------------------------------------------------
  String get contactUs => _t('Contact us', 'تواصل معنا');
  String get contactUsSub => _t(
      'We usually respond within 24 hours.',
      'عادة نرد خلال 24 ساعة.');
  String get subject => _t('Subject', 'الموضوع');
  String get message => _t('Message', 'الرسالة');
  String get sendMessage => _t('Send message', 'إرسال الرسالة');
  String get messageSent => _t(
      'Thanks! Your message has been received.',
      'شكرًا! تم استلام رسالتك.');
  String get contactValidation => _t(
      'Please fill in your email, subject and message.',
      'يرجى إدخال البريد الإلكتروني والموضوع والرسالة.');

  // ---------------------------------------------------------------
  // History (passenger / driver previous trips)
  // ---------------------------------------------------------------
  String get tripHistory => _t('Trip history', 'سجل الرحلات');
  String get previousTrips => _t('Previous trips', 'الرحلات السابقة');
  String get previousTripsSub => _t(
      'A summary of your past rides',
      'ملخص رحلاتك السابقة');
  String get noHistory => _t('No history yet', 'لا يوجد سجل بعد');
  String get noHistoryBody => _t(
      'Once you complete a trip, it\'ll appear here.',
      'بمجرد إكمال رحلة، ستظهر هنا.');
  String get passengersWord => _t('Passengers', 'الركّاب');
  String get earningsWord => _t('Earnings', 'الأرباح');
  String get driverNameLabel => _t('Driver', 'السائق');
  String get tripDate => _t('Trip date', 'تاريخ الرحلة');
  String get tripPrice => _t('Price', 'السعر');
  String get tripStatus => _t('Status', 'الحالة');

  // ---------------------------------------------------------------
  // Driver rating / reputation
  // ---------------------------------------------------------------
  String get reviews => _t('Reviews', 'التقييمات');
  String reviewsCount(int n) => _t(
      '$n review${n == 1 ? '' : 's'}',
      '$n ${n == 1 ? 'تقييم' : 'تقييمات'}');
  String get noRatingsYet =>
      _t('No ratings yet', 'لا توجد تقييمات بعد');
  String get alreadyRated =>
      _t('You\'ve already rated this trip.', 'لقد قيّمت هذه الرحلة من قبل.');
  String get reviewOptional =>
      _t('Write a short review (optional)', 'اكتب مراجعة قصيرة (اختياري)');

  // Status badges (also used by StatusBadge in constant.dart for dynamic codes)
  String statusLabel(String s) {
    switch (s) {
      case 'pending':
        return _t('Pending', 'قيد الانتظار');
      case 'accepted':
        return _t('Accepted', 'مقبول');
      case 'rejected':
        return _t('Rejected', 'مرفوض');
      case 'cancelled':
        return _t('Cancelled', 'ملغى');
      case 'completed':
        return _t('Completed', 'مكتمل');
      case 'scheduled':
        return _t('Scheduled', 'مجدول');
      case 'in_progress':
        return _t('In progress', 'قيد التنفيذ');
      case 'checked_in':
        return _t('Checked in', 'تم تسجيل الوصول');
      case 'no_show':
        return _t('No show', 'لم يحضر');
      case 'refunded':
        return _t('Refunded', 'مستردّ');
      default:
        return s;
    }
  }

  // ---------------------------------------------------------------
  // Notifications (enhanced)
  // ---------------------------------------------------------------
  String get allNotifs => _t('All', 'الكل');
  String get unreadNotifs => _t('Unread', 'غير مقروء');
  String get clearAll => _t('Clear all', 'مسح الكل');
  String get clearedAll => _t('All notifications cleared', 'تم مسح جميع الإشعارات');
  String get nTripCompletedTitle => _t('Trip completed', 'اكتملت الرحلة');
  String get nTripCompletedBody => _t(
      'Your trip Amman → Irbid was completed. Thank you for riding with us!',
      'اكتملت رحلتك عمّان → إربد. شكراً لاستخدامك سمارت رايد!');
  String get nCancelledTitle => _t('Booking cancelled', 'تم إلغاء الحجز');
  String get nCancelledBody => _t(
      'A passenger cancelled their booking on your trip. Their seat is now available.',
      'ألغى راكب حجزه على رحلتك. المقعد متاح الآن.');
  String get nWalletCreditTitle => _t('Wallet credited', 'تم شحن المحفظة');
  String get nWalletCreditBody => _t(
      '12.50 JD was added to your wallet for the completed Zarqa → Amman trip.',
      'تمت إضافة 12.50 د.أ إلى محفظتك لرحلة الزرقاء → عمّان المكتملة.');
  String get nCheckinTitle => _t('Passenger checked in', 'سجّل راكب وصوله');
  String get nCheckinBody => _t(
      'A passenger checked in for your trip at Tabarbour stop.',
      'سجّل راكب وصوله لرحلتك عند محطة تبربور.');
  String get nPromoTitle => _t('Special offer', 'عرض خاص');
  String get nPromoBody => _t(
      'Ride 3 times this week and get 20% off your next booking!',
      'اركب 3 مرات هذا الأسبوع واحصل على خصم 20% على حجزك القادم!');
  String get nTripReminderTitle => _t('Trip tomorrow', 'رحلة غداً');
  String get nTripReminderBody => _t(
      'Don\'t forget: your trip Amman → Zarqa departs at 08:00 tomorrow.',
      'لا تنسَ: رحلتك عمّان → الزرقاء تنطلق في 08:00 غداً.');

  // Notification category chip labels
  String get nCatBooking => _t('Booking', 'حجز');
  String get nCatTrip => _t('Trip', 'رحلة');
  String get nCatPayment => _t('Payment', 'دفع');
  String get nCatPromo => _t('Offer', 'عرض');
  String get nCatSystem => _t('System', 'نظام');

  // ---------------------------------------------------------------
  // Payment simulation
  // ---------------------------------------------------------------
  String get paymentTitle => _t('Complete payment', 'إتمام الدفع');
  String get paymentMethod => _t('Payment method', 'طريقة الدفع');
  String get payByCash => _t('Pay by cash', 'الدفع نقداً');
  String get payByCard => _t('Pay by card', 'الدفع ببطاقة');
  String get payByWallet => _t('Smart Ride wallet', 'محفظة سمارت رايد');
  String get cashCaption => _t('Pay the driver directly on board', 'ادفع للسائق مباشرة في السيارة');
  String get cardCaption => _t('Visa / Mastercard — secure encrypted', 'فيزا / ماستركارد — مشفّر وآمن');
  String get walletCaption => _t('Use your Smart Ride wallet balance', 'استخدم رصيد محفظتك');
  String get cardNumber => _t('Card number', 'رقم البطاقة');
  String get cardHolder => _t('Cardholder name', 'اسم حامل البطاقة');
  String get expiryDate => _t('Expiry (MM/YY)', 'تاريخ الانتهاء (شهر/سنة)');
  String get cvv => _t('CVV', 'رمز الأمان');
  String get walletBalance => _t('Wallet balance', 'رصيد المحفظة');
  String get insufficientBalance => _t('Insufficient balance', 'رصيد غير كافٍ');
  String get payNow => _t('Pay now', 'ادفع الآن');
  String get processing => _t('Processing payment…', 'جارٍ معالجة الدفع…');
  String get paymentSuccess => _t('Payment successful!', 'تم الدفع بنجاح!');
  String get paymentSuccessBody => _t(
      'Your booking is confirmed. Have a great trip!',
      'تم تأكيد حجزك. رحلة موفّقة!');
  String get paymentFailed => _t('Payment failed', 'فشل الدفع');
  String get paymentFailedBody => _t(
      'Something went wrong. Please try again or use a different method.',
      'حدث خطأ ما. يرجى المحاولة مجدداً أو استخدام طريقة دفع مختلفة.');
  String get tryAgain => _t('Try again', 'حاول مجدداً');
  String get orderSummary => _t('Order summary', 'ملخص الطلب');
  String get totalAmount => _t('Total amount', 'المبلغ الإجمالي');
  String get securedBy => _t('Secured by Smart Ride Pay', 'مؤمَّن بواسطة سمارت رايد باي');
  String get proceedToPayment => _t('Proceed to payment', 'المتابعة للدفع');
  String get cashInstructions => _t(
      'Pay the driver in cash when you board. Keep your booking confirmation ready.',
      'ادفع للسائق نقداً عند الركوب. احتفظ بتأكيد الحجز جاهزاً.');
  String get fillCardDetails => _t('Please fill in all card details', 'يرجى ملء جميع بيانات البطاقة');

  // Payment processing step labels
  String get payStep1 => _t('Connecting to payment gateway…', 'الاتصال ببوابة الدفع…');
  String get payStep2 => _t('Verifying payment details…', 'التحقق من بيانات الدفع…');
  String get payStep3 => _t('Securing transaction…', 'تأمين المعاملة…');
  String get payStep4 => _t('Confirming booking…', 'تأكيد الحجز…');
  String get paySimMode => _t('Simulation mode — demo card loaded', 'وضع المحاكاة — بطاقة تجريبية محملة');
  String get paySimCard => _t(
      'Card: 4242 4242 4242 4242  ·  Exp: 12/28  ·  CVV: 123',
      'البطاقة: 4242 4242 4242 4242 · الانتهاء: 12/28 · CVV: 123');
  String get greatThanks => _t('Great, thanks!', 'رائع، شكراً!');

  // ---------------------------------------------------------------
  // Privacy Policy
  // ---------------------------------------------------------------
  String get privacyPolicy => _t('Privacy Policy', 'سياسة الخصوصية');
  String get privacyLastUpdated => _t('Last updated: May 2026', 'آخر تحديث: مايو 2026');
  String get privacyIntroTitle => _t('Your privacy matters', 'خصوصيتك تهمنا');
  String get privacyIntroBody => _t(
      'Smart Ride is committed to protecting your personal information. This policy explains what we collect, why we collect it, and how we keep it safe.',
      'تلتزم سمارت رايد بحماية معلوماتك الشخصية. توضّح هذه السياسة ما نجمعه، ولماذا نجمعه، وكيف نحافظ عليه.');
  String get privacyCollectTitle => _t('What we collect', 'ما نجمعه');
  String get privacyCollectBody => _t(
      'We collect your name, phone, email, and location data necessary to match you with rides. Driver accounts additionally require identity and vehicle documents for verification.',
      'نجمع اسمك ورقم هاتفك وبريدك الإلكتروني وبيانات الموقع اللازمة لمطابقتك مع الرحلات. تتطلب حسابات السائقين أيضاً مستندات هوية للتحقق.');
  String get privacyUseTitle => _t('How we use it', 'كيف نستخدمه');
  String get privacyUseBody => _t(
      'Your data is used solely to operate the Smart Ride service: booking trips, processing payments, providing support, and improving safety. We never sell your data to third parties.',
      'تُستخدم بياناتك حصراً لتشغيل خدمة سمارت رايد: حجز الرحلات، معالجة المدفوعات، تقديم الدعم، وتحسين السلامة. لا نبيع بياناتك لأي طرف ثالث.');
  String get privacySharingTitle => _t('Data sharing', 'مشاركة البيانات');
  String get privacySharingBody => _t(
      'Limited trip details (pickup stop, seat count) are shared between matched drivers and passengers. Payment processing is handled by encrypted, PCI-compliant systems.',
      'يتم مشاركة تفاصيل الرحلة المحدودة (محطة الصعود، عدد المقاعد) بين السائقين والركّاب المطابقين. تتم معالجة الدفع عبر أنظمة مشفّرة متوافقة مع معايير PCI.');
  String get privacyRetentionTitle => _t('Data retention', 'الاحتفاظ بالبيانات');
  String get privacyRetentionBody => _t(
      'Trip and payment records are retained for 2 years for regulatory compliance. You may request deletion of your account and data at any time through the contact form.',
      'يتم الاحتفاظ بسجلات الرحلات والمدفوعات لمدة عامين للامتثال التنظيمي. يمكنك طلب حذف حسابك وبياناتك في أي وقت من خلال نموذج التواصل.');
  String get privacyRightsTitle => _t('Your rights', 'حقوقك');
  String get privacyRightsBody => _t(
      'You have the right to access, correct, or delete your personal data. Contact us at privacy@smartride.jo and we\'ll respond within 30 days.',
      'يحق لك الوصول إلى بياناتك الشخصية أو تصحيحها أو حذفها. تواصل معنا على privacy@smartride.jo وسنردّ خلال 30 يوماً.');
  String get privacySecurityTitle => _t('Security', 'الأمان');
  String get privacySecurityBody => _t(
      'All data is encrypted in transit (TLS 1.3) and at rest. We conduct regular security audits and our servers are hosted in ISO 27001-certified data centres.',
      'جميع البيانات مشفّرة أثناء النقل (TLS 1.3) وأثناء التخزين. نجري عمليات تدقيق أمني منتظمة وخوادمنا مستضافة في مراكز بيانات معتمدة بمعيار ISO 27001.');
  String get privacyContactUs => _t('Questions? Contact us', 'لأسئلتك، تواصل معنا');

  // ---------------------------------------------------------------
  // About Us
  // ---------------------------------------------------------------
  String get aboutUs => _t('About Smart Ride', 'حول سمارت رايد');
  String get aboutTagline => _t(
      'Smarter carpooling for Jordan\'s roads.',
      'كاربول أذكى لطرق الأردن.');
  String get aboutMissionTitle => _t('Our mission', 'مهمتنا');
  String get aboutMissionBody => _t(
      'Smart Ride was founded to make daily commuting across Jordanian cities affordable, flexible, and community-driven. We believe every seat in every car should count.',
      'تأسّست سمارت رايد لجعل التنقل اليومي عبر المدن الأردنية ميسور التكلفة ومرناً وقائماً على المجتمع. نؤمن بأن كل مقعد في كل سيارة يجب أن يكون ذا قيمة.');
  String get aboutHowTitle => _t('How it works', 'كيف يعمل');
  String get aboutHowBody => _t(
      'Drivers post trips with flexible stops. Passengers book individual segments — only the stops they need. Fares are split fairly, payments are held securely until the trip completes.',
      'ينشر السائقون رحلات بمحطات مرنة. يحجز الركّاب مقاطع فردية — المحطات التي يحتاجونها فقط. تُوزَّع الأجور بعدالة، وتُحتجز المدفوعات بأمان حتى اكتمال الرحلة.');
  String get aboutTeamTitle => _t('The team', 'الفريق');
  String get aboutTeamBody => _t(
      'We are a team of engineers and designers based in Amman, Jordan, passionate about sustainable urban mobility and building technology that serves real people.',
      'نحن فريق من المهندسين والمصممين مقرّه عمّان، الأردن، شغوف بالتنقل الحضري المستدام وبناء تقنية تخدم الناس الحقيقيين.');
  String get aboutVersionTitle => _t('Version', 'الإصدار');
  String get aboutVersionBody => _t(
      'Smart Ride v1.0 — built with Flutter & Laravel.',
      'سمارت رايد v1.0 — مبني باستخدام Flutter و Laravel.');
  String get aboutContactTitle => _t('Contact', 'تواصل');
  String get aboutContactBody => _t(
      'support@smartride.jo\n+962 6 000 0000\nAmman, Jordan',
      'support@smartride.jo\n+962 6 000 0000\nعمّان، الأردن');
  String get aboutSocial => _t('Follow us', 'تابعنا');
  String get aboutStats1 => _t('10,000+\nPassengers', '+10,000\nراكب');
  String get aboutStats2 => _t('2,500+\nDrivers', '+2,500\nسائق');
  String get aboutStats3 => _t('50,000+\nTrips', '+50,000\nرحلة');

  // ---------------------------------------------------------------
  // Trip details — partial-route price notice
  // ---------------------------------------------------------------
  String get priceAtCheckout =>
      _t('Exact price at checkout', 'السعر الدقيق عند الدفع');
  String get priceAtCheckoutSub =>
      _t('Shown in booking summary →', 'يظهر في ملخص الحجز →');

  // ---------------------------------------------------------------
  // Create trip — segment prices section
  // ---------------------------------------------------------------
  String get segmentPrices => _t('Segment Prices', 'أسعار المقاطع');
  String get segmentPricesSub => _t(
      'Enter the price from the start to each stop. '
      'Example: A→B = 3 JD, A→C = 6 JD means the full trip costs 6 JD '
      'and a passenger riding only A→B pays 3 JD.',
      'أدخل السعر من البداية إلى كل محطة. مثال: أ→ب = 3 د.أ، أ→ج = 6 د.أ '
      'يعني أن الرحلة الكاملة تكلف 6 د.أ وراكب يركب فقط أ→ب يدفع 3 د.أ.');
  String get segPriceFirstLeg => _t('Price for this leg', 'سعر هذا الجزء');
  String segPriceTotalFrom(String prevJd) =>
      _t('Total from start (> $prevJd)', 'الإجمالي من البداية (> $prevJd)');
  String segPriceGtZero(String label) => _t(
      'Enter a price greater than 0 for: $label',
      'أدخل سعراً أكبر من 0 لـ: $label');
  String segPriceMustBeHigher(
          String label, String prevLabel, String prevPrice) =>
      _t(
          '$label price must be higher than $prevLabel ($prevPrice JD)',
          'سعر $label يجب أن يكون أعلى من $prevLabel ($prevPrice د.أ)');

  // ---------------------------------------------------------------
  // Segment booking screen
  // ---------------------------------------------------------------
  String get confirmBooking => _t('Confirm Booking', 'تأكيد الحجز');
  String get yourRoute => _t('Your Route', 'مسارك');
  String get yourRouteSub =>
      _t('Segment breakdown and seat availability.', 'تفاصيل المقاطع وتوفر المقاعد.');
  String get yourPickupAddress => _t('Your Pickup Address', 'عنوان الالتقاط');
  String get yourPickupAddressSub =>
      _t('Tell the driver exactly where to find you.', 'أخبر السائق بالضبط أين تتواجد.');
  String get locationArea => _t('Area / Neighborhood', 'المنطقة / الحي');
  String get areaRequired => _t('Area is required', 'المنطقة مطلوبة');
  String get streetName => _t('Street Name', 'اسم الشارع');
  String get buildingNumber => _t('Building Number', 'رقم المبنى');
  String get noSegmentsAvailable =>
      _t('No segments available', 'لا توجد مقاطع متاحة');
  String get noSegmentsAvailableSub => _t(
      'The driver has not set up segments for this trip yet.',
      'لم يقم السائق بإعداد مقاطع لهذه الرحلة بعد.');
  String get routeNotFound => _t('Route not found', 'المسار غير موجود');
  String get routeNotFoundSub => _t(
      'Could not match your selected stops to trip segments.',
      'تعذّر مطابقة محطاتك المختارة مع مقاطع الرحلة.');
  String get noSegmentsForRoute =>
      _t('No segments found for this route', 'لا توجد مقاطع لهذا المسار');
  String get enterPickupArea =>
      _t('Enter your pickup area to continue', 'أدخل منطقة الالتقاط للمتابعة');
  String get outstandingDebt => _t('+ Outstanding debt', '+ ديون مستحقة');
  String get grandTotal => _t('Grand Total', 'المجموع الكلي');
  String get tripCost => _t('Trip cost', 'تكلفة الرحلة');

  // ---------------------------------------------------------------
  // About screen (graduation project version)
  // ---------------------------------------------------------------
  String get aboutAppTitle => _t('About the App', 'حول التطبيق');
  String get aboutAppBody => _t(
      'Smart Ride is a modern carpooling platform built to connect passengers '
      'with trusted drivers across Jordan. Whether you\'re commuting between '
      'cities or just need a reliable ride, Smart Ride makes shared '
      'transportation simple, affordable, and safe.',
      'سمارت رايد منصة كاربول حديثة مبنية لربط الركّاب بسائقين موثوقين في '
      'جميع أنحاء الأردن. سواء كنت تتنقل بين المدن أو تحتاج إلى رحلة موثوقة، '
      'تجعل سمارت رايد وسائل النقل المشترك بسيطة وميسورة وآمنة.');
  String get aboutKeyFeatures => _t('Key Features', 'المميزات الرئيسية');
  String get aboutFeat1Title => _t('Multi-Stop Trips', 'رحلات متعددة المحطات');
  String get aboutFeat1Body =>
      _t('Book segments of any trip between any two stops.',
          'احجز مقاطع أي رحلة بين أي محطتين.');
  String get aboutFeat2Title => _t('Precise Pickup', 'الالتقاط الدقيق');
  String get aboutFeat2Body =>
      _t('Share your exact street and building for easy pickup.',
          'شارك شارعك ومبناك بالضبط لسهولة الالتقاط.');
  String get aboutFeat3Title => _t('Flexible Payments', 'مدفوعات مرنة');
  String get aboutFeat3Body =>
      _t('Pay by cash, card, or your in-app wallet.',
          'ادفع نقداً أو ببطاقة أو بمحفظتك داخل التطبيق.');
  String get aboutFeat4Title => _t('Live Notifications', 'إشعارات فورية');
  String get aboutFeat4Body => _t(
      'Instant push alerts for bookings, acceptance, and cancellations.',
      'تنبيهات فورية للحجوزات والقبول والإلغاء.');
  String get aboutFeat5Title => _t('Verified Drivers', 'سائقون موثّقون');
  String get aboutFeat5Body => _t(
      'All drivers are reviewed and approved by the admin team.',
      'جميع السائقين مراجَعون ومعتمَدون من قِبَل فريق الإدارة.');
  String get aboutDevTeam => _t('Development Team', 'فريق التطوير');
  String get aboutGradProjectBody => _t(
      'Smart Ride was designed and developed as part of a graduation project, '
      'combining a Flutter mobile app with a Laravel-powered backend to deliver '
      'a full-stack carpooling solution.',
      'صُمِّمت سمارت رايد وطُوِّرت كجزء من مشروع تخرج، تجمع بين تطبيق '
      'Flutter للهاتف المحمول وخادم مبني على Laravel لتقديم حل متكامل للكاربول.');
  String get aboutDevRole =>
      _t('Mobile & Backend Development', 'تطوير التطبيق والخادم');
  String get aboutDevName => _t('Smart Ride Dev Team', 'فريق سمارت رايد');
  String get aboutProjectType => _t('Project Type', 'نوع المشروع');
  String get aboutProjectTypeName =>
      _t('Graduation Project', 'مشروع التخرج');
  String get aboutPlatformType => _t('Platform', 'المنصة');
  String get aboutVersionDisplay => _t('Version 1.0.0', 'الإصدار 1.0.0');
  String aboutCopyright(int year) => _t(
      '© $year Smart Ride. All rights reserved.',
      '© $year سمارت رايد. جميع الحقوق محفوظة.');
}
