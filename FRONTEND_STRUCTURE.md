# Circulation+ — Frontend Architecture

> **Stack**: Flutter 3.41.9 · Dart 3.11.5 · Riverpod · GoRouter · fl_chart · flutter_animate  
> **Pattern**: Feature-first Clean Architecture (Presentation only — mock data, no backend yet)  
> **Status**: Frontend complete ✅ — backend integration pending

---

## Project Tree

```
circulation_plus/
├── lib/
│   ├── main.dart                          # Entry point — ProviderScope + CirculationPlusApp
│   ├── app.dart                           # MaterialApp.router — theme, locale, router wired here
│   │
│   ├── theme/
│   │   ├── app_colors.dart                # All colors, gradients (dark palette + Congo flag colors)
│   │   ├── app_text_styles.dart           # Typography scale (Inter font, 20+ named styles)
│   │   └── app_theme.dart                 # darkTheme + lightTheme (ThemeData) — day/night ready
│   │
│   ├── router/
│   │   └── app_router.dart                # GoRouter — all routes, ShellRoutes, guards
│   │
│   ├── l10n/
│   │   ├── app_fr.arb                     # French strings (primary language)
│   │   ├── app_en.arb                     # English strings
│   │   ├── app_localizations.dart         # Generated — do not edit by hand
│   │   ├── app_localizations_fr.dart      # Generated
│   │   └── app_localizations_en.dart      # Generated
│   │
│   ├── core/
│   │   ├── constants/app_constants.dart   # SharedPreferences keys, app-wide constants
│   │   └── utils/extensions.dart          # BuildContext, String, DateTime, int, double extensions
│   │
│   ├── shared/
│   │   ├── models/                        # Pure data models (mock data included inside each)
│   │   │   ├── fine_model.dart            # FineModel, FineStatus enum, mockFines list
│   │   │   ├── driver_model.dart          # DriverModel, mockDriver
│   │   │   ├── citizen_model.dart         # CitizenModel, mockCitizen
│   │   │   ├── officer_model.dart         # OfficerModel, mockOfficers
│   │   │   ├── vehicle_model.dart         # VehicleModel, mockVehicles
│   │   │   ├── infraction_model.dart      # InfractionModel, infraction catalogue
│   │   │   ├── notification_model.dart    # NotificationModel, NotificationType enum
│   │   │   └── models.dart                # Barrel export
│   │   │
│   │   └── widgets/                       # Reusable UI components
│   │       ├── pnc_badge.dart             # CustomPainter — Police badge (shield, stars, Congo arc)
│   │       ├── premium_button.dart        # PremiumButton (gradient) + GhostButton (outlined)
│   │       ├── glass_card.dart            # PremiumCard — glassmorphism container
│   │       ├── stat_card.dart             # Dashboard stat tile (icon + value + trend)
│   │       ├── status_badge.dart          # Fine status pill (pending/paid/overdue/contested)
│   │       ├── animated_counter.dart      # TweenAnimationBuilder number counter
│   │       └── custom_app_bar.dart        # Reusable AppBar with Congo flag bar
│   │
│   ├── features/
│   │   │
│   │   ├── auth/
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart     # AuthNotifier (StateNotifier) — role, login, logout
│   │   │   └── presentation/
│   │   │       ├── splash_screen.dart     # Animated PNC badge + logo + tagline (3s → auto-navigate)
│   │   │       ├── role_selection_screen.dart  # Choose: Police / Citoyen / Admin
│   │   │       └── login_screen.dart      # Email + password form, role-aware branding
│   │   │
│   │   ├── police/
│   │   │   ├── presentation/
│   │   │   │   ├── police_shell.dart      # BottomNavigationBar shell (4 tabs)
│   │   │   │   ├── police_dashboard.dart  # Stats, recent fines, quick actions
│   │   │   │   ├── driver_history_screen.dart   # TabBar: pending / paid fines + search
│   │   │   │   ├── police_notifications_screen.dart  # Officer notification feed
│   │   │   │   └── interpellation/        # 5-step interpellation wizard:
│   │   │   │       ├── scan_screen.dart             # Step 1 — Document scanner (mock viewfinder)
│   │   │   │       ├── ocr_preview_screen.dart      # Step 2 — OCR result preview + correction
│   │   │   │       ├── infraction_selection_screen.dart  # Step 3 — Pick infraction from catalogue
│   │   │   │       ├── fine_calculation_screen.dart # Step 4 — Amount + deadline + context
│   │   │   │       ├── signature_screen.dart        # Step 5a — Driver signature (CustomPainter pad)
│   │   │   │       └── interpellation_confirmation_screen.dart  # Step 5b — Review + confirm
│   │   │
│   │   ├── citizen/
│   │   │   ├── presentation/
│   │   │   │   ├── citizen_shell.dart     # BottomNavigationBar shell (4 tabs)
│   │   │   │   ├── citizen_dashboard.dart # Fine list, license points, quick pay
│   │   │   │   ├── fine_details_screen.dart    # Single fine detail + pay CTA
│   │   │   │   ├── payment_screen.dart    # MTN / Airtel Money payment flow
│   │   │   │   ├── receipt_screen.dart    # Payment receipt (QR mock, PDF download)
│   │   │   │   ├── license_status_screen.dart  # Points gauge, history, validity
│   │   │   │   └── citizen_notifications_screen.dart  # Citizen notification feed
│   │   │
│   │   ├── admin/
│   │   │   ├── presentation/
│   │   │   │   ├── admin_shell.dart       # NavigationRail shell (desktop-style)
│   │   │   │   ├── admin_dashboard.dart   # KPIs, bar chart (fl_chart), officer list
│   │   │   │   ├── revenue_dashboard.dart # Revenue charts, collection stats
│   │   │   │   ├── officers_management_screen.dart  # Officer CRUD list
│   │   │   │   └── map_screen.dart        # Infraction heat-map (mock CustomPainter)
│   │   │
│   │   └── settings/
│   │       ├── providers/
│   │       │   └── settings_provider.dart # SettingsNotifier — locale + isDarkMode (SharedPreferences)
│   │       └── presentation/
│   │           └── settings_screen.dart   # Language toggle, dark/light mode switch, app info
│
├── test/
│   └── widget_test.dart                   # Smoke test placeholder
│
├── l10n.yaml                              # flutter gen-l10n config
├── pubspec.yaml                           # Dependencies
└── FRONTEND_STRUCTURE.md                  # ← This file
```

