from decimal import Decimal
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.virtual_wallet.models import Wallet
from apps.transactions.models import Transaction

User = get_user_model()


class VirtualWalletTests(APITestCase):
    def setUp(self):
        self.player = User.objects.create_user(
            username="walletplayer",
            email="walletplayer@example.com",
            password="Password123!",
        )
        self.admin = User.objects.create_superuser(
            username="walletadmin",
            email="walletadmin@example.com",
            password="AdminPassword123!",
        )

    def test_auto_created_wallet_with_welcome_bonus(self):
        # Wallet should exist with ₹100 welcome bonus from post_save signal
        wallet = Wallet.objects.get(user=self.player)
        self.assertEqual(wallet.balance, Decimal("100.00"))

    def test_player_get_wallet(self):
        self.client.force_authenticate(user=self.player)
        res = self.client.get(reverse("wallet-detail"))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(Decimal(str(res.data["balance"])), Decimal("100.00"))

    def test_whatsapp_deposit_request_and_admin_approval(self):
        self.client.force_authenticate(user=self.player)
        req_res = self.client.post(
            reverse("wallet-deposit-whatsapp"),
            {"amount": "500.00"},
            format="json",
        )
        self.assertEqual(req_res.status_code, status.HTTP_201_CREATED)
        self.assertIn("whatsapp_url", req_res.data)
        txn_id = req_res.data["transaction_id"]

        txn = Transaction.objects.get(id=txn_id)
        self.assertEqual(txn.status, "pending")
        self.assertEqual(txn.amount, Decimal("500.00"))

        # Admin views pending deposits
        self.client.force_authenticate(user=self.admin)
        list_res = self.client.get(reverse("admin-deposits-list"), {"status": "pending"})
        self.assertEqual(list_res.status_code, status.HTTP_200_OK)
        results = list_res.data if isinstance(list_res.data, list) else list_res.data.get("results", [])
        self.assertTrue(any(item["id"] == txn_id for item in results))

        # Admin approves deposit
        approve_res = self.client.post(
            reverse("admin-deposits-approve", kwargs={"txn_id": txn_id}),
            format="json",
        )
        self.assertEqual(approve_res.status_code, status.HTTP_200_OK)

        # Wallet should now have 100 + 500 = 600
        wallet = Wallet.objects.get(user=self.player)
        self.assertEqual(wallet.balance, Decimal("600.00"))

        # Transaction status should be success
        txn.refresh_from_db()
        self.assertEqual(txn.status, "success")

    def test_admin_wallet_credit_debit_adjust(self):
        self.client.force_authenticate(user=self.admin)
        url = reverse("admin-wallet-adjust", kwargs={"user_id": self.player.id})

        # Credit ₹250
        credit_res = self.client.post(url, {
            "action": "credit",
            "amount": "250.00",
            "description": "Tournament prize",
        }, format="json")
        self.assertEqual(credit_res.status_code, status.HTTP_200_OK)
        self.assertEqual(Decimal(str(credit_res.data["new_balance"])), Decimal("350.00"))

        # Debit ₹50
        debit_res = self.client.post(url, {
            "action": "debit",
            "amount": "50.00",
            "description": "Platform fee",
        }, format="json")
        self.assertEqual(debit_res.status_code, status.HTTP_200_OK)
        self.assertEqual(Decimal(str(debit_res.data["new_balance"])), Decimal("300.00"))
