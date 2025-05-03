import 'package:flutter/material.dart';
import 'package:anx_reader/page/book_player/page_turn/page_turn_animation.dart';
import 'package:anx_reader/enums/page_direction.dart';

class SlideAnimation extends PageTurnAnimation {
  PageDirection? pageDirection;
  final Function() onNextPage;
  final Function() onPrevPage;

  SlideAnimation({
    required this.onNextPage,
    required this.onPrevPage,
  });

  @override
  void onDragStart(DragStartDetails details) {
    if (isPageTurning) return;
    isPageTurning = true;
    turnedPage = false;
    pageDirection = null;
    position = 0;
    currentImage = preparedImage;
    showAnimationScreen = true;
  }

  @override
  void onDragUpdate(DragUpdateDetails details, BuildContext context) {
    if (!turnedPage) {
      turnedPage = true;
      if (details.delta.dx < 0) {
        pageDirection = PageDirection.next;
        onNextPage();
      } else {
        pageDirection = PageDirection.prev;
        onPrevPage();
      }
    }
    if (pageDirection == PageDirection.next && position + details.delta.dx > 0 ||
        pageDirection == PageDirection.prev && position + details.delta.dx < 0) {
      return;
    }
    position += details.delta.dx;
  }

  @override
  Future<void> onDragEnd(DragEndDetails details, BuildContext context, Function(void Function()) setState) async {
    turnedPage = false;
    double time = 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final shouldTurnPage = position.abs() > screenWidth / 10;

    if (!shouldTurnPage) {
      if (pageDirection == PageDirection.next) {
        onPrevPage();
      } else if (pageDirection == PageDirection.prev) {
        onNextPage();
      }
      while (position.abs() > 0) {
        time += 0.01;
        if (pageDirection == PageDirection.next) {
          position += (time * time) + 5;
          if (position > 0) position = 0;
        } else {
          position -= (time * time) + 5;
          if (position < 0) position = 0;
        }
        await Future.delayed(const Duration(milliseconds: 1));
        setState(() {});
      }
    } else {
      while (position.abs() < screenWidth) {
        time += 0.01;
        if (pageDirection == PageDirection.next) {
          position -= (time * time) + 5;
        } else {
          position += (time * time) + 5;
        }
        await Future.delayed(const Duration(milliseconds: 1));
        setState(() {});
      }
    }
    pageDirection = null;
    showAnimationScreen = false;
    isPageTurning = false;
  }

  @override
  Widget buildAnimationWidget(BuildContext context) {
    if (!showAnimationScreen) return const SizedBox();
    
    return Positioned(
      left: position,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(180),
              blurRadius: 10,
            ),
          ],
        ),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: currentImage,
      ),
    );
  }
} 