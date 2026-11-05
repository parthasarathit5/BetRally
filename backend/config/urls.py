from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse, HttpResponse

def home_view(request):
    html_content = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BetRally Game Backend - Status Online</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: linear-gradient(135deg, #0a0e17 0%, #151d2a 100%);
            color: #ffffff;
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .card {
            background: rgba(26, 34, 49, 0.85);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 215, 0, 0.2);
            border-radius: 16px;
            padding: 40px;
            max-width: 580px;
            width: 90%;
            box-shadow: 0 20px 40px rgba(0,0,0,0.5);
            text-align: center;
        }
        .badge {
            display: inline-block;
            background: #00e676;
            color: #000;
            font-weight: bold;
            padding: 6px 16px;
            border-radius: 20px;
            font-size: 13px;
            margin-bottom: 20px;
            letter-spacing: 0.5px;
        }
        h1 {
            color: #ffd700;
            margin: 0 0 10px 0;
            font-size: 28px;
        }
        p {
            color: #94a3b8;
            font-size: 15px;
            line-height: 1.6;
            margin-bottom: 25px;
        }
        .btn-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            margin-top: 20px;
        }
        .btn {
            display: block;
            padding: 12px 18px;
            background: #2563eb;
            color: #fff;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.2s ease;
        }
        .btn:hover {
            background: #1d4ed8;
            transform: translateY(-2px);
        }
        .btn-gold {
            background: #f59e0b;
            color: #000;
        }
        .btn-gold:hover {
            background: #d97706;
        }
        .meta {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid rgba(255,255,255,0.1);
            font-size: 12px;
            color: #64748b;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="badge">&#9679; BACKEND OPERATIONAL</div>
        <h1>BetRally Gaming Platform API</h1>
        <p>Production Django REST Service connected live to Supabase PostgreSQL cloud database.</p>
        
        <div class="btn-grid">
            <a class="btn btn-gold" href="https://nexlyn-8fd9c.web.app" target="_blank">&#127918; Launch Web App</a>
            <a class="btn" href="/admin/" target="_blank">&#128272; Admin Portal</a>
            <a class="btn" href="/api/games/" target="_blank">&#127922; 20 Games API</a>
            <a class="btn" href="https://wa.me/917780383832" target="_blank">&#128172; Admin WhatsApp</a>
        </div>

        <div class="meta">
            Database: Supabase AWS-ap-northeast-1 &bull; Active Mode: Production
        </div>
    </div>
</body>
</html>"""
    return HttpResponse(html_content)

urlpatterns = [
    path("", home_view, name="home"),
    path("admin/", admin.site.urls),
    path("api/accounts/", include("apps.accounts.urls")),
    path("api/games/", include("apps.games.urls")),
    path("api/wallet/", include("apps.virtual_wallet.urls")),
]
