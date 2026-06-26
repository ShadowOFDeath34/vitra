import 'foods_turkish.dart';
import 'foods_global.dart';
import 'foods_fastfood.dart';
import 'foods_extra.dart';
import 'foods_produce.dart';
import 'foods_saglik.dart';
import 'foods_brands_tr.dart';
import 'foods_market_tr.dart';
import 'foods_fitness_tr.dart';
import 'foods_restoran_tr.dart';
import 'foods_icecek_atistirma.dart';
import 'foods_dunya_mutfagi.dart';
import 'foods_fastfood_tr.dart';
import 'foods_spor_supplement.dart';
import 'foods_asya_mutfagi.dart';
import 'foods_avrupa_amerikan.dart';
import 'foods_tahil_kahvalti.dart';
import 'foods_tatli_pastane.dart';
import 'foods_ek_malzeme.dart';
import 'foods_tr_yemek2.dart';
import 'foods_icecek_detay.dart';
import 'foods_market_hazir2.dart';
import 'foods_yemek_cesitleri.dart';
import 'foods_son_ekleme.dart';
import 'foods_ek_liste.dart';
import 'foods_tamamlayici.dart';
import 'foods_final.dart';

class TurkishFoodItem {
  final String name;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int fiberG;
  final int sodiumMg;
  final int sugarG;
  final String serving;
  final String category;
  final String? nameEn;
  final String? barcode;

  const TurkishFoodItem({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0,
    this.sodiumMg = 0,
    this.sugarG = 0,
    required this.serving,
    required this.category,
    this.nameEn,
    this.barcode,
  });
}

class TurkishFoodsDB {
  TurkishFoodsDB._();

  static final List<TurkishFoodItem> all = [
    ...FoodsTurkish.items,
    ...FoodsGlobal.items,
    ...FoodsFastFood.items,
    ...FoodsExtra.items,
    ...FoodsProduce.items,
    ...FoodsSaglik.items,
    ...FoodsBrandsTr.items,
    ...FoodsMarketTr.items,
    ...FoodsFitnessTr.items,
    ...FoodsRestoranTr.items,
    ...FoodsIcecekAtistirma.items,
    ...FoodsDunyaMutfagi.items,
    ...FoodsFastfoodTr.items,
    ...FoodsSporSupplement.items,
    ...FoodsAsyaMutfagi.items,
    ...FoodsAvrupaAmerikan.items,
    ...FoodsTahilKahvalti.items,
    ...FoodsTatliPastane.items,
    ...FoodsEkMalzeme.items,
    ...FoodsTrYemek2.items,
    ...FoodsIcecekDetay.items,
    ...FoodsMarketHazir2.items,
    ...FoodsYemekCesitleri.items,
    ...FoodsSonEkleme.items,
    ...FoodsEkListe.items,
    ...FoodsTamamlayici.items,
    ...FoodsFinal.items,
  ];

  static String _normalize(String s) => s
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  static List<TurkishFoodItem> search(String query) {
    if (query.isEmpty) return [];
    final q = _normalize(query.toLowerCase());
    return all.where((f) {
      final name = _normalize(f.name.toLowerCase());
      final nameEn = f.nameEn?.toLowerCase() ?? '';
      return name.contains(q) || nameEn.contains(q);
    }).toList();
  }

  static List<TurkishFoodItem> byCategory(String category) =>
      all.where((f) => f.category == category).toList();

  static const popular = [
    'Haşlanmış yumurta',
    'Mercimek çorbası',
    'Tavuk ızgara (göğüs)',
    'Pirinç pilavı',
    'Ayran (büyük)',
    'Çoban salata',
    'Köfte (3 adet)',
    'Kuru fasulye',
  ];
}
