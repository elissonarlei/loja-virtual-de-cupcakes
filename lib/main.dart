import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String globalGenericCupcakeImageUrl = 'https://source.unsplash.com/600x800/?cupcake,dessert,sweet,food,bakery,colorful';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _database;
  static const String dbName = 'cupcake_store_v6.db';

  static const String cartStoreName = 'cart_items';
  static const String ordersStoreName = 'orders';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDocumentDir.path, dbName);
    final dbFactory = databaseFactoryIo;
    return await dbFactory.openDatabase(dbPath);
  }

  StoreRef<int, Map<String, dynamic>> get cartStore =>
      intMapStoreFactory.store(cartStoreName);

  StoreRef<String, Map<String, dynamic>> get ordersStore =>
      stringMapStoreFactory.store(ordersStoreName);
}
class Cupcake {
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final Map<String, String> nutritionalInfo;

  Cupcake({
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.nutritionalInfo,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'price': price,
    'imageUrl': imageUrl,
    'nutritionalInfo': nutritionalInfo,
  };

  factory Cupcake.fromJson(Map<String, dynamic> json) => Cupcake(
    name: json['name'] as String,
    description: json['description'] as String,
    price: (json['price'] as num).toDouble(),
    imageUrl: json['imageUrl'] as String,
    nutritionalInfo: Map<String, String>.from(json['nutritionalInfo'] as Map),
  );
}

class CartItem {
  final int dbKey;
  final Cupcake cupcake;

  CartItem({required this.dbKey, required this.cupcake});
}
class Order {
  final String id;
  final DateTime date;
  final String status;
  final String trackingCode;
  final List<Cupcake> items;

  Order({
    required this.id,
    required this.date,
    required this.status,
    required this.trackingCode,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'status': status,
    'trackingCode': trackingCode,
    'items': items.map((cupcake) => cupcake.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    status: json['status'] as String,
    trackingCode: json['trackingCode'] as String,
    items: (json['items'] as List<dynamic>)
        .map((itemJson) => Cupcake.fromJson(itemJson as Map<String, dynamic>))
        .toList(),
  );
}
class CartRepository {
  final DbHelper _dbHelper = DbHelper();

  Future<int> addToCart(Cupcake cupcake) async {
    final db = await _dbHelper.database;
    return await _dbHelper.cartStore.add(db, cupcake.toJson());
  }

  Future<List<CartItem>> getCartItems() async {
    final db = await _dbHelper.database;
    final snapshots = await _dbHelper.cartStore.find(db);
    return snapshots.map((snapshot) {
      return CartItem(
        dbKey: snapshot.key,
        cupcake: Cupcake.fromJson(snapshot.value),
      );
    }).toList();
  }

  Future<void> removeFromCart(int dbKey) async {
    final db = await _dbHelper.database;
    await _dbHelper.cartStore.record(dbKey).delete(db);
  }

  Future<void> clearCart() async {
    final db = await _dbHelper.database;
    await _dbHelper.cartStore.delete(db);
  }

  Future<List<Cupcake>> getCupcakesFromCartForOrder() async {
    final db = await _dbHelper.database;
    final snapshots = await _dbHelper.cartStore.find(db);
    return snapshots.map((snapshot) => Cupcake.fromJson(snapshot.value)).toList();
  }
}
class OrderRepository {
  final DbHelper _dbHelper = DbHelper();

  Future<void> addOrder(Order order) async {
    final db = await _dbHelper.database;
    await _dbHelper.ordersStore.record(order.id).put(db, order.toJson());
  }

  Future<List<Order>> getOrders() async {
    final db = await _dbHelper.database;
    final snapshots = await _dbHelper.ordersStore.find(db);
    List<Order> orders = snapshots.map((snapshot) => Order.fromJson(snapshot.value)).toList();
    orders.sort((a, b) => b.date.compareTo(a.date));
    return orders;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String initialRoute = isLoggedIn ? '/products' : '/login';
  runApp(MyApp(initialRoute: initialRoute));
}
class MyApp extends StatelessWidget {
  final String initialRoute;
  MyApp({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Loja de Cupcakes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green[900],
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(
        backgroundColor: Colors.green[900],
        elevation: 0,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    iconTheme: IconThemeData(color: Colors.white),
    ),
    drawerTheme: DrawerThemeData(
    backgroundColor: Colors.grey[900],
    ),
    textTheme: ThemeData.dark().textTheme.apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
    ).copyWith(
    titleLarge: TextStyle(color: Colors.green[300]),
    bodyMedium: TextStyle(height: 1.5),
    ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.green[300],
              textStyle: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[850],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.green[400]!),
            ),
            labelStyle: TextStyle(color: Colors.grey[400]),
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIconColor: Colors.green[400],
          ),
          cardTheme: CardTheme(
            elevation: 2,
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          ),
        ),
      initialRoute: this.initialRoute,
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/products': (context) => ProductsPage(),
        '/cart': (context) => CartPage(),
        '/payment': (context) => PaymentPage(),
        '/finalizeOrder': (context) => FinalizeOrderPage(),
        '/orders': (context) => OrdersPage(),
      },
    );
  }
}

class CustomScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? fabLocation;
  final bool showNavigationElements;

  CustomScaffold({
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.fabLocation,
    this.showNavigationElements = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: showNavigationElements ? Drawer(
        child: ListView(
        padding: EdgeInsets.zero,
        children: [
        DrawerHeader(
        decoration: BoxDecoration(
        gradient: LinearGradient(
        colors: [Colors.green[700]!, Colors.green[900]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
    ),
    ),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Icon(Icons.bakery_dining, color: Colors.white, size: 40),
    SizedBox(height: 8),
    Text(
    'Menu Cupcake Store',
    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    ),
    ],
    )
    ),
    _buildDrawerItem(context, Icons.store, "Produtos", '/products', replace: true),
    _buildDrawerItem(context, Icons.shopping_cart, "Carrinho", '/cart'),
    _buildDrawerItem(context, Icons.assignment, "Meus Pedidos", '/orders'),
    Divider(color: Colors.grey[700]),
    _buildDrawerItem(context, Icons.exit_to_app, "Sair (Login)", '/login', replace: true, isLogout: true),
    ],
    ),
    ) : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Loja Virtual de Cupcakes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.9)),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: showNavigationElements,
        actions: showNavigationElements ? [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined),
            tooltip: "Ver Carrinho",
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ] : null,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[700]!, Colors.green[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: fabLocation,
      bottomNavigationBar: Container(
        color: Colors.green[900]?.withOpacity(0.8),
        padding: EdgeInsets.all(12.0),
        child: Text(
          '© ${DateTime.now().year} Loja de Cupcakes. Todos os direitos reservados.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, String routeName, {bool replace = false, bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () async {
        Navigator.pop(context);

        if (isLogout) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', false);

          // ignore: use_build_context_synchronously
          Future.delayed(Duration.zero, () {
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(context, '/login', (Route<dynamic> route) => false);
          });
        } else {
          // ignore: use_build_context_synchronously
          Future.delayed(Duration.zero, () {
            if (!context.mounted) return;
            final String? currentRouteName = ModalRoute.of(context)?.settings.name;
            if (replace) {
              Navigator.pushReplacementNamed(context, routeName);
            } else {
              if (currentRouteName != routeName) {
                Navigator.pushNamed(context, routeName);
              }
            }
          });
        }
      },
    );
  }
}
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(text: "cliente@email.com");
  final TextEditingController _passwordController = TextEditingController(text: "123456");

  void _login() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login realizado com sucesso! Bem-vindo(a)!'), backgroundColor: Colors.green[700]),
      );
      Navigator.pushReplacementNamed(context, '/products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Acesse sua Conta',
      showNavigationElements: false,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.bakery_dining_outlined, size: 80, color: Colors.green[400]),
                  SizedBox(height: 20),
                  Text(
                    "Bem-vindo à Cupcake Store!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30.0),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu email';
                      if (!value.contains('@') || !value.contains('.')) return 'Email inválido';
                      return null;
                    },
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe sua senha';
                      if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                      return null;
                    },
                  ),
                  SizedBox(height: 30.0),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('Entrar'),
                  ),
                  SizedBox(height: 15.0),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: Text('Não tem conta? Cadastre-se aqui'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}
class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _register() {
    if (_formKey.currentState!.validate()){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cadastro realizado com sucesso! Faça login para continuar.'), backgroundColor: Colors.green[700]),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Crie sua Conta',
      showNavigationElements: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 450),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Novo por aqui? É rapidinho!",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: 'Nome Completo', prefixIcon: Icon(Icons.person_outline)),
                  validator: (value) => value!.isEmpty ? 'Informe seu nome completo' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Informe seu email';
                      if (!value.contains('@') || !value.contains('.')) return 'Email inválido';
                      return null;
                    }
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Informe uma senha';
                    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirmar Senha', prefixIcon: Icon(Icons.lock_person_outlined)),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirme sua senha';
                    if (value != _passwordController.text) return 'As senhas não coincidem';
                    return null;
                  },
                ),
                SizedBox(height: 30.0),
                ElevatedButton(
                  onPressed: _register,
                  child: Text('Cadastrar'),
                ),
                SizedBox(height: 15.0),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Já tenho uma conta. Fazer Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class ProductsPage extends StatelessWidget {
  final CartRepository _cartRepository = CartRepository();

  final List<Cupcake> products = [
  Cupcake(
  name: 'Cupcake de Chocolate Belga',
  description: 'Intenso e cremoso, com gotas de chocolate belga.',
  price: 7.50,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {
  "Calorias": "320 kcal", "Carboidratos": "40 g", "Proteína": "6 g", "Gorduras Totais": "18 g",
  "Gorduras Saturadas": "10 g", "Fibra": "3 g", "Sódio": "190 mg", "Açúcares": "25 g",
  },
  ),
  Cupcake(
  name: 'Cupcake de Baunilha com Framboesa',
  description: 'Leve massa de baunilha com recheio e cobertura de framboesa fresca.',
  price: 6.90,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {
  "Calorias": "280 kcal", "Carboidratos": "35 g", "Proteína": "5 g", "Gorduras Totais": "14 g",
  "Gorduras Saturadas": "7 g", "Fibra": "2 g", "Sódio": "160 mg", "Açúcares": "20 g",
  },
  ),
  Cupcake(
  name: 'Cupcake Red Velvet Clássico',
  description: 'Aveludado, com tradicional cream cheese frosting.',
  price: 8.00,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {
  "Calorias": "350 kcal", "Carboidratos": "42 g", "Proteína": "5 g", "Gorduras Totais": "20 g",
  "Gorduras Saturadas": "12 g", "Fibra": "1 g", "Sódio": "220 mg", "Açúcares": "28 g",
  },
  ),
  Cupcake(
  name: 'Cupcake de Limão Siciliano',
  description: 'Refrescante, com raspas de limão e merengue tostado.',
  price: 7.00,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {
  "Calorias": "290 kcal", "Carboidratos": "38 g", "Proteína": "4 g", "Gorduras Totais": "15 g",
  "Gorduras Saturadas": "8 g", "Fibra": "1 g", "Sódio": "150 mg", "Açúcares": "22 g",
  },
  ),
  Cupcake(
  name: 'Cupcake de Cenoura com Nozes',
  description: 'Fofinho, com especiarias, nozes e cobertura de cream cheese.',
  price: 7.20,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {
  "Calorias": "330 kcal", "Carboidratos": "39 g", "Proteína": "6 g", "Gorduras Totais": "18 g",
  "Gorduras Saturadas": "9 g", "Fibra": "3 g", "Sódio": "200 mg", "Açúcares": "24 g",
  },
  ),
  Cupcake(
  name: 'Cupcake de Doce de Leite Argentino',
  description: 'Massa suave com generoso recheio e cobertura de doce de leite.',
  price: 7.80,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {
  "Calorias": "360 kcal", "Carboidratos": "45 g", "Proteína": "7 g", "Gorduras Totais": "19 g",
  "Gorduras Saturadas": "11 g", "Fibra": "1 g", "Sódio": "180 mg", "Açúcares": "30 g",
  },
  ),
  Cupcake(
  name: 'Cupcake Oreo Supreme',
  description: 'Massa de chocolate com pedaços de Oreo e creme de baunilha.',
  price: 7.50,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {"Calorias": "340 kcal", "Carboidratos": "43 g", "Proteína": "5 g", "Gorduras Totais": "18 g", "Açúcares": "27 g"}),
  Cupcake(
  name: 'Cupcake de Coco Queimado',
  description: 'Sabor intenso de coco queimado com recheio cremoso.',
  price: 6.80,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {"Calorias": "310 kcal", "Carboidratos": "39 g", "Proteína": "4 g", "Gorduras Totais": "16 g", "Açúcares": "23 g"}),
  Cupcake(
  name: 'Cupcake de Maracujá com Chocolate Branco',
  description: 'Contraste perfeito entre o azedinho do maracujá e a doçura do chocolate branco.',
  price: 7.90,
  imageUrl: globalGenericCupcakeImageUrl,
  nutritionalInfo: {"Calorias": "330 kcal", "Carboidratos": "41 g", "Proteína": "5 g", "Gorduras Totais": "17 g", "Açúcares": "26 g"}),
    Cupcake(
        name: 'Cupcake de Café Mocha',
        description: 'Para os amantes de café, com toque de chocolate e chantilly de café.',
        price: 7.20,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "300 kcal", "Carboidratos": "37 g", "Proteína": "5 g", "Gorduras Totais": "16 g", "Açúcares": "22 g"}),
    Cupcake(
        name: 'Cupcake de Pistache com Flor de Sal',
        description: 'Sabor sofisticado de pistache com um toque de flor de sal.',
        price: 8.50,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "350 kcal", "Carboidratos": "40 g", "Proteína": "7 g", "Gorduras Totais": "20 g", "Açúcares": "24 g"}),
    Cupcake(
        name: 'Cupcake de Amendoim Crocante',
        description: 'Com pasta de amendoim, pedaços crocantes e cobertura de chocolate.',
        price: 7.00,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "340 kcal", "Carboidratos": "40 g", "Proteína": "8 g", "Gorduras Totais": "19 g", "Açúcares": "23 g"}),
    Cupcake(
        name: 'Cupcake Romeu e Julieta',
        description: 'Clássica combinação de queijo com goiabada cremosa.',
        price: 6.90,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "320 kcal", "Carboidratos": "42 g", "Proteína": "6 g", "Gorduras Totais": "16 g", "Açúcares": "28 g"}),
    Cupcake(
        name: 'Cupcake de Frutas Vermelhas Silvestres',
        description: 'Mix de amora, mirtilo e framboesa com massa leve.',
        price: 8.20,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "290 kcal", "Carboidratos": "38 g", "Proteína": "4 g", "Gorduras Totais": "14 g", "Açúcares": "23 g"}),
    Cupcake(
        name: 'Cupcake de Banana com Canela e Crumble',
        description: 'Massa de banana, toque de canela e topo crocante de crumble.',
        price: 7.30,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "330 kcal", "Carboidratos": "44 g", "Proteína": "5 g", "Gorduras Totais": "17 g", "Açúcares": "27 g"}),
    Cupcake(
        name: 'Cupcake de Menta com Chocolate Amargo',
        description: 'Refrescância da menta com a intensidade do chocolate amargo.',
        price: 7.60,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "310 kcal", "Carboidratos": "39 g", "Proteína": "5 g", "Gorduras Totais": "17 g", "Açúcares": "24 g"}),
    Cupcake(
        name: 'Cupcake Vegano de Chocolate e Abacate',
        description: 'Delicioso e cremoso, feito com abacate no lugar da manteiga.',
        price: 8.80,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "300 kcal", "Carboidratos": "38 g", "Proteína": "4 g", "Gorduras Totais": "16 g", "Açúcares": "20 g"}),
    Cupcake(
        name: 'Cupcake de Abóbora com Especiarias',
        description: 'Sazonal e aconchegante, com mix de especiarias (cravo, canela, noz-moscada).',
        price: 7.00,
        imageUrl: globalGenericCupcakeImageUrl,
        nutritionalInfo: {"Calorias": "310 kcal", "Carboidratos": "40 g", "Proteína": "5 g", "Gorduras Totais": "16 g", "Açúcares": "25 g"}),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Nossos Cupcakes Incríveis',
      body: GridView.builder(
        padding: EdgeInsets.all(10.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final cupcake = products.elementAt(index);
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProductDetailPage(cupcake: cupcake)),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Image.network(
                      globalGenericCupcakeImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.green[300],
                            strokeWidth: 2.0,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bakery_dining_outlined, size: 40, color: Colors.grey[600]),
                            ],
                          )
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            cupcake.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'R\$ ${cupcake.price.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.green[300]),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.add_shopping_cart, size: 18),
                              label: Text('Comprar', style: TextStyle(fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                backgroundColor: Colors.green[600],
                              ),
                              onPressed: () async {
                                await _cartRepository.addToCart(cupcake);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${cupcake.name} foi adicionado ao carrinho!'),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.green[800],
                                    behavior: SnackBarBehavior.floating,
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
            ),
          );
        },
      ),
    );
  }
}
class ProductDetailPage extends StatelessWidget {
  final Cupcake cupcake;
  final CartRepository _cartRepository = CartRepository();

