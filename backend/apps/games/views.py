import random
from decimal import Decimal
from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework.response import Response

from .models import Game, MinesGameSession
from .serializers import GameSerializer
from .mines_logic import calculate_mines_multiplier
from apps.virtual_wallet.models import Wallet


# Players can see active games.
class PublicGameListView(generics.ListAPIView):
    serializer_class = GameSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        return Game.objects.filter(is_active=True).order_by("sort_order", "name")


# Admin can list and create games.
class AdminGameListCreateView(generics.ListCreateAPIView):
    serializer_class = GameSerializer
    permission_classes = [IsAdminUser]
    queryset = Game.objects.all().order_by("sort_order", "name")


# Admin can view, edit and delete games.
class AdminGameDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = GameSerializer
    permission_classes = [IsAdminUser]
    queryset = Game.objects.all()


# ---------------- MINES GAME ENGINE ----------------


class MinesActiveSessionView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        session = MinesGameSession.objects.filter(
            user=request.user,
            status="in_progress",
        ).first()

        if not session:
            return Response({"active_session": None})

        next_mult = calculate_mines_multiplier(
            session.grid_size,
            session.mine_count,
            len(session.revealed_tiles) + 1,
        )

        return Response({
            "active_session": {
                "id": session.id,
                "bet_amount": str(session.bet_amount),
                "mine_count": session.mine_count,
                "grid_size": session.grid_size,
                "revealed_tiles": session.revealed_tiles,
                "current_multiplier": str(session.current_multiplier),
                "current_payout": str((session.bet_amount * session.current_multiplier).quantize(Decimal("0.01"))),
                "next_multiplier": str(next_mult),
                "status": session.status,
            }
        })


class MinesStartGameView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            bet_amount = Decimal(str(request.data.get("bet_amount", "10")))
            mine_count = int(request.data.get("mine_count", 3))
        except Exception:
            return Response({"error": "Invalid bet amount or mine count."}, status=status.HTTP_400_BAD_REQUEST)

        if bet_amount <= Decimal("0"):
            return Response({"error": "Bet amount must be greater than zero."}, status=status.HTTP_400_BAD_REQUEST)

        if mine_count < 1 or mine_count > 24:
            return Response({"error": "Mine count must be between 1 and 24."}, status=status.HTTP_400_BAD_REQUEST)

        wallet, _ = Wallet.objects.get_or_create(
            user=request.user,
            defaults={"balance": Decimal("100.00")},
        )

        if not wallet.can_afford(bet_amount):
            return Response({
                "error": f"Insufficient wallet balance. You have ₹{wallet.balance:.2f}."
            }, status=status.HTTP_400_BAD_REQUEST)

        # Invalidate any lingering in_progress session as busted
        MinesGameSession.objects.filter(
            user=request.user,
            status="in_progress",
        ).update(status="busted")

        # Deduct bet from wallet
        ref_id = f"MINES-BET-{request.user.id}"
        try:
            wallet.debit(
                amount=bet_amount,
                description=f"Mines Bet ({mine_count} mines)",
                reference_id=ref_id,
                transaction_type="game_bet",
            )
        except ValueError as err:
            return Response({"error": str(err)}, status=status.HTTP_400_BAD_REQUEST)

        # Generate random mine locations
        mine_locations = sorted(random.sample(range(25), mine_count))

        session = MinesGameSession.objects.create(
            user=request.user,
            bet_amount=bet_amount,
            mine_count=mine_count,
            grid_size=25,
            mine_locations=mine_locations,
            revealed_tiles=[],
            current_multiplier=Decimal("1.00"),
            status="in_progress",
        )

        next_mult = calculate_mines_multiplier(25, mine_count, 1)

        return Response({
            "session_id": session.id,
            "bet_amount": str(session.bet_amount),
            "mine_count": session.mine_count,
            "grid_size": session.grid_size,
            "revealed_tiles": session.revealed_tiles,
            "current_multiplier": "1.00",
            "current_payout": str(session.bet_amount),
            "next_multiplier": str(next_mult),
            "wallet_balance": str(wallet.balance),
            "status": "in_progress",
        }, status=status.HTTP_201_CREATED)


