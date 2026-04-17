import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:yumbook_backend/services/supabase/supabase_data_service.dart';
import 'package:yumbook_shared/data/mock_restaurants.dart';

void main(List<String> args) async {
  final app = Router();

  // CORS middleware
  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(app);

  // Routes
  app.get('/', (Request request) {
    return Response.ok('YumBook Backend Server');
  });

  // Get user profile
  app.get('/user/profile/<userId>', (Request request, String userId) async {
    try {
      final profile = await SupabaseDataService.fetchUserProfile(userId);
      return Response.ok(jsonEncode(profile.toJson()), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  // Get restaurants
  app.get('/restaurants', (Request request) {
    final restaurants = mockRestaurants.map((r) => {
      'id': r.id,
      'name': r.name,
      'location': r.location,
      'tags': r.tags,
      'description': r.description,
      'imagePath': r.imagePath,
      'rating': r.rating,
      'reviewCount': r.reviewCount,
    }).toList();
    return Response.ok(jsonEncode(restaurants), headers: {'content-type': 'application/json'});
  });

  // Get user reservations
  app.get('/user/reservations/<userId>', (Request request, String userId) async {
    try {
      final reservations = await SupabaseDataService.fetchReservations(userId);
      final data = reservations.map((r) => r.toJson()).toList();
      return Response.ok(jsonEncode(data), headers: {'content-type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  // Create reservation
  app.post('/reservations', (Request request) async {
    try {
      final payload = jsonDecode(await request.readAsString());
      final reservation = ReservationData.fromJson(payload);
      final userId = payload['userId'];
      await SupabaseDataService.insertReservation(reservation, userId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  });

  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server listening on port ${server.port}');
}

Middleware corsHeaders() {
  return (Handler handler) {
    return (Request request) async {
      final response = await handler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
      });
    };
  };
}