import 'enums.dart';

/// Paiement rattache a une commande (table `payments`).
/// Le modele 70/30 = une ligne "deposit" + une ligne "balance".
class Payment {
  final String? id;
  final String orderId;
  final PaymentType type;
  final num amount;
  final String? method; // wave / orange_money / especes / virement
  final String? reference;
  final DateTime? paidAt;

  const Payment({
    this.id,
    required this.orderId,
    required this.type,
    required this.amount,
    this.method,
    this.reference,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String?,
        orderId: j['order_id'] as String,
        type: PaymentType.fromDb((j['type'] ?? 'deposit') as String),
        amount: (j['amount'] ?? 0) as num,
        method: j['method'] as String?,
        reference: j['reference'] as String?,
        paidAt: j['paid_at'] != null
            ? DateTime.tryParse(j['paid_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsert() => {
        'order_id': orderId,
        'type': type.dbValue,
        'amount': amount,
        'method': method,
        'reference': reference,
        if (paidAt != null) 'paid_at': paidAt!.toIso8601String(),
      };
}
