# 🎮 BetRally – Real-Money Multi-Gaming & Betting Platform

**Play games. Win rewards. Experience next-gen fair gaming.**

BetRally (WinPlay) is an enterprise real-money multi-gaming and betting application offering 20 playable games, bank-grade virtual wallet management, real-time admin monitoring, and instant WhatsApp escrow support. It combines a **Flutter** app with a **Django REST Framework** backend and a **PostgreSQL (Supabase)** database.

🌐 **Live Demo:** [nexlyn-8fd9c.web.app](https://nexlyn-8fd9c.web.app/)  
⚡ **Backend API:** [betrally.onrender.com](https://betrally.onrender.com/)  
💬 **Admin WhatsApp:** [+91 7780383832](https://wa.me/917780383832)

> This repository (`BetRally`) contains the Flutter app, the Django REST backend, and a full 1,800 automated testing suite.

---

## ✨ Features

### 🎮 Game Management & 20 Playable Games
- 20 fully implemented games: Mines Arcade, Blitz Chess, Cricket Clash, Carrom King, Galaxy Strike, Moto Rush, Kingdom Tower Defense, 2048 Mega Blitz, Zombie Outbreak, Archery Master, Space Invaders, Bubble Shooter, Fruit Slash, Block Puzzle, Knife Hit, Penalty Shootout, Snake & Ladders, Ludo Express, Tic Tac Toe Pro, and Spin & Win Wheel
- Real-time opponent AI (Chess, Cricket, Carrom, Tic Tac Toe)
- 10-minute strategic gameplay sessions
- Fair multiplier algorithms and instant payout calculations

### 💳 Virtual Wallet & Financial Security
- Zero free play enforced: starting balance is strictly ₹0.00; entry blocked if `balance < entry_fee`
- Safe deposit workflow: self-service automated injection disabled; generates WhatsApp request to Admin (+91 7780383832) with unique reference ID
- Minimum withdrawal strictly ₹500.00: pending escrow locking prevents double-spending
- 1-click admin approval: "Approve & Paid" or "Reject & Refund" (restores funds immediately)
- Full ledger audit: every match records `balance_before` and `balance_after`

### 📊 Admin Control Center & Analytics
- Executive KPI dashboard: Total Players, User Balances Pool, House Profit / Margin, Pending Deposits, Pending Withdrawals, and Win/Loss Rate
- Live player activity ticker: real-time match results, player ID, bet amount, and balance flow
- User management: search players, inspect balances, adjust credits/debits with notes, and toggle active status
- Game catalogue management: activate, deactivate, and adjust entry fees

### 🔐 Authentication & Dual-Delivery OTP
- Secure user registration and login with JWT Bearer tokens
- Resilient password reset pipeline: sends real SMTP emails to user's inbox + instant verification code on screen + direct WhatsApp Admin verification link
- Role-based access control protecting all administrative endpoints

---

## 🛠️ Tech Stack

| Layer            | Technology                                |
|------------------|-------------------------------------------|
| Frontend         | Flutter, Dart                             |
| Backend          | Python, Django, Django REST Framework     |
| Database         | PostgreSQL (Supabase)                     |
| Authentication   | SimpleJWT, PBKDF2 Password Hashing, OTP   |
| Hosting          | Render (backend), Firebase Hosting (web)  |
| Escrow Support   | Admin WhatsApp (+91 7780383832)           |
| CI/CD            | GitHub Actions                            |
| Testing          | Selenium, Appium, API, Load, Validation   |

---

## 🏗️ Architecture

```
        Flutter App (Mobile / Web)
                   │
               REST APIs
                   │
     Django + Django REST Framework
                   │
          PostgreSQL (Supabase)
```

The Flutter app talks to the Django backend over secure REST APIs. The backend handles business logic, atomic wallet transactions, rule validation, match records, and Supabase database operations.

---

## 📂 Repository Structure

```
BetRally/
├── mobile_app/              # Flutter cross-platform application (Web & Mobile)
│   ├── lib/
│   │   ├── screens/         # 20 game screens, wallet, admin dashboard, auth
│   │   ├── services/        # API service, token storage
│   │   └── main.dart        # App entry point & navigation
│   └── test/                # Flutter widget & screen tests
├── backend/                 # Django REST Framework backend
│   ├── apps/
│   │   ├── accounts/        # User auth, JWT, OTP password reset, admin stats
│   │   ├── games/           # 20 games catalogue, match records, Mines engine
│   │   ├── virtual_wallet/  # Wallet models, deposit/withdrawal escrow
│   │   └── transactions/    # Audit transaction logs
│   ├── config/              # Django settings, URLs, WSGI
│   └── manage.py            # Django management CLI
├── tests/                   # Automated test suites
│   └── run_1800_suite.py    # 1,800 automated test scenarios runner
├── .github/workflows/       # GitHub Actions CI/CD pipelines
├── firebase.json            # Firebase Hosting configuration
├── .firebaserc              # Firebase project settings
└── render.yaml              # Render Cloud deployment blueprint
```

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK and Dart SDK
- Python 3.11+
- Git
- PostgreSQL (or a Supabase project)
- Android Studio or VS Code

### 1. Clone the repository

```bash
git clone https://github.com/parthasarathit5/BetRally.git
cd BetRally
```

### 2. Run the Flutter app

```bash
cd mobile_app
flutter pub get
flutter run -d chrome
```

### 3. Run the Django backend

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate
# macOS / Linux
source venv/bin/activate

pip install -r requirements.txt
```

Create a `.env` file with your own values:

```env
SECRET_KEY=your-django-secret-key
DEBUG=True
DATABASE_URL=postgresql://postgres.zcslpyqbusbdsggrdtma:Supabase%40123@aws-0-ap-northeast-1.pooler.supabase.com:5432/postgres
ADMIN_WHATSAPP_NUMBER=+917780383832
```

Then run:

```bash
python manage.py migrate
python manage.py seed_games
python manage.py runserver
```

---

## 🧪 Testing

This repository includes automated tests across multiple layers:

| Test Type    | Folder / File           | Purpose                                  |
|--------------|-------------------------|------------------------------------------|
| API          | `backend/`              | Verify Django endpoints, auth and wallet |
| Web UI       | `mobile_app/test/`      | Flutter widget & UI workflow tests       |
| Validation   | `tests/`                | Rule validation, escrow, min withdrawal  |
| 1,800 Suite  | `tests/run_1800_suite.py`| Comprehensive 1,800 automated scenarios |
| Deployment   | `check_cloud.py`        | Live Render & Firebase health checks     |

Results from all suites run automatically through GitHub Actions (see `.github/workflows/ci.yml`).

### Running the 1,800 Test Suite
```bash
python tests/run_1800_suite.py
```

---

## 🔐 Security

- Keep secrets in environment variables (`SECRET_KEY`, `DATABASE_URL`).
- Never commit passwords, API keys, or private certificates.
- Backend-side input validation and atomic database transactions (`select_for_update`) to prevent race conditions.
- Strict withdrawal minimum (₹500+) with pending escrow locking.
- Zero self-service wallet modification: all cash additions are verified through Admin WhatsApp (+91 7780383832).

---

## 🔮 Future Enhancements

- Multi-player real-time WebSockets matchmaking
- Automated UPI auto-pay integration
- Push notifications via Firebase Cloud Messaging (FCM)
- Extended tournament brackets and leaderboards

---

## 👨‍💻 Developer

**Partha Sarathi Talapala**  
B.Tech – Computer Science and Engineering, Saveetha School of Engineering  
GitHub: [@parthasarathit5](https://github.com/parthasarathit5)
