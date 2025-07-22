class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Simulated Google Sign-In method
  Future<bool> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // For demo purposes, always return true
    // In a real app, implement actual Google Sign-In here
    return true;
  }

  // Simulated email/password sign in
  Future<bool> signInWithEmail(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Basic validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty');
    }

    if (!email.contains('@')) {
      throw Exception('Please enter a valid email address');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // For demo purposes, always return true
    return true;
  }

  // Simulated sign up
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String confirmPassword,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Basic validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      throw Exception('All fields are required');
    }

    if (!email.contains('@')) {
      throw Exception('Please enter a valid email address');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    if (password != confirmPassword) {
      throw Exception('Passwords do not match');
    }

    // For demo purposes, always return true
    return true;
  }
}
