import 'enums.dart';
import 'order.dart';

/// Vue enrichie d'une commande pour l'affichage : jointure
/// orders → customer_quotes → parts_requests.
class OrderView {
  final Order order;
  final String partName;
  final String vehicleLabel;
  final num total;

  const OrderView({
    required this.order,
    required this.partName,
    required this.vehicleLabel,
    required this.total,
  });

  OrderStatus get status => order.status;
  num get deposit => (total * 0.7).roundToDouble();
  num get balance => total - deposit;

  factory OrderView.fromJson(Map<String, dynamic> j) {
    final quote = j['customer_quotes'] as Map<String, dynamic>?;
    final request = quote?['parts_requests'] as Map<String, dynamic>?;

    final brand = request?['vehicle_brand'] as String?;
    final model = request?['vehicle_model'] as String?;
    final year = request?['vehicle_year'] as int?;
    final label = [brand, model]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' ');

    return OrderView(
      order: Order.fromJson(j),
      partName: (request?['part_name'] ?? 'Piece') as String,
      vehicleLabel: label.isEmpty
          ? 'Vehicule non precise'
          : (year != null ? '$label ($year)' : label),
      total: (quote?['total_fcfa'] ?? 0) as num,
    );
  }
}
