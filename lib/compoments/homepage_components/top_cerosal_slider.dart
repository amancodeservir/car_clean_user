import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class CarouselWithButtons extends StatefulWidget {
  @override
  _CarouselWithButtonsState createState() => _CarouselWithButtonsState();
}

class _CarouselWithButtonsState extends State<CarouselWithButtons> {
  List<String> imgList = [
    'https://i.pinimg.com/736x/32/81/b9/3281b9d22a591aa3208f1340f3cc50e4.jpg',
    'https://quicksetautoglass.com/wp-content/uploads/freshizer/e1abe7d378fed5a2c8b9cf3eb31628e4_automatic-car-wash-basics-950-c-90.jpg',
    'https://zoomcarwash.com.au/wp-content/uploads/2023/08/man-washing-his-car-garage.jpg',
    'https://i.pinimg.com/736x/32/81/b9/3281b9d22a591aa3208f1340f3cc50e4.jpg',
  ];

  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carousel with Buttons'),
      ),
      body: Column(
        children: [
          CarouselSlider.builder(
            itemCount: imgList.length,
            itemBuilder: (context, index, realIndex) {
              return Image.network(
                imgList[index],
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child; // Image loaded
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                            : null
                            : null,
                      ),
                    );
                  }
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Icon(Icons.error)); // Display error icon if image fails to load
                },
              );
            },
            options: CarouselOptions(
              autoPlay: true,
              enlargeCenterPage: true,
              viewportFraction: 1.0,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imgList.asMap().entries.map((entry) {
              return GestureDetector(
                child: Container(
                  width: 8.0,
                  height: 8.0,
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black)
                        .withOpacity(_current == entry.key ? 0.9 : 0.4),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
