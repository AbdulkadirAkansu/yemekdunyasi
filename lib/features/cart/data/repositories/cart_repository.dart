import 'package:supabase_flutter/supabase_flutter.dart';

class CartRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    final response = await _supabase
      .from('cart_items')
      .select('''
        *,
        menu_item:menu_items (
          name,
          price,
          image_url,
          restaurant:restaurants (
            name
          )
        )
      ''')
      .eq('user_id', userId);

    return response;
  }

  Future<void> addToCart({
    required String menuItemId,
    required int quantity,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    // Önce mevcut ürünü kontrol et
    final existingItem = await _supabase
      .from('cart_items')
      .select()
      .eq('user_id', userId)
      .eq('menu_item_id', menuItemId)
      .maybeSingle();

    if (existingItem != null) {
      // Varsa miktarı güncelle
      await _supabase
        .from('cart_items')
        .update({'quantity': existingItem['quantity'] + quantity})
        .eq('id', existingItem['id']);
    } else {
      // Yoksa yeni ekle
      await _supabase.from('cart_items').insert({
        'user_id': userId,
        'menu_item_id': menuItemId,
        'quantity': quantity,
      });
    }
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
    } else {
      await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    await _supabase
      .from('cart_items')
      .delete()
      .eq('id', cartItemId);
  }

  Future<void> clearCart() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Kullanıcı girişi yapılmamış');

    await _supabase
      .from('cart_items')
      .delete()
      .eq('user_id', userId);
  }
} 