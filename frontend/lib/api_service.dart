import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 여기에 PORTS 탭에서 복사한 주소를 넣으세요!
  static const String baseUrl = "https://obscure-orbit-x5qwvvpwp6473v9gp-8000.app.github.dev/";
  const String baseUrl = 'http://10.0.2.2:8000'; 
// 안드로이드 에뮬레이터: 10.0.2.2
// 실제 기기: 내 컴퓨터 IP (예: 192.168.x.x)

  // 회원가입 함수
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup/'), // Django의 URL 경로
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sign up');
    }
  }
}


/*
// 예시: API 서비스 클래스
class ApiService {
  // Codespaces 포트 포워딩 주소 또는 로컬 IP
  final String baseUrl = "https://상단-포트-탭에서-복사한-주소.dev"; 

  Future<void> signUp(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup/'), // Django의 urls.py에 정의된 경로
      body: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );
    // ... 이후 처리
  }
}
*/