import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const CashflowEscapeApp());
}

class CashflowEscapeApp extends StatelessWidget {
  const CashflowEscapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cashflow Escape',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.green[900],
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int cash = 3500;
  int salary = 4500;
  int expenses = 3200;
  int passiveIncome = 0;
  int turn = 1;
  String status = "Rat Race";
  List<String> assets = [];
  List<String> liabilities = ["Mortgage \$2400", "Car Loan \$380"];

  // Cards
  final List<Map<String, dynamic>> cards = [
    {'name': '3-Plex Rental', 'cost': 50000, 'income': 800, 'desc': '+800 passive/mo'},
    {'name': 'Stocks', 'cost': 10000, 'income': 200, 'desc': '+200 dividends/mo'},
    {'name': 'New Boat', 'cost': 12000, 'income': 0, 'desc': '-12k cash (doodad)'},
    {'name': 'Business Deal', 'cost': 20000, 'income': 1500, 'desc': '+1.5k passive/mo'},
    {'name': 'Vacation', 'cost': 5000, 'income': 0, 'desc': '-5k cash (doodad)'},
  ];

  // Ads (test IDs)
  RewardedAd? _rewardedAd;
  BannerAd? _bannerAd;
  bool adsRemoved = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  void _loadAds() {
    RewardedAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/5224354917',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => setState(() => _rewardedAd = ad),
        onAdFailedToLoad: (err) => print(err),
      ),
    );

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(),
    )..load();
  }

  void _showRandomCard() {
    final card = cards[Random().nextInt(cards.length)];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: card['income'] > 0 ? Colors.green[800] : Colors.red[800],
        title: Text(card['name']),
        content: Text(card['desc']),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                cash -= card['cost'];
                passiveIncome += card['income'];
                if (card['income'] > 0) assets.add(card['name']);
                Navigator.pop(context);
              });
            },
            child: const Text("Buy/Do"),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Pass")),
        ],
      ),
    );
  }

  void rollDice() {
    if (_rewardedAd != null && !adsRemoved && turn % 2 == 0) {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        setState(() => cash += 5000);
      });
      _rewardedAd = null;
      _loadAds();
    }

    setState(() {
      cash += salary + passiveIncome - expenses;
      turn++;
      if (turn % 3 == 0) _showRandomCard();
      if (passiveIncome > expenses) {
        status = "FAST TRACK! 🏆";
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.amber[800],
            title: const Text("YOU ESCAPED THE RAT RACE! 🎉"),
            content: Text("Passive \$ $passiveIncome > Expenses \$ $expenses"),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Play Again"))],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cashflow Escape"), actions: [
        IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () {}),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Turn $turn | Status: $status", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _card("Cash", "\$$cash", Colors.blue),
              _card("Salary", "\$$salary", Colors.green),
            ]),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _card("Expenses", "\$$expenses", Colors.red),
              _card("Passive", "\$$passiveIncome", Colors.amber),
            ]),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 40),
              label: const Text("ROLL & COLLECT", style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber[700], padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20)),
              onPressed: rollDice,
            ),
            if (_bannerAd != null && !adsRemoved)
              Container(margin: const EdgeInsets.only(top: 20), height: 50, child: AdWidget(ad: _bannerAd!)),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [Text(title), Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))]),
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }
}
