from django.urls import path
from .views import (
    WalletDetailView,
    WalletDepositView,
    WhatsAppDepositRequestView,
    WalletWithdrawView,
    TransactionHistoryView,
    AdminWalletCreditDebitView,
    AdminDepositListView,
    AdminDepositApproveView,
    AdminDepositRejectView,
)

urlpatterns = [
    path("", WalletDetailView.as_view(), name="wallet-detail"),
    path("deposit/", WalletDepositView.as_view(), name="wallet-deposit"),
    path("deposit/whatsapp/", WhatsAppDepositRequestView.as_view(), name="wallet-deposit-whatsapp"),
    path("withdraw/", WalletWithdrawView.as_view(), name="wallet-withdraw"),
    path("transactions/", TransactionHistoryView.as_view(), name="wallet-transactions"),

    # Admin Deposit Verification & Adjustment Endpoints
    path("admin/deposits/", AdminDepositListView.as_view(), name="admin-deposits-list"),
    path("admin/deposits/<int:txn_id>/approve/", AdminDepositApproveView.as_view(), name="admin-deposits-approve"),
    path("admin/deposits/<int:txn_id>/reject/", AdminDepositRejectView.as_view(), name="admin-deposits-reject"),
    path("admin/<int:user_id>/adjust/", AdminWalletCreditDebitView.as_view(), name="admin-wallet-adjust"),
]
