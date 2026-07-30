/// Estimation du prix d'achat Encar (brut, sans marge) a partir du prix FCFA
/// affiche — en inversant la formule d'import :
///   prix_fcfa = arrondi_100k( prix_krw * 0.45 + marge )
/// Sert au controle admin (comparer a la vraie annonce Encar).
///
/// Le resultat est une ESTIMATION (l'arrondi au 100 000 introduit ~±80 $).
class EncarPriceEstimate {
  final int krw; // won coreens
  final int usd; // dollars (approx)
  final int fcfa; // FCFA brut (converti, AVANT marge)
  const EncarPriceEstimate(this.krw, this.usd, this.fcfa);
}

// Taux utilises a l'import (coherents entre eux) : 1 KRW = 0.45 FCFA,
// 1 USD ~= 1350 KRW (~607 FCFA). Ajustables si le cours bouge.
const double kKrwToFcfa = 0.45;
const int kUsdToKrw = 1350;

const int _marginLow = 1300000;
const int _marginHigh = 1500000;
const int _marginThreshold = 6000000;

EncarPriceEstimate? estimatedEncarPrice(num? priceFcfa) {
  if (priceFcfa == null || priceFcfa <= 0) return null;
  num raw = priceFcfa - _marginLow;
  if (raw >= _marginThreshold) raw = priceFcfa - _marginHigh;
  if (raw <= 0) return null;
  final krw = (raw / kKrwToFcfa).round();
  final usd = (krw / kUsdToKrw).round();
  return EncarPriceEstimate(krw, usd, raw.round());
}
