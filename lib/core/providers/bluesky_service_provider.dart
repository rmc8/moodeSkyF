// Package imports:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Project imports:
import 'package:moodesky/core/providers/database_provider.dart';
import 'package:moodesky/services/bluesky/bluesky_service_v2.dart';
import 'package:moodesky/shared/models/auth_models.dart';

/// Provider for the Bluesky service - using regular Provider to ensure singleton instance
final blueskyServiceProvider = Provider<BlueskyServiceV2>((ref) {
  final database = ref.watch(databaseProvider);
  
  final service = BlueskyServiceV2(
    database: database,
    secureStorage: const FlutterSecureStorage(),
    authConfig: const AuthConfig(defaultPdsHost: 'bsky.social'),
  );

  // Initialize service asynchronously inside a background process or before first use
  // We don't await here as providers are synchronous, but the service handles internal state
  
  return service;
});