---

## Navigation (GoRouter)

```
/                        → SplashScreen (auto-redirect after 3s)
/roles                   → RoleSelectionScreen
/login/:role             → LoginScreen (role = police | citizen | admin)

/police                  → PoliceShell (tab 0: Dashboard)
/police/history          → PoliceShell (tab 1: DriverHistory)
/police/notifications    → PoliceShell (tab 2: Notifications)
/police/scan             → ScanScreen        ← interpellation step 1
/police/ocr              → OcrPreviewScreen  ← step 2
/police/infraction       → InfractionSelectionScreen ← step 3
/police/fine-calc        → FineCalculationScreen     ← step 4
/police/signature        → SignatureScreen            ← step 5a
/police/confirm          → InterpellationConfirmationScreen ← step 5b

/citizen                 → CitizenShell (tab 0: Dashboard)
/citizen/fine/:id        → FineDetailsScreen
/citizen/pay/:id         → PaymentScreen
/citizen/receipt/:id     → ReceiptScreen
/citizen/license         → CitizenShell (tab 1: LicenseStatus)
/citizen/notifications   → CitizenShell (tab 2: Notifications)

/admin                   → AdminShell (rail 0: Dashboard)
/admin/revenue           → AdminShell (rail 1: RevenueDashboard)
/admin/officers          → AdminShell (rail 2: OfficersManagement)
/admin/map               → AdminShell (rail 3: MapScreen)

/settings                → SettingsScreen (accessible from all roles)
```

