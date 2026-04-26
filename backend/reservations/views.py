from django.shortcuts import render
from django.http import JsonResponse
from supabase_client import supabase
import json

def signup(request):
    if request.method == "POST":
        body = json.loads(request.body)
        email = body.get("email")
        password = body.get("password")

        res = supabase.auth.sign_up({
            "email": email,
            "password": password
        })

        if res.user:
            return JsonResponse({"message": "가입 성공!"})
        return JsonResponse({"error": "가입 실패"}, status=400)

''' 
        def login(request):
    if request.method == "POST":
        body = json.loads(request.body)
        email = body.get("email")
        password = body.get("password")

        res = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })

        if res.user:
            return JsonResponse({
                "message": "로그인 성공!",
                "access_token": res.session.access_token
            })
        return JsonResponse({"error": "이메일/비밀번호 확인"}, status=401)
    '''