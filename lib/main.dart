import 'package:demo/repositories/user_repository.dart';
import 'package:demo/services/deep_link_service.dart';
import 'package:demo/view/reward/reward.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  DeepLinkService.instance?.handleDynamiclinks();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    Userrepository.instance.listenTocurrentAuth();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reward App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RewardWidget(),
    );
  }
}
