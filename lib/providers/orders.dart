import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  final List<OrderItem> _orders = [];

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSaveOrders() async {
    final url =
        Uri.https('shopapp-114b4-default-rtdb.firebaseio.com', '/orders.json');
    try {
      final response = await http.get(url);
      final List<OrderItem> loadedOrders = [];
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData.isEmpty) {
        return;
      }
      extractedData.forEach((orderId, orderData) {
        loadedOrders.add(OrderItem(
          id: orderId,
          amount: orderData['amount'],
          products: (orderData['products'] as List<dynamic>)
              .map((item) => CartItem(
                    id: item['id'],
                    title: item['title'],
                    quantity: item['quantity'],
                    price: item['price'],
                  ))
              .toList(),
          dateTime: DateTime.parse(orderData['dateTime']),
        ));
      });
      _orders.clear();
      _orders.addAll(loadedOrders.reversed);
      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url =
        Uri.https('shopapp-114b4-default-rtdb.firebaseio.com', '/orders.json');
    final timeStamp = DateTime.now();
    final http.Response response;
    try {
      response = await http.post(
        url,
        body: json.encode({
          'amount': total,
          'products': cartProducts
              .map((cartItem) => {
                    'id': cartItem.id,
                    'title': cartItem.title,
                    'quantity': cartItem.quantity,
                    'price': cartItem.price,
                  })
              .toList(),
          'dateTime': timeStamp.toIso8601String(),
        }),
      );
    } catch (error) {
      rethrow;
    }

    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)['name'],
        amount: total,
        products: cartProducts,
        dateTime: timeStamp,
      ),
    );
    notifyListeners();
  }

  void clear() {
    _orders.clear();
    notifyListeners();
  }

  void removeOrder(String orderId) {
    _orders.removeWhere((order) => order.id == orderId);
    notifyListeners();
  }

  void clearOrders() {
    _orders.clear();
    notifyListeners();
  }

  void clearOrderItems(String orderId) {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    _orders[orderIndex].products.clear();
    notifyListeners();
  }

  void removeOrderItem(String orderId, String productId) {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    _orders[orderIndex]
        .products
        .removeWhere((product) => product.id == productId);
    notifyListeners();
  }

  void addOrderItem(String orderId, CartItem cartItem) {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    _orders[orderIndex].products.add(cartItem);
    notifyListeners();
  }

  void updateOrderItem(String orderId, CartItem cartItem) {
    final orderIndex = _orders.indexWhere((order) => order.id == orderId);
    final productIndex = _orders[orderIndex]
        .products
        .indexWhere((product) => product.id == cartItem.id);
    _orders[orderIndex].products[productIndex] = cartItem;
    notifyListeners();
  }
}
