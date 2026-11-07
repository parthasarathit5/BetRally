import random
import uuid
import urllib.parse
from decimal import Decimal
from django.conf import settings
from django.db import transaction
from django.db.models import Q
from rest_framework import generics, status
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework.response import Response

from .models import Game, MinesGameSession, GamePlayRecord
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


class RecordMatchView(APIView):
    """
    Records match completion for any of the 20 playable games (Chess, Cricket, Carrom, Galaxy Strike, Tower Defense, etc.)
    Validates wallet balance, processes entry fee and win payouts atomically, and creates an audit record in Supabase.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        game_name = request.data.get("game_name", "Game").strip()
        game_slug = request.data.get("game_slug", "game").strip()
        result = request.data.get("result", "loss").lower().strip()

        try:
            bet_amount = Decimal(str(request.data.get("bet_amount", "0.00")))
            payout_amount = Decimal(str(request.data.get("payout_amount", "0.00")))
        except Exception:
            return Response({"error": "Invalid bet or payout amount."}, status=status.HTTP_400_BAD_REQUEST)

        score_details = request.data.get("score_details", {})
        if not isinstance(score_details, dict):
            score_details = {"details": str(score_details)}

        wallet, _ = Wallet.objects.get_or_create(
            user=request.user,
            defaults={"balance": Decimal("0.00")},
        )

        ref_id = f"MATCH-{game_slug[:6].upper()}-{uuid.uuid4().hex[:8].upper()}"

        with transaction.atomic():
            wallet = Wallet.objects.select_for_update().get(id=wallet.id)
            balance_before = wallet.balance

            is_win_result = result in ["win", "won"]

            if is_win_result:
                # User won! Calculate prize credit
                if payout_amount > bet_amount:
                    net_change = payout_amount - bet_amount
                    final_payout = payout_amount
                elif payout_amount > Decimal("0.00"):
                    net_change = payout_amount
                    final_payout = payout_amount
                else:
                    final_payout = (bet_amount * Decimal("2.0")).quantize(Decimal("0.01"))
                    net_change = final_payout - bet_amount

                # Automatically add to user wallet
                wallet.balance += net_change
                wallet.save(update_fields=["balance", "updated_at"])
                balance_after = wallet.balance

                from apps.transactions.models import Transaction
                Transaction.objects.create(
                    user=request.user,
                    wallet=wallet,
                    amount=net_change,
                    balance_after=balance_after,
                    transaction_type="game_win",
                    status="success",
                    description=f"{game_name} Victory (Won ₹{final_payout:.2f})",
                    reference_id=ref_id,
                )
            else:
                deduct = min(wallet.balance, bet_amount)
                wallet.balance = max(Decimal("0.00"), wallet.balance - deduct)
                wallet.save(update_fields=["balance", "updated_at"])
                balance_after = wallet.balance
                final_payout = Decimal("0.00")

                from apps.transactions.models import Transaction
                if deduct > Decimal("0.00"):
                    Transaction.objects.create(
                        user=request.user,
                        wallet=wallet,
                        amount=-deduct,
                        balance_after=balance_after,
                        transaction_type="game_bet",
                        status="success",
                        description=f"{game_name} Match Entry / Loss",
                        reference_id=ref_id,
                    )

            # Save match record in Supabase PostgreSQL - Guaranteed audit trail
            record = GamePlayRecord.objects.create(
                user=request.user,
                game_name=game_name,
                game_slug=game_slug,
                bet_amount=bet_amount,
                payout_amount=final_payout,
                balance_before=balance_before,
                balance_after=balance_after,
                result="win" if is_win_result else "loss",
                score_details=score_details,
                reference_id=ref_id,
            )

        admin_phone = getattr(settings, "ADMIN_WHATSAPP_NUMBER", "+917780383832").replace(" ", "").replace("-", "")
        wa_text = (
            f"Hello Admin, Match Completed on BetRally/WinPlay!\n"
            f"Player ID: #{request.user.id}\n"
            f"Username: {request.user.username}\n"
            f"Game: {game_name}\n"
            f"Result: {result.upper()}\n"
            f"Entry: ₹{bet_amount:.2f}\n"
            f"Payout: ₹{final_payout:.2f}\n"
            f"Wallet: ₹{balance_after:.2f}\n"
            f"Match Ref: {ref_id}\n"
            f"Date: {record.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
        )
        encoded_wa = urllib.parse.quote(wa_text)
        clean_phone = admin_phone.replace("+", "")
        wa_url = f"https://wa.me/{clean_phone}?text={encoded_wa}"

        return Response({
            "message": f"Match record saved: {result.upper()} in {game_name}",
            "match_id": record.id,
            "reference_id": ref_id,
            "result": result,
            "bet_amount": str(bet_amount),
            "payout_amount": str(final_payout),
            "balance_before": str(balance_before),
            "balance_after": str(balance_after),
            "wallet_balance": str(balance_after),
            "whatsapp_admin_url": wa_url,
            "admin_whatsapp_number": admin_phone,
        }, status=status.HTTP_201_CREATED)


class AdminMatchRecordsView(APIView):
    """
    Admin view for monitoring all player match activities, scores, wins, and losses.
    """
    permission_classes = [IsAdminUser]

    def get(self, request):
        search = request.query_params.get("search", "").strip()
        result_filter = request.query_params.get("result", "").strip()

        records = GamePlayRecord.objects.select_related("user").all()

        if search:
            from django.db.models import Q
            records = records.filter(
                Q(user__username__icontains=search) |
                Q(user__email__icontains=search) |
                Q(game_name__icontains=search) |
                Q(reference_id__icontains=search)
            )

        if result_filter:
            records = records.filter(result__iexact=result_filter)

        results = []
        for r in records[:100]:
            results.append({
                "id": r.id,
                "user_id": r.user.id,
                "username": r.user.username,
                "email": r.user.email,
                "game_name": r.game_name,
                "game_slug": r.game_slug,
                "bet_amount": str(r.bet_amount),
                "payout_amount": str(r.payout_amount),
                "balance_before": str(getattr(r, "balance_before", "0.00")),
                "balance_after": str(getattr(r, "balance_after", "0.00")),
                "result": r.result,
                "score_details": r.score_details,
                "reference_id": r.reference_id,
                "created_at": r.created_at.isoformat(),
            })

        return Response({
            "count": len(results),
            "results": results,
        })

