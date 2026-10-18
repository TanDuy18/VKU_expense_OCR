MINI-PROJECT SHORT TECHNICAL REPORT
Course: Cross-Platform Mobile App Development (VKU)
Mini-Project Title: Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)
Student Name: Nguyễn Tấn Duy
Submission Date: [DD/MM/YYYY]
1. GENERAL INFORMATION & DELIVERABLE LINKS
Team Members:
1. Nguyễn Tấn Duy — Student ID: 23IT.B029 — Role: Individual project (architecture, UI, OCR/regex logic, database, testing) — Contribution: 100%
Live Demo / APK Download: [APK link]
GitHub Repository: [https://github.com/username/your-repo-name]
2. FEATURE IMPLEMENTATION CHECKLIST
#
Required Feature
Status
Implementation Details & Acceptance Level
1
Camera capture & image cropping
⚠️ Partial
Receipt photo from the device camera or the gallery via image_picker (images downscaled to 1600 px before OCR). A live viewfinder with flash toggle, tap-to-focus and a crop overlay is not implemented.
2
On-device text recognition (Google ML Kit)
✅ Complete
google_mlkit_text_recognition runs fully on the device, so no Internet and no cloud cost. Works offline.
3
Regex heuristic parser
✅ Complete
Extracts the total (150,000 VND, 150.000 đ), the date (DD/MM/YYYY) and the merchant name. Also parses bank transfer messages (signed amounts, transfer note) and ignores the account balance. Guesses the category from keywords.
4
Interactive review screen
✅ Complete
OCR result pre-fills the form (merchant, amount, date, category). The user can edit every field and view the raw OCR text before saving.
5
Local database & transaction lifecycle
✅ Complete
sqflite (SQLite) with 5 categories (Food, Study, Travel, Shopping, Entertainment), schema versioning with migration (v1 to v2), and seed data on first launch. Receipt images are copied into the app documents directory; displaying receipt thumbnails is not implemented.
6
Custom canvas charts (CustomPainter)
✅ Complete
Animated donut chart (spending by category) and weekly bar chart (Monday to Sunday), both drawn directly on Canvas without any chart library.
7
Spending summary & history
✅ Complete
Monthly total, search by merchant, filter by category, and a budget allocation view with percentages.
8
Gemini AI saving advice (extra)
✅ Complete
Sends only per-category totals (no images, no merchant names) to the Gemini API. Retries on temporary errors and falls back to a second model. The last advice is stored in SQLite and stays readable offline.
9
Automated tests
✅ Complete
Unit tests for the parser, statistics, demo receipts and the Gemini prompt builder, run with flutter test.
3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE
Directory structure (lib/):
• main.dart, theme.dart — application shell with 3 bottom tabs (Home, History, Analysis) and the theme.
• models/expense.dart — Expense and Category models.
• data/db.dart — AppDb (sqflite: tables expenses and advice) and ExpenseStore; data/demo_receipts.dart — sample receipts for quick testing.
• parser/receipt_parser.dart — regex heuristics (amount, date, merchant, category).
• ocr/ocr_service.dart — wrapper around the ML Kit TextRecognizer.
• ai/gemini_service.dart — Gemini REST client.
• stats.dart — pure functions for chart data (totals by category, weekly totals, monthly total).
• widgets.dart — DonutPainter and BarPainter (CustomPainter), shared UI widgets.
• screens/ — home, history, analysis, scan, review and the Gemini advice panel.
• test/ — unit tests.
State management and data flow. The app uses Flutter's built-in ChangeNotifier (ExpenseStore) with ListenableBuilder, and no third-party state library. The flow is: image, then ML Kit text, then the regex parser, then the review screen, then SQLite insert, then store.load() and notifyListeners(). The charts and lists rebuild automatically. Statistics are pure functions, which keeps them easy to unit test.
Offline behavior. OCR, parsing, storage and charts do not need a network. Only the Gemini advice needs a connection, and it falls back to the cached advice.
Exception handling strategy.
• OCR failure: show the error in the raw-text section and let the user type the values manually. Amounts are validated (greater than 0) before saving.
• Gemini: 15 second timeout; retry on HTTP 429/500/503/504; fallback to a second model; offline errors keep the stored advice visible; the user sees a readable message instead of a status code.
• API key: passed at build time with --dart-define-from-file and excluded from Git via .gitignore, so it is not published in the public repository.
• Database: onUpgrade migration keeps existing data when the schema changes.
4. EMPIRICAL EVIDENCE & SCREENSHOTS
[Insert screenshot 1: Home tab: monthly total, donut chart and weekly bar chart]
[Insert screenshot 2: Scan screen with Camera / Gallery buttons and the demo receipts]
[Insert screenshot 3: Review screen after OCR, with the extracted amount, date and merchant]
[Insert screenshot 4: Analysis tab with the Gemini saving advice and the budget allocation bars]
[Insert screenshot 5: Terminal output of flutter test with all tests passing]
5. TECHNICAL CHALLENGES & RESOLUTIONS
Challenge 1: the parser read the account balance as the payment amount. In bank messages such as "-200,000 VND ... Số dư: 3.000.000 VND", the first version took the largest money value, which was the balance. Fix: prefer the amount with a +/- sign, exclude any number that follows "số dư", and read the transfer note after "ND:". A word boundary was needed so that the letters "ND" inside "VND" are not matched as the note. Each case was added as a unit test before the fix was accepted.
Challenge 2: Gemini errors caused by model retirement and overload. The first model name returned HTTP 404 because Google retired it, and the replacement sometimes returned HTTP 503 under load. Fix: the model name is configurable at build time, temporary errors are retried, a fallback model is tried, and the last successful answer is stored in SQLite, so the feature degrades gracefully instead of failing.
Build environment note: the project is on drive E: while the Pub cache is on drive C:, which made incremental Kotlin compilation fail. Setting kotlin.incremental=false in android/gradle.properties fixed the build.
