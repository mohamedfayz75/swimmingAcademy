# Swimming Academy Management System (نظام إدارة أكاديمية عالم السباحة)

A production-grade, cross-platform Flutter application built with Clean Architecture, Firebase Firestore, Firebase Authentication, and State Management via Flutter Riverpod. Designed with Modern Arabic RTL and Material 3 styling.

---

## 🏗️ Project Architecture & Directory Layout

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # Collection names, training types, week days
│   ├── rbac/
│   │   └── app_role.dart               # RBAC definitions (Staff vs Owner permissions)
│   ├── theme/
│   │   └── app_theme.dart              # Aquatic Material 3 theme & Cairo typography
│   └── utils/
│       ├── dialogs.dart                # Animated QR ID card dialog & toasts
│       └── formatters.dart             # Arabic currency, dates, numbers formatters
├── data/
│   └── firebase/
│       └── firebase_options.dart       # Cross-platform Firebase config
├── features/
│   ├── auth/                           # Authentication & Role profiles
│   ├── players/                        # Player Registration & QR Code Generation
│   ├── groups/                         # Training Groups & Pool Slot Matrix
│   ├── subscriptions/                  # Subscription Entry & Financial Calculations
│   ├── attendance/                     # QR Scanner & Today Attendance Logs
│   ├── water_cards/                    # Water Card 4-day session consumption
│   └── owner_dashboard/                # Financial Closure, Net Profit, Group Attendees
├── app_shell.dart                      # RBAC navigation drawer & bottom bar
└── main.dart                           # RTL setup & App entry point
```

---

## 🔐 Role-Based Access Control (RBAC)

1. **Staff Role (الإداري - Data Entry):**
   - **Accessible:**
     - تسجيل لاعب جديد (New Player Registration + Auto QR generation)
     - تسجيل اشتراك جديد (Subscription entry with locked auto-populated group details)
     - ماسح باركود الحضور (QR Attendance scanner with real-time session progress)
     - جدول المواعيد (Pool Slot Matrix daily view)
     - كروت المياة (Daily session consumption logging)
   - **Strictly Hidden:** Financial reports, monthly closures, coach payroll calculations, expense entries, profit margins.

2. **Owner Role (المالك - Super Admin):**
   - Full CRUD across all collections.
   - Access to Financial Dashboards, Monthly Closures (`net_profit = revenues - expenses`), Coach Payroll, Expenses, Pool Slot Matrix, and Water Card audits.

---

## 🗄️ Firestore Collections Schema

| Collection | Key Fields |
|---|---|
| `players` | `player_code`, `player_name`, `branch`, `birth_date`, `guardian_phone`, `customer_type`, `qr_code_url`, `created_at` |
| `groups` | `group_code`, `coach_id`, `coach_name`, `training_days`, `session_time`, `training_type`, `level`, `max_capacity`, `current_registered`, `available_seats`, `status` |
| `subscriptions` | `id`, `player_code`, `player_name`, `group_code`, `coach_name`, `training_days`, `session_time`, `training_type`, `stamp_card_fee`, `amount_required`, `amount_paid`, `amount_remaining`, `payment_date`, `subscription_type`, `sessions_count`, `attended_sessions`, `start_date`, `end_date`, `payment_status`, `created_by` |
| `attendance` | `id`, `player_code`, `player_name`, `group_code`, `timestamp`, `session_number`, `status`, `recorded_by` |
| `water_cards` | `id`, `card_date`, `card_name`, `card_price`, `total_sessions`, `used_day_1`..`used_day_4`, `total_used_sessions`, `remaining_sessions`, `status`, `monthly_closing_ref` |
| `coaches` | `coach_id`, `coach_name`, `phone_number`, `status`, `groups_count` |
| `payroll` | `coach_id`, `coach_name`, `sessions_1_to_10`, `sessions_11_to_20`, `sessions_21_to_31`, `total_sessions`, `session_rate`, `total_earnings`, `advance_payments`, `net_payable`, `payment_status`, `payout_date`, `month_year` |
| `expenses` | `id`, `category`, `amount`, `date`, `notes`, `month_year` |
| `general_accounting` | `month_year`, `total_subscription_revenues`, `total_stamp_card_revenues`, `total_coach_payroll`, `total_water_card_expenses`, `other_expenses`, `total_expenses`, `net_profit` |
| `users` | `uid`, `email`, `display_name`, `role`, `phone`, `created_at` |

---

## 🚀 Running the Project

1. Set active workspace to:
   ```
   C:\Users\INFANTRY\.gemini\antigravity\scratch\swimming_academy
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Connect your Firebase project using FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
4. Run on your desired target:
   ```bash
   flutter run
   ```
