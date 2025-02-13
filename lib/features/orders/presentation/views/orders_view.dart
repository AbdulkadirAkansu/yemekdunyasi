import 'package:flutter/material.dart';
import 'package:yemekdunyasi/features/order/data/repositories/order_repository.dart';

class OrdersView extends StatefulWidget {
  const OrdersView({super.key});

  @override
  State<OrdersView> createState() => _OrdersViewState();
}

class _OrdersViewState extends State<OrdersView> {

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Siparişlerim'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Aktif'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrderList(status: 'active'),
            _OrderList(status: 'completed'),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final String status;
  final _orderRepository = OrderRepository();

  _OrderList({required this.status});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _orderRepository.getUserOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];
        final filteredOrders = orders.where((order) {
          if (status == 'active') {
            return ['pending', 'preparing', 'on_the_way'].contains(order['status']);
          } else {
            return ['delivered', 'cancelled'].contains(order['status']);
          }
        }).toList();

        if (filteredOrders.isEmpty) {
          return Center(
            child: Text(
              status == 'active' 
                ? 'Aktif siparişiniz bulunmuyor' 
                : 'Geçmiş siparişiniz bulunmuyor'
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return OrderCard(order: order);
          },
        );
      },
    );
  }
}

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['restaurant']['name'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '₺${order['total_amount']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            ...List.generate(
              (order['order_items'] as List).length,
              (index) {
                final item = order['order_items'][index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['quantity']}x ${item['menu_item']['name']}'),
                      Text('₺${item['total_price']}'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 