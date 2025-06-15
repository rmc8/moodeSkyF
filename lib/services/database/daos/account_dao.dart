// Package imports:
import 'package:drift/drift.dart';

// Project imports:
import 'package:moodesky/services/database/database.dart';
import 'package:moodesky/services/database/tables/accounts.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [Accounts])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(AppDatabase db) : super(db);

  // Get all accounts ordered by usage
  Future<List<Account>> getAllAccounts() {
    return (select(accounts)..orderBy([
          (t) => OrderingTerm(expression: t.isActive, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.lastUsed, mode: OrderingMode.desc),
          (t) =>
              OrderingTerm(expression: t.accountOrder, mode: OrderingMode.asc),
        ]))
        .get();
  }

  // Get active account
  Future<Account?> getActiveAccount() {
    return (select(
      accounts,
    )..where((t) => t.isActive.equals(true))).getSingleOrNull();
  }

  // Get account by DID
  Future<Account?> getAccountByDid(String did) {
    return (select(
      accounts,
    )..where((t) => t.did.equals(did))).getSingleOrNull();
  }

  // Get account by handle
  Future<Account?> getAccountByHandle(String handle) {
    return (select(
      accounts,
    )..where((t) => t.handle.equals(handle))).getSingleOrNull();
  }

  // Create new account
  Future<int> createAccount(AccountsCompanion account) {
    return into(accounts).insert(account);
  }

  // Upsert account (insert or update based on DID)
  Future<int> upsertAccountByDid(AccountsCompanion account) async {
    return await transaction(() async {
      if (!account.did.present) {
        throw ArgumentError('DID must be provided for upsert operation');
      }

      final did = account.did.value;
      final handle = account.handle.present ? account.handle.value : null;

      // Check if account with this DID already exists
      final existingAccountByDid = await getAccountByDid(did);

      if (existingAccountByDid != null) {
        // Update existing account by DID
        final updatedRows =
            await (update(accounts)..where((t) => t.did.equals(did))).write(
              account.copyWith(id: const Value.absent()),
            );
        return updatedRows;
      } else if (handle != null) {
        // Check if an account with the same handle but different DID exists
        final existingAccountByHandle = await getAccountByHandle(handle);

        if (existingAccountByHandle != null) {
          // Remove the old account with same handle but different DID
          await (delete(accounts)..where((t) => t.handle.equals(handle))).go();
        }

        // Insert new account
        return await into(accounts).insert(account);
      } else {
        // Insert new account (no handle conflict possible)
        return await into(accounts).insert(account);
      }
    });
  }

  // Update account
  Future<bool> updateAccount(Account account) {
    return update(accounts).replace(account);
  }

  // Update account with OAuth session data
  Future<int> updateAccountWithOAuthSession({
    required String did,
    required String accessJwt,
    required String refreshJwt,
    required String dpopPublicKey,
    required String dpopPrivateKey,
    required String dpopNonce,
    required DateTime tokenExpiry,
    String? scope,
  }) {
    return (update(accounts)..where((t) => t.did.equals(did))).write(
      AccountsCompanion(
        accessJwt: Value(accessJwt),
        refreshJwt: Value(refreshJwt),
        dpopPublicKey: Value(dpopPublicKey),
        dpopPrivateKey: Value(dpopPrivateKey),
        dpopNonce: Value(dpopNonce),
        tokenExpiry: Value(tokenExpiry),
        scope: Value(scope),
        loginMethod: const Value('oauth'),
        lastUsed: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Update account with app password session
  Future<int> updateAccountWithAppPasswordSession({
    required String did,
    required String accessJwt,
    required String refreshJwt,
    required String sessionString,
    DateTime? tokenExpiry,
  }) {
    return (update(accounts)..where((t) => t.did.equals(did))).write(
      AccountsCompanion(
        accessJwt: Value(accessJwt),
        refreshJwt: Value(refreshJwt),
        sessionString: Value(sessionString),
        tokenExpiry: Value(tokenExpiry),
        loginMethod: const Value('app_password'),
        lastUsed: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Set active account (deactivates others)
  Future<void> setActiveAccount(String did) async {
    await transaction(() async {
      // Deactivate all accounts
      await (update(accounts)).write(
        const AccountsCompanion(
          isActive: Value(false),
          updatedAt: Value.absent(),
        ),
      );

      // Activate specified account
      await (update(accounts)..where((t) => t.did.equals(did))).write(
        AccountsCompanion(
          isActive: const Value(true),
          lastUsed: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  // Update last used timestamp
  Future<int> updateLastUsed(String did) {
    return (update(accounts)..where((t) => t.did.equals(did))).write(
      AccountsCompanion(
        lastUsed: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Delete account
  Future<int> deleteAccount(String did) {
    return (delete(accounts)..where((t) => t.did.equals(did))).go();
  }

  // Clear session data (logout)
  Future<int> clearAccountSession(String did) {
    return (update(accounts)..where((t) => t.did.equals(did))).write(
      const AccountsCompanion(
        accessJwt: Value(null),
        refreshJwt: Value(null),
        sessionString: Value(null),
        dpopPublicKey: Value(null),
        dpopPrivateKey: Value(null),
        dpopNonce: Value(null),
        tokenExpiry: Value(null),
        scope: Value(null),
        isActive: Value(false),
        updatedAt: Value.absent(),
      ),
    );
  }

  // Get accounts that need token refresh
  Future<List<Account>> getAccountsNeedingRefresh() {
    final fiveMinutesFromNow = DateTime.now().add(const Duration(minutes: 5));
    return (select(accounts)..where(
          (t) =>
              t.loginMethod.equals('oauth') &
              t.tokenExpiry.isNotNull() &
              t.tokenExpiry.isSmallerThanValue(fiveMinutesFromNow),
        ))
        .get();
  }

  // Update account profile information
  Future<int> updateAccountProfile({
    required String did,
    String? displayName,
    String? description,
    String? avatar,
    String? banner,
  }) {
    return (update(accounts)..where((t) => t.did.equals(did))).write(
      AccountsCompanion(
        displayName: Value(displayName),
        description: Value(description),
        avatar: Value(avatar),
        banner: Value(banner),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Update account order for multi-account management
  Future<int> updateAccountOrder(String did, int order) {
    return (update(accounts)..where((t) => t.did.equals(did))).write(
      AccountsCompanion(
        accountOrder: Value(order),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Update account label
  Future<int> updateAccountLabel(String did, String? label) {
    return (update(accounts)..where((t) => t.did.equals(did))).write(
      AccountsCompanion(
        accountLabel: Value(label),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Update token expiry
  Future<int> updateAccountTokenExpiry(String did, DateTime? tokenExpiry) {
    return (update(accounts)..where((t) => t.did.equals(did))).write(
      AccountsCompanion(
        tokenExpiry: Value(tokenExpiry),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Get OAuth accounts (excluding app password accounts)
  Future<List<Account>> getOAuthAccounts() {
    return (select(
      accounts,
    )..where((t) => t.loginMethod.equals('oauth'))).get();
  }

  // Get app password accounts
  Future<List<Account>> getAppPasswordAccounts() {
    return (select(
      accounts,
    )..where((t) => t.loginMethod.equals('app_password'))).get();
  }

  // Watch active account changes
  Stream<Account?> watchActiveAccount() {
    return (select(
      accounts,
    )..where((t) => t.isActive.equals(true))).watchSingleOrNull();
  }

  // Watch all accounts
  Stream<List<Account>> watchAllAccounts() {
    return (select(accounts)..orderBy([
          (t) => OrderingTerm(expression: t.isActive, mode: OrderingMode.desc),
          (t) => OrderingTerm(expression: t.lastUsed, mode: OrderingMode.desc),
          (t) =>
              OrderingTerm(expression: t.accountOrder, mode: OrderingMode.asc),
        ]))
        .watch();
  }

  // Delete all mock OAuth accounts
  Future<int> deleteMockOAuthAccounts() {
    return (delete(
      accounts,
    )..where((t) => t.did.like('did:plc:oauth_mock_%'))).go();
  }

  // Alias methods for backward compatibility
  Future<Account?> getAccount(String did) => getAccountByDid(did);

  Future<void> setAllAccountsInactive() async {
    await (update(
      accounts,
    )).write(const AccountsCompanion(isActive: Value(false)));
  }

  Future<void> setAccountActive(String did) async {
    await setActiveAccount(did);
  }

  Future<void> setAccountInactive(String did) async {
    await (update(accounts)..where((t) => t.did.equals(did))).write(
      const AccountsCompanion(isActive: Value(false)),
    );
  }

  Future<void> deleteAllAccounts() async {
    await delete(accounts).go();
  }
}
