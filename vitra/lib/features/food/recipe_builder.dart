import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/v_theme.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/recipe_model.dart';
import '../../core/models/meal_entry.dart';
import '../../core/services/recipe_service.dart';
import '../../core/data/turkish_foods_db.dart';

// ── Renk sabitleri (food_tab ile tutarlı) ─────────────────────────────────────
const _kProtein = Color(0xFF3B82F6);
const _kCarbs   = Color(0xFFF59E0B);
const _kFat     = Color(0xFFEF4444);

// ── Provider ──────────────────────────────────────────────────────────────────

final recipesProvider = FutureProvider.autoDispose<List<RecipeModel>>((ref) {
  return RecipeService.instance.fetchRecipes();
});

// ── Recipes Page ──────────────────────────────────────────────────────────────

class RecipesPage extends ConsumerWidget {
  final void Function(RecipeModel recipe, MealType type)? onAddToLog;

  const RecipesPage({super.key, this.onAddToLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vc           = context.vt;
    final recipesAsync = ref.watch(recipesProvider);

    return Scaffold(
      backgroundColor: vc.bg,
      appBar: AppBar(
        backgroundColor: vc.surfaceHigh,
        title: Text(
          'Tariflerim',
          style: TextStyle(
            color: vc.text,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: vc.text),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBuilder(context, ref, null),
        backgroundColor: _kProtein,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Yeni Tarif',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (_, __) => Center(
          child: Text('Tarifler yüklenemedi', style: TextStyle(color: vc.textSub)),
        ),
        data: (recipes) {
          if (recipes.isEmpty) {
            return _EmptyState(onTap: () => _openBuilder(context, ref, null));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: recipes.length,
            itemBuilder: (_, i) => _RecipeCard(
              recipe:     recipes[i],
              onAddToLog: onAddToLog,
              onEdit:     () => _openBuilder(context, ref, recipes[i]),
              onDelete:   () async {
                await RecipeService.instance.deleteRecipe(recipes[i].id);
                ref.invalidate(recipesProvider);
              },
            ),
          );
        },
      ),
    );
  }

  void _openBuilder(BuildContext context, WidgetRef ref, RecipeModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecipeBuilderSheet(
        existing: existing,
        onSaved:  () => ref.invalidate(recipesProvider),
      ),
    );
  }
}

// ── Recipe Card ───────────────────────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final void Function(RecipeModel, MealType)? onAddToLog;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecipeCard({
    required this.recipe,
    this.onAddToLog,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        vc.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: vc.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: vc.text,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert_rounded, color: vc.textSub, size: 20),
                      color: vc.surfaceHigh,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'edit')   onEdit();
                        if (val == 'delete') onDelete();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Düzenle', style: TextStyle(color: vc.text)),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Sil', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                if (recipe.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    recipe.description,
                    style: TextStyle(fontSize: 13, color: vc.textSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Badge('${recipe.caloriesPerServing} kcal', AppColors.calories),
                    const SizedBox(width: 6),
                    _Badge('P ${recipe.proteinGPerServing}g', _kProtein),
                    const SizedBox(width: 6),
                    _Badge('K ${recipe.carbsGPerServing}g',   _kCarbs),
                    const SizedBox(width: 6),
                    _Badge('Y ${recipe.fatGPerServing}g',     _kFat),
                    const Spacer(),
                    if (recipe.servings > 1)
                      Text(
                        '${recipe.servings} kişilik',
                        style: TextStyle(fontSize: 11, color: vc.textSub),
                      ),
                  ],
                ),
                if (recipe.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    recipe.ingredients.map((i) => i.name).join(', '),
                    style: TextStyle(fontSize: 11, color: vc.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecipeDetailSheet(
        recipe:     recipe,
        onAddToLog: onAddToLog,
      ),
    );
  }
}

// ── Recipe Detail Sheet ───────────────────────────────────────────────────────

