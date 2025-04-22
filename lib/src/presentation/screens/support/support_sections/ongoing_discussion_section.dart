import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/support_model/support_discussion_model.dart';

class OngoingDiscussionSection extends StatefulWidget {
  const OngoingDiscussionSection({super.key});

  @override
  OngoingDiscussionSectionState createState() =>
      OngoingDiscussionSectionState();
}

class OngoingDiscussionSectionState extends State<OngoingDiscussionSection> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < 4) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.055),
      child: Column(
        children: [
          Text(
            "Ongoing Discussion",
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(
              fontWeight: FontWeight.w700,
              fontSize: MediaQuery.of(context).size.width * 0.06,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Column(
            children: [
              SizedBox(
                height: 190,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildCard(supportDiscussionModel[index]);
                  },
                  itemCount: supportDiscussionModel.length,
                ),
              ),
              const SizedBox(height: 20),
              CustomDotIndicator(
                currentIndex: _currentPage,
                itemCount: 5,
                dotColor: const Color(0xFF4581DD),
                dotSize: 8,
                spacing: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic discussion) {
    return Card(
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              discussion["title"],
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.w700,
                fontSize: MediaQuery.of(context).size.width * 0.048,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              discussion["desc"],
              style: GoogleFonts.nunito(
                  color: Colors.black87,
                  fontSize: MediaQuery.of(context).size.width * 0.036),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Stack(clipBehavior: Clip.none, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          discussion["image1"],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: -30,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            discussion["image2"],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            discussion["image3"],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                          right: -160,
                          top: 8,
                          child: Text(
                            discussion["people"],
                            style:
                                GoogleFonts.nunito(fontWeight: FontWeight.w700),
                          ))
                    ]),
                  ],
                ),
                IconButton(
                    onPressed: () {},
                    icon: SvgPicture.asset(
                      "assets/icons/icon_svg/hearts.svg",
                      width: 28,
                    ))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomDotIndicator extends StatelessWidget {
  final int currentIndex;
  final int itemCount;
  final Color dotColor;
  final double dotSize;
  final double spacing;

  const CustomDotIndicator({
    super.key,
    required this.currentIndex,
    required this.itemCount,
    this.dotColor = const Color(0xFF4581DD),
    this.dotSize = 10,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) {
          return Container(
            width: dotSize,
            height: dotSize,
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentIndex == index ? dotColor : Colors.transparent,
              border: Border.all(
                color: currentIndex == index
                    ? Colors.transparent
                    : const Color(0xFF4581DD),
                width: 1,
              ),
            ),
          );
        },
      ),
    );
  }
}
