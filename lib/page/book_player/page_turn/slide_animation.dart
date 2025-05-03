import 'package:flutter/material.dart';
import 'package:anx_reader/page/book_player/page_turn/page_turn_animation.dart';
import 'package:anx_reader/enums/page_direction.dart';
import 'package:anx_reader/main.dart';

class SlideAnimation extends PageTurnAnimation {
  PageDirection? pageDirection;
  final Function() onNextPage;
  final Function() onPrevPage;
  final screenWidth = MediaQuery.of(navigatorKey.currentContext!).size.width;

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
    webviewPosition = 0;
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
        showAnimationScreen = false;
        // 当检测到是返回上一页时，立即将webview移到屏幕左侧
        webviewPosition = -screenWidth;
      }
    }

    if (pageDirection == PageDirection.next) {
      if (position + details.delta.dx > 0) return;
      position += details.delta.dx;
    } else if (pageDirection == PageDirection.prev) {
      // 对于返回上一页，只更新webview的位置，不更新底层截图的位置
      if (webviewPosition + details.delta.dx > 0) return;
      webviewPosition += details.delta.dx;
    }
  }

  @override
  Future<void> onDragEnd(DragEndDetails details, BuildContext context, Function(void Function()) setState) async {
    turnedPage = false;
    double time = 0.0;
    final shouldTurnPage = pageDirection == PageDirection.next 
        ? position.abs() > screenWidth / 10
        : webviewPosition.abs() < screenWidth * 0.9; // 为上一页调整判断逻辑

    if (!shouldTurnPage) {
      if (pageDirection == PageDirection.next) {
        onPrevPage();
        while (position.abs() > 0) {
          time += 0.01;
          position += (time * time) + 5;
          if (position > 0) position = 0;
          await Future.delayed(const Duration(milliseconds: 1));
          setState(() {});
        }
      } else if (pageDirection == PageDirection.prev) {
        onNextPage();
        while (webviewPosition < 0) {
          time += 0.01;
          webviewPosition -= (time * time) + 5;
          if (webviewPosition < -screenWidth) webviewPosition = -screenWidth;
          await Future.delayed(const Duration(milliseconds: 1));
          setState(() {});
        }
      }
    } else {
      if (pageDirection == PageDirection.next) {
        while (position.abs() < screenWidth) {
          time += 0.01;
          position -= (time * time) + 5;
          await Future.delayed(const Duration(milliseconds: 1));
          setState(() {});
        }
      } else {
        while (webviewPosition < 0) {
          time += 0.01;
          webviewPosition += (time * time) + 5;
          await Future.delayed(const Duration(milliseconds: 1));
          setState(() {});
        }
        webviewPosition = 0; // 确保webview最终回到原位
      }
    }
    
    pageDirection = null;
    showAnimationScreen = false;
    isPageTurning = false;
  }

  @override
  Widget buildAnimationWidget(BuildContext context) {
    if (!showAnimationScreen) return const SizedBox();
    
    // 对于下一页的动画，才移动底层截图
    if (pageDirection == PageDirection.next) {
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
    
    // 对于上一页的动画，底层截图保持不动
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: currentImage,
    );
  }
} 