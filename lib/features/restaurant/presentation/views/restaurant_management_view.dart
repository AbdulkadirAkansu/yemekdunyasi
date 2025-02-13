import 'package:flutter/material.dart';
import 'package:yemekdunyasi/features/restaurant/data/repositories/restaurant_repository.dart';

class RestaurantManagementView extends StatefulWidget {
  const RestaurantManagementView({super.key});

  @override
  State<RestaurantManagementView> createState() => _RestaurantManagementViewState();
}

class _RestaurantManagementViewState extends State<RestaurantManagementView> {
  final _restaurantRepository = RestaurantRepository();
  bool _isLoading = false;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _loadRestaurantId();
  }

  Future<void> _loadRestaurantId() async {
    try {
      final restaurants = await _restaurantRepository.getUserRestaurants();
      if (restaurants.isNotEmpty) {
        setState(() {
          _restaurantId = restaurants.first['id'];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurantId == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Restoran Yönetimi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Menü'),
              Tab(text: 'Siparişler'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMenuTab(),
            _buildOrdersTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddItemDialog(context),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildMenuTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _restaurantRepository.getMenuItems(restaurantId: _restaurantId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Hata: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          );
        }

        final menuItems = snapshot.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: menuItems.length,
          itemBuilder: (context, index) => _buildMenuItem(menuItems[index]),
        );
      },
    );
  }

  Widget _buildMenuItem(Map<String, dynamic> item) {
    return Card(
      child: ListTile(
        leading: item['image_url'] != null
            ? Image.network(
                item['image_url'],
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.restaurant_menu),
        title: Text(item['name']),
        subtitle: Text('₺${item['price']}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _showEditItemDialog(context, item),
        ),
      ),
    );
  }

  Widget _buildOrdersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _restaurantRepository.getRestaurantOrders(restaurantId: _restaurantId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) => _buildOrderItem(orders[index]),
        );
      },
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('Sipariş #${order['id']}'),
        subtitle: Text('Toplam: ₺${order['total_amount']}'),
        trailing: Text(order['status']),
      ),
    );
  }

  Future<void> _showAddItemDialog(BuildContext context) async {
    if (!mounted) return;
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yeni Ürün Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Ürün Adı'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Fiyat'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!mounted) return;
              try {
                setState(() => _isLoading = true);
                await _restaurantRepository.addMenuItem(
                  restaurantId: _restaurantId!,
                  name: nameController.text,
                  description: descriptionController.text,
                  price: double.parse(priceController.text),
                  category: 'Genel',
                );
                if (!mounted) return;
                Navigator.pop(dialogContext);
                setState(() {});
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditItemDialog(BuildContext context, Map<String, dynamic> item) async {
    final nameController = TextEditingController(text: item['name']);
    final priceController = TextEditingController(text: item['price'].toString());
    final descriptionController = TextEditingController(text: item['description']);
    var dialogContext = context;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        dialogContext = context;
        return AlertDialog(
          title: const Text('Ürünü Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Ürün Adı'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Fiyat'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!mounted) return;
                try {
                  setState(() => _isLoading = true);
                  await _restaurantRepository.updateMenuItem(
                    itemId: item['id'],
                    name: nameController.text,
                    description: descriptionController.text,
                    price: double.parse(priceController.text),
                    category: item['category'] ?? 'Genel',
                  );
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    setState(() {});
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }
} 