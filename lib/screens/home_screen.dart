import 'package:bank_app/auth_services/user_auth.dart';
import 'package:bank_app/screens/transfer_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
              onPressed: () => authProvider.signOut(),
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Welcome ${authProvider.user?.email}",
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 20),
          Text(
            "Balance: ₦${authProvider.balance.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => TransferScreen()));
            },
            child: const Text("Transfer Money"),
          ),
        ],
      )),
    );
  }
}