  ProductDetailPage({required this.cupcake});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: cupcake.name,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16,16,16,80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: globalGenericCupcakeImageUrl + cupcake.name,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.network(
                    globalGenericCupcakeImageUrl,
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: MediaQuery.of(context).size.width * 0.7,
                    fit: BoxFit.cover,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.green[300],
                            strokeWidth: 2.0,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        child: Center(child: Icon(Icons.cake, size: 100, color: Colors.grey[600]))
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24.0),
            Text(
              cupcake.name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.green[300], fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.0),
            Text(
              'R\$ ${cupcake.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16.0),
            Text(
              cupcake.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70, height: 1.6),
            ),
            SizedBox(height: 24.0),
            _buildSectionTitle(context, 'Especificações Gerais'),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: Text(
                '- Ingredientes base: Farinha, Açúcar, Ovos, Leite, Fermento (variações conforme sabor).\n'
                    '- Peso aproximado: 120g - 150g por unidade.\n'
                    '- Validade: 3 dias (refrigerado), ideal consumir em 24h.\n'
                    '- Alergênicos: Pode conter glúten, lactose, ovos, nozes (verificar por sabor).\n'
                    '- Embalagem: Caixa individual protetora e personalizada.',
                style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.5),
              ),
            ),
            SizedBox(height: 24.0),
            _buildSectionTitle(context, 'Tabela Nutricional (Valores Aproximados por Unidade)'),
            Container(
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: MaterialStateProperty.all(Colors.grey[800]),
                columns: [
                  DataColumn(label: Text("Nutriente", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  DataColumn(label: Text("Valor", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                ],
                rows: cupcake.nutritionalInfo.entries.map((entry) {
                  return DataRow(
                    cells: [
                      DataCell(Text(entry.key, style: TextStyle(color: Colors.white70))),
                      DataCell(Text(entry.value, style: TextStyle(color: Colors.white70))),
                    ],
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 30.0),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.add_shopping_cart),
                label: Text('Adicionar ao Carrinho'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: () async {
                  await _cartRepository.addToCart(cupcake);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${cupcake.name} adicionado ao carrinho!'),
                      backgroundColor: Colors.green[800],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green[400], fontWeight: FontWeight.w600),
    );
  }
}

class CartPage extends StatefulWidget {
  @override
  _CartPageState createState() => _CartPageState();
}
class _CartPageState extends State<CartPage> {
  final CartRepository _cartRepository = CartRepository();
  late Future<List<CartItem>> _cartItemsFuture;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  void _loadCartItems() {
    setState(() {
      _cartItemsFuture = _cartRepository.getCartItems();
    });
  }

  double _calculateTotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.cupcake.price);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Seu Carrinho de Compras',
      body: FutureBuilder<List<CartItem>>(
        future: _cartItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.green[400]));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar o carrinho: ${snapshot.error}', style: TextStyle(color: Colors.red[300])));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_checkout_outlined, size: 100, color: Colors.grey[600]),
                  SizedBox(height: 20),
                  Text('Seu carrinho está vazio.', style: TextStyle(fontSize: 20, color: Colors.grey[500])),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.storefront_outlined),
                    label: Text("Explorar Produtos"),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/products'),
                  )
                ],
              ),
            );
          }

          final cartItems = snapshot.data!;
          final total = _calculateTotal(cartItems);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartItems[index];
                    final cupcake = cartItem.cupcake;
                    return Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6.0),
                          child: Image.network(
                            globalGenericCupcakeImageUrl,
                            width: 60, height: 60, fit: BoxFit.cover,
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(width:60, height:60, child: Center(child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.green[300])));
                            },
                            errorBuilder: (context, error, stackTrace) => Container(width:60, height:60, child: Icon(Icons.cake, size: 40, color: Colors.grey[500])),
                          ),
                        ),
                        title: Text(cupcake.name, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('R\$ ${cupcake.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.green[300])),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                          tooltip: "Remover do carrinho",
                          onPressed: () async {
                            await _cartRepository.removeFromCart(cartItem.dbKey);
                            _loadCartItems();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${cupcake.name} removido.'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), spreadRadius: 0, blurRadius: 5, offset: Offset(0,-2))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70)),
                        Text('R\$ ${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[300])),
                      ],
                    ),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      icon: Icon(Icons.payment_outlined),
                      label: Text('Prosseguir para Pagamento'),
                      style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                      onPressed: total > 0 ? () => Navigator.pushNamed(context, '/payment') : null,
                    ),
                    if (cartItems.isNotEmpty) SizedBox(height: 8),
                    if (cartItems.isNotEmpty)
                      TextButton.icon(
                        icon: Icon(Icons.remove_shopping_cart_outlined, size: 20),
                        label: Text('Limpar Carrinho'),
                        style: TextButton.styleFrom(foregroundColor: Colors.orange[400]),
                        onPressed: () async {
                          final confirm = await _showConfirmationDialog(context, 'Limpar Carrinho?', 'Deseja remover todos os itens do carrinho?');
                          if (confirm == true) {
                            await _cartRepository.clearCart();
                            _loadCartItems();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Carrinho esvaziado.'), backgroundColor: Colors.orange[700], behavior: SnackBarBehavior.floating),
                            );
                          }
                        },
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
  Future<bool?> _showConfirmationDialog(BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text(title, style: TextStyle(color: Colors.white)),
          content: Text(content, style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(child: Text('Cancelar', style: TextStyle(color: Colors.grey[400])), onPressed: () => Navigator.of(ctx).pop(false)),
            TextButton(child: Text('Confirmar', style: TextStyle(color: Colors.red[300])), onPressed: () => Navigator.of(ctx).pop(true)),
          ],
        );
      },
    );
  }
}

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}
class _PaymentPageState extends State<PaymentPage> {
  String? _selectedPayment;
  final List<Map<String, dynamic>> paymentOptions = [
    {'name': 'PIX', 'icon': Icons.qr_code_2_outlined},
    {'name': 'Boleto Bancário', 'icon': Icons.description_outlined},
    {'name': 'Cartão de Crédito', 'icon': Icons.credit_card_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Escolha o Pagamento',
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Como você gostaria de pagar?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green[300], fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),
            Expanded(
              child: ListView(
                children: paymentOptions.map((option) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 7.0),
                    child: RadioListTile<String>(
                      title: Text(option['name'] as String, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      value: option['name'] as String,
                      groupValue: _selectedPayment,
                      secondary: Icon(option['icon'] as IconData, color: Colors.green[400], size: 28),
                      onChanged: (value) => setState(() => _selectedPayment = value),
                      activeColor: Colors.green[400],
                      controlAffinity: ListTileControlAffinity.trailing,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.local_shipping_outlined),
              label: Text('Informar Endereço de Entrega'),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              onPressed: _selectedPayment == null
                  ? null
                  : () => Navigator.pushNamed(context, '/finalizeOrder'),
            ),
          ],
        ),
      ),
    );
  }
}

class FinalizeOrderPage extends StatefulWidget {
  @override
  _FinalizeOrderPageState createState() => _FinalizeOrderPageState();
}
class _FinalizeOrderPageState extends State<FinalizeOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final CartRepository _cartRepository = CartRepository();
  final OrderRepository _orderRepository = OrderRepository();

  final TextEditingController _addressController = TextEditingController(text: "Rua dos Cupcakes Felizes");
  final TextEditingController _numberController = TextEditingController(text: "123");
  final TextEditingController _complementController = TextEditingController(text: "Casa B, Fundos");
  final TextEditingController _neighborhoodController = TextEditingController(text: "Bairro Doce");
  final TextEditingController _cityController = TextEditingController(text: "Cidade dos Sonhos");
  final TextEditingController _stateController = TextEditingController(text: "SP");
  final TextEditingController _cepController = TextEditingController(text: "12345-678");
  final TextEditingController _referenceController = TextEditingController(text: "Próximo à padaria");

  bool _isLoading = false;

  void _confirmOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        List<Cupcake> cartCupcakes = await _cartRepository.getCupcakesFromCartForOrder();
        if (cartCupcakes.isEmpty) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Carrinho vazio. Adicione itens para continuar.'), backgroundColor: Colors.orange[700], behavior: SnackBarBehavior.floating),
          );
          setState(() => _isLoading = false);
          if (!context.mounted) return;
          Navigator.popUntil(context, ModalRoute.withName('/products'));
          return;
        }

        Order newOrder = Order(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          status: "Em Processamento",
          trackingCode: "CPK${DateTime.now().second}${DateTime.now().millisecond}",
          items: List.from(cartCupcakes),
        );

        await _orderRepository.addOrder(newOrder);
        await _cartRepository.clearCart();

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido #${newOrder.id.substring(newOrder.id.length-6)} realizado! Obrigado!'), backgroundColor: Colors.green[700], behavior: SnackBarBehavior.floating),
        );
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/orders', ModalRoute.withName('/products'));

      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ops! Erro ao confirmar pedido: ${e.toString()}'), backgroundColor: Colors.red[700], behavior: SnackBarBehavior.floating),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios.'), backgroundColor: Colors.orange[700], behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Endereço de Entrega',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Onde entregaremos suas delícias?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.green[300], fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 25),
              _buildTextFormField(_cepController, 'CEP', Icons.markunread_mailbox_outlined, (v) {
                if (v == null || v.isEmpty) return 'Informe o CEP';
                if (!RegExp(r'^\d{5}-?\d{3}$').hasMatch(v)) return 'CEP inválido (Formato: XXXXX-XXX ou XXXXXXXX)';
                return null;
              }, TextInputType.number),
              _buildTextFormField(_addressController, 'Endereço (Rua, Avenida)', Icons.home_work_outlined, (v) => v!.isEmpty ? 'Informe o endereço' : null),
              Row(children: [
                Expanded(child: _buildTextFormField(_numberController, 'Número', Icons.pin_outlined, (v) => v!.isEmpty ? 'Informe o número' : null, TextInputType.number)),
                SizedBox(width: 10),
                Expanded(child: _buildTextFormField(_complementController, 'Complemento', Icons.add_road_outlined)),
              ]),
              _buildTextFormField(_neighborhoodController, 'Bairro', Icons.location_city_outlined, (v) => v!.isEmpty ? 'Informe o bairro' : null),
              Row(children: [
                Expanded(child: _buildTextFormField(_cityController, 'Cidade', Icons.map_outlined, (v) => v!.isEmpty ? 'Informe a cidade' : null)),
                SizedBox(width: 10),
                SizedBox(width: 100, child: _buildTextFormField(_stateController, 'UF', Icons.public_outlined, (v) => v!.isEmpty ? 'UF' : null)),
              ]),
              _buildTextFormField(_referenceController, 'Ponto de Referência (Opcional)', Icons.help_outline),
              SizedBox(height: 30),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.green[400]))
                  : ElevatedButton.icon(
                icon: Icon(Icons.check_circle_outline),
                label: Text('Finalizar e Confirmar Pedido'),
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
                onPressed: _confirmOrder,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, IconData icon, [String? Function(String?)? validator, TextInputType? keyboardType]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}
