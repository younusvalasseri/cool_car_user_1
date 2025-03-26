import 'package:cool_car_user_1/Providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideApprovalPage extends ConsumerWidget {
  const RideApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rideApprovalState = ref.watch(rideApprovalNotifierProvider);
    final rideApprovalNotifier =
        ref.read(rideApprovalNotifierProvider.notifier);

    final user = FirebaseAuth.instance.currentUser;

    // Fetch Ride Details if Not Already Loaded
    Future.microtask(() {
      if (rideApprovalState.rentalId == null && user != null) {
        rideApprovalNotifier.fetchRideForUser(user.uid);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Ride Approval")),
      body: rideApprovalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : rideApprovalState.rideDetails == null
              ? const Center(child: Text("No active ride found"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🚗 Ride Details",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                          "👤 Owner: ${rideApprovalState.rideDetails!['ownerName']}"),
                      Text(
                          "📞 Contact: ${rideApprovalState.rideDetails!['ownerPhone']}"),
                      const Divider(),
                      Text(
                          "🚙 Car: ${rideApprovalState.rideDetails!['car']['modelName']}"),
                      const Divider(),
                      Text(
                          "📅 Pickup Date: ${rideApprovalState.rideDetails!['pickupDate'].toDate()}"),
                      Text(
                          "📆 Days: ${rideApprovalState.rideDetails!['days']}"),
                      Text(
                          "💰 Fare: ₹${rideApprovalState.rideDetails!['totalFare']}"),
                      Text(
                        "🛑 Payment Status: ${rideApprovalState.rideDetails!['paymentStatus']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              rideApprovalState.rideDetails!['paymentStatus'] ==
                                      "Paid"
                                  ? Colors.green
                                  : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 20),
                      rideApprovalState.rideDetails!['paymentStatus'] == "Paid"
                          ? const Text("✅ Payment Completed",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 16))
                          : ElevatedButton(
                              onPressed: () =>
                                  rideApprovalNotifier.startPayment(
                                rideApprovalState.rideDetails!['totalFare'],
                              ),
                              child: const Text("Make Payment"),
                            ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: rideApprovalState.isPaymentCompleted
                            ? () => rideApprovalNotifier.completeRide(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rideApprovalState.isPaymentCompleted
                              ? Colors.green
                              : Colors.grey,
                        ),
                        child: const Text("Complete Ride"),
                      ),
                    ],
                  ),
                ),
    );
  }
}
