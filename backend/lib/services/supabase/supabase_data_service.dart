import 'package:yumbook_shared/models/payment_method_model.dart';
import 'package:yumbook_shared/models/reservation_data.dart';
import 'package:yumbook_shared/models/transaction_model.dart';
import 'package:yumbook_shared/models/user_profile.dart';
import 'package:yumbook_backend/services/supabase/supabase_auth_service.dart';
import 'package:yumbook_backend/core/supabase/supabase_client.dart';

class SupabaseDataService {
  static String get currentUserId => SupabaseAuthService.currentUser!.id;

  static Future<UserProfile> fetchUserProfile(String userId) async {
    final response = await SupabaseClientManager.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserProfile.fromJson(response);
  }

  static Future<List<PaymentMethodModel>> fetchPaymentMethods(String userId) async {
    final response = await SupabaseClientManager.client
        .from('payment_methods')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => PaymentMethodModel.fromJson(json))
        .toList();
  }

  static Future<void> insertPaymentMethod(PaymentMethodModel method, String userId) async {
    await SupabaseClientManager.client.from('payment_methods').insert({
      'user_id': userId,
      'brand': method.brand,
      'last4': method.last4,
      'holder_name': method.holderName,
      'expiry': method.expiry,
    });
  }

  static Future<void> deletePaymentMethod(String methodId, String userId) async {
    await SupabaseClientManager.client
        .from('payment_methods')
        .delete()
        .eq('id', methodId)
        .eq('user_id', userId);
  }

  static Future<List<String>> fetchSavedRestaurantIds(String userId) async {
    final response = await SupabaseClientManager.client
        .from('saved_restaurants')
        .select('restaurant_id')
        .eq('user_id', userId);

    return (response as List)
        .map((json) => json['restaurant_id'] as String)
        .toList();
  }

  static Future<void> insertSavedRestaurant(String restaurantId, String userId) async {
    await SupabaseClientManager.client.from('saved_restaurants').insert({
      'user_id': userId,
      'restaurant_id': restaurantId,
    });
  }

  static Future<void> deleteSavedRestaurant(String restaurantId, String userId) async {
    await SupabaseClientManager.client
        .from('saved_restaurants')
        .delete()
        .eq('restaurant_id', restaurantId)
        .eq('user_id', userId);
  }

  static Future<List<ReservationData>> fetchReservations(String userId) async {
    final response = await SupabaseClientManager.client
        .from('reservations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => ReservationData.fromJson(json))
        .toList();
  }

  static Future<void> insertReservation(ReservationData reservation, String userId) async {
    await SupabaseClientManager.client.from('reservations').insert({
      'user_id': userId,
      'restaurant_id': reservation.restaurantId,
      'restaurant_name': reservation.restaurantName,
      'date': reservation.date.toIso8601String().split('T')[0],
      'time': '${reservation.time.hour.toString().padLeft(2, '0')}:${reservation.time.minute.toString().padLeft(2, '0')}:00',
      'party_size': reservation.partySize,
      'guest_name': reservation.guestName,
      'seat_type': reservation.seatType,
      'confirmation_code': reservation.confirmationCode,
    });
  }

  static Future<List<TransactionModel>> fetchTransactions(String userId) async {
    final response = await SupabaseClientManager.client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }
}