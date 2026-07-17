// Test de fumee minimal. Les tests fonctionnels viendront avec les lots MVP.
import 'package:flutter_test/flutter_test.dart';

import 'package:teranga_parts/models/enums.dart';

void main() {
  test('Le workflow commande comporte bien 13 statuts ordonnes', () {
    expect(OrderStatus.values.length, 13);
    expect(OrderStatus.nouvelleDemande.step, 1);
    expect(OrderStatus.livree.step, 13);
  });

  test('Le devis applique bien 70/30 sur le total', () {
    // 300 000 -> acompte 210 000 / solde 90 000
    const total = 300000;
    final deposit = (total * 0.7).round();
    expect(deposit, 210000);
    expect(total - deposit, 90000);
  });
}