class _RecipeDetailSheet extends StatelessWidget {
  final RecipeModel recipe;
  final void Function(RecipeModel, MealType)? onAddToLog;

  const _RecipeDetailSheet({required this.recipe, this.onAddToLog});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize:     0.96,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color:        vc.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: vc.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: vc.text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: vc.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (recipe.servings > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${recipe.servings} kişilik · kişi başı değerler',
                    style: TextStyle(fontSize: 13, color: vc.textSub),
                  ),
                ),
              ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // Makro özeti
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:        vc.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutBox('Kalori', '${recipe.caloriesPerServing}', 'kcal', AppColors.calories),
                        _NutBox('Protein', '${recipe.proteinGPerServing}', 'g', _kProtein),
                        _NutBox('Karb',   '${recipe.carbsGPerServing}',   'g', _kCarbs),
                        _NutBox('Yağ',    '${recipe.fatGPerServing}',     'g', _kFat),
                      ],
                    ),
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(recipe.description, style: TextStyle(fontSize: 14, color: vc.textSub)),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Malzemeler (${recipe.ingredients.length})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: vc.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...recipe.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: _kProtein,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ing.name, style: TextStyle(color: vc.text, fontSize: 14)),
                        ),
                        Text(
                          _quantityLabel(ing),
                          style: TextStyle(color: vc.textSub, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${ing.calories} kcal',
                          style: TextStyle(color: vc.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )),
                  if (onAddToLog != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Öğüne Ekle',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: vc.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...MealType.values.map((type) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        icon: Text(type.emoji, style: const TextStyle(fontSize: 16)),
                        label: Text(
                          '${type.label}  —  ${recipe.caloriesPerServing} kcal',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onPressed: () {
                          onAddToLog!(recipe, type);
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kProtein,
                          side: BorderSide(color: _kProtein.withValues(alpha: 0.4)),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _quantityLabel(RecipeIngredient ing) {
    final q = ing.quantity;
    final display = q == q.floorToDouble()
        ? q.toInt().toString()
        : q.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return '$display× ${ing.servingLabel}';
  }
}

// ── Recipe Builder Sheet ──────────────────────────────────────────────────────

class RecipeBuilderSheet extends StatefulWidget {
  final RecipeModel? existing;
  final VoidCallback onSaved;

  const RecipeBuilderSheet({
    super.key,
    this.existing,
    required this.onSaved,
  });

  @override
  State<RecipeBuilderSheet> createState() => _RecipeBuilderSheetState();
}

class _RecipeBuilderSheetState extends State<RecipeBuilderSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _ingredients = <RecipeIngredient>[];
  int  _servings = 1;
  bool _saving   = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _nameCtrl.text = ex.name;
      _descCtrl.text = ex.description;
      _servings      = ex.servings;
      _ingredients.addAll(ex.ingredients);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  int get _perCals => _safeDivide(_totalCals, _servings);
  int get _perProt => _safeDivide(_totalProt, _servings);
  int get _perCarb => _safeDivide(_totalCarb, _servings);
  int get _perFat  => _safeDivide(_totalFat,  _servings);

  int get _totalCals => _ingredients.fold(0, (s, i) => s + i.calories);
  int get _totalProt => _ingredients.fold(0, (s, i) => s + i.proteinG);
  int get _totalCarb => _ingredients.fold(0, (s, i) => s + i.carbsG);
  int get _totalFat  => _ingredients.fold(0, (s, i) => s + i.fatG);

  int _safeDivide(int total, int by) =>
      by > 0 ? (total / by).round() : total;

  bool get _canSave =>
      !_saving &&
      _nameCtrl.text.trim().isNotEmpty &&
      _ingredients.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      maxChildSize:     0.98,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color:        vc.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: vc.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing != null ? 'Tarifi Düzenle' : 'Yeni Tarif',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: vc.text,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: vc.textSub),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  // Tarif adı
                  TextField(
                    controller: _nameCtrl,
                    style:      TextStyle(color: vc.text),
                    onChanged:  (_) => setState(() {}),
                    decoration: _inputDec(vc, 'Tarif adı *'),
                  ),
                  const SizedBox(height: 12),

                  // Açıklama
                  TextField(
                    controller: _descCtrl,
                    style:      TextStyle(color: vc.text),
                    maxLines:   2,
                    decoration: _inputDec(vc, 'Açıklama (opsiyonel)'),
                  ),
                  const SizedBox(height: 20),

                  // Kaç kişilik
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kaç kişilik?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: vc.text,
                              ),
                            ),
                            Text(
                              'Kişi başı kalori otomatik hesaplanır',
                              style: TextStyle(fontSize: 12, color: vc.textSub),
                            ),
                          ],
                        ),
                      ),
                      _IntStepper(
                        value:     _servings,
                        min:       1,
                        max:       20,
                        onChanged: (v) => setState(() => _servings = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Canlı özet
                  if (_ingredients.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:        _kProtein.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border:       Border.all(color: _kProtein.withValues(alpha: 0.18)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _servings > 1 ? 'Kişi Başı' : 'Toplam',
                            style: TextStyle(
                              fontSize: 12,
                              color: vc.textSub,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _NutBox('Kalori', '$_perCals', 'kcal', AppColors.calories),
                              _NutBox('Protein', '$_perProt', 'g', _kProtein),
                              _NutBox('Karb',    '$_perCarb', 'g', _kCarbs),
                              _NutBox('Yağ',     '$_perFat',  'g', _kFat),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Malzeme başlık
                  Row(
                    children: [
                      Text(
                        'Malzemeler',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: vc.text,
                        ),
                      ),
                      if (_ingredients.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color:        _kProtein.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_ingredients.length}',
                            style: const TextStyle(
                              color: _kProtein,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Malzeme listesi
                  ..._ingredients.asMap().entries.map((e) {
                    final idx = e.key;
                    final ing = e.value;
                    return _IngredientRow(
                      ingredient:       ing,
                      onRemove:         () => setState(() => _ingredients.removeAt(idx)),
                      onQuantityChange: (q) =>
                          setState(() => _ingredients[idx] = ing.copyWith(quantity: q)),
                    );
                  }),

                  // Ekle butonu
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon:     const Icon(Icons.add_rounded, color: _kProtein),
                    label:    const Text(
                      'Malzeme Ekle',
                      style: TextStyle(color: _kProtein, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _openPicker(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side:        BorderSide(color: _kProtein.withValues(alpha: 0.4)),
                      shape:       RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Kaydet
                  ElevatedButton(
                    onPressed: _canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kProtein,
                      disabledBackgroundColor: _kProtein.withValues(alpha: 0.3),
                      minimumSize: const Size(double.infinity, 54),
                      shape:       RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Tarifi Kaydet',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(VColors vc, String label) => InputDecoration(
    labelText:  label,
    labelStyle: TextStyle(color: vc.textSub),
    filled:     true,
    fillColor:  vc.surfaceHigh,
    border:     OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:   BorderSide.none,
    ),
  );

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IngredientPickerSheet(
        onAdd: (ing) => setState(() => _ingredients.add(ing)),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final id = widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final recipe = RecipeModel(
      id:          id,
      name:        _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      servings:    _servings,
      ingredients: List.unmodifiable(_ingredients),
      createdAt:   widget.existing?.createdAt ?? DateTime.now(),
    );
    await RecipeService.instance.saveRecipe(recipe);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }
}

// ── Ingredient Row ────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  final RecipeIngredient ingredient;
  final VoidCallback onRemove;
  final void Function(double) onQuantityChange;

  const _IngredientRow({
    required this.ingredient,
    required this.onRemove,
    required this.onQuantityChange,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Container(
      margin:     const EdgeInsets.only(bottom: 8),
      padding:    const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color:        vc.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: TextStyle(
                    color:      vc.text,
                    fontWeight: FontWeight.w600,
                    fontSize:   14,
                  ),
                ),
                Text(
                  '${ingredient.calories} kcal · ${ingredient.servingLabel}',
                  style: TextStyle(color: vc.textSub, fontSize: 11),
                ),
              ],
            ),
          ),
          _FloatStepper(
            value:     ingredient.quantity,
            onChanged: onQuantityChange,
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, color: vc.textSub, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ingredient Picker Sheet ───────────────────────────────────────────────────

class _IngredientPickerSheet extends StatefulWidget {
  final void Function(RecipeIngredient) onAdd;

  const _IngredientPickerSheet({required this.onAdd});

  @override
  State<_IngredientPickerSheet> createState() => _IngredientPickerSheetState();
}

class _IngredientPickerSheetState extends State<_IngredientPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<TurkishFoodItem> _results  = [];
  TurkishFoodItem?      _selected;
  double                _quantity = 1.0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() => _results = TurkishFoodsDB.search(q));
  }

  void _pick(TurkishFoodItem item) {
    setState(() {
      _selected = item;
      _quantity = 1.0;
    });
  }

  void _add() {
    final s = _selected!;
    widget.onAdd(RecipeIngredient(
      name:               s.name,
      quantity:           _quantity,
      servingLabel:       s.serving,
      caloriesPerServing: s.calories,
      proteinGPerServing: s.proteinG,
      carbsGPerServing:   s.carbsG,
      fatGPerServing:     s.fatG,
      fiberGPerServing:   s.fiberG,
      sodiumMgPerServing: s.sodiumMg,
      sugarGPerServing:   s.sugarG,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize:     0.96,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color:        vc.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: vc.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Malzeme Ekle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: vc.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    autofocus:  true,
                    style:      TextStyle(color: vc.text),
                    onChanged:  _search,
                    decoration: InputDecoration(
                      hintText:  'Yemek ara...',
                      hintStyle: TextStyle(color: vc.textSub),
                      prefixIcon: Icon(Icons.search_rounded, color: vc.textSub),
                      filled:    true,
                      fillColor: vc.surfaceHigh,
                      border:    OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:   BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Seçili malzeme paneli
            if (_selected != null)
              _SelectedPanel(
                item:      _selected!,
                quantity:  _quantity,
                onChanged: (q) => setState(() => _quantity = q),
                onAdd:     _add,
              ),

            const Divider(height: 1),

            // Sonuçlar veya popülerler
            Expanded(
              child: _searchCtrl.text.isEmpty && _results.isEmpty
                  ? _PopularList(onPick: _pick)
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(color: vc.textSub),
                          ),
                        )
                      : ListView.builder(
                          controller: ctrl,
                          itemCount:  _results.length,
                          itemBuilder: (_, i) {
                            final item = _results[i];
                            final selected = _selected?.name == item.name;
                            return ListTile(
                              selected: selected,
                              selectedTileColor: _kProtein.withValues(alpha: 0.08),
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  color: selected ? _kProtein : vc.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${item.calories} kcal · ${item.serving}',
                                style: TextStyle(color: vc.textSub, fontSize: 12),
                              ),
                              onTap: () => _pick(item),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Selected Panel ────────────────────────────────────────────────────────────

class _SelectedPanel extends StatelessWidget {
  final TurkishFoodItem item;
  final double quantity;
  final void Function(double) onChanged;
  final VoidCallback onAdd;

  const _SelectedPanel({
    required this.item,
    required this.quantity,
    required this.onChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final vc  = context.vt;
    final cal = (item.calories * quantity).round();
    return Container(
      margin:     const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding:    const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        _kProtein.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: _kProtein.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color:      vc.text,
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                      ),
                    ),
                    Text(
                      '1 porsiyon = ${item.serving} = ${item.calories} kcal',
                      style: TextStyle(color: vc.textSub, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _FloatStepper(value: quantity, onChanged: onChanged),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kProtein,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Ekle  ($cal kcal)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Popular List ──────────────────────────────────────────────────────────────

class _PopularList extends StatelessWidget {
  final void Function(TurkishFoodItem) onPick;

  const _PopularList({required this.onPick});

  static const _names = [
    'Haşlanmış yumurta',
    'Tavuk ızgara (göğüs)',
    'Pirinç pilavı',
    'Makarna (pişmiş)',
    'Domates',
    'Zeytinyağı',
    'Ekmek (beyaz)',
    'Süt (tam yağlı)',
    'Yoğurt (tam yağlı)',
    'Soğan',
    'Patates',
    'Mercimek çorbası',
  ];

  @override
  Widget build(BuildContext context) {
    final vc    = context.vt;
    final items = _names
        .map((n) => TurkishFoodsDB.search(n).firstOrNull)
        .nonNulls
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            'Sık kullanılanlar',
            style: TextStyle(
              fontSize: 13,
              color: vc.textSub,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              return ListTile(
                title: Text(
                  item.name,
                  style: TextStyle(color: vc.text, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${item.calories} kcal · ${item.serving}',
                  style: TextStyle(color: vc.textSub, fontSize: 12),
                ),
                onTap: () => onPick(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                color: _kProtein.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded, size: 36, color: _kProtein),
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz tarif yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: vc.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Kendi tariflerini oluştur.\nMalzemeleri seç, bir kez hesapla —\nsonra her öğüne tek dokunuşla ekle.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: vc.textSub, height: 1.5),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onTap,
              icon:  const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'İlk Tarifi Yap',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kProtein,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape:   RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color  color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color:        color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _NutBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color  color;

  const _NutBox(this.label, this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(unit,  style: TextStyle(fontSize: 10, color: vc.textSub)),
        Text(label, style: TextStyle(fontSize: 11, color: vc.textSub)),
      ],
    );
  }
}

// Tam sayı stepper (porsiyon)
class _IntStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _IntStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vc = context.vt;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon:    Icons.remove,
          enabled: value > min,
          onTap:   () => onChanged(value - 1),
          vc:      vc,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '$value',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: vc.text),
          ),
        ),
        _Btn(
          icon:    Icons.add,
          enabled: value < max,
          onTap:   () => onChanged(value + 1),
          vc:      vc,
        ),
      ],
    );
  }
}

// Ondalıklı stepper (malzeme miktarı)
class _FloatStepper extends StatelessWidget {
  final double value;
  final void Function(double) onChanged;

  const _FloatStepper({required this.value, required this.onChanged});

  static const _steps = <double>[
    0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0,
  ];

  int get _idx {
    final i = _steps.indexOf(value);
    return i < 0 ? _steps.indexOf(1.0) : i;
  }

  String get _display {
    if (value == 0.25) return '¼';
    if (value == 0.75) return '¾';
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final vc  = context.vt;
    final idx = _idx;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon:    Icons.remove,
          enabled: idx > 0,
          onTap:   () => onChanged(_steps[idx - 1]),
          vc:      vc,
          small:   true,
        ),
        SizedBox(
          width: 32,
          child: Text(
            _display,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: vc.text,
            ),
          ),
        ),
        _Btn(
          icon:    Icons.add,
          enabled: idx < _steps.length - 1,
          onTap:   () => onChanged(_steps[idx + 1]),
          vc:      vc,
          small:   true,
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;
  final VColors  vc;
  final bool     small;

  const _Btn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.vc,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final sz = small ? 28.0 : 36.0;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width:      sz,
        height:     sz,
        decoration: BoxDecoration(
          color:        enabled ? vc.surfaceHigh : vc.surfaceHigh.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size:  small ? 14 : 18,
          color: enabled ? vc.text : vc.textMuted,
        ),
      ),
    );
  }
}
