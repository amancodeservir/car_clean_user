import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../theme/brand_theme.dart';
import '../../utils/constants.dart';

class CarouselWithButtons extends StatefulWidget {
  const CarouselWithButtons({super.key});

  @override
  State<CarouselWithButtons> createState() => _CarouselWithButtonsState();
}

class _CarouselWithButtonsState extends State<CarouselWithButtons> {
  final List<String> imgList = [
    AppConstants.photoHero,
    AppConstants.photoBasic,
    AppConstants.photoInterior,
    AppConstants.photoBeforeAfter,
  ];

  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: imgList.length,
          itemBuilder: (context, index, realIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BrandPhoto(asset: imgList[index], height: 200),
            );
          },
          options: CarouselOptions(
            height: 200,
            autoPlay: imgList.length > 1,
            enlargeCenterPage: false,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: imgList.asMap().entries.map((entry) {
            final active = _current == entry.key;
            return Container(
              width: active ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: active ? AppConstants.signal : AppConstants.line,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
