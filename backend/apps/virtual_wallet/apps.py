from django.apps import AppConfig


class VirtualWalletConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.virtual_wallet"

    def ready(self):
        import apps.virtual_wallet.signals  # noqa: F401