---

## State Management (Riverpod)

| Provider | Type | Purpose |
|---|---|---|
| `authProvider` | `StateNotifierProvider<AuthNotifier, AuthState>` | Current user role, login/logout |
| `settingsProvider` | `StateNotifierProvider<SettingsNotifier, SettingsState>` | Dark mode, locale — persisted to SharedPreferences |
| `routerProvider` | `Provider<GoRouter>` | Router instance, reads `authProvider` for guards |

---

## Theme System

```dart
// app.dart
MaterialApp.router(
  theme:      AppTheme.lightTheme,   // ← light mode
  darkTheme:  AppTheme.darkTheme,    // ← dark mode
  themeMode:  settings.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,   // ← toggled from SettingsScreen
)
```

Toggle is saved to `SharedPreferences` key `pref_dark_mode`.  
Default: **dark mode** (police-grade UI).

---

## Mock Data → Backend Replacement Plan

Every model class contains a `static List<T> mock*` field.  
When the backend is ready, replace each with a repository call:

| Mock field | Replace with | Endpoint (suggested) |
|---|---|---|
| `FineModel.mockFines` | `FineRepository.getFines(citizenId)` | `GET /api/fines?citizen={id}` |
| `FineModel.mockFines` (police) | `FineRepository.getOfficerFines(officerId)` | `GET /api/fines?officer={id}` |
| `DriverModel.mockDriver` | `DriverRepository.getByPlate(plate)` | `GET /api/drivers?plate={plate}` |
| `OfficerModel.mockOfficers` | `OfficerRepository.getAll()` | `GET /api/officers` |
| `InfractionModel.catalogue` | `InfractionRepository.getCatalogue()` | `GET /api/infractions` |
| `NotificationModel.mockOfficerNotifications` | `NotificationRepository.getForUser(userId)` | `GET /api/notifications?user={id}` |

---

## Key Design Tokens

```dart
// Identity colors (Congo national palette)
AppColors.congoGreen   = Color(0xFF009A44)
AppColors.congoYellow  = Color(0xFFFCD116)
AppColors.congoRed     = Color(0xFFDC241F)

// Police gold
AppColors.gold         = Color(0xFFC9A84C)

// Dark theme base
AppColors.background   = Color(0xFF080D1A)
AppColors.surface      = Color(0xFF0D1526)
AppColors.cardBackground = Color(0xFF111827)

// Semantic
AppColors.success = Color(0xFF10B981)
AppColors.warning = Color(0xFFF59E0B)
AppColors.error   = Color(0xFFEF4444)
AppColors.primary = Color(0xFF3B82F6)
```

---

## What the Backend Must Provide

### Authentication
- `POST /api/auth/login` → `{ token, user: { id, role, name, badgeNumber? } }`
- `POST /api/auth/logout`
- `GET  /api/auth/me`

### Fines
- `GET    /api/fines` (filters: citizen, officer, status, date)
- `GET    /api/fines/:id`
- `POST   /api/fines` (officer creates)
- `PATCH  /api/fines/:id/status`
- `POST   /api/fines/:id/pay` → triggers payment gateway

### Payment
- `POST /api/payments/initiate` → `{ paymentUrl, reference }` (MTN / Airtel gateway)
- `POST /api/payments/confirm` (webhook from gateway)
- `GET  /api/payments/receipt/:id`

### Drivers & Vehicles
- `GET /api/drivers?plate=` or `?license=`
- `GET /api/vehicles/:plate`

### Officers & Admin
- `GET    /api/officers`
- `POST   /api/officers`
- `PATCH  /api/officers/:id`
- `GET    /api/stats/revenue` (date range)
- `GET    /api/stats/infractions/heatmap`

### Notifications
- `GET    /api/notifications` (paginated, user-scoped)
- `PATCH  /api/notifications/:id/read`
- Push via FCM (Firebase Cloud Messaging)

---

*Generated: 2026-05-15 — Circulation+ v1.0 frontend*
