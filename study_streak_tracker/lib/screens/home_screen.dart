import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;

  int currentStreak = 0;
  DateTime? lastCheckIn;

  @override
  void initState() {
    super.initState();
    fetchUserStreak();
  }

  // Fetch the user's current streak data
  Future<void> fetchUserStreak() async {
    final doc = await firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        currentStreak = data['streak'] ?? 0;
        final timestamp = data['lastCheckIn'] as Timestamp?;
        lastCheckIn = timestamp?.toDate();
      });
    }
  }

  // Handle check-in logic
  Future<void> handleCheckIn() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // If already checked in today
    if (lastCheckIn != null &&
        DateTime(lastCheckIn!.year, lastCheckIn!.month, lastCheckIn!.day)
            == today) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You already checked in today!')),
      );
      return;
    }

    int newStreak = 1;
    if (lastCheckIn != null &&
        DateTime(lastCheckIn!.year, lastCheckIn!.month, lastCheckIn!.day)
            == yesterday) {
      newStreak = currentStreak + 1;
    }

    // Save to Firestore
    await firestore.collection('users').doc(user.uid).set({
      'streak': newStreak,
      'lastCheckIn': Timestamp.fromDate(today),
    });

    // Update local state
    setState(() {
      currentStreak = newStreak;
      lastCheckIn = today;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Great! Streak updated.')),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Streak Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔥 Current Streak', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text('$currentStreak days', style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 32),
              const Text('📅 Last Check-In:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(formatDate(lastCheckIn), style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: handleCheckIn,
                child: const Text('✅ I Studied Today'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
