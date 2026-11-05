from pathlib import Path
import os
import sys
import dj_database_url

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env if present
for env_candidate in [BASE_DIR / ".env", BASE_DIR.parent / ".env"]:
    if env_candidate.exists():
        with open(env_candidate, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    os.environ.setdefault(k.strip(), v.strip().strip("'\""))
        break

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY") or os.environ.get("SECRET_KEY") or "dev-only-winplay-key-change-before-deployment"

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = (os.environ.get("DJANGO_DEBUG") or os.environ.get("DEBUG") or "True").lower() == "true"

ALLOWED_HOSTS = [h.strip() for h in os.environ.get("ALLOWED_HOSTS", "*").split(",") if h.strip()]

# Application definition
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",

    "rest_framework",
    "corsheaders",

    "apps.accounts.apps.AccountsConfig",
    "apps.games.apps.GamesConfig",
    "apps.matchmaking.apps.MatchmakingConfig",
    "apps.tournaments.apps.TournamentsConfig",
    "apps.virtual_wallet.apps.VirtualWalletConfig",
    "apps.transactions.apps.TransactionsConfig",
    "apps.notifications.apps.NotificationsConfig",
    "apps.support.apps.SupportConfig",
    "apps.audit.apps.AuditConfig",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"

# Database Configuration (Supabase PostgreSQL / SQLite Fallback)
DATABASE_URL = os.environ.get("DATABASE_URL", "").strip()

if "test" in sys.argv:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": ":memory:",
        }
    }
elif DATABASE_URL and "[YOUR-PASSWORD]" not in DATABASE_URL:
    DATABASES = {
        "default": dj_database_url.parse(
            DATABASE_URL,
            conn_max_age=600,
            ssl_require=True,
        )
    }
else:
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]

# Internationalization
LANGUAGE_CODE = "en-us"
TIME_ZONE = "UTC"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
AUTH_USER_MODEL = "accounts.User"

# Admin WhatsApp Configuration (for manual payment verification & player inquiries)
ADMIN_WHATSAPP_NUMBER = os.environ.get("ADMIN_WHATSAPP_NUMBER", "+917780383832").strip()

# Email Configuration
EMAIL_HOST = os.environ.get("WINPLAY_EMAIL_HOST", "smtp.gmail.com")
EMAIL_PORT = int(os.environ.get("WINPLAY_EMAIL_PORT", 587))
EMAIL_USE_TLS = os.environ.get("WINPLAY_EMAIL_USE_TLS", "True").lower() == "true"
EMAIL_USE_SSL = os.environ.get("WINPLAY_EMAIL_USE_SSL", "False").lower() == "true"
EMAIL_HOST_USER = os.environ.get("WINPLAY_EMAIL", "").strip()
EMAIL_HOST_PASSWORD = os.environ.get("WINPLAY_EMAIL_PASSWORD", "").strip()
DEFAULT_FROM_EMAIL = os.environ.get(
    "WINPLAY_FROM_EMAIL",
    EMAIL_HOST_USER or "winplay@example.com",
)
EMAIL_TIMEOUT = 10  # 10s timeout to prevent hanging on SMTP connection issues

# Use SMTP backend only when credentials are provided; otherwise use console backend for local testing
EMAIL_BACKEND = (
    "django.core.mail.backends.smtp.EmailBackend"
    if EMAIL_HOST_USER and EMAIL_HOST_PASSWORD
    else "django.core.mail.backends.console.EmailBackend"
)

CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOWED_ORIGINS = [
    "http://localhost:5000",
    "http://127.0.0.1:5000",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8000",
    "http://127.0.0.1:8000",
]

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
}