class _OrdersPageState extends State<OrdersPage> {
  final OrderRepository _orderRepository = OrderRepository();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = _orderRepository.getOrders();
    });
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('processamento')) return Colors.orange[400]!;
    if (status.contains('enviado')) return Colors.blue[400]!;
    if (status.contains('entregue')) return Colors.green[400]!;
    if (status.contains('cancelado')) return Colors.red[400]!;
    return Colors.grey[400]!;
  }

  IconData _getStatusIcon(String status) {
    status = status.toLowerCase();
    if (status.contains('processamento')) return Icons.hourglass_top_outlined;
    if (status.contains('enviado')) return Icons.local_shipping_outlined;
    if (status.contains('entregue')) return Icons.check_circle_outline;
    if (status.contains('cancelado')) return Icons.cancel_outlined;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Histórico de Pedidos',
      body: RefreshIndicator(
        onRefresh: () async => _loadOrders(),
        color: Colors.green[400],
        backgroundColor: Colors.grey[850],
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Colors.green[400]));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar pedidos: ${snapshot.error}', style: TextStyle(color: Colors.red[300])));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 100, color: Colors.grey[600]),
                      SizedBox(height: 20),
                      Text('Nenhum pedido encontrado.', style: TextStyle(fontSize: 20, color: Colors.grey[500])),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add_shopping_cart_outlined),
                        label: Text("Fazer meu primeiro pedido"),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/products'),
                      )
                    ],
                  )
              );
            }

            final orders = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                Order order = orders[index];
                String formattedDate = "${order.date.day.toString().padLeft(2,'0')}/${order.date.month.toString().padLeft(2,'0')}/${order.date.year}";
                String formattedTime = "${order.date.hour.toString().padLeft(2,'0')}:${order.date.minute.toString().padLeft(2,'0')}";

                return Card(
                  child: ExpansionTile(
                    leading: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status), size: 30),
                    title: Text('Pedido #${order.id.substring(order.id.length-6)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text('$formattedDate às $formattedTime', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    trailing: Text(
                      'R\$ ${order.items.fold(0.0, (sum, item) => sum + item.price).toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.green[300], fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0).copyWith(top:0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: Colors.grey[700]),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Status:', style: TextStyle(color: Colors.white70)),
                                Text(order.status, style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.w500)),
                              ],
                            ),
                            SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rastreio:', style: TextStyle(color: Colors.white70)),
                                Text(order.trackingCode, style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text('Itens (${order.items.length}):', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                            SizedBox(height: 6),
                            ...order.items.map((cupcake) => Padding(
                              padding: const EdgeInsets.only(left:8.0, bottom: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("- ${cupcake.name}", style: TextStyle(fontSize: 13, color: Colors.white70)),
                                  Text("R\$ ${cupcake.price.toStringAsFixed(2)}", style: TextStyle(fontSize: 13, color: Colors.white70)),
                                ],
                              ),
                            )).toList(),
                            SizedBox(height: 8),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}