import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/auth_provider.dart';
import '../router.dart';
import '../theme.dart';
import '../widgets/ui.dart';

/// First-run tour, in the style of the store screenshots.
class TourScreen extends StatefulWidget {
  const TourScreen({super.key});

  @override
  State<TourScreen> createState() => _TourScreenState();
}

class _TourScreenState extends State<TourScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      title: 'Car & Bike Wash\nat Your Doorstep',
      body: 'Trained washers come to your home or office with everything they need.',
      image: Photos.hero,
    ),
    _Slide(
      title: 'Book Your Wash\nin 3 Easy Steps',
      body: 'Pick a service, choose a time slot, and confirm. Pay after the wash or online.',
      image: Photos.premium,
    ),
    _Slide(
      title: 'Track Every Wash,\nLive',
      body: 'See when the washer is assigned, on the way and done. Before and after photos included.',
      image: Photos.interior,
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final auth = context.read<AuthProvider>();
    await context.read<TourGate>().finish();
    await auth.markOnboardingSeen();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 12, 0),
                  child: TextButton(onPressed: _finish, child: const Text('Skip')),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) => _SlideView(_slides[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.ink : AppColors.line,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: PrimaryButton(
                  label: last ? 'Get started' : 'Next',
                  icon: last ? null : Icons.arrow_forward_rounded,
                  onPressed: () {
                    if (last) {
                      _finish();
                    } else {
                      _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.title, required this.body, required this.image});

  final String title;
  final String body;
  final String image;
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.slide);

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(slide.title, style: AppText.hero)),
              const Padding(padding: EdgeInsets.only(bottom: 6), child: Sparkle(size: 26)),
            ],
          ),
          const SizedBox(height: 12),
          Text(slide.body, style: AppText.body.copyWith(fontSize: 15)),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => Center(
                child: Container(
                  width: box.maxWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10))],
                  ),
                  child: Photo(slide.image, width: box.maxWidth, height: box.maxHeight, radius: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
