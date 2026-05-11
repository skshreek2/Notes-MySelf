import 'package:dashboard_demo/styles/app_style.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const DashboardApp());
}

class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Payment Dashboard',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xffeef2ff),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: Stack(
    children: [

    /// BACKGROUND BASE GRADIENT
    Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEFF6FF),
            Color(0xFFFAF5FF),
          ],
        ),
      ),
    ),

    /// OVERLAY GRADIENT
    Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromRGBO(230, 237, 255, 0.60),
            Color.fromRGBO(157, 183, 249, 0.60),
          ],
          stops: [0.5244, 0.9723],
        ),
      ),
    ),

    /// MAIN CONTENT
    SafeArea(
      child: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            /// HEADER
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Good Morning Trisha!",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1b2559),
                  ),
                ),

                /// FILTER BUTTONS
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.7),
                    borderRadius:
                        BorderRadius.circular(40),
                    border:
                        Border.all(color: Colors.white),
                  ),
                  child: Row(
                    children: [
                      filterButton("Yesterday"),
                      filterButton("Today"),
                      filterButton("Weekly"),
                      filterButton(
                        "Monthly",
                        selected: true,
                      ),
                      filterButton("Custom"),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// TOP CARDS
            Row(
              children: [
                Expanded(
                  child: blueCard(
                    title: "Total Transactions",
                    value: "1,284",
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: statCard(
                    title: "Success Rate",
                    value: "92.6%",
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: statCard(
                    title: "Refund Transactions",
                    value: "₹30,000",
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: statCard(
                    title:
                        "Total Processed Amount",
                    value: "₹8,72,450",
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: statCard(
                    title:
                        "Total Settled Amount",
                    value: "₹8,52,450",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            /// MIDDLE SECTION
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                /// CHART CARD
                Expanded(
                  flex: 3,
                  child: glassCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Top Payment Method by Volume",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 30),

                        paymentBar(
                            "UPI", 0.50, "₹2637"),
                        paymentBar(
                            "Credit Card",
                            0.60,
                            "₹3456"),
                        paymentBar(
                            "Debit Card",
                            0.78,
                            "₹7354"),
                        paymentBar(
                            "Net Banking",
                            0.82,
                            "₹8474"),
                        paymentBar(
                            "Wallets",
                            1.0,
                            "₹9346"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                /// QUICK LINKS
                Expanded(
                  flex: 2,
                  child: glassCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Quick Links",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 25),

                        quickLink(
                          Icons
                              .account_balance_wallet_outlined,
                          "Settlements",
                        ),

                        quickLink(
                          Icons.currency_rupee,
                          "Payment Links",
                        ),

                        quickLink(
                          Icons.bar_chart,
                          "Reports",
                        ),

                        quickLink(
                          Icons.receipt_long,
                          "Orders",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            /// BOTTOM SECTION
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                /// LINE CHART
                Expanded(
                  flex: 2,
                  child: glassCard(
                    height: 320,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Average Ticket Size",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          "1,458",
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Color(0xff1b2559),
                          ),
                        ),

                        const Spacer(),

                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                                    18),
                            gradient: LinearGradient(
                              colors: [
                                Colors
                                    .blue
                                    .shade100,
                                Colors
                                    .blue
                                    .shade400,
                              ],
                              begin:
                                  Alignment.topLeft,
                              end: Alignment
                                  .bottomRight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                /// DONUT CHART
                Expanded(
                  child: glassCard(
                    height: 320,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Top Payment Methods",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const Spacer(),

                        Center(
                          child: SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              alignment:
                                  Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: 0.75,
                                  strokeWidth: 26,
                                  backgroundColor:
                                      Colors.blue
                                          .shade100,
                                  valueColor:
                                      AlwaysStoppedAnimation(
                                    Colors.blue
                                        .shade700,
                                  ),
                                ),

                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        Colors.white,
                                    shape:
                                        BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ],
)
      );
  }

  static Widget filterButton(String title, {bool selected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: selected ? const Color(0xff1558d6) : Colors.transparent,
        borderRadius: AppStyles.screenRadius,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: selected
              ? Colors.white
              : const Color(0xff5b6475),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget blueCard({
    required String title,
    required String value,
  }) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff0d47bf),
            Color(0xff1f6fff),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget statCard({
    required String title,
    required String value,
  }) {
    return glassCard(
      height: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 18,
            ),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: Color(0xff1b2559),
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget glassCard({
  required Widget child,
  double? height,
}) {
  return Container(
    height: height,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: AppStyles.screenRadius,
      border: Border.all(
        color: Colors.white.withOpacity(0.20),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}

  static Widget paymentBar(
      String title,
      double value,
      String amount,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    height: 42,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 18),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade200,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget quickLink(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
