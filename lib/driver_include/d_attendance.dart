import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class d_attendance extends StatefulWidget {
  const d_attendance({Key? key}) : super(key: key);

  @override
  State<d_attendance> createState() => _d_attendanceState();
}

class _d_attendanceState extends State<d_attendance> {
  Map<String, int> goingDestinationCounts = {};
  Map<String, int> comingDestinationCounts = {};
  int approvedCount = 0;
  bool showGoingValues = true;

  @override
  void initState() {
    super.initState();
    _calculateDestinationCounts();
  }

  Future<void> _calculateDestinationCounts() async {
    try {
      if (!mounted) {
        return;
      }

      final currentTime = DateTime.now();
      final startOfDay =
          DateTime(currentTime.year, currentTime.month, currentTime.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final goingValuesCollection =
          FirebaseFirestore.instance.collection("going_values");
      final comingValuesCollection =
          FirebaseFirestore.instance.collection("coming_values");

      if (!mounted) {
        return;
      }

      final goingQuerySnapshot = await goingValuesCollection
          .where("timestamp",
              isGreaterThanOrEqualTo: startOfDay, isLessThan: endOfDay)
          .get();

      if (!mounted) {
        return;
      }

      final comingQuerySnapshot = await comingValuesCollection
          .where("timestamp",
              isGreaterThanOrEqualTo: startOfDay, isLessThan: endOfDay)
          .get();

      if (!mounted) {
        return;
      }

      goingDestinationCounts = _countDestinations(goingQuerySnapshot.docs);
      comingDestinationCounts = _countDestinations(comingQuerySnapshot.docs);

      final int totalGoingCount =
          goingDestinationCounts.values.fold(0, (a, b) => a + b);
      final int totalComingCount =
          comingDestinationCounts.values.fold(0, (a, b) => a + b);
      goingDestinationCounts['Total'] = totalGoingCount;
      comingDestinationCounts['Total'] = totalComingCount;

      approvedCount = await calculateApprovedCountForCurrentWeek();

      if (!mounted) {
        return;
      }

      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }

      print("Error in _calculateDestinationCounts: $error");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text("An error occurred while calculating destination counts."),
      ));
    }
  }

  Future<int> calculateApprovedCountForCurrentWeek() async {
    try {
      if (!mounted) {
        return 0;
      }

      final DateTime now = DateTime.now();
      final DateTime startOfWeek = now.subtract(Duration(days: now.weekday));
      final DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

      final snapshot = await FirebaseFirestore.instance
          .collection('request_history')
          .where("status", isEqualTo: "approved")
          .where("timestamp", isGreaterThanOrEqualTo: startOfWeek)
          .where("timestamp", isLessThanOrEqualTo: endOfWeek)
          .get();

      if (!mounted) {
        return 0;
      }

      int totalApprovedSeats = 0;

      for (final doc in snapshot.docs) {
        final status = doc.get("status") as String?;
        final requestedSeats = doc.get("requestedSeats") as int?;

        if (status == "approved" && requestedSeats != null) {
          totalApprovedSeats += requestedSeats;
        }
      }

      return totalApprovedSeats;
    } catch (error) {
      if (!mounted) {
        return 0;
      }

      print("Error in calculateApprovedCountForCurrentWeek: $error");
      return 0;
    }
  }

  Map<String, int> _countDestinations(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> destinationCounts = {};

    for (final doc in docs) {
      final selectedValue = doc.get("selectedValue") as String?;
      if (selectedValue != null) {
        destinationCounts[selectedValue] =
            (destinationCounts[selectedValue] ?? 0) + 1;
      }
    }

    return destinationCounts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 21, 255),
        title: const Text('Destination Counts'),
        actions: [],
      ),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            Container(
              alignment: Alignment.topCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio(
                    value: true,
                    groupValue: showGoingValues,
                    onChanged: (value) {
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        showGoingValues = true;
                      });

                      _calculateDestinationCounts();
                    },
                  ),
                  const Text("Southern to Home"),
                  Radio(
                    value: false,
                    groupValue: showGoingValues,
                    onChanged: (value) {
                      if (!mounted) {
                        return;
                      }

                      setState(() {
                        showGoingValues = false;
                      });

                      _calculateDestinationCounts();
                    },
                  ),
                  const Text("Home to Southern"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDestinationCountSection(
              showGoingValues
                  ? "Southern to Home Destination Counts (Current Day):"
                  : "Home to Southern Destination Counts (Current Day):",
              showGoingValues
                  ? goingDestinationCounts
                  : comingDestinationCounts,
            ),
            const SizedBox(height: 20),
            _buildTotalCountSection(showGoingValues
                ? goingDestinationCounts['Total'] ?? 0
                : comingDestinationCounts['Total'] ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCountSection(
    String title,
    Map<String, int> destinationCounts,
  ) {
    return Container(
      width: 375.0, // Adjust the width as needed
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: destinationCounts.entries.map((entry) {
                  return _buildDestinationCountCard(entry.key, entry.value);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCountSection(int totalCount) {
    return Container(
      width: 375.0, // Adjust the width as needed
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Destination Counts:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildTotalCountCard("Total", totalCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCountCard(String title, int count) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(
        "Count: $count",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDestinationCountCard(String destination, int count) {
    return ListTile(
      title: Text(
        destination,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(
        "Count: $count",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
