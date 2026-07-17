import 'enums.dart';

/// Commande (table `orders`), pilote par le workflow des 13 statuts.
class Order {
  final String? id;
  final String quoteId;
  final String clientId;
  final OrderStatus status;
  final bool depositPaid;
  final bool balancePaid;
  final DateTime? createdAt;

  const Order({
    this.id,
    required this.quoteId,
    required this.clientId,
    this.status = OrderStatus.acomptePaye,
    this.depositPaid = false,
    this.balancePaid = false,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as String?,
        quoteId: j['quote_id'] as String,
        clientId: j['client_id'] as String,
        status: OrderStatus.fromDb(j['status'] as String?),
        depositPaid: (j['deposit_paid'] ?? false) as bool,
        balancePaid: (j['balance_paid'] ?? false) as bool,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toUpsert() => {
        if (id != null) 'id': id,
        'quote_id': quoteId,
        'client_id': clientId,
        'status': status.dbValue,
        'deposit_paid': depositPaid,
        'balance_paid': balancePaid,
      };
}
