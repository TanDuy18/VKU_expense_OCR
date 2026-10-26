# MINI-PROJECT SHORT TECHNICAL REPORT

|  |  |
|---|---|
| **Course** | Cross-Platform Mobile App Development (VKU) |
| **Mini-Project Title** | Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart) |
| **Student Name** | Nguyễn Tấn Duy |

---

## 1. GENERAL INFORMATION & DELIVERABLE LINKS

**Team Members**

| # | Full Name | Student ID | Role | Contribution |
|:-:|---|---|---|:-:|
| 1 | Nguyễn Tấn Duy | 23IT.B029 | Individual project: architecture, UI, OCR/regex logic, database, testing | 100% |

**Deliverables**

- 📦 **APK Download:** [https://github.com/TanDuy18/VKU_expense_OCR/releases/]
- 💻 **GitHub Repository:** [https://github.com/tanduy18/vku_expense_ocr]
-    **Demo app: ** [https://withered-hat-34e2.tanduy18-it.workers.dev/]

---

## 2. FEATURE IMPLEMENTATION CHECKLIST

| # | Required Feature | Status | Implementation Details & Acceptance Level |
|:-:|---|:-:|---|
| 1 | Camera capture & image cropping | ⚠️ Partial | Receipt photo from the camera or the gallery via `image_picker`; images are downscaled to 1600 px before OCR. A live viewfinder with flash toggle, tap-to-focus and a crop overlay is **not** implemented. |
| 2 | On-device text recognition (Google ML Kit) | ✅ Complete | `google_mlkit_text_recognition` runs fully on the device: no Internet, no cloud cost. Works offline. |
| 3 | Regex heuristic parser | ✅ Complete | Extracts the total (`150,000 VND`, `150.000 đ`), the date (`DD/MM/YYYY`) and the merchant name. Also parses bank transfer messages (signed amounts, transfer note) and ignores the account balance. Guesses the category from keywords. |
| 4 | Interactive review screen | ✅ Complete | The OCR result pre-fills the form (merchant, amount, date, category). The user can edit every field and view the raw OCR text before saving. |
| 5 | Local database & transaction lifecycle | ✅ Complete | `sqflite` (SQLite) with 5 categories (Food, Study, Travel, Shopping, Entertainment), schema versioning with migration (v1 → v2) and seed data on first launch. Receipt images are copied into the app documents directory; displaying receipt thumbnails is not implemented. |
| 6 | Custom canvas charts (`CustomPainter`) | ✅ Complete | Animated donut chart (spending by category) and weekly bar chart (Monday to Sunday), both drawn directly on `Canvas` without any chart library. |
| 7 | Spending summary & history | ✅ Complete | Monthly total, search by merchant, filter by category, and a budget allocation view with percentages. |
| 8 | Gemini AI saving advice *(extra)* | ✅ Complete | Sends only per-category totals (no images, no merchant names) to the Gemini API. Retries on temporary errors and falls back to a second model. The last advice is stored in SQLite and stays readable offline. |
| 9 | Automated tests | ✅ Complete | Unit tests for the parser, statistics, demo receipts and the Gemini prompt builder, run with `flutter test`. |

---

## 3. TECHNICAL ARCHITECTURE & PROJECT STRUCTURE

### 3.1 Directory structure

```text
lib/
├── main.dart                  # app shell, 3 bottom tabs (Home, History, Analysis)
├── theme.dart                 # colors and ThemeData
├── stats.dart                 # pure functions for chart data (category totals, weekly, monthly)
├── widgets.dart               # DonutPainter, BarPainter (CustomPainter), shared UI widgets
├── models/
│   └── expense.dart           # Expense and Category models
├── data/
│   ├── db.dart                # AppDb (sqflite: expenses, advice) and ExpenseStore
│   └── demo_receipts.dart     # sample receipts for quick testing
├── parser/
│   └── receipt_parser.dart    # regex heuristics: amount, date, merchant, category
├── ocr/
│   └── ocr_service.dart       # wrapper around the ML Kit TextRecognizer
├── ai/
│   └── gemini_service.dart    # Gemini REST client
└── screens/                   # home, history, analysis, scan, review, advice panel
test/                          # unit tests
```

### 3.2 State management and data flow

The app uses Flutter's built-in `ChangeNotifier` (`ExpenseStore`) with `ListenableBuilder`, with no third-party state library.

```text
Image → ML Kit text → regex parser → review screen → SQLite insert
      → store.load() → notifyListeners() → charts and lists rebuild
```

Statistics are pure functions, which keeps them easy to unit test.

### 3.3 Offline behavior

OCR, parsing, storage and charts do not need a network. Only the Gemini advice needs a connection, and it falls back to the cached advice.

### 3.4 Exception handling strategy

| Area | Strategy |
|---|---|
| OCR failure | Show the error in the raw-text section and let the user type the values manually. The amount is validated (> 0) before saving. |
| Gemini API | 15 s timeout; retry on HTTP 429 / 500 / 503 / 504; fallback to a second model; offline errors keep the stored advice visible; the user sees a readable message instead of a status code. |
| API key | Passed at build time with `--dart-define-from-file` and excluded from Git via `.gitignore`, so it is not published in the public repository. |
| Database | An `onUpgrade` migration keeps existing data when the schema changes. |

---

## 4. EMPIRICAL EVIDENCE & SCREENSHOTS

Save the screenshots in `docs/images/` and keep the file names below so they render automatically.

![Home tab: monthly total, donut chart and weekly bar chart](docs/images/01-home.png)
*Figure 1. Home tab: monthly total, donut chart and weekly bar chart.*

![Scan screen with Camera / Gallery buttons and demo receipts](docs/images/02-scan.png)
*Figure 2. Scan screen with Camera / Gallery buttons and the demo receipts.*

![Review screen after OCR](docs/images/03-review.png)
*Figure 3. Review screen after OCR, with the extracted amount, date and merchant.*

![Analysis tab with Gemini advice](docs/images/04-analysis.png)
*Figure 4. Analysis tab with the Gemini saving advice and the budget allocation bars.*

![flutter test output](docs/images/05-tests.png)
*Figure 5. Terminal output of `flutter test` with all tests passing.*

---

## 5. TECHNICAL CHALLENGES & RESOLUTIONS

### Challenge 1: the parser read the account balance as the payment amount

In bank messages such as `-200,000 VND ... Số dư: 3.000.000 VND`, the first version took the largest money value, which was the balance.

**Resolution**

- Prefer the amount that has a `+` / `-` sign.
- Exclude any number that follows "số dư".
- Read the transfer note after `ND:`. A word boundary (`\b`) was needed so that the letters "ND" inside "VND" are not matched as the note.

Each case was added as a unit test before the fix was accepted.

### Challenge 2: Gemini errors caused by model retirement and overload

The first model name returned HTTP 404 because Google had retired it, and its replacement sometimes returned HTTP 503 under load.

**Resolution**

- The model name is configurable at build time (`GEMINI_MODEL`).
- Temporary errors are retried, then a fallback model is tried.
- The last successful answer is stored in SQLite, so the feature degrades gracefully instead of failing.

### Build environment note

The project is on drive `E:` while the Pub cache is on drive `C:`, which made incremental Kotlin compilation fail. Setting `kotlin.incremental=false` in `android/gradle.properties` fixed the build.
