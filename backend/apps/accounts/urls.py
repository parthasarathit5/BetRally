from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)
from . import views

urlpatterns = [
    path("register/", views.RegisterView.as_view(), name="register"),

    path("login/", TokenObtainPairView.as_view(), name="login"),
    path("admin-login/", views.AdminLoginView.as_view(), name="admin-login"),
    path("admin/users/", views.AdminUserListView.as_view(), name="admin-users"),
    path("admin/users/<int:user_id>/status/", views.AdminUserStatusView.as_view(), name="admin-user-status"),
    path("admin/stats/", views.AdminDashboardStatsView.as_view(), name="admin-stats"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token-refresh"),

    path("password-reset/request/", views.request_password_reset),
    path("password-reset/verify/", views.verify_password_reset_otp),
    path("password-reset/confirm/", views.confirm_password_reset),
]