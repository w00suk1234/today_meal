import '../models/food_item.dart';

// 데모용 추정 샘플 데이터입니다. 실제 서비스에서는 공인 영양 DB 또는 검증된 API로 교체하세요.
const fallbackFoods = <FoodItem>[
  FoodItem(id: 'rice', name: '공깃밥', category: '밥', servingGram: 210, kcalPer100g: 145, carbPer100g: 32, proteinPer100g: 2.7, fatPer100g: 0.3),
  FoodItem(id: 'kimchi_stew', name: '김치찌개', category: '찌개', servingGram: 300, kcalPer100g: 62, carbPer100g: 4.8, proteinPer100g: 4.2, fatPer100g: 3.1),
  FoodItem(id: 'chicken_breast', name: '닭가슴살', category: '단백질', servingGram: 120, kcalPer100g: 110, carbPer100g: 0, proteinPer100g: 23, fatPer100g: 1.6),
];
