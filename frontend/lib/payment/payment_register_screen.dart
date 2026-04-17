import 'package:flutter/material.dart';
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/screens/profile_update_screen.dart';
import 'package:yumbook_app/widgets/payment_methods_widget.dart';
import 'package:yumbook_app/state/payment_method_store.dart';

class PaymentRegisterScreen extends StatelessWidget {
  final ReservationData? data;

  const PaymentRegisterScreen({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: PaymentMethodsWidget(
          onMethodSelected: (selectedMethod) {
            if (data != null) {
              final updatedData = data!.copyWith(
                paymentMethodId: selectedMethod.id,
                paymentMethodLabel:
                    '${selectedMethod.brand} •••• ${selectedMethod.last4}',
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileUpdateScreen(data: updatedData),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}

class PaymentMethodsSheet extends StatelessWidget {
  final ReservationData? data;

  const PaymentMethodsSheet({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        child: PaymentMethodsWidget(
          onMethodSelected: (selectedMethod) {
            Navigator.pop(context);

            if (data != null) {
              final updatedData = data!.copyWith(
                paymentMethodId: selectedMethod.id,
                paymentMethodLabel:
                    '${selectedMethod.brand} •••• ${selectedMethod.last4}',
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileUpdateScreen(data: updatedData),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class PaymentRegisterSheet extends StatelessWidget {
  final ReservationData? data;

  const PaymentRegisterSheet({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(top: 80),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: PaymentMethodsWidget(
          onMethodSelected: (selectedMethod) {
            Navigator.pop(context);

            if (data != null) {
              final updatedData = data!.copyWith(
                paymentMethodId: selectedMethod.id,
                paymentMethodLabel:
                    '${selectedMethod.brand} •••• ${selectedMethod.last4}',
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileUpdateScreen(data: updatedData),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}