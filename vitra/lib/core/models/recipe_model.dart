class RecipeIngredient {
  final String name;
  final double quantity;
  final String servingLabel;
  final int caloriesPerServing;
  final int proteinGPerServing;
  final int carbsGPerServing;
  final int fatGPerServing;
  final int fiberGPerServing;
  final int sodiumMgPerServing;
  final int sugarGPerServing;

  const RecipeIngredient({
    required this.name,
    required this.quantity,
    required this.servingLabel,
    required this.caloriesPerServing,
    this.proteinGPerServing = 0,
    this.carbsGPerServing   = 0,
    this.fatGPerServing     = 0,
    this.fiberGPerServing   = 0,
    this.sodiumMgPerServing = 0,
    this.sugarGPerServing   = 0,
  });

  int get calories  => (caloriesPerServing  * quantity).round();
  int get proteinG  => (proteinGPerServing  * quantity).round();
  int get carbsG    => (carbsGPerServing    * quantity).round();
  int get fatG      => (fatGPerServing      * quantity).round();
  int get fiberG    => (fiberGPerServing    * quantity).round();
  int get sodiumMg  => (sodiumMgPerServing  * quantity).round();
  int get sugarG    => (sugarGPerServing    * quantity).round();

  RecipeIngredient copyWith({double? quantity}) => RecipeIngredient(
    name:                name,
    quantity:            quantity ?? this.quantity,
    servingLabel:        servingLabel,
    caloriesPerServing:  caloriesPerServing,
    proteinGPerServing:  proteinGPerServing,
    carbsGPerServing:    carbsGPerServing,
    fatGPerServing:      fatGPerServing,
    fiberGPerServing:    fiberGPerServing,
    sodiumMgPerServing:  sodiumMgPerServing,
    sugarGPerServing:    sugarGPerServing,
  );

  Map<String, dynamic> toJson() => {
    'name':               name,
    'quantity':           quantity,
    'servingLabel':       servingLabel,
    'caloriesPerServing': caloriesPerServing,
    'proteinGPerServing': proteinGPerServing,
    'carbsGPerServing':   carbsGPerServing,
    'fatGPerServing':     fatGPerServing,
    'fiberGPerServing':   fiberGPerServing,
    'sodiumMgPerServing': sodiumMgPerServing,
    'sugarGPerServing':   sugarGPerServing,
  };

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
    name:               j['name']               as String,
    quantity:           (j['quantity']           as num).toDouble(),
    servingLabel:       j['servingLabel']        as String,
    caloriesPerServing: j['caloriesPerServing']  as int,
    proteinGPerServing: (j['proteinGPerServing'] as int?) ?? 0,
    carbsGPerServing:   (j['carbsGPerServing']   as int?) ?? 0,
    fatGPerServing:     (j['fatGPerServing']     as int?) ?? 0,
    fiberGPerServing:   (j['fiberGPerServing']   as int?) ?? 0,
    sodiumMgPerServing: (j['sodiumMgPerServing'] as int?) ?? 0,
    sugarGPerServing:   (j['sugarGPerServing']   as int?) ?? 0,
  );
}

class RecipeModel {
  final String id;
  final String name;
  final String description;
  final int servings;
  final List<RecipeIngredient> ingredients;
  final DateTime createdAt;

  const RecipeModel({
    required this.id,
    required this.name,
    this.description = '',
    this.servings    = 1,
    required this.ingredients,
    required this.createdAt,
  });

  int get totalCalories => ingredients.fold(0, (s, i) => s + i.calories);
  int get totalProteinG => ingredients.fold(0, (s, i) => s + i.proteinG);
  int get totalCarbsG   => ingredients.fold(0, (s, i) => s + i.carbsG);
  int get totalFatG     => ingredients.fold(0, (s, i) => s + i.fatG);
  int get totalFiberG   => ingredients.fold(0, (s, i) => s + i.fiberG);
  int get totalSodiumMg => ingredients.fold(0, (s, i) => s + i.sodiumMg);
  int get totalSugarG   => ingredients.fold(0, (s, i) => s + i.sugarG);

  int get caloriesPerServing  => servings > 0 ? (totalCalories  / servings).round() : totalCalories;
  int get proteinGPerServing  => servings > 0 ? (totalProteinG  / servings).round() : totalProteinG;
  int get carbsGPerServing    => servings > 0 ? (totalCarbsG    / servings).round() : totalCarbsG;
  int get fatGPerServing      => servings > 0 ? (totalFatG      / servings).round() : totalFatG;
  int get fiberGPerServing    => servings > 0 ? (totalFiberG    / servings).round() : totalFiberG;
  int get sodiumMgPerServing  => servings > 0 ? (totalSodiumMg  / servings).round() : totalSodiumMg;
  int get sugarGPerServing    => servings > 0 ? (totalSugarG    / servings).round() : totalSugarG;

  Map<String, dynamic> toJson() => {
    'id':          id,
    'name':        name,
    'description': description,
    'servings':    servings,
    'ingredients': ingredients.map((i) => i.toJson()).toList(),
    'createdAt':   createdAt.millisecondsSinceEpoch,
  };

  factory RecipeModel.fromJson(Map<String, dynamic> j) => RecipeModel(
    id:          j['id']          as String,
    name:        j['name']        as String,
    description: (j['description'] as String?) ?? '',
    servings:    (j['servings']   as int?) ?? 1,
    ingredients: ((j['ingredients'] as List<dynamic>?) ?? [])
        .map((e) => RecipeIngredient.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    createdAt:   DateTime.fromMillisecondsSinceEpoch((j['createdAt'] as int?) ?? 0),
  );
}
