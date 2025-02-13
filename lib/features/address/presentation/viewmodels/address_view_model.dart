import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/address.dart';

class AddressViewModel extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  List<Address> _addresses = [];

  bool get isLoading => _isLoading;
  List<Address> get addresses => _addresses;

  AddressViewModel() {
    _loadAddresses();
  }

  void _loadAddresses() {
    _supabase
        .from('user_addresses')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser!.id)
        .order('is_default', ascending: false)
        .listen((data) {
      _addresses = data
          .map((json) => Address.fromJson({
                ...json,
                'user_id': json['user_id'] as String,
                'is_default': json['is_default'] as bool? ?? false,
              }))
          .toList();
      notifyListeners();
    });
  }

  Future<void> addAddress(String title, String address, bool isDefault) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (isDefault) {
        await _supabase
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', _supabase.auth.currentUser!.id);
      }

      await _supabase.from('user_addresses').insert({
        'user_id': _supabase.auth.currentUser!.id,
        'title': title,
        'address': address,
        'is_default': isDefault,
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAddress(
    String id,
    String title,
    String address,
    bool isDefault,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (isDefault) {
        await _supabase
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', _supabase.auth.currentUser!.id);
      }

      await _supabase.from('user_addresses').update({
        'title': title,
        'address': address,
        'is_default': isDefault,
      }).eq('id', id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.from('user_addresses').delete().eq('id', id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setDefaultAddress(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', _supabase.auth.currentUser!.id);

      await _supabase
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 