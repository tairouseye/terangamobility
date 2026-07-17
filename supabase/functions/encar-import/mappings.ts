// =====================================================================
// Dictionnaires de normalisation Encar (coreen -> latin / francais).
//
// L'API interne d'Encar renvoie des libelles EN COREEN. On les traduit ici
// vers des valeurs propres pour le catalogue senegalais. Ces tables sont
// volontairement isolees : elles s'enrichissent sans toucher a la logique
// d'import.  Toute valeur inconnue est conservee telle quelle (fallback).
// =====================================================================

export const MANUFACTURERS: Record<string, string> = {
  "현대": "Hyundai",
  "기아": "Kia",
  "제네시스": "Genesis",
  "쌍용": "SsangYong",
  "르노삼성": "Renault Samsung",
  "쉐보레(GM대우)": "Chevrolet",
  "쉐보레": "Chevrolet",
};

// Modeles coreens les plus courants (a completer au fil de l'eau).
export const MODELS: Record<string, string> = {
  "그랜저": "Grandeur",
  "쏘나타": "Sonata",
  "아반떼": "Avante (Elantra)",
  "투싼": "Tucson",
  "싼타페": "Santa Fe",
  "팰리세이드": "Palisade",
  "코나": "Kona",
  "스타렉스": "Starex",
  "포터": "Porter",
  "쏘렌토": "Sorento",
  "스포티지": "Sportage",
  "카니발": "Carnival",
  "모닝": "Morning",
  "레이": "Ray",
  "K5": "K5",
  "K7": "K7",
  "K8": "K8",
  "K9": "K9",
  "니로": "Niro",
  "셀토스": "Seltos",
  "G70": "G80",
  "G80": "G80",
  "G90": "G90",
  "GV70": "GV70",
  "GV80": "GV80",
  "렉스턴": "Rexton",
  "티볼리": "Tivoli",
  "코란도": "Korando",
};

export const FUELS: Record<string, string> = {
  "가솔린": "Essence",
  "디젤": "Diesel",
  "하이브리드": "Hybride",
  "가솔린+전기": "Hybride",
  "LPG": "GPL",
  "LPG(일반인)": "GPL",
  "전기": "Electrique",
  "수소": "Hydrogene",
};

export const TRANSMISSIONS: Record<string, string> = {
  "오토": "Automatique",
  "자동": "Automatique",
  "수동": "Manuelle",
  "CVT": "Automatique (CVT)",
  "세미오토": "Semi-automatique",
};

export const COLORS: Record<string, string> = {
  "흰색": "Blanc",
  "검정색": "Noir",
  "검정": "Noir",
  "쥐색": "Gris",
  "은색": "Argent",
  "은회색": "Gris argent",
  "빨간색": "Rouge",
  "파란색": "Bleu",
  "남색": "Bleu nuit",
  "진주색": "Nacre",
  "갈색": "Marron",
  "금색": "Or",
};

// Regions coreennes (champ OfficeCityState de la liste) -> nom lisible.
export const REGIONS: Record<string, string> = {
  "서울": "Seoul",
  "경기": "Gyeonggi",
  "인천": "Incheon",
  "부산": "Busan",
  "대구": "Daegu",
  "대전": "Daejeon",
  "광주": "Gwangju",
  "울산": "Ulsan",
  "세종": "Sejong",
  "강원": "Gangwon",
  "충북": "Chungbuk",
  "충남": "Chungnam",
  "전북": "Jeonbuk",
  "전남": "Jeonnam",
  "경북": "Gyeongbuk",
  "경남": "Gyeongnam",
  "제주": "Jeju",
};

/** Traduit avec repli sur la valeur d'origine (jamais de perte de donnee). */
export function tr(dict: Record<string, string>, value?: string | null): string | null {
  if (!value) return null;
  return dict[value] ?? value;
}
