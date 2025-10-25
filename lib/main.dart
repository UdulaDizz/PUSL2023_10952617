import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:collection';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart'; // Import for Input Formatters

const Color kPrimaryColor = Color(0xFF6F4E37);
const Color kBackgroundColor = Color(0xFFFDFCF8);
const Color kAccentColor = Color(0xFFD2B48C);
const Color kSecondaryAccent = Color(0xFFC08552);

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const CoffeeShopApp(),
    ),
  );
}

class CoffeeShopApp extends StatelessWidget {
  const CoffeeShopApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colombo Coffee House',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          iconTheme: IconThemeData(color: kPrimaryColor),
          titleTextStyle: TextStyle(
            color: kPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kAccentColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
      routes: {
        '/cart': (context) => const CartScreen(),
        '/payment': (context) => PaymentScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class Product {
  final int id;
  final String name;
  final double price;
  final String description;
  final String shortDesc;
  final String image;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.shortDesc,
    required this.image,
    required this.category,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class Order {
  final String id;
  final List<CartItem> items;

  Order({required this.id, required this.items});
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(
    0.0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );

  void addItem(Product product, [int quantity = 1]) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void updateItemQuantity(Product product, int change) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity += change;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}

class LoyaltyProvider extends ChangeNotifier {
  int _points = 35000;
  int get points => _points;

  void addPoints(int amount) {
    _points += amount;
    notifyListeners();
  }

  bool spendPoints(int amount) {
    if (_points >= amount) {
      _points -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }
}

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];

  UnmodifiableListView<Order> get orders => UnmodifiableListView(_orders);

  Order? findOrderById(String id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (e) {
      return null;
    }
  }

  String addOrder(List<CartItem> cartItems) {
    final String newId = (10000 + Random().nextInt(90000)).toString();

    final newOrder = Order(id: newId, items: List<CartItem>.from(cartItems));

    _orders.add(newOrder);
    notifyListeners();
    return newId;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    ServicesScreen(),
    PromotionsScreen(),
    OrderTrackingScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(10.0),
          child: Icon(Icons.coffee),
        ),
        title: Text(['Menu', 'Rewards', 'Track Order'][_selectedIndex]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/cart'),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 28),
                  Positioned(
                    top: 4,
                    right: 0,
                    child: Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        if (cart.itemCount == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: kSecondaryAccent,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cart.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showChatDialog(context),
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.chat_bubble_outline),
        tooltip: 'Live Chat',
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.coffee_outlined),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            label: 'Rewards',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Track Order',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 10,
        onTap: _onItemTapped,
      ),
    );
  }
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({Key? key}) : super(key: key);

  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static final List<Product> _products = [
    Product(
      id: 1,
      name: 'Caramel Macchiato',
      price: 750,
      description:
          'Rich espresso with vanilla-flavored syrup, steamed milk, and a caramel drizzle.',
      shortDesc: 'Sweet & creamy',
      image: '☕️',
      category: 'Hot Coffee',
    ),
    Product(
      id: 2,
      name: 'Iced Latte',
      price: 1250,
      description:
          'Chilled espresso mixed with milk and served over ice. A refreshing classic.',
      shortDesc: 'Cool & refreshing',
      image: '🧊',
      category: 'Iced Coffee',
    ),
    Product(
      id: 3,
      name: 'Butter Croissant',
      price: 950,
      description:
          'A buttery, flaky, viennoiserie pastry. Perfect with any coffee.',
      shortDesc: 'Buttery & flaky',
      image: '🥐',
      category: 'Pastries',
    ),
    Product(
      id: 4,
      name: 'Classic Cappuccino',
      price: 550,
      description:
          'Dark, rich espresso under a smoothed and stretched layer of thick milk foam.',
      shortDesc: 'Rich & foamy',
      image: '☕️',
      category: 'Hot Coffee',
    ),
    Product(
      id: 5,
      name: 'Cold Brew',
      price: 670,
      description:
          'Our custom blend, slow-steeped in cool water for 20 hours for a super-smooth flavour.',
      shortDesc: 'Strong & smooth',
      image: '🧊',
      category: 'Iced Coffee',
    ),
    Product(
      id: 6,
      name: 'Chocolate Muffin',
      price: 250,
      description:
          'A rich, moist chocolate muffin packed with chocolate chips.',
      shortDesc: 'Rich & chocolatey',
      image: '🧁',
      category: 'Pastries',
    ),
  ];

  final List<String> _categories = [
    'All',
    'Hot Coffee',
    'Iced Coffee',
    'Pastries',
  ];
  String _selectedCategory = 'All';

  Widget _buildCategoryChip(String category) {
    bool isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        selectedColor: kPrimaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : kPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: kPrimaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showProductDetail(context, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[200],
                child: Center(
                  child: Text(
                    product.image,
                    style: const TextStyle(fontSize: 50),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.shortDesc,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'LKR ${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor,
                        ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: kSecondaryAccent,
                        child: IconButton(
                          iconSize: 16,
                          splashRadius: 16,
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: () {
                            Provider.of<CartProvider>(
                              context,
                              listen: false,
                            ).addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} added to cart.'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: kPrimaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _selectedCategory == 'All'
        ? _products
        : _products.where((p) => p.category == _selectedCategory).toList();

    return Column(
      children: [
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _categories.length,
            itemBuilder: (context, index) =>
                _buildCategoryChip(_categories[index]),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredProducts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildProductCard(product, context);
            },
          ),
        ),
      ],
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  Widget _buildCartItemCard(CartItem item, BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                width: 70,
                height: 70,
                color: Colors.grey[200],
                child: Center(
                  child: Text(
                    item.product.image,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'LKR ${item.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 15, color: kPrimaryColor),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: kSecondaryAccent,
                  ),
                  onPressed: () => cart.updateItemQuantity(item.product, -1),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: kSecondaryAccent,
                  ),
                  onPressed: () => cart.updateItemQuantity(item.product, 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Order')),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _buildCartItemCard(item, context);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          'LKR ${cart.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/payment'),
                        child: const Text(
                          'Proceed to Payment',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  PaymentScreen({Key? key}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

enum PaymentMethod { none, card, wallet, loyalty }

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.none;
  final _formKey = GlobalKey<FormState>();

  void _onPaymentSuccess() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orders = Provider.of<OrderProvider>(context, listen: false);
    final loyalty = Provider.of<LoyaltyProvider>(context, listen: false);

    String newOrderId = orders.addOrder(List<CartItem>.from(cart.items));

    loyalty.addPoints(5);

    cart.clearCart();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(orderId: newOrderId),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    int points = Provider.of<LoyaltyProvider>(context).points;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Payment Method",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.credit_card, color: kPrimaryColor),
            title: const Text(
              "Credit / Debit Card",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _selectedMethod = PaymentMethod.card),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.account_balance_wallet_outlined,
              color: kPrimaryColor,
            ),
            title: const Text(
              "Digital Wallet",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text("Google Pay / Apple Pay"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _selectedMethod = PaymentMethod.wallet),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.star_outline, color: kPrimaryColor),
            title: const Text(
              "Use Loyalty Points",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text("Available: $points points"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                setState(() => _selectedMethod = PaymentMethod.loyalty),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            "Your payment is secure and encrypted.",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Cardholder Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter a name' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Card Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.credit_card),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              CardNumberInputFormatter(),
            ],
            validator: (value) {
              final pureValue = value?.replaceAll(' ', '');
              if (pureValue == null || pureValue.length != 16) {
                return 'Please enter a 16-digit card number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    ExpiryDateInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(value)) {
                      return 'Enter a valid MM/YY date';
                    }
                    final parts = value.split('/');
                    final month = int.tryParse(parts[0]);
                    final year = int.tryParse(parts[1]);
                    final now = DateTime.now();
                    final currentYearShort = now.year % 100;
                    if (month == null || year == null) {
                      return 'Invalid date';
                    }
                    if (year < currentYearShort ||
                        (year == currentYearShort && month < now.month)) {
                      return 'Card has expired';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'CVC',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) => value == null || value.length != 3
                      ? 'Enter a 3-digit CVC'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _onPaymentSuccess();
                }
              },
              child: const Text('Pay Now', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalWalletView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: kPrimaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            "Connecting to Digital Wallet...",
            style: TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              _onPaymentSuccess();
            },
            child: const Text('Simulate Successful Payment'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyWalletView() {
    double total = Provider.of<CartProvider>(context).totalPrice;
    int pointsNeeded = (total * 10).round();
    int currentPoints = Provider.of<LoyaltyProvider>(context).points;
    bool canPay = currentPoints >= pointsNeeded;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.star, size: 80, color: Colors.amber),
          const SizedBox(height: 20),
          Text(
            "Total Cost: $pointsNeeded Points",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            "Your Balance: $currentPoints Points",
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canPay ? Colors.green.shade600 : Colors.grey,
            ),
            onPressed: canPay
                ? () {
                    Provider.of<LoyaltyProvider>(
                      context,
                      listen: false,
                    ).spendPoints(pointsNeeded);
                    _onPaymentSuccess();
                  }
                : null,
            child: Text(
              canPay ? 'Pay with Points' : 'Not Enough Points',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedMethod) {
      case PaymentMethod.none:
        return _buildPaymentMethodSelector();
      case PaymentMethod.card:
        return SingleChildScrollView(child: _buildCreditCardForm());
      case PaymentMethod.wallet:
        return _buildDigitalWalletView();
      case PaymentMethod.loyalty:
        return _buildLoyaltyWalletView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Payment'),
        leading: _selectedMethod != PaymentMethod.none
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    setState(() => _selectedMethod = PaymentMethod.none),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildBody(),
        ),
      ),
    );
  }
}

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({Key? key}) : super(key: key);

  Widget _buildDealCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPunchCard() {
    const int totalPunches = 5;
    const int currentPunches = 3;

    List<Widget> punches = [];
    for (int i = 0; i < totalPunches; i++) {
      punches.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Icon(
            i < currentPunches ? Icons.coffee : Icons.coffee_outlined,
            color: i < currentPunches ? kPrimaryColor : Colors.grey[400],
            size: 35,
          ),
        ),
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buy 5, Get 1 Free!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: punches,
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$currentPunches of $totalPunches coffees purchased',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRedeemableItem(String title, String points, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kAccentColor.withOpacity(0.2),
          child: Icon(icon, color: kPrimaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$points points',
          style: const TextStyle(color: kSecondaryAccent),
        ),
        trailing: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: kSecondaryAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: const Text('Redeem'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor, kSecondaryAccent.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loyalty Points',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<LoyaltyProvider>(
                    builder: (context, loyalty, child) => Text(
                      '${loyalty.points}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Redeem for free drinks!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildPunchCard(),
          const SizedBox(height: 24),
          const Text(
            "Redeem Your Points",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRedeemableItem('Free Pastry', '50', Icons.bakery_dining),
          const SizedBox(height: 8),
          _buildRedeemableItem('Free Coffee (Any size)', '100', Icons.coffee),
          const SizedBox(height: 8),
          _buildRedeemableItem('25% Off Entire Order', '150', Icons.percent),
          const SizedBox(height: 24),
          const Text(
            "Today's Deals",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDealCard(
            'Happy Hour!',
            '50% off all iced drinks from 2 PM to 4 PM.',
            Icons.access_time,
            Colors.blue.shade400,
          ),
          const SizedBox(height: 12),
          _buildDealCard(
            'Pastry Combo',
            'Get a free croissant with any large hot coffee.',
            Icons.bakery_dining_outlined,
            Colors.orange.shade400,
          ),
          const SizedBox(height: 12),
          _buildDealCard(
            'Refer a Friend',
            'Get 50 points when your friend makes an order.',
            Icons.people_outline,
            Colors.green.shade400,
          ),
        ],
      ),
    );
  }
}

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({Key? key}) : super(key: key);

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final TextEditingController _orderIdController = TextEditingController();
  Order? _trackedOrder;
  int _currentStep = 0;
  Timer? _timer;
  bool _isLoading = false;
  bool _notFound = false;

  @override
  void dispose() {
    _orderIdController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _trackOrder() {
    final id = _orderIdController.text;
    if (id.isEmpty) return;

    _timer?.cancel();
    setState(() {
      _isLoading = true;
      _trackedOrder = null;
      _notFound = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      final orders = Provider.of<OrderProvider>(context, listen: false);
      final foundOrder = orders.findOrderById(id);

      if (foundOrder != null) {
        setState(() {
          _trackedOrder = foundOrder;
          _currentStep = 1;
          _isLoading = false;
        });
        _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
          setState(() {
            _currentStep++;
            if (_currentStep >= 4) {
              _timer?.cancel();
            }
          });
        });
      } else {
        setState(() {
          _trackedOrder = null;
          _notFound = true;
          _isLoading = false;
        });
      }
    });
  }

  Widget _buildTrackerStep(
    String title,
    String subtitle,
    IconData icon,
    int step,
  ) {
    bool isActive = _currentStep >= step;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? kPrimaryColor : Colors.grey[300],
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isActive ? kPrimaryColor : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.black54 : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackerLine(bool isActive) {
    return Container(
      height: 30,
      width: 2,
      color: isActive ? kPrimaryColor : Colors.grey[300],
      margin: const EdgeInsets.only(left: 19, top: 4, bottom: 4),
    );
  }

  Widget _buildTrackingContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notFound) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 60),
            SizedBox(height: 16),
            Text(
              "Order Not Found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Please check your order ID and try again.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_trackedOrder == null && !_notFound && !_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 60),
            SizedBox(height: 16),
            Text(
              "Enter your order ID to track its status.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_trackedOrder != null) {
      return ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Text(
            'Showing results for Order #${_trackedOrder!.id}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items in this order:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._trackedOrder!.items.map(
                    (item) => ListTile(
                      leading: Text(
                        item.product.image,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(item.product.name),
                      trailing: Text('Qty: ${item.quantity}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Status:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTrackerStep(
                    'Order Placed',
                    'We have received your order.',
                    Icons.check,
                    1,
                  ),
                  _buildTrackerLine(_currentStep >= 2),
                  _buildTrackerStep(
                    'Preparing',
                    'Your order is being prepared.',
                    Icons.coffee_maker_outlined,
                    2,
                  ),
                  _buildTrackerLine(_currentStep >= 3),
                  _buildTrackerStep(
                    'On The Way',
                    'Your order is on its way.',
                    Icons.delivery_dining_outlined,
                    3,
                  ),
                  _buildTrackerLine(_currentStep >= 4),
                  _buildTrackerStep(
                    'Delivered',
                    'Enjoy your coffee!',
                    Icons.home_outlined,
                    4,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final pastOrders = orderProvider.orders;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ListView(
        children: [
          if (pastOrders.isNotEmpty)
            const Text(
              "Your Past Orders",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          if (pastOrders.isNotEmpty) const SizedBox(height: 12),
          if (pastOrders.isNotEmpty)
            Column(
              children: pastOrders.map((order) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.receipt, color: kPrimaryColor),
                    title: Text(
                      'Order ID: #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${order.items.length} items'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _orderIdController.text = order.id;
                      _trackOrder();
                    },
                  ),
                );
              }).toList(),
            ),
          if (pastOrders.isNotEmpty) const SizedBox(height: 24),
          if (pastOrders.isNotEmpty)
            Row(
              children: [
                Expanded(child: Divider(color: Colors.grey[300])),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('OR', style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(color: Colors.grey[300])),
              ],
            ),
          if (pastOrders.isNotEmpty) const SizedBox(height: 24),
          const Text(
            "Track Your Order",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _orderIdController,
                  decoration: InputDecoration(
                    labelText: "Enter Order ID (e.g., 12345)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _trackOrder,
                icon: const Icon(Icons.search),
                style: IconButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildTrackingContent(),
          ),
        ],
      ),
    );
  }
}

// --- ADDED HELPER CLASSES FOR CARD FORMATTING ---

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write('  ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;

    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
// --- END OF HELPER CLASSES ---

void _showProductDetail(BuildContext context, Product product) {
  int quantity = 1;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 150,
                      height: 150,
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          product.image,
                          style: const TextStyle(fontSize: 70),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LKR ${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: kSecondaryAccent,
                          ),
                          onPressed: () => setModalState(() {
                            if (quantity > 1) quantity--;
                          }),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: kSecondaryAccent,
                          ),
                          onPressed: () => setModalState(() => quantity++),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      'Add $quantity to Cart',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Provider.of<CartProvider>(
                        context,
                        listen: false,
                      ).addItem(product, quantity);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$quantity ${product.name} added to cart.',
                          ),
                          duration: const Duration(seconds: 2),
                          backgroundColor: kPrimaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showChatDialog(BuildContext context) {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"sender": "support", "text": "Hi! How can we help you today?"},
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text("Live Chat"),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            height: 300,
            width: 300,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      bool isUser = _messages[index]['sender'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isUser
                                ? kAccentColor.withOpacity(0.8)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_messages[index]['text']!),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        decoration: InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (text) {
                          if (text.isNotEmpty) {
                            setState(() {
                              _messages.add({"sender": "user", "text": text});
                              _messages.add({
                                "sender": "support",
                                "text":
                                    "Thanks for your message! An agent will be with you shortly.",
                              });
                              _chatController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: kPrimaryColor),
                      onPressed: () {
                        final text = _chatController.text;
                        if (text.isNotEmpty) {
                          setState(() {
                            _messages.add({"sender": "user", "text": text});
                            _messages.add({
                              "sender": "support",
                              "text":
                                  "Thanks for your message! An agent will be with you shortly.",
                            });
                            _chatController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}

class ConfirmationScreen extends StatelessWidget {
  final String orderId;
  const ConfirmationScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade500, size: 100),
              const SizedBox(height: 24),
              const Text(
                'Order Confirmed!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Thank you for your purchase! You\'ve earned 5 loyalty points.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Text(
                'Your Order ID is:\n$orderId',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
