import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class OnboardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // OPTIMASI: Menggunakan sizeOf untuk kinerja performa rebuild yang lebih hemat
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Center(
        // SOLUSI: Menggunakan SingleChildScrollView agar aman dari eror overflow di layar kecil
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize
                .min, // Sesuai dengan isi konten agar tidak rakus space
            children: [
              // Image Section dengan batasan constraints yang fleksibel
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      screenHeight *
                      0.35, // Sedikit dikurangi agar ruang teks lebih lega
                ),
                child: Image.asset(image, fit: BoxFit.contain),
              ),
              const SizedBox(height: 32),

              // Title Section
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description Section
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.text,
                  height:
                      1.4, // Menambah line height agar teks lebih nyaman dibaca
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
