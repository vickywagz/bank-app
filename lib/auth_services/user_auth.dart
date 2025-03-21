import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  double _balance = 0.0;

  User? get user => _user;
  double get balance => _balance;

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();

      if (user != null) {
        _listenToBalance(user.uid);
        _saveFCMToken(); // Save token when auth state changes
        listenForFCMTokenChanges(); // Listen for token updates
      }
    });
  }

  void listenForFCMTokenChanges() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      if (_user != null) {
        _firestore.collection('users').doc(_user!.uid).update({
          'fcmToken': newToken,
        });
      }
    });
  }

  void _listenToBalance(String userId) {
    _firestore.collection('users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        _balance = snapshot.data()?['balance'] ?? 0.0;
        notifyListeners();
      }
    });
  }

  Future<void> sendPushNotification(
      String token, String sender, double amount) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'key=YOUR_SERVER_KEY', // Replace with your Firebase server key
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': 'New Transaction Received!',
            'body': '$sender sent you \$${amount.toStringAsFixed(2)}',
          },
          'priority': 'high',
        }),
      );
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }

  Future<void> _saveFCMToken() async {
    if (_user == null) return;

    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(_user!.uid).update({
        'fcmToken': token,
      });
    }
  }

  Future<String> transferMoney(String receiverEmail, double amount) async {
    if (_user == null) return "User not logged in";

    //Get senders document
    DocumentReference senderRef =
        _firestore.collection('users').doc(_user!.uid);

    //Find receiver by email
    QuerySnapshot userQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: receiverEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return "Reeiver not found";

    DocumentSnapshot receiverDoc = userQuery.docs.first;
    DocumentReference receiverRef = userQuery.docs.first.reference;

    String? receiverToken = receiverDoc['fcmToken'];
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot senderSnap = await transaction.get(senderRef);
      DocumentSnapshot receiverSnap = await transaction.get(receiverRef);

      double senderBalance = senderSnap['balance'] ?? 0.0;
      double receiverBalance = receiverSnap['balance'] ?? 0.0;

      if (senderBalance < amount) {
        return "Insufficient balance";
      }

      //Update balance
      transaction.update(senderRef, {'balance': senderBalance - amount});
      transaction.update(receiverRef, {'balance': receiverBalance + amount});

      //save transaction record
      _firestore.collection('transactions').add({
        'sender': _user!.email,
        'receiver': receiverEmail,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
      return "Transaction Successful";
    });
  }

  Future<String?> signUp(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await credential.user?.sendEmailVerification();

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({'email': email, 'balance': 100000.0});

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
