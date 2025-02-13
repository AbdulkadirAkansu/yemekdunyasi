import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getUserOrders() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    final response = await _supabase
      .from('orders')
      .select('''
        *,
        restaurant:restaurants (
          name,
          image_url
        ),
        order_items:order_items (
          *,
          menu_item:menu_items (
            name,
            price
          )
        )
      ''')
      .eq('user_id', userId)
      .order('created_at', ascending: false);

    return response;
  }

  Future<List<Map<String, dynamic>>> getRestaurantOrders(String restaurantId) async {
    final response = await _supabase
      .from('orders')
      .select('''
        *,
        user:users (
          email
        ),
        order_items:order_items (
          *,
          menu_item:menu_items (
            name,
            price
          )
        )
      ''')
      .eq('restaurant_id', restaurantId)
      .order('created_at', ascending: false);

    return response;
  }

  Future<void> createOrder({
    required String restaurantId,
    required String addressId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double deliveryFee,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    // Transaction başlat
    await _supabase.rpc('create_order', params: {
      'p_user_id': userId,
      'p_restaurant_id': restaurantId,
      'p_address_id': addressId,
      'p_total_amount': totalAmount,
      'p_delivery_fee': deliveryFee,
      'p_items': items,
    });
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await _supabase
      .from('orders')
      .update({'status': status})
      .eq('id', orderId);
  }

  Future<void> deleteOrder(String orderId) async {
    await _supabase
      .from('orders')
      .delete()
      .eq('id', orderId);
  }
} 