// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:drift/drift.dart';

// Project imports:
import 'package:moodesky/services/database/database.dart';
import 'package:moodesky/services/database/tables/decks.dart';

part 'deck_dao.g.dart';

@DriftAccessor(tables: [Decks])
class DeckDao extends DatabaseAccessor<AppDatabase> with _$DeckDaoMixin {
  DeckDao(AppDatabase db) : super(db);

  // Get all decks ordered by position
  Future<List<Deck>> getAllDecks() {
    return (select(decks)..orderBy([
          (t) => OrderingTerm(expression: t.deckOrder, mode: OrderingMode.asc),
        ]))
        .get();
  }

  // Get decks for specific account
  Future<List<Deck>> getDecksForAccount(String accountDid) {
    return (select(decks)
          ..where(
            (t) =>
                t.accountDid.equals(accountDid) | t.isCrossAccount.equals(true),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.deckOrder, mode: OrderingMode.asc),
          ]))
        .get();
  }

  // Get deck by ID
  Future<Deck?> getDeckById(String deckId) {
    return (select(
      decks,
    )..where((t) => t.deckId.equals(deckId))).getSingleOrNull();
  }

  // Create new deck
  Future<int> createDeck(DecksCompanion deck) {
    return into(decks).insert(deck);
  }

  // Update deck
  Future<bool> updateDeck(Deck deck) {
    return update(decks).replace(deck);
  }

  // Delete deck
  Future<int> deleteDeck(String deckId) async {
    debugPrint('🗃️ DeckDao.deleteDeck: Starting deletion for deckId=$deckId');

    final result = await (delete(
      decks,
    )..where((t) => t.deckId.equals(deckId))).go();

    debugPrint(
      '🗃️ DeckDao.deleteDeck: Deleted $result rows for deckId=$deckId',
    );
    return result;
  }

  // Update deck order
  Future<bool> updateDeckOrder(String deckId, int order) async {
    final count = await (update(decks)..where((t) => t.deckId.equals(deckId)))
        .write(
          DecksCompanion(
            deckOrder: Value(order),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return count > 0;
  }

  // Update deck visibility
  Future<bool> updateDeckVisibility(String deckId, bool isVisible) async {
    final count = await (update(decks)..where((t) => t.deckId.equals(deckId)))
        .write(
          DecksCompanion(
            isVisible: Value(isVisible),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return count > 0;
  }

  // Mark deck as favorite
  Future<bool> updateDeckFavorite(String deckId, bool isFavorite) async {
    final count = await (update(decks)..where((t) => t.deckId.equals(deckId)))
        .write(
          DecksCompanion(
            isFavorite: Value(isFavorite),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return count > 0;
  }

  // Update last refresh time
  Future<bool> updateLastRefresh(String deckId) async {
    final count = await (update(decks)..where((t) => t.deckId.equals(deckId)))
        .write(
          DecksCompanion(
            lastRefresh: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return count > 0;
  }

  // Update last read time
  Future<bool> updateLastRead(String deckId) async {
    final count = await (update(decks)..where((t) => t.deckId.equals(deckId)))
        .write(
          DecksCompanion(
            lastRead: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return count > 0;
  }

  // Get favorite decks
  Future<List<Deck>> getFavoriteDecks() {
    return (select(decks)
          ..where((t) => t.isFavorite.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.deckOrder, mode: OrderingMode.asc),
          ]))
        .get();
  }

  // Watch all decks
  Stream<List<Deck>> watchAllDecks() {
    return (select(decks)..orderBy([
          (t) => OrderingTerm(expression: t.deckOrder, mode: OrderingMode.asc),
        ]))
        .watch();
  }

  // Watch decks for account
  Stream<List<Deck>> watchDecksForAccount(String accountDid) {
    return (select(decks)
          ..where(
            (t) =>
                t.accountDid.equals(accountDid) | t.isCrossAccount.equals(true),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.deckOrder, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  // Delete decks associated with a specific account (excluding cross-account decks)
  Future<int> deleteDecksForAccount(String accountDid) async {
    debugPrint('🗃️ DeckDao.deleteDecksForAccount: Starting deletion for accountDid=${accountDid.substring(0, 20)}...');
    
    // まず削除対象となるデッキを確認
    final candidateDecks = await (select(decks)
          ..where((t) => 
              t.accountDid.isNotNull() & 
              t.accountDid.equals(accountDid) & 
              t.isCrossAccount.equals(false)
          )).get();
    
    debugPrint('🗃️ DeckDao.deleteDecksForAccount: Found ${candidateDecks.length} candidate decks for deletion');
    for (final deck in candidateDecks) {
      debugPrint('  - Deck: ${deck.deckId} | Title: ${deck.title} | AccountDid: ${deck.accountDid} | IsCrossAccount: ${deck.isCrossAccount}');
    }
    
    // 全デッキの状況も確認（デバッグ用）
    final allDecks = await getAllDecks();
    debugPrint('🗃️ DeckDao.deleteDecksForAccount: Current deck inventory (${allDecks.length} total):');
    for (final deck in allDecks) {
      debugPrint('  - Deck: ${deck.deckId} | Title: ${deck.title} | AccountDid: ${deck.accountDid} | IsCrossAccount: ${deck.isCrossAccount}');
    }
    
    // より確実な削除を行うため、条件を改善
    // accountDidがnullでないことも確認
    final result = await (delete(decks)
          ..where((t) => 
              t.accountDid.isNotNull() & 
              t.accountDid.equals(accountDid) & 
              t.isCrossAccount.equals(false)
          )).go();
    
    debugPrint('🗃️ DeckDao.deleteDecksForAccount: Deleted $result account-specific decks for accountDid=${accountDid.substring(0, 20)}...');
    return result;
  }

  // Delete all decks (used during complete account cleanup)
  Future<int> deleteAllDecks() async {
    debugPrint('🗃️ DeckDao.deleteAllDecks: Starting deletion of all decks');
    
    // 削除前の状況を確認
    final allDecks = await getAllDecks();
    debugPrint('🗃️ DeckDao.deleteAllDecks: Current deck inventory (${allDecks.length} total):');
    for (final deck in allDecks) {
      debugPrint('  - Deck: ${deck.deckId} | Title: ${deck.title} | AccountDid: ${deck.accountDid} | IsCrossAccount: ${deck.isCrossAccount}');
    }
    
    final result = await delete(decks).go();
    
    debugPrint('🗃️ DeckDao.deleteAllDecks: Deleted $result decks total');
    return result;
  }
}
