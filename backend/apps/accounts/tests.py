from django.contrib.auth import get_user_model
from django.core import mail
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.accounts.models import PasswordResetOTP

User = get_user_model()


class AccountsAuthTests(APITestCase):
    def setUp(self):
        self.player_data = {
            "username": "tester1",
            "email": "tester1@example.com",
            "phone_number": "9876543210",
            "password": "Password123!",
        }
        self.player = User.objects.create_user(
            username=self.player_data["username"],
            email=self.player_data["email"],
            password=self.player_data["password"],
            phone_number=self.player_data["phone_number"],
        )

        self.admin = User.objects.create_superuser(
            username="adminuser",
            email="admin@example.com",
            password="AdminPassword123!",
        )

    def test_registration(self):
        url = reverse("register")
        data = {
            "username": "newplayer",
            "email": "newplayer@example.com",
            "phone_number": "9123456780",
            "password": "SecurePass123!",
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["email"], "newplayer@example.com")
        self.assertTrue(User.objects.filter(email="newplayer@example.com").exists())

    def test_player_login(self):
        url = reverse("login")
        data = {
            "email": "tester1@example.com",
            "password": "Password123!",
        }
        response = self.client.post(url, data, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)

    def test_admin_login(self):
        url = reverse("admin-login")
        # Regular player cannot login via admin-login
        player_res = self.client.post(url, {
            "email": "tester1@example.com",
            "password": "Password123!",
        }, format="json")
        self.assertIn(player_res.status_code, [status.HTTP_400_BAD_REQUEST, status.HTTP_403_FORBIDDEN])

        # Superuser can login
        admin_res = self.client.post(url, {
            "email": "admin@example.com",
            "password": "AdminPassword123!",
        }, format="json")
        self.assertEqual(admin_res.status_code, status.HTTP_200_OK)
        self.assertIn("access", admin_res.data)

    def test_password_reset_flow(self):
        # 1. Request OTP
        req_res = self.client.post("/api/accounts/password-reset/request/", {
            "email": "tester1@example.com",
        }, format="json")
        self.assertEqual(req_res.status_code, status.HTTP_200_OK)

        # Retrieve OTP code from email outbox or debug_otp
        if len(mail.outbox) > 0:
            content = mail.outbox[-1].body
            # Example text: 'Your WinPlay / BetRally password reset code is: 123456'
            otp = content.split("code is: ")[1][:6].strip()
        else:
            otp = req_res.data["debug_otp"]

        # 2. Verify OTP
        verify_res = self.client.post("/api/accounts/password-reset/verify/", {
            "email": "tester1@example.com",
            "otp": otp,
        }, format="json")
        self.assertEqual(verify_res.status_code, status.HTTP_200_OK)
        reset_token = verify_res.data["reset_token"]

        # 3. Confirm new password
        confirm_res = self.client.post("/api/accounts/password-reset/confirm/", {
            "email": "tester1@example.com",
            "reset_token": reset_token,
            "new_password": "NewSecretPassword123!",
        }, format="json")
        self.assertEqual(confirm_res.status_code, status.HTTP_200_OK)

        # 4. Verify login with new password
        login_res = self.client.post(reverse("login"), {
            "email": "tester1@example.com",
            "password": "NewSecretPassword123!",
        }, format="json")
        self.assertEqual(login_res.status_code, status.HTTP_200_OK)

    def test_admin_stats_view(self):
        # Player forbidden
        self.client.force_authenticate(user=self.player)
        res = self.client.get(reverse("admin-stats"))
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)

        # Admin authorized
        self.client.force_authenticate(user=self.admin)
        admin_res = self.client.get(reverse("admin-stats"))
        self.assertEqual(admin_res.status_code, status.HTTP_200_OK)
        self.assertIn("total_players", admin_res.data)
        self.assertIn("total_wallet_pool", admin_res.data)