class MinesRevealTileView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        session_id = request.data.get("session_id")
        try:
            tile_index = int(request.data.get("tile_index"))
        except (TypeError, ValueError):
            return Response({"error": "Invalid tile index."}, status=status.HTTP_400_BAD_REQUEST)

        if tile_index < 0 or tile_index >= 25:
            return Response({"error": "Tile index must be 0 to 24."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            session = MinesGameSession.objects.get(
                id=session_id,
                user=request.user,
            )
        except MinesGameSession.DoesNotExist:
            return Response({"error": "Game session not found."}, status=status.HTTP_404_NOT_FOUND)

        if session.status != "in_progress":
            return Response({
                "error": f"Game is already {session.status}.",
                "status": session.status,
                "mine_locations": session.mine_locations,
            }, status=status.HTTP_400_BAD_REQUEST)

        if tile_index in session.revealed_tiles:
            return Response({"error": "Tile already revealed."}, status=status.HTTP_400_BAD_REQUEST)

        # Check if mine hit
        if tile_index in session.mine_locations:
            session.status = "busted"
            session.payout = Decimal("0.00")
            session.save(update_fields=["status", "payout", "updated_at"])

            wallet = Wallet.objects.get(user=request.user)

            return Response({
                "status": "busted",
                "hit_mine": True,
                "tile_index": tile_index,
                "mine_locations": session.mine_locations,
                "revealed_tiles": session.revealed_tiles,
                "current_multiplier": "0.00",
                "payout": "0.00",
                "wallet_balance": str(wallet.balance),
                "message": "💥 Boom! You hit a mine.",
            })

        # Safe tile revealed
        session.revealed_tiles.append(tile_index)
        new_mult = calculate_mines_multiplier(25, session.mine_count, len(session.revealed_tiles))
        session.current_multiplier = new_mult
        current_payout = (session.bet_amount * new_mult).quantize(Decimal("0.01"))

        max_safe = 25 - session.mine_count
        auto_cleared = len(session.revealed_tiles) >= max_safe

        wallet = Wallet.objects.get(user=request.user)

        if auto_cleared:
            # Player cleared all safe tiles! Auto cashout
            session.status = "cashed_out"
            session.payout = current_payout
            session.save(update_fields=["status", "payout", "current_multiplier", "revealed_tiles", "updated_at"])

            wallet.credit(
                amount=current_payout,
                description=f"Mines Grand Win ({new_mult}x)",
                reference_id=f"MINES-WIN-{session.id}",
                transaction_type="game_win",
            )

            return Response({
                "status": "cashed_out",
                "hit_mine": False,
                "tile_index": tile_index,
                "revealed_tiles": session.revealed_tiles,
                "mine_locations": session.mine_locations,
                "current_multiplier": str(new_mult),
                "payout": str(current_payout),
                "wallet_balance": str(wallet.balance),
                "auto_cleared": True,
                "message": f"🎉 Incredible! All {max_safe} safe tiles found! Won ₹{current_payout:.2f} ({new_mult}x)!",
            })

        session.save(update_fields=["current_multiplier", "revealed_tiles", "updated_at"])
        next_mult = calculate_mines_multiplier(25, session.mine_count, len(session.revealed_tiles) + 1)

        return Response({
            "status": "in_progress",
            "hit_mine": False,
            "tile_index": tile_index,
            "revealed_tiles": session.revealed_tiles,
            "current_multiplier": str(new_mult),
            "current_payout": str(current_payout),
            "next_multiplier": str(next_mult),
            "wallet_balance": str(wallet.balance),
        })


class MinesCashoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        session_id = request.data.get("session_id")
        try:
            session = MinesGameSession.objects.get(
                id=session_id,
                user=request.user,
            )
        except MinesGameSession.DoesNotExist:
            return Response({"error": "Game session not found."}, status=status.HTTP_404_NOT_FOUND)

        if session.status != "in_progress":
            return Response({
                "error": f"Game is already {session.status}.",
            }, status=status.HTTP_400_BAD_REQUEST)

        if not session.revealed_tiles:
            return Response({
                "error": "You must reveal at least one safe tile before cashing out.",
            }, status=status.HTTP_400_BAD_REQUEST)

        payout = (session.bet_amount * session.current_multiplier).quantize(Decimal("0.01"))
        session.status = "cashed_out"
        session.payout = payout
        session.save(update_fields=["status", "payout", "updated_at"])

        wallet, _ = Wallet.objects.get_or_create(
            user=request.user,
            defaults={"balance": Decimal("100.00")},
        )
        wallet.credit(
            amount=payout,
            description=f"Mines Cashout ({session.current_multiplier}x)",
            reference_id=f"MINES-WIN-{session.id}",
            transaction_type="game_win",
        )

        return Response({
            "status": "cashed_out",
            "payout": str(payout),
            "current_multiplier": str(session.current_multiplier),
            "mine_locations": session.mine_locations,
            "revealed_tiles": session.revealed_tiles,
            "wallet_balance": str(wallet.balance),
            "message": f"Successfully cashed out ₹{payout:.2f} ({session.current_multiplier}x)!",
        })
