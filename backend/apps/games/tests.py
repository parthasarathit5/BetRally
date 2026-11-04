from decimal import Decimal
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.games.models import Game, MinesGameSession
from apps.virtual_wallet.models import Wallet

User = get_user_model()


class GamesAndMinesTests(APITestCase):
    def setUp(self):
        self.player = User.objects.create_user(
            username="gameplayer",
            email="gameplayer@example.com",
            password="Password123!",
        )
        self.admin = User.objects.create_superuser(
            username="gameadmin",
            email="gameadmin@example.com",
            password="AdminPassword123!",
        )
        self.game = Game.objects.create(
            name="Mines Arcade",
            slug="mines-arcade",
            description="Find gems and avoid hidden mines.",
            category="casual",
            icon_name="casino",
            is_active=True,
        )

    def test_games_catalog_public(self):
        res = self.client.get(reverse("public-games"))
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        results = res.data if isinstance(res.data, list) else res.data.get("results", [])
        self.assertTrue(any(g["slug"] == "mines-arcade" for g in results))

    def test_admin_games_crud(self):
        self.client.force_authenticate(user=self.admin)

        # Create game
        create_res = self.client.post(reverse("admin-games"), {
            "name": "Speed Ludo",
            "slug": "speed-ludo",
            "description": "Fast paced ludo matches.",
            "category": "board",
            "icon_name": "casino",
            "is_active": True,
        }, format="json")
        self.assertEqual(create_res.status_code, status.HTTP_201_CREATED)
        game_id = create_res.data["id"]

        # Update game
        patch_res = self.client.patch(
            reverse("admin-game-detail", kwargs={"pk": game_id}),
            {"name": "Speed Ludo Pro", "is_active": False},
            format="json",
        )
        self.assertEqual(patch_res.status_code, status.HTTP_200_OK)
        self.assertFalse(patch_res.data["is_active"])

        # Delete game
        del_res = self.client.delete(reverse("admin-game-detail", kwargs={"pk": game_id}))
        self.assertEqual(del_res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Game.objects.filter(id=game_id).exists())

    def test_mines_gameplay_flow(self):
        self.client.force_authenticate(user=self.player)

        # 1. Start session with ₹50 bet and 3 mines
        start_res = self.client.post(reverse("mines-start"), {
            "bet_amount": "50.00",
            "mine_count": 3,
        }, format="json")
        self.assertEqual(start_res.status_code, status.HTTP_201_CREATED)
        session_id = start_res.data["session_id"]

        # Player wallet should have 100 - 50 = 50
        wallet = Wallet.objects.get(user=self.player)
        self.assertEqual(wallet.balance, Decimal("50.00"))

        # Look up mine positions to guarantee revealing a gem
        session = MinesGameSession.objects.get(id=session_id)
        mine_indices = set(session.mine_locations)
        safe_index = next(i for i in range(25) if i not in mine_indices)

        # 2. Reveal safe tile
        reveal_res = self.client.post(reverse("mines-reveal"), {
            "session_id": session_id,
            "tile_index": safe_index,
        }, format="json")
        self.assertEqual(reveal_res.status_code, status.HTTP_200_OK)
        self.assertEqual(reveal_res.data["status"], "in_progress")
        self.assertGreater(Decimal(str(reveal_res.data["current_multiplier"])), Decimal("1.00"))

        # 3. Cashout
        cashout_res = self.client.post(reverse("mines-cashout"), {
            "session_id": session_id,
        }, format="json")
        self.assertEqual(cashout_res.status_code, status.HTTP_200_OK)
        self.assertEqual(cashout_res.data["status"], "cashed_out")
        payout = Decimal(str(cashout_res.data["payout"]))

        # Wallet should now have 50 + payout > 50
        wallet.refresh_from_db()
        self.assertEqual(wallet.balance, Decimal("50.00") + payout)
