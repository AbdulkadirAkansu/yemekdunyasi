import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class RestaurantRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getRestaurants() async {
    final response = await _supabase
      .from('restaurants')
      .select('''
        *,
        menu_items (*)
      ''')
      .eq('is_active', true)
      .order('name');

    return response;
  }

  Future<Map<String, dynamic>> getRestaurantDetails(String restaurantId) async {
    final response = await _supabase
      .from('restaurants')
      .select('''
        *,
        menu_items (*)
      ''')
      .eq('id', restaurantId)
      .single();

    return response;
  }

  Future<String> uploadImage(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().toIso8601String()}.$fileExt';
    final filePath = 'restaurant_images/$userId/$fileName';

    await _supabase.storage.from('public').upload(filePath, imageFile);

    return _supabase.storage.from('public').getPublicUrl(filePath);
  }

  Future<void> addRestaurant({
    required String name,
    required String description,
    required String phone,
    required String address,
    required double minOrder,
    required File? imageFile,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    await _supabase.from('restaurants').insert({
      'owner_id': userId,
      'name': name,
      'description': description,
      'phone': phone,
      'address': address,
      'min_order': minOrder,
      'image_url': imageUrl,
    });
  }

  Future<void> addMenuItem({
    required String restaurantId,
    required String name,
    required String description,
    required double price,
    required String category,
    File? imageFile,
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    await _supabase.from('menu_items').insert({
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
    });
  }

  Future<void> toggleFavorite(String restaurantId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    final exists = await _supabase
      .from('favorite_restaurants')
      .select()
      .eq('user_id', userId)
      .eq('restaurant_id', restaurantId)
      .maybeSingle();

    if (exists == null) {
      await _supabase.from('favorite_restaurants').insert({
        'user_id': userId,
        'restaurant_id': restaurantId,
      });
    } else {
      await _supabase
        .from('favorite_restaurants')
        .delete()
        .eq('user_id', userId)
        .eq('restaurant_id', restaurantId);
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteRestaurants() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    final response = await _supabase
      .from('favorite_restaurants')
      .select('''
        restaurant:restaurants (
          *,
          menu_items (*)
        )
      ''')
      .eq('user_id', userId);

    return response.map((item) => item['restaurant'] as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getMenuItems({required String restaurantId}) async {
    final response = await _supabase
      .from('menu_items')
      .select()
      .eq('restaurant_id', restaurantId);

    return response;
  }

  Future<List<Map<String, dynamic>>> getRestaurantOrders({required String restaurantId}) async {
    final response = await _supabase
      .from('orders')
      .select('''
        *,
        user:users (
          email,
          phone
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

  Future<void> updateMenuItem({
    required String itemId,
    required String name,
    required String description,
    required double price,
    required String category,
    File? imageFile,
  }) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    final updateData = {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
    };

    if (imageUrl != null) {
      updateData['image_url'] = imageUrl;
    }

    await _supabase
      .from('menu_items')
      .update(updateData)
      .eq('id', itemId);
  }

  Future<void> deleteMenuItem(String itemId) async {
    await _supabase
      .from('menu_items')
      .delete()
      .eq('id', itemId);
  }

  Future<List<Map<String, dynamic>>> getUserRestaurants() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    final response = await _supabase
      .from('restaurants')
      .select()
      .eq('owner_id', userId);

    return response;
  }
} 