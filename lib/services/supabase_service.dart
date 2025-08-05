import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _client = Supabase.instance.client;
    
    // Ensure party creator account exists
    await _ensurePartyCreatorExists();
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    bool isPartyCreator = false,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'is_party_creator': isPartyCreator,
      },
    );

    if (response.user != null) {
      // Insert user role into the database
      await _client.from('user_roles').insert({
        'user_id': response.user!.id,
        'is_party_creator': isPartyCreator,
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<bool> isPartyCreator(String userId) async {
    final response = await _client
        .from('user_roles')
        .select('is_party_creator')
        .eq('user_id', userId)
        .single();
    
    return response['is_party_creator'] ?? false;
  }

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> _ensurePartyCreatorExists() async {
    try {
      // Try to sign in as party creator
      await signIn(
        email: 'ttemp6122@gmail.com',
        password: 'Testing123',
      );
      await signOut(); // Sign out after checking
    } catch (e) {
      // If sign in fails, create the account
      try {
        await signUp(
          email: 'ttemp6122@gmail.com',
          password: 'Testing123',
          isPartyCreator: true,
        );
        await signOut(); // Sign out after creation
      } catch (e) {
        // Ignore if account already exists or other errors
      }
    }

    // Also ensure regular user account exists
    try {
      await signIn(
        email: 'jraydirect@gmail.com',
        password: 'Testing123',
      );
      await signOut();
    } catch (e) {
      try {
        await signUp(
          email: 'jraydirect@gmail.com',
          password: 'Testing123',
          isPartyCreator: false,
        );
        await signOut();
      } catch (e) {
        // Ignore if account already exists or other errors
      }
    }
  }
}