import 'package:flutter/material.dart';

class PaymentMethod {
  final String key;
  final String label;
  final String parentMethod;
  final String? subMethod;
  final List<String> subMethods;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;

  const PaymentMethod({
    required this.key,
    required this.label,
    this.parentMethod = 'cash',
    this.subMethod,
    this.subMethods = const [],
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

class SplitPaymentEntry {
  final String methodKey;
  final String parentMethod;
  final String label;
  final String? subMethod;
  final double amount;

  const SplitPaymentEntry({
    required this.methodKey,
    required this.parentMethod,
    required this.label,
    this.subMethod,
    required this.amount,
  });

  SplitPaymentEntry copyWith({
    String? methodKey,
    String? parentMethod,
    String? label,
    String? subMethod,
    double? amount,
  }) {
    return SplitPaymentEntry(
      methodKey: methodKey ?? this.methodKey,
      parentMethod: parentMethod ?? this.parentMethod,
      label: label ?? this.label,
      subMethod: subMethod ?? this.subMethod,
      amount: amount ?? this.amount,
    );
  }
}
