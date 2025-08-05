import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:inviteme/services/supabase_service.dart';
import 'package:inviteme/pages/party_creator_page.dart';
import 'package:inviteme/pages/parties_page.dart';
import 'package:inviteme/pages/signup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase - Replace with your actual Supabase URL and anon key
  await SupabaseService().initialize(
    supabaseUrl: 'https://ejebwmifyiwixnrjcuud.supabase.co',
    supabaseAnonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVqZWJ3bWlmeWl3aXhucmpjdXVkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQzNjU4NTEsImV4cCI6MjA2OTk0MTg1MX0.H6WJIt24gdX_6qR5mdz1U19Bz3IkD0zS1jAizaLS4Ds',
  );
  
  runApp(const InviteMeApp());
}

class InviteMeApp extends StatelessWidget {
  const InviteMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InviteMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}



// Confetti Animation Widget
class ConfettiAnimation extends StatefulWidget {
  const ConfettiAnimation({super.key});

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<ConfettiParticle> particles = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 5), // Slower animation
      vsync: this,
    )..repeat();

    // Create confetti particles - more for raining effect
    for (int i = 0; i < 100; i++) {
      particles.add(ConfettiParticle());
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(particles, _animationController.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class ConfettiParticle {
  late double x;
  late double y;
  late double size;
  late Color color;
  late double speed;
  late double rotation;
  late double opacity;

  ConfettiParticle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = -0.1 - math.Random().nextDouble() * 0.2; // Start closer to top
    size = math.Random().nextDouble() * 8 + 4; // Slightly smaller confetti
    speed = math.Random().nextDouble() * 0.4 + 0.2; // Even slower speeds
    rotation = math.Random().nextDouble() * 2 * math.pi;
    opacity = 1.0;
    
    // Enhanced confetti colors - more vibrant party colors
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF69B4), // Hot Pink
      const Color(0xFF00BFFF), // Deep Sky Blue
      const Color(0xFF32CD32), // Lime Green
      const Color(0xFFFF4500), // Orange Red
      const Color(0xFF9370DB), // Medium Purple
      const Color(0xFFFF1493), // Deep Pink
      const Color(0xFF00FF7F), // Spring Green
      const Color(0xFFFFB347), // Peach
      const Color(0xFF87CEEB), // Sky Blue
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }

  void update(double progress) {
    y += speed * 0.005; // Even slower fall speed
    rotation += 0.05;
    
    // Add subtle horizontal drift for more natural movement
    x += math.sin(y * 8) * 0.002;
    
    // Fade out as it falls
    if (y > 0.2) { // Start fading after 20% of screen height
      opacity = math.max(0, 1.0 - (y - 0.2) / 0.4); // Fade out over next 40% of screen
    }
    
    // Reset when particle goes off screen or becomes invisible
    if (y > 1.0 || opacity <= 0) {
      reset();
    }
  }
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animationValue;

  ConfettiPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(animationValue);
      
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation);
      
      // Draw confetti as small rectangles
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with image and login content
          Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/loginBackground.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromRGBO(108, 99, 255, 0.7),
                    Color.fromRGBO(156, 89, 209, 0.7),
                    Color.fromRGBO(252, 70, 107, 0.7),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Top section with logo
                                  Column(
                                    children: [
                                      const SizedBox(height: 40),
                                      
                                      // Floating Logo - No party icon, much bigger
                                      FadeInDown(
                                        duration: const Duration(milliseconds: 800),
                                        child: TweenAnimationBuilder<double>(
                                          duration: const Duration(seconds: 6),
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          builder: (context, value, child) {
                                            return Transform.translate(
                                              offset: Offset(0, math.sin(value * 2 * math.pi) * 12),
                                              child: Image.asset(
                                                'assets/logo.png',
                                                height: 300, // Reduced size so form fits
                                                fit: BoxFit.contain,
                                              ),
                                            );
                                          },
                                          onEnd: () {
                                            // Restart the animation
                                            setState(() {});
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 0), // Moved closer to logo
                                      Text(
                                        'Create the Vibe. Invite the Tribe.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 20, // Bigger font
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600, // Slightly bolder
                                          letterSpacing: 0.5, // Added letter spacing for better readability
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  // Login form section
                                  Column(
                                    children: [
                                      // Login Form with Yellow Trim
                                      FadeInUp(
                                        duration: const Duration(milliseconds: 1000),
                                        child: Container(
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFFFFD700), // Yellow trim
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 20,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Form(
                                            key: _formKey,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  'Welcome Back!',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF2D3748),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Sign in to continue discovering amazing parties',
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: const Color(0xFF718096),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                                const SizedBox(height: 18),

                                                // Email Field
                                                _buildTextField(
                                                  controller: _emailController,
                                                  label: 'Email',
                                                  icon: Icons.email_outlined,
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Please enter your email';
                                                    }
                                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                                      return 'Please enter a valid email';
                                                    }
                                                    return null;
                                                  },
                                                ),

                                                const SizedBox(height: 12),

                                                // Password Field
                                                _buildTextField(
                                                  controller: _passwordController,
                                                  label: 'Password',
                                                  icon: Icons.lock_outlined,
                                                  isPassword: true,
                                                  validator: (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Please enter your password';
                                                    }
                                                    if (value.length < 6) {
                                                      return 'Password must be at least 6 characters';
                                                    }
                                                    return null;
                                                  },
                                                ),

                                                const SizedBox(height: 18),

                                                // Login Button
                                                _buildLoginButton(),

                                                const SizedBox(height: 12),

                                                // Divider
                                                Row(
                                                  children: [
                                                    const Expanded(child: Divider()),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: Text(
                                                        'OR',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 10,
                                                          color: const Color(0xFF718096),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    const Expanded(child: Divider()),
                                                  ],
                                                ),

                                                const SizedBox(height: 12),

                                                // Social Login Buttons
                                                _buildSocialLoginButtons(),
                                                
                                                const SizedBox(height: 16),
                                                
                                                // Sign Up Link
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Don\'t have an account?',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 11,
                                                        color: const Color(0xFF718096),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => const SignUpPage(),
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Sign Up',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 11,
                                                          color: const Color(0xFF6C63FF),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 30),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Confetti overlay - On top, but ignoring pointer events
          const Positioned.fill(
            child: IgnorePointer(
              child: ConfettiAnimation(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: const Color(0xFF718096),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF6C63FF),
          size: 16,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF718096),
                  size: 16,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF6C63FF).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Sign In',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialLoginButtons() {
    return Column(
      children: [
        _buildSocialButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          color: const Color(0xFFDB4437),
          onPressed: () {
            // TODO: Implement Google sign in
          },
        ),
        const SizedBox(height: 4),
        _buildSocialButton(
          label: 'Continue with Apple',
          icon: Icons.apple,
          color: const Color(0xFF000000),
          onPressed: () {
            // TODO: Implement Apple sign in
          },
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon, color: color, size: 14),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF2D3748),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final supabase = SupabaseService();
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        // Check if this is the party creator account
        final isPartyCreator = email == 'ttemp6122@gmail.com';
        
        final response = await supabase.signIn(
          email: email,
          password: password,
        );

        if (!mounted) return;

        if (response.user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => IntranetPage(isPartyCreator: isPartyCreator),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}

// Intranet Page with Bottom Navigation
class IntranetPage extends StatefulWidget {
  final bool isPartyCreator;
  
  const IntranetPage({
    super.key,
    required this.isPartyCreator,
  });

  @override
  State<IntranetPage> createState() => _IntranetPageState();
}

class _IntranetPageState extends State<IntranetPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      widget.isPartyCreator
          ? const PartyCreatorPage()  // Admin view for party creator
          : const PartiesPage(),      // Regular user view
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFAFAFA),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFF6C63FF).withOpacity(0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.celebration_outlined,
                      activeIcon: Icons.celebration,
                      label: 'Parties',
                      index: 0,
                      isActive: _currentIndex == 0,
                    ),
                    _buildNavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Profile',
                      index: 1,
                      isActive: _currentIndex == 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.12),
                      const Color(0xFF6C63FF).withOpacity(0.08),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: isActive
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF6C63FF),
                            Color(0xFF9C59D1),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6C63FF).withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? const Color(0xFF6C63FF) : const Color(0xFF9CA3AF),
                  height: 1.0,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// Profile Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF6C63FF)),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF7FAFC),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage your account settings and preferences',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: const Color(0xFF718096),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '⚙️ Profile settings coming soon! ⚙️',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
