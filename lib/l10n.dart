/// Lightweight English / Urdu translations.
///
/// Every user-facing string is written in English in the code and wrapped in
/// [tr]. When Urdu is selected, [tr] looks the English text up in [_ur].
/// Placeholders `{0}`, `{1}` are filled from [args].
library;

String appLanguage = 'en';

bool get isUrdu => appLanguage == 'ur';

String tr(String en, [List<Object?> args = const []]) {
  var s = isUrdu ? (_ur[en] ?? en) : en;
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i]}');
  }
  return s;
}

const Map<String, String> _ur = {
  // Navigation
  'Home': 'ہوم',
  'Movies': 'فلمیں',
  'Cinemas': 'سنیما',
  'Tickets': 'ٹکٹس',
  'Profile': 'پروفائل',

  // Home
  'Now Showing': 'ابھی چل رہی ہیں',
  'Coming Soon': 'جلد آ رہی ہیں',
  'See all': 'سب دیکھیں',
  'Offers & Deals': 'آفرز اور ڈیلز',
  'What\'s your mood?': 'آج آپ کا موڈ کیا ہے؟',
  'Good morning': 'صبح بخیر',
  'Good afternoon': 'دوپہر بخیر',
  'Good evening': 'شام بخیر',
  'Book Tickets': 'ٹکٹ بک کریں',
  'Pick your favourite cinema': 'اپنا پسندیدہ سنیما چنیں',
  'See its showtimes first, every time':
      'اس کے شو ٹائمز ہمیشہ سب سے پہلے دیکھیں',
  'Your cinema • {0}': 'آپ کا سنیما • {0}',
  'Choose': 'چنیں',
  'Showtimes': 'شو ٹائمز',
  'Your next show starts {0}': 'آپ کا اگلا شو {0} شروع ہو گا',
  'in {0} min': '{0} منٹ میں',
  'in {0}h {1}m': '{0} گھنٹے {1} منٹ میں',
  'Releasing {0}': 'ریلیز: {0}',
  'Remind me': 'مجھے یاد دلائیں',
  'Reminder set': 'یاد دہانی لگ گئی',
  'Reminder removed': 'یاد دہانی ہٹا دی گئی',
  'We\'ll remind you when bookings open for {0}':
      '{0} کی بکنگ کھلتے ہی ہم آپ کو بتا دیں گے',
  'Code {0} copied — apply it at checkout':
      'کوڈ {0} کاپی ہو گیا — چیک آؤٹ پر لگائیں',
  'Nothing for this mood right now — new releases land every Friday!':
      'اس موڈ کے لیے ابھی کچھ نہیں — نئی فلمیں ہر جمعہ آتی ہیں!',

  // Moods and genres
  'Laugh': 'ہنسی',
  'Thrill': 'سنسنی',
  'Scare': 'ڈر',
  'Love': 'محبت',
  'Epic': 'شاندار',
  'Feels': 'جذبات',
  'All': 'سب',
  'Action': 'ایکشن',
  'Adventure': 'ایڈونچر',
  'Sci-Fi': 'سائنس فکشن',
  'Fantasy': 'فینٹسی',
  'Comedy': 'کامیڈی',
  'Family': 'فیملی',
  'Romance': 'رومانس',
  'Thriller': 'تھرلر',
  'Survival': 'سروائیول',
  'Horror': 'ہارر',
  'Mystery': 'پراسرار',
  'Drama': 'ڈرامہ',
  'History': 'تاریخی',

  // Languages
  'English': 'انگریزی',
  'Urdu': 'اردو',
  'Punjabi': 'پنجابی',

  // Offers
  'Tuesday Treat': 'منگل اسپیشل',
  '25% off all tickets every Tuesday': 'ہر منگل تمام ٹکٹوں پر 25٪ رعایت',
  'Student Pass': 'اسٹوڈنٹ پاس',
  '15% off with valid student ID': 'اسٹوڈنٹ کارڈ پر 15٪ رعایت',
  'First Booking': 'پہلی بکنگ',
  '10% off your first app booking': 'ایپ سے پہلی بکنگ پر 10٪ رعایت',

  // Movies
  'Search movies, actors, languages': 'فلم، اداکار یا زبان تلاش کریں',
  'No movies match your search.': 'آپ کی تلاش سے کوئی فلم نہیں ملی۔',
  'Director': 'ہدایت کار',
  'Cast': 'کاسٹ',
  'Watch trailer': 'ٹریلر دیکھیں',
  'Showing in {0}': '{0} میں چل رہی ہے',
  'Change city': 'شہر بدلیں',
  'All cinemas': 'تمام سنیما',
  'No shows left for this date here.\nTry another day or cinema.':
      'اس تاریخ کو یہاں کوئی شو باقی نہیں۔\nکوئی اور دن یا سنیما آزمائیں۔',
  'Add to watchlist': 'واچ لسٹ میں شامل کریں',
  'Remove from watchlist': 'واچ لسٹ سے ہٹائیں',
  'Bookings open closer to release. Get notified first.':
      'بکنگ ریلیز کے قریب کھلے گی۔ سب سے پہلے اطلاع پائیں۔',
  'days to go': 'دن باقی',
  '{0} • ends {1}': '{0} • ختم {1}',
  'Late night • {0}': 'رات گئے • {0}',
  'Almost full': 'تقریباً فل',
  'Filling fast': 'تیزی سے بھر رہا ہے',
  'Available': 'دستیاب',
  'Today': 'آج',
  'Tmrw': 'کل',

  // Seats
  'SCREEN THIS WAY': 'اسکرین اس طرف',
  'Standard': 'اسٹینڈرڈ',
  'Gold': 'گولڈ',
  'Platinum Recliner': 'پلاٹینم ریکلائنر',
  'Select up to 10 seats\nPinch to zoom':
      'زیادہ سے زیادہ 10 سیٹیں چنیں\nزوم کے لیے چٹکی سے کھینچیں',
  'Continue': 'آگے بڑھیں',
  '{0} seat: {1}': '{0} سیٹ: {1}',
  '{0} seats: {1}': '{0} سیٹیں: {1}',
  'You can book up to {0} seats at a time.':
      'آپ ایک وقت میں زیادہ سے زیادہ {0} سیٹیں بک کر سکتے ہیں۔',
  'Pick best available seats for me': 'میرے لیے بہترین سیٹیں چنیں',
  'How many seats?': 'کتنی سیٹیں؟',
  'We\'ll find the best seats together, centred with a great view.':
      'ہم آپ کے لیے ساتھ ساتھ بہترین سیٹیں ڈھونڈیں گے، درمیان میں اور بہترین نظارے کے ساتھ۔',
  'Sorry, {0} seats together aren\'t available. Try fewer seats.':
      'معذرت، {0} سیٹیں ساتھ ساتھ دستیاب نہیں۔ کم سیٹیں آزمائیں۔',
  'View from seat {0}': 'سیٹ {0} سے نظارہ',
  'Very close to the screen': 'اسکرین کے بہت قریب',
  'Perfect view': 'بہترین نظارہ',
  'Good view': 'اچھا نظارہ',
  'Approximate preview': 'اندازاً منظر',
  'Selected': 'منتخب',
  'Sold': 'بک شدہ',
  'Recliner': 'ریکلائنر',
  'Seat hold expired': 'سیٹوں کا وقت ختم ہو گیا',
  'Your seats were held for 8 minutes. Please pick your seats again — you have not been charged.':
      'آپ کی سیٹیں 8 منٹ کے لیے روکی گئی تھیں۔ براہ کرم دوبارہ سیٹیں چنیں — آپ سے کوئی رقم نہیں لی گئی۔',
  'Choose seats': 'سیٹیں چنیں',
  'Online booking for this show has closed.':
      'اس شو کی آن لائن بکنگ بند ہو چکی ہے۔',

  // Snacks
  'Add snacks': 'اسنیکس شامل کریں',
  'Pre-order and skip the queue — collect at the counter by showing your ticket QR.':
      'پہلے سے آرڈر کریں اور لائن سے بچیں — کاؤنٹر پر ٹکٹ کا QR دکھا کر وصول کریں۔',
  'Add': 'شامل کریں',
  'Skip': 'چھوڑیں',
  '{0} ticket': '{0} ٹکٹ',
  '{0} tickets': '{0} ٹکٹ',
  '{0} ticket + {1} snacks': '{0} ٹکٹ + {1} اسنیکس',
  '{0} tickets + {1} snacks': '{0} ٹکٹ + {1} اسنیکس',
  'Combos': 'کومبو',
  'Popcorn': 'پاپ کارن',
  'Snacks': 'اسنیکس',
  'Drinks': 'مشروبات',
  'Solo Combo': 'سولو کومبو',
  'Couple Combo': 'کپل کومبو',
  'Family Combo': 'فیملی کومبو',
  'Salted Popcorn': 'نمکین پاپ کارن',
  'Caramel Popcorn': 'کیریمل پاپ کارن',
  'Cheese Popcorn': 'چیز پاپ کارن',
  'Loaded Nachos': 'لوڈڈ ناچوز',
  'Fries': 'فرائز',
  'Soft Drink': 'کولڈ ڈرنک',
  'Mineral Water': 'منرل واٹر',
  'Regular popcorn + regular drink': 'ریگولر پاپ کارن + ریگولر ڈرنک',
  'Large popcorn + 2 regular drinks': 'لارج پاپ کارن + 2 ریگولر ڈرنکس',
  '2 large popcorn + nachos + 4 drinks': '2 لارج پاپ کارن + ناچوز + 4 ڈرنکس',
  'Large, freshly popped': 'لارج، تازہ',
  'Large, sweet & crunchy': 'لارج، میٹھا اور کرنچی',
  'Large, loaded with cheese': 'لارج، چیز سے بھرپور',
  'With cheese sauce & jalapeños': 'چیز ساس اور ہالاپینو کے ساتھ',
  'Crispy, lightly salted': 'کرسپی، ہلکا نمکین',
  'Regular, chilled': 'ریگولر، ٹھنڈا',
  '500 ml': '500 ملی لیٹر',

  // Checkout
  'Checkout': 'چیک آؤٹ',
  'Your details': 'آپ کی تفصیلات',
  'Full name': 'پورا نام',
  'Mobile number': 'موبائل نمبر',
  'Email (optional, for e-ticket copy)':
      'ای میل (اختیاری، ای ٹکٹ کی کاپی کے لیے)',
  'Please enter your name': 'براہ کرم اپنا نام لکھیں',
  'Enter a valid mobile number, e.g. 03001234567':
      'درست موبائل نمبر لکھیں، مثلاً 03001234567',
  'Enter a valid email': 'درست ای میل لکھیں',
  'Promo code': 'پرومو کوڈ',
  'e.g. MOVIEBOX10': 'مثلاً MOVIEBOX10',
  'Apply': 'لگائیں',
  '{0} applied: {1}% off tickets 🎉': '{0} لگ گیا: ٹکٹوں پر {1}٪ رعایت 🎉',
  'This code is not valid': 'یہ کوڈ درست نہیں',
  'TUESDAY25 is valid for Tuesday shows only':
      'TUESDAY25 صرف منگل کے شوز کے لیے ہے',
  'Payment method': 'ادائیگی کا طریقہ',
  'Debit / Credit Card': 'ڈیبٹ / کریڈٹ کارڈ',
  'Visa, Mastercard, UnionPay, PayPak': 'ویزا، ماسٹر کارڈ، یونین پے، پے پاک',
  'JazzCash': 'جاز کیش',
  'Pay from your JazzCash wallet': 'اپنے جاز کیش والٹ سے ادائیگی',
  'Easypaisa': 'ایزی پیسہ',
  'Pay from your Easypaisa wallet': 'اپنے ایزی پیسہ والٹ سے ادائیگی',
  'Raast / SadaPay / NayaPay': 'راست / صدا پے / نیا پے',
  'Instant bank transfer via Raast ID': 'راست آئی ڈی سے فوری بینک ٹرانسفر',
  '{0} account number': '{0} اکاؤنٹ نمبر',
  'Raast ID (mobile number)': 'راست آئی ڈی (موبائل نمبر)',
  'Card number': 'کارڈ نمبر',
  'Expiry': 'میعاد',
  'Enter a valid card number': 'درست کارڈ نمبر لکھیں',
  'Invalid month': 'غلط مہینہ',
  'Card expired': 'کارڈ کی میعاد ختم',
  'Invalid CVV': 'غلط CVV',
  'Price details': 'قیمت کی تفصیل',
  'Tickets ({0})': 'ٹکٹ ({0})',
  'Snacks ({0})': 'اسنیکس ({0})',
  'Convenience fee': 'سروس فیس',
  'Discount ({0})': 'رعایت ({0})',
  'Total payable': 'کل رقم',
  'You\'ll earn {0} MovieBox Rewards points':
      'آپ کو {0} مووی باکس ریوارڈز پوائنٹس ملیں گے',
  'Secure payment. Free cancellation up to 2 hours before the show, refunded to your original payment method.':
      'محفوظ ادائیگی۔ شو سے 2 گھنٹے پہلے تک مفت منسوخی، رقم اسی طریقے سے واپس۔',
  'Total': 'کل',
  'Pay now': 'ابھی ادا کریں',
  'Please check the highlighted fields.': 'براہ کرم نشان زدہ خانے درست کریں۔',
  'Processing {0} payment…': '{0} سے ادائیگی ہو رہی ہے…',
  'Please don\'t close the app.': 'براہ کرم ایپ بند نہ کریں۔',
  'Payment not completed': 'ادائیگی مکمل نہیں ہوئی',
  'We could not reach the payment server.': 'پیمنٹ سرور سے رابطہ نہیں ہو سکا۔',
  'No money has been taken. If your bank shows a deduction, it is reversed automatically within 3–5 working days. Retrying will never charge you twice for this booking.':
      'آپ سے کوئی رقم نہیں لی گئی۔ اگر بینک میں کٹوتی نظر آئے تو وہ 3 سے 5 کاروباری دنوں میں خود بخود واپس ہو جائے گی۔ دوبارہ کوشش پر آپ سے دو بار رقم کبھی نہیں لی جائے گی۔',
  'Close': 'بند کریں',
  'Try again': 'دوبارہ کوشش کریں',
  'Seats: {0}': 'سیٹیں: {0}',
  'Payment successful': 'ادائیگی کامیاب',

  // Booking success
  'Booking confirmed!': 'بکنگ کنفرم ہو گئی!',
  'Your ticket is saved in the Tickets tab and works offline. Show the QR code at the entrance.':
      'آپ کا ٹکٹ ٹکٹس ٹیب میں محفوظ ہے اور بغیر انٹرنیٹ بھی کھلتا ہے۔ داخلے پر QR کوڈ دکھائیں۔',
  ' MovieBox Rewards points': ' مووی باکس ریوارڈز پوائنٹس',
  'Share with friends on WhatsApp': 'دوستوں کو واٹس ایپ پر بھیجیں',
  'Back to home': 'ہوم پر واپس',
  'My tickets': 'میرے ٹکٹ',
  'Ticket not found': 'ٹکٹ نہیں ملا',

  // Tickets
  'My Tickets': 'میرے ٹکٹ',
  'Upcoming': 'آنے والے',
  'Past & Cancelled': 'پرانے اور منسوخ',
  'No upcoming shows yet.\nYour next movie night is a tap away!':
      'ابھی کوئی آنے والا شو نہیں۔\nاگلی مووی نائٹ بس ایک ٹیپ دور ہے!',
  'Your past bookings will appear here.': 'آپ کی پرانی بکنگز یہاں نظر آئیں گی۔',
  'Browse movies': 'فلمیں دیکھیں',
  'Cancelled • Refunded': 'منسوخ • رقم واپس',
  'Confirmed': 'کنفرم',
  'Watched': 'دیکھ لی',
  '{0} • Seats {1}': '{0} • سیٹیں {1}',
  'Seats': 'سیٹیں',
  'Hall': 'ہال',
  'Booking ID': 'بکنگ آئی ڈی',
  'Paid': 'ادا شدہ',
  '{0} via {1}': '{0} بذریعہ {1}',
  'Tap to enlarge': 'بڑا کرنے کے لیے ٹیپ کریں',
  'CANCELLED • {0} refunded to {1}': 'منسوخ • {0} {1} میں واپس',
  '{0} • {1} • Seats {2}': '{0} • {1} • سیٹیں {2}',
  'Show this code at the entrance.\nTip: turn your screen brightness up for faster scanning.':
      'داخلے پر یہ کوڈ دکھائیں۔\nمشورہ: جلد اسکین کے لیے اسکرین کی روشنی بڑھا دیں۔',
  'Cancel this booking?': 'یہ بکنگ منسوخ کریں؟',
  '{0} will be refunded to your {1} within 3–5 working days.':
      '{0} آپ کے {1} میں 3 سے 5 کاروباری دنوں میں واپس آ جائیں گے۔',
  'Keep booking': 'بکنگ رکھیں',
  'Cancel booking': 'بکنگ منسوخ کریں',
  'Booking cancelled. Refund of {0} initiated.':
      'بکنگ منسوخ ہو گئی۔ {0} کی واپسی شروع ہو گئی۔',
  'Your ticket': 'آپ کا ٹکٹ',
  'SHOWTIME IN': 'شو شروع ہونے میں',
  'Please arrive by {0}': 'براہ کرم {0} تک پہنچ جائیں',
  'Doors open 15 minutes before the show. The movie starts exactly at {0}.':
      'دروازے شو سے 15 منٹ پہلے کھلتے ہیں۔ فلم ٹھیک {0} پر شروع ہو گی۔',
  'Ends around {0}': 'تقریباً {0} پر ختم',
  'Plan your ride home in advance.': 'گھر واپسی کا انتظام پہلے سے کر لیں۔',
  'Call cinema': 'سنیما کو کال کریں',
  'Directions': 'راستہ',
  'Share & split with friends': 'دوستوں کے ساتھ شیئر اور تقسیم کریں',
  'Share on WhatsApp': 'واٹس ایپ پر شیئر کریں',
  'Cancel booking & get refund': 'بکنگ منسوخ کریں اور رقم واپس لیں',
  'Cancellation closes 2 hours before the show.':
      'منسوخی شو سے 2 گھنٹے پہلے بند ہو جاتی ہے۔',
  'Showtime! Enjoy the movie 🍿': 'شو ٹائم! فلم کا مزہ لیں 🍿',
  'days': 'دن',
  'hrs': 'گھنٹے',
  'min': 'منٹ',
  'sec': 'سیکنڈ',

  // Cinemas
  'Call': 'کال',
  '{0} screens': '{0} اسکرینز',
  'Set as my cinema': 'میرا سنیما بنائیں',
  'Your cinema': 'آپ کا سنیما',
  'No more shows on this date.\nTry another day.':
      'اس تاریخ کو مزید شو نہیں۔\nکوئی اور دن آزمائیں۔',
  'Dolby Sound': 'ڈولبی ساؤنڈ',
  'Food Court': 'فوڈ کورٹ',
  'Parking': 'پارکنگ',
  'Platinum Recliners': 'پلاٹینم ریکلائنرز',
  'Wheelchair Access': 'وہیل چیئر رسائی',
  'Select your city': 'اپنا شہر چنیں',
  '{0} cinema(s)': '{0} سنیما',
  'Your cinema in {0}': '{0} میں آپ کا سنیما',

  // Profile & settings
  'Guest': 'مہمان',
  'Sign in to save your details for faster checkout':
      'جلد چیک آؤٹ کے لیے سائن ان کریں',
  'Sign in': 'سائن ان',
  'Edit profile': 'پروفائل میں ترمیم',
  'Bookings': 'بکنگز',
  'Watchlist': 'واچ لسٹ',
  'Preferences': 'ترجیحات',
  'City': 'شہر',
  'Favourite cinema': 'پسندیدہ سنیما',
  'Not set': 'منتخب نہیں',
  'Notifications': 'نوٹیفکیشنز',
  'Show reminders & new releases': 'شو کی یاد دہانی اور نئی فلمیں',
  'Support': 'مدد',
  'Help & support': 'مدد اور سپورٹ',
  'Sign out': 'سائن آؤٹ',
  'Sign out?': 'سائن آؤٹ کریں؟',
  'Your tickets stay saved on this phone.':
      'آپ کے ٹکٹ اسی فون میں محفوظ رہیں گے۔',
  'Cancel': 'منسوخ',
  'Version {0}': 'ورژن {0}',
  'Language': 'زبان',
  'Appearance': 'تھیم',
  'System': 'فون کے مطابق',
  'Dark': 'ڈارک',
  'Light': 'لائٹ',
  'Choose language': 'زبان منتخب کریں',
  'Choose appearance': 'تھیم منتخب کریں',
  'Follow phone setting': 'فون کی سیٹنگ کے مطابق',
  'App insights': 'ایپ انسائٹس',
  'For the cinema team (demo)': 'سینما ٹیم کے لیے (ڈیمو)',
  'My Watchlist': 'میری واچ لسٹ',
  'Tap the heart on any movie to save it here for later.':
      'کسی بھی فلم پر دل کا نشان دبائیں اور اسے یہاں محفوظ کریں۔',

  // Sign in
  'Verify your number': 'اپنا نمبر تصدیق کریں',
  'We\'ll text you a one-time code. No password needed.':
      'ہم آپ کو ایک کوڈ SMS کریں گے۔ پاس ورڈ کی ضرورت نہیں۔',
  'Enter the 4-digit code sent to {0}':
      '{0} پر بھیجا گیا 4 ہندسوں کا کوڈ لکھیں',
  'Used for your tickets and receipts.': 'آپ کے ٹکٹ اور رسید کے لیے۔',
  'Demo code: {0}': 'ڈیمو کوڈ: {0}',
  'Change number / resend code': 'نمبر بدلیں / کوڈ دوبارہ بھیجیں',
  'Email (optional)': 'ای میل (اختیاری)',
  'Send code': 'کوڈ بھیجیں',
  'Verify': 'تصدیق کریں',
  'Save': 'محفوظ کریں',
  'Incorrect code. Please try again.': 'غلط کوڈ۔ دوبارہ کوشش کریں۔',
  'Please enter a valid email': 'درست ای میل لکھیں',
  'Profile updated': 'پروفائل اپ ڈیٹ ہو گئی',
  'Welcome, {0}!': 'خوش آمدید، {0}!',

  // Help
  'We\'re here to help': 'ہم مدد کے لیے حاضر ہیں',
  'Report a problem and get a reference number. Our team responds within 24 hours.':
      'مسئلہ رپورٹ کریں اور ریفرنس نمبر حاصل کریں۔ ہماری ٹیم 24 گھنٹوں میں جواب دیتی ہے۔',
  'Report a problem': 'مسئلہ رپورٹ کریں',
  'Frequently asked questions': 'اکثر پوچھے جانے والے سوالات',
  'Call your cinema': 'اپنے سنیما کو کال کریں',
  'Payment deducted, no ticket': 'رقم کٹ گئی، ٹکٹ نہیں ملا',
  'Refund status': 'رقم واپسی کی صورتحال',
  'Wrong show time / seats': 'غلط شو ٹائم / سیٹیں',
  'App not working': 'ایپ کام نہیں کر رہی',
  'Other': 'دیگر',
  'Topic': 'موضوع',
  'Related booking': 'متعلقہ بکنگ',
  'None': 'کوئی نہیں',
  'Tell us what happened…': 'بتائیں کیا ہوا…',
  'Please describe the problem (at least 10 characters)':
      'براہ کرم مسئلہ بیان کریں (کم از کم 10 حروف)',
  'Submit': 'جمع کرائیں',
  'Complaint logged. Reference: {0}. We\'ll get back within 24 hours.':
      'شکایت درج ہو گئی۔ ریفرنس: {0}۔ ہم 24 گھنٹوں میں رابطہ کریں گے۔',
  'Money was deducted but I didn\'t get a ticket':
      'رقم کٹ گئی لیکن ٹکٹ نہیں ملا',
  'Your booking is only confirmed after payment succeeds, and every booking has a unique reference so you are never charged twice. If money was deducted without a ticket, it is automatically reversed within 3–5 working days. You can also report it below with your transaction details.':
      'آپ کی بکنگ صرف کامیاب ادائیگی کے بعد کنفرم ہوتی ہے، اور ہر بکنگ کا الگ ریفرنس ہوتا ہے اس لیے آپ سے دو بار رقم کبھی نہیں لی جاتی۔ اگر ٹکٹ کے بغیر رقم کٹ جائے تو 3 سے 5 کاروباری دنوں میں خود بخود واپس ہو جاتی ہے۔ آپ نیچے ٹرانزیکشن کی تفصیل کے ساتھ رپورٹ بھی کر سکتے ہیں۔',
  'How do I cancel a booking?': 'بکنگ کیسے منسوخ کروں؟',
  'Open the ticket in the Tickets tab and tap "Cancel booking". Cancellation is free up to 2 hours before the show and the full amount is refunded to your original payment method.':
      'ٹکٹس ٹیب میں ٹکٹ کھولیں اور "بکنگ منسوخ کریں" دبائیں۔ شو سے 2 گھنٹے پہلے تک منسوخی مفت ہے اور پوری رقم اسی طریقے سے واپس آتی ہے جس سے ادا کی تھی۔',
  'Do I need to print my ticket?': 'کیا ٹکٹ پرنٹ کرنا ضروری ہے؟',
  'No. Show the QR code in the app at the entrance. Tickets are stored on your phone and open even without internet.':
      'نہیں۔ داخلے پر ایپ میں QR کوڈ دکھائیں۔ ٹکٹ آپ کے فون میں محفوظ رہتے ہیں اور بغیر انٹرنیٹ بھی کھلتے ہیں۔',
  'Why can\'t I book a show that is about to start?':
      'شروع ہونے والے شو کی بکنگ کیوں نہیں ہو رہی؟',
  'Online booking closes 10 minutes before each show so you are never sold a ticket for a movie that has already started. You can still buy at the box office.':
      'ہر شو سے 10 منٹ پہلے آن لائن بکنگ بند ہو جاتی ہے تاکہ آپ کو کبھی شروع ہو چکی فلم کا ٹکٹ نہ ملے۔ باکس آفس سے ٹکٹ پھر بھی لیا جا سکتا ہے۔',
  'What does "Late night" mean on a showtime?':
      'شو ٹائم پر "رات گئے" کا کیا مطلب ہے؟',
  'Late-night shows start after midnight. For example, a Friday late-night 12:30 AM show actually starts in the early hours of Saturday. The app shows the exact day on the chip.':
      'رات گئے والے شو آدھی رات کے بعد شروع ہوتے ہیں۔ مثلاً جمعہ رات 12:30 کا شو دراصل ہفتے کی صبح شروع ہوتا ہے۔ ایپ شو ٹائم پر صحیح دن دکھاتی ہے۔',
  'Which payment methods are accepted?': 'کون سے ادائیگی کے طریقے قبول ہیں؟',
  'Debit/credit cards (Visa, Mastercard, UnionPay, PayPak), JazzCash, Easypaisa and Raast (SadaPay, NayaPay and bank apps).':
      'ڈیبٹ/کریڈٹ کارڈ (ویزا، ماسٹر کارڈ، یونین پے، پے پاک)، جاز کیش، ایزی پیسہ اور راست (صدا پے، نیا پے اور بینک ایپس)۔',
  'Are 3D glasses included?': 'کیا 3D چشمے شامل ہیں؟',
  'Yes, 3D glasses are provided at the cinema for all 3D shows.':
      'جی ہاں، تمام 3D شوز کے لیے سنیما میں 3D چشمے دیے جاتے ہیں۔',

  // Onboarding
  'Pakistan\'s cinema, in your pocket': 'پاکستان کا سنیما، آپ کی جیب میں',
  'Every movie, on the big screen': 'ہر فلم، بڑی اسکرین پر',
  'Browse what\'s showing across Pakistan with exact show times — no surprises at the door.':
      'پورے پاکستان میں چلنے والی فلمیں درست شو ٹائمز کے ساتھ دیکھیں — دروازے پر کوئی سرپرائز نہیں۔',
  'Pick your perfect seat': 'اپنی پسندیدہ سیٹ چنیں',
  'Live seat map with a preview of your view. Or let us pick the best seats for your group.':
      'لائیو سیٹ میپ اور آپ کی سیٹ سے نظارے کی جھلک۔ یا اپنے گروپ کے لیے بہترین سیٹیں ہم پر چھوڑ دیں۔',
  'Tickets that always work': 'ٹکٹ جو ہمیشہ کام کرے',
  'Pay with card, JazzCash or Easypaisa. Earn rewards on every booking. Your QR ticket works offline.':
      'کارڈ، جاز کیش یا ایزی پیسہ سے ادائیگی کریں۔ ہر بکنگ پر ریوارڈز پائیں۔ آپ کا QR ٹکٹ بغیر انٹرنیٹ بھی چلتا ہے۔',
  'Where do you watch?': 'آپ کہاں فلم دیکھتے ہیں؟',
  'We\'ll show you showtimes near you. You can change this anytime.':
      'ہم آپ کے قریب کے شو ٹائمز دکھائیں گے۔ آپ اسے کبھی بھی بدل سکتے ہیں۔',
  'Favourite cinema (optional)': 'پسندیدہ سنیما (اختیاری)',
  'Next': 'اگلا',
  'Start exploring': 'شروع کریں',

  // Rewards
  'MovieBox Rewards': 'مووی باکس ریوارڈز',
  '{0} member': '{0} ممبر',
  'Silver': 'سلور',
  'Platinum': 'پلاٹینم',
  'Top tier reached — enjoy your perks!':
      'سب سے اونچا درجہ حاصل — اپنے فائدے اٹھائیں!',
  '{0} points to {1} • Tap to see perks':
      '{1} تک {0} پوائنٹس • فائدے دیکھنے کے لیے ٹیپ کریں',
  'Earn 1 point for every Rs. 100 you spend on tickets and snacks in the app.':
      'ایپ میں ٹکٹ اور اسنیکس پر ہر 100 روپے خرچ کرنے پر 1 پوائنٹ پائیں۔',
  'Your tier': 'آپ کا درجہ',
  'from {0} pts': '{0} پوائنٹس سے',
  'pts': 'پوائنٹس',
  '1 point for every Rs. 100 spent': 'ہر 100 روپے پر 1 پوائنٹ',
  'Free regular popcorn in your birthday month':
      'سالگرہ کے مہینے میں مفت ریگولر پاپ کارن',
  'Everything in Silver': 'سلور کی تمام سہولیات',
  '10% off all snacks': 'تمام اسنیکس پر 10٪ رعایت',
  'Early access to blockbuster bookings': 'بڑی فلموں کی بکنگ تک جلد رسائی',
  'Everything in Gold': 'گولڈ کی تمام سہولیات',
  'One free recliner upgrade every month': 'ہر مہینے ایک مفت ریکلائنر اپ گریڈ',
  'Priority support line': 'ترجیحی سپورٹ لائن',

  // Common
  'Could not open. Please try again.': 'نہیں کھل سکا۔ دوبارہ کوشش کریں۔',
  'Something went wrong. Check your connection.':
      'کچھ غلط ہو گیا۔ اپنا انٹرنیٹ چیک کریں۔',
  'Nothing here yet': 'ابھی یہاں کچھ نہیں',

  // Notifications
  '🎬 {0} starts in 1 hour': '🎬 {0} ایک گھنٹے میں شروع',
  '{0} • {1} • Seats {2}. Doors open 15 min early.':
      '{0} • {1} • سیٹیں {2}۔ دروازے 15 منٹ پہلے کھلتے ہیں۔',
  '🍿 Bookings are open: {0}': '🍿 بکنگ کھل گئی: {0}',
  'Grab the best seats before they\'re gone!':
      'بہترین سیٹیں ختم ہونے سے پہلے لے لیں!',
  '{0}, {1}!': '{0}، {1}',
  'Demo app · No real payments · Built by TwinStack Studio':
      'ڈیمو ایپ · کوئی اصل ادائیگی نہیں · TwinStack Studio کی تیار کردہ',
  'Demo app: no real payments': 'ڈیمو ایپ: کوئی اصل ادائیگی نہیں',
  'Nothing is charged and no details leave your device. Only the demo card {0} is accepted.':
      'کوئی رقم نہیں کٹتی اور کوئی تفصیل آپ کے فون سے باہر نہیں جاتی۔ صرف ڈیمو کارڈ {0} قبول ہوتا ہے۔',
  'Use demo details': 'ڈیمو تفصیلات استعمال کریں',
  'Demo app: use the card {0}': 'ڈیمو ایپ: کارڈ {0} استعمال کریں',
};
