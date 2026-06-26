import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/recipe_model.dart';

class RecipeService {
  RecipeService._();
  static final RecipeService instance = RecipeService._();

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  bool   get _hasUser => _uid != null;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('recipes');

  Future<void> saveRecipe(RecipeModel recipe) async {
    if (!_hasUser) return;
    try { await _col.doc(recipe.id).set(recipe.toJson()); } catch (_) {}
  }

  Future<void> updateRecipe(RecipeModel recipe) async {
    if (!_hasUser) return;
    try { await _col.doc(recipe.id).update(recipe.toJson()); } catch (_) {}
  }

  Future<void> deleteRecipe(String id) async {
    if (!_hasUser) return;
    try { await _col.doc(id).delete(); } catch (_) {}
  }

  Future<List<RecipeModel>> fetchRecipes() async {
    if (!_hasUser) return [];
    try {
      final snap = await _col.orderBy('createdAt', descending: true).get();
      return snap.docs
          .map((d) => RecipeModel.fromJson(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
