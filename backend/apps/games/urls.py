from django.urls import path

from .views import (
    PublicGameListView,
    AdminGameListCreateView,
    AdminGameDetailView,
    MinesStartGameView,
    MinesRevealTileView,
    MinesCashoutView,
    MinesActiveSessionView,
    RecordMatchView,
    AdminMatchRecordsView,
)

urlpatterns = [
    path("", PublicGameListView.as_view(), name="public-games"),
    path("record-match/", RecordMatchView.as_view(), name="record-match"),
    path("admin/matches/", AdminMatchRecordsView.as_view(), name="admin-matches"),
    path("admin/", AdminGameListCreateView.as_view(), name="admin-games"),
    path("admin/<int:pk>/", AdminGameDetailView.as_view(), name="admin-game-detail"),

    # Mines Game Endpoints
    path("mines/active/", MinesActiveSessionView.as_view(), name="mines-active"),
    path("mines/start/", MinesStartGameView.as_view(), name="mines-start"),
    path("mines/reveal/", MinesRevealTileView.as_view(), name="mines-reveal"),
    path("mines/cashout/", MinesCashoutView.as_view(), name="mines-cashout"),
]
