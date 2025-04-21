import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

class FivePageNavigator extends StatefulWidget {
  final Widget centerPage;
  final Widget leftPage;
  final Widget rightPage;
  final Widget topPage;
  final Widget bottomPage;
  final Duration animationDuration;
  final double swipeThreshold;
  final double zoomOutScale;
  final bool showAppBar;
  final Function(PageType)? onPageChanged;
  final double verticalDetectionAreaHeight;
  final double horizontalDetectionAreaWidth;

  const FivePageNavigator({
    super.key,
    required this.centerPage,
    required this.leftPage,
    required this.rightPage,
    required this.topPage,
    required this.bottomPage,
    this.animationDuration = const Duration(milliseconds: 300),
    this.swipeThreshold = 0.25,
    this.zoomOutScale = 1,
    this.showAppBar = false,
    this.onPageChanged,
    this.verticalDetectionAreaHeight = 200.0,
    this.horizontalDetectionAreaWidth = 100.0,
  });

  @override
  State<FivePageNavigator> createState() => _FivePageNavigatorState();
}

class _FivePageNavigatorState extends State<FivePageNavigator>
    with TickerProviderStateMixin {
  // Animasyon kontrolcüleri ve state değişkenleri
  late AnimationController _zoomController;
  late AnimationController _swipeController;
  late Animation<double> _zoomAnimation;
  late Animation<double> _swipeAnimation;

  double _swipeOffset = 0;
  SwipeDirection? _currentSwipeDirection;
  bool _isInitialZoomCompleted = false;
  bool _isAnimating = false;
  PageType _currentPage = PageType.center;
  Offset? _dragStartPosition;

  // --- initState ve dispose (Değişiklik yok) ---
  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 300), // İlk animasyon süresi
      vsync: this,
    );
    _zoomAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInOut,
    ))
      // İlk zoom animasyonu için de listener ekleyerek her adımda build'i tetikleyelim
      ..addListener(() {
        if (mounted) setState(() {});
      });

    _swipeController = AnimationController(
      duration: widget.animationDuration, // Kaydırma animasyon süresi
      vsync: this,
    );
    _swipeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _swipeController,
      curve: Curves.easeOut,
    ))
          ..addListener(() {
            if (mounted) setState(() {});
          });

    // İlk açılış animasyonunu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 900), () {
        // Küçük bir gecikme
        if (mounted) {
          _zoomController.forward().then((_) {
            if (mounted) {
              setState(() {
                _isInitialZoomCompleted = true; // Animasyon bitince işaretle
              });
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _swipeController.dispose();
    super.dispose();
  }

  // --- Gesture Handling (Değişiklik yok) ---
  void _handlePanStart(DragStartDetails details) {
    if (_currentPage != PageType.center ||
        !_isInitialZoomCompleted ||
        _isAnimating) {
      _dragStartPosition = null;
      return;
    }
    _dragStartPosition = details.localPosition;
    _currentSwipeDirection = null;
    _swipeOffset = 0;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStartPosition == null || _isAnimating) return;
    final screenSize = MediaQuery.of(context).size;
    if (_currentSwipeDirection == null) {
      _determineSwipeDirection(details, screenSize);
    }
    if (_currentSwipeDirection != null) {
      setState(() {
        switch (_currentSwipeDirection!) {
          case SwipeDirection.left:
            _swipeOffset = math.min(
                0.0, _swipeOffset + details.delta.dx / screenSize.width);
            _swipeOffset = _swipeOffset.clamp(-1.0, 0.0);
            break;
          case SwipeDirection.right:
            _swipeOffset = math.max(
                0.0, _swipeOffset + details.delta.dx / screenSize.width);
            _swipeOffset = _swipeOffset.clamp(0.0, 1.0);
            break;
          case SwipeDirection.up:
            _swipeOffset = math.min(
                0.0, _swipeOffset + details.delta.dy / screenSize.height);
            _swipeOffset = _swipeOffset.clamp(-1.0, 0.0);
            break;
          case SwipeDirection.down:
            _swipeOffset = math.max(
                0.0, _swipeOffset + details.delta.dy / screenSize.height);
            _swipeOffset = _swipeOffset.clamp(0.0, 1.0);
            break;
        }
      });
    }
  }

  void _determineSwipeDirection(DragUpdateDetails details, Size screenSize) {
    final startX = _dragStartPosition!.dx;
    final startY = _dragStartPosition!.dy;
    final deltaX = details.delta.dx;
    final deltaY = details.delta.dy;
    final absDeltaX = deltaX.abs();
    final absDeltaY = deltaY.abs();
    const double minMovement = 1.0;
    if (absDeltaX > absDeltaY && absDeltaX > minMovement) {
      if (deltaX > 0 && startX < widget.horizontalDetectionAreaWidth) {
        _currentSwipeDirection = SwipeDirection.right;
      } else if (deltaX < 0 &&
          startX > screenSize.width - widget.horizontalDetectionAreaWidth) {
        _currentSwipeDirection = SwipeDirection.left;
      }
    } else if (absDeltaY > absDeltaX && absDeltaY > minMovement) {
      if (deltaY > 0 && startY < widget.verticalDetectionAreaHeight) {
        _currentSwipeDirection = SwipeDirection.down;
      } else if (deltaY < 0 &&
          startY > screenSize.height - widget.verticalDetectionAreaHeight) {
        _currentSwipeDirection = SwipeDirection.up;
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_currentSwipeDirection == null || _isAnimating) {
      _resetDragState();
      return;
    }
    final swipeProgress = _swipeOffset.abs();
    if (swipeProgress >= widget.swipeThreshold) {
      _animateToPage();
    } else {
      _animateBackToCenter();
    }
  }

  void _resetDragState() {
    if (mounted) {
      setState(() {
        _swipeOffset = 0;
        _currentSwipeDirection = null;
        _dragStartPosition = null;
        if (_swipeController.isAnimating) {
          _swipeController.stop();
        }
        _isAnimating = false;
      });
    }
  }

  // --- Animation Logic (Değişiklik yok) ---
  void _animateToPage() {
    if (_currentSwipeDirection == null) return;
    setState(() {
      _isAnimating = true;
    });
    final currentProgress = _swipeOffset.abs();
    // Kaydırma animasyonunu başlat
    _swipeController.forward(from: currentProgress).then((_) {
      if (mounted) {
        _navigateToPageActual(); // Animasyon bitince diğer sayfaya geç
      }
    }).catchError((error) {
      // Hata olursa durumu sıfırla
      if (mounted) _resetDragState();
    });
  }

  void _animateBackToCenter() {
    if (_currentSwipeDirection == null) return;
    setState(() {
      _isAnimating = true;
    });
    final currentProgress = _swipeOffset.abs();
    // Geri animasyonunu başlat
    _swipeController.reverse(from: currentProgress).then((_) {
      // Animasyon bitince durumu sıfırla
      if (mounted) {
        setState(() {
          _swipeOffset = 0;
          _currentSwipeDirection = null;
          _dragStartPosition = null;
          _isAnimating = false;
        });
      }
    }).catchError((error) {
      // Hata olursa durumu sıfırla
      if (mounted) _resetDragState();
    });
  }

  // --- Navigation (Değişiklik yok) ---
  void _navigateToPageActual() {
    if (_currentSwipeDirection == null) {
      _resetDragState();
      return;
    }
    PageType targetPage;
    Widget targetWidget;
    switch (_currentSwipeDirection!) {
      case SwipeDirection.left:
        targetPage = PageType.right;
        targetWidget = widget.rightPage;
        break;
      case SwipeDirection.right:
        targetPage = PageType.left;
        targetWidget = widget.leftPage;
        break;
      case SwipeDirection.up:
        targetPage = PageType.bottom;
        targetWidget = widget.bottomPage;
        break;
      case SwipeDirection.down:
        targetPage = PageType.top;
        targetWidget = widget.topPage;
        break;
    }
    // Sayfa geçişini Navigator ile yap, animasyonu sıfırla
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => PageWrapper(
          pageType: targetPage,
          showAppBar: widget.showAppBar,
          onReturnToCenter: () {
            if (mounted) {
              setState(() {
                _currentPage = PageType.center;
                // Navigatörden geri dönünce durumu sıfırla
                _resetDragState(); // Bu satır zaten vardı
              });
              widget.onPageChanged?.call(PageType.center);
            }
          },
          child: targetWidget,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) {
      // Navigatörden geri dönülünce PageWrapper'daki onReturnToCenter tetiklenir.
      // Buraya ayrıca bir şey eklemeye gerek yok.
    });
    // Mevcut sayfayı güncelle
    if (mounted) {
      setState(() {
        _currentPage = targetPage;
      });
      widget.onPageChanged?.call(targetPage);
    }
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior:
            Clip.hardEdge, // Kenarlardan taşmayı önle (swipe sırasında)
        width: double.infinity,
        height: double.infinity,
        // Arka planı transparan yapabilirsin, veya bir renk verebilirsin
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10), // Senin eklediğin stil
        ),
        // İlk zoom animasyonu bitmediyse onu göster, bittiyse kaydırılabilir içeriği göster
        child:
            !_isInitialZoomCompleted // _isInitialZoomCompleted false ise animasyonu göster
                ? AnimatedBuilder(
                    animation: _zoomAnimation, // İlk zoom animasyonunu dinle
                    builder: (context, child) {
                      return _buildInitialZoomView(); // İlk zoom görünümünü çiz
                    })
                : _buildSwipeableContent(), // Kaydırılabilir içeriği çiz
      ),
    );
  }

  // Kaydırılabilir içeriği oluşturan ana metot (Değişiklik yok, sadece AnimatedBuilder eklendi)
  Widget _buildSwipeableContent() {
    // Kaydırma ve animasyon sırasında rebuild için AnimatedBuilder ekliyoruz
    // Bu, _swipeOffset veya _swipeAnimation değiştikçe görünümün güncellenmesini sağlar
    return AnimatedBuilder(
      animation: _isAnimating
          ? _swipeController
          : AlwaysStoppedAnimation(
              0), // Animasyon sırasında _swipeController'ı dinle
      builder: (context, child) {
        if (_isAnimating) {
          return _buildAnimatingView(); // Animasyon devam ediyorsa animasyonlu görünümü çiz
        } else if (_currentSwipeDirection != null) {
          return _buildDraggingView(); // Sürükleme devam ediyorsa sürükleme görünümünü çiz
        } else {
          return Center(
              child:
                  _getCurrentMainPage()); // Herhangi bir işlem yoksa merkez sayfayı çiz
        }
      },
    );
  }

  // Sürükleme sırasındaki görünüm (Değişiklik yok, helper fonksiyonları güncellendi)
  Widget _buildDraggingView() {
    return Stack(
      children: [
        // Merkez sayfa (iteleniyor)
        Transform.translate(
          offset: _getCenterPageOffsetWhileSwiping(), // Yeni offset hesaplama
          child: Transform.scale(
            scale: _getCenterPageScaleWhileSwiping(),
            alignment: Alignment.center,
            child: widget.centerPage,
          ),
        ),
        // Kayan sayfa (ekrana geliyor)
        if (_currentSwipeDirection != null)
          Transform.translate(
            offset: _getSwipingPageOffset(), // Bu fonksiyon aynı kaldı
            child: Transform.scale(
              scale: _getSwipingPageScale(), // Bu fonksiyon aynı kaldı
              alignment: Alignment.center,
              child: _getSwipingPage(),
            ),
          ),
      ],
    );
  }

  // Geçiş animasyonu sırasındaki görünüm (Değişiklik yok, helper fonksiyonları güncellendi)
  Widget _buildAnimatingView() {
    if (_currentSwipeDirection == null) return const SizedBox.shrink();
    Widget shrinkingPage = widget.centerPage; // Merkez sayfa
    Widget growingOrShrinkingPage = _getSwipingPage(); // Kayan sayfa
    return Stack(
      children: [
        // Merkez sayfa (iteleniyor ve ölçekleniyor)
        Transform.translate(
          offset: _getAnimatingCenterOffset(), // Yeni offset hesaplama
          child: Transform.scale(
            scale: _getAnimatingCenterScale(), // Bu fonksiyon aynı kaldı
            alignment: Alignment.center,
            child: shrinkingPage,
          ),
        ),
        // Kayan sayfa (geliyor ve ölçekleniyor)
        Transform.translate(
          offset: _getAnimatingTargetOffset(), // Bu fonksiyon aynı kaldı
          child: Transform.scale(
            scale: _getAnimatingTargetScale(), // Bu fonksiyon aynı kaldı
            alignment: Alignment.center,
            child: growingOrShrinkingPage,
          ),
        ),
      ],
    );
  }

  // ***** İLK AÇILIŞ ANİMASYONU GÖRÜNÜMÜ (Değişiklik yok, AnimatedBuilder artık build içinde) *****
  Widget _buildInitialZoomView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final animationProgress =
        _zoomAnimation.value; // Mevcut animasyon değeri (0.0 ile 1.0 arası)

    // İlk görünüm için başlangıç ölçeği (widget.zoomOutScale=1 olsa bile kullanılır)
    const double initialViewScale = .5;
    const double spacing = 15.0; // Başlangıçta sayfalar arası boşluk

    // Merkez sayfanın ölçeği: initialViewScale -> 1.0
    final centerScale = lerpDouble(initialViewScale, 1.0, animationProgress)!;
    // Yan sayfaların ölçeği: initialViewScale -> 0.0 (kaybolacaklar)
    final sideScale = lerpDouble(initialViewScale, 0.0, animationProgress)!;

    // --- Pozisyon Hesaplamaları ---

    // Merkez sayfanın hedefi: Tam ekran, (0,0) pozisyonu
    const finalCenterX = 0.0;
    const finalCenterY = 0.0;

    // Merkez sayfanın başlangıcı: Küçültülmüş ve ortalanmış
    final initialCenterWidth = screenWidth * initialViewScale;
    final initialCenterHeight = screenHeight * initialViewScale;
    final initialCenterX = (screenWidth - initialCenterWidth) / 2;
    final initialCenterY = (screenHeight - initialCenterHeight) / 2;

    // Merkez sayfanın mevcut (anime edilen) pozisyonu ve boyutu
    final currentCenterX =
        lerpDouble(initialCenterX, finalCenterX, animationProgress)!;
    final currentCenterY =
        lerpDouble(initialCenterY, finalCenterY, animationProgress)!;
    final currentCenterWidth = screenWidth * centerScale; // Anime edilen boyut
    final currentCenterHeight = screenHeight * centerScale;

    // Yan sayfaların başlangıç boyutu (sabit veya küçülebilir, burada sabit alalım)
    final initialSideWidth = screenWidth * initialViewScale;
    final initialSideHeight = screenHeight * initialViewScale;

    // Yan sayfaların BAŞLANGIÇ pozisyonları (initialCenter etrafında)
    final initialLeftX = initialCenterX - initialSideWidth - spacing;
    final initialRightX = initialCenterX + initialCenterWidth + spacing;
    final initialTopY = initialCenterY - initialSideHeight - spacing;
    final initialBottomY = initialCenterY + initialCenterHeight + spacing;
    final initialSideY = initialCenterY; // Sol/Sağ için Y hizalaması
    final initialSideX = initialCenterX; // Üst/Alt için X hizalaması

    // Yan sayfaların HEDEF pozisyonları (ekran dışına doğru hareket)
    final finalLeftX = -initialSideWidth * 2; // Ekranın çok soluna
    final finalRightX = screenWidth + initialSideWidth; // Ekranın çok sağına
    final finalTopY = -initialSideHeight * 2; // Ekranın çok üstüne
    final finalBottomY = screenHeight + initialSideHeight; // Ekranın çok altına

    // Yan sayfaların mevcut (anime edilen) pozisyonları
    final currentLeftX =
        lerpDouble(initialLeftX, finalLeftX, animationProgress)!;
    final currentRightX =
        lerpDouble(initialRightX, finalRightX, animationProgress)!;
    final currentTopY = lerpDouble(initialTopY, finalTopY, animationProgress)!;
    final currentBottomY =
        lerpDouble(initialBottomY, finalBottomY, animationProgress)!;
    // Yan sayfaların hizalanması için Y/X pozisyonları da anime edilebilir
    final sideCurrentY =
        lerpDouble(initialSideY, finalCenterY, animationProgress)!;
    final sideCurrentX =
        lerpDouble(initialSideX, finalCenterX, animationProgress)!;

    // Eğer yan sayfaların ölçeği çok küçüldüyse çizme (performans)
    if (sideScale < 0.01) {
      // Sadece büyüyen merkez sayfayı çiz
      return Stack(
        children: [
          Positioned(
            left: currentCenterX,
            top: currentCenterY,
            width: currentCenterWidth,
            height: currentCenterHeight,
            child: widget.centerPage, // Sadece centerPage
          ),
        ],
      );
    }

    // Hem merkez hem de yan sayfaları çiz
    return Stack(
      clipBehavior: Clip.antiAlias, // Animasyonun taşmasına izin ver
      children: [
        // Yan Sayfalar (Önce çizilir, merkezin altında kalır)
        Positioned(
          // Sol
          left: currentLeftX, top: sideCurrentY,
          width: initialSideWidth, height: initialSideHeight, // Sabit boyut
          child: Transform.scale(
              scale: sideScale,
              alignment: Alignment.center,
              child: widget.leftPage), // Ölçekle küçült
        ),
        Positioned(
          // Sağ
          left: currentRightX, top: sideCurrentY,
          width: initialSideWidth, height: initialSideHeight,
          child: Transform.scale(
              scale: sideScale,
              alignment: Alignment.center,
              child: widget.rightPage),
        ),
        Positioned(
          // Üst
          left: sideCurrentX, top: currentTopY,
          width: initialSideWidth, height: initialSideHeight,
          child: Transform.scale(
              scale: sideScale,
              alignment: Alignment.center,
              child: widget.topPage),
        ),
        Positioned(
          // Alt
          left: sideCurrentX, top: currentBottomY,
          width: initialSideWidth, height: initialSideHeight,
          child: Transform.scale(
              scale: sideScale,
              alignment: Alignment.center,
              child: widget.bottomPage),
        ),
        // Merkez Sayfa (En son çizilir, üstte kalır)
        Positioned(
          left: currentCenterX, top: currentCenterY,
          width: currentCenterWidth,
          height: currentCenterHeight, // Büyüyen boyut
          child: widget.centerPage, // Ölçekleme Positioned ile yapıldı
        ),
      ],
    );
  }

  // --- Helper Functions for Transformations ---

  // YENİ FONKSİYON: Merkez sayfanın itelenerek gideceği son pozisyonu hesaplar
  Offset _getCenterPageEndOffset(SwipeDirection swipeDirection, Size size) {
    switch (swipeDirection) {
      case SwipeDirection
            .left: // Kullanıcı sola kaydırdı, sağ sayfa geliyor. Merkez sola itilecek.
        return Offset(-size.width, 0);
      case SwipeDirection
            .right: // Kullanıcı sağa kaydırdı, sol sayfa geliyor. Merkez sağa itilecek.
        return Offset(size.width, 0);
      case SwipeDirection
            .up: // Kullanıcı yukarı kaydırdı, alt sayfa geliyor. Merkez yukarı itilecek.
        return Offset(0, -size.height);
      case SwipeDirection
            .down: // Kullanıcı aşağı kaydırdı, üst sayfa geliyor. Merkez aşağı itilecek.
        return Offset(0, size.height);
    }
  }

  // Kayan sayfanın başlangıç pozisyonu (ekran dışı) - DEĞİŞİKLİK YOK
  Offset _getOffScreenOffset(SwipeDirection direction, Size size) {
    switch (direction) {
      case SwipeDirection.left: // Sağ sayfa soldan geliyor
        return Offset(size.width, 0);
      case SwipeDirection.right: // Sol sayfa sağdan geliyor
        return Offset(-size.width, 0);
      case SwipeDirection.up: // Alt sayfa yukarıdan geliyor
        return Offset(0, size.height);
      case SwipeDirection.down: // Üst sayfa aşağıdan geliyor
        return Offset(0, -size.height);
    }
  }

  // DEĞİŞTİRİLDİ: Sürükleme sırasında merkez sayfanın offsetini hesaplar
  Offset _getCenterPageOffsetWhileSwiping() {
    if (_currentSwipeDirection == null) return Offset.zero;
    final size = MediaQuery.of(context).size;
    // Merkez sayfanın başlangıcı (0) ve sonu (_getCenterPageEndOffset) arasında interpolasyon yap
    final endOffset = _getCenterPageEndOffset(_currentSwipeDirection!, size);
    return Offset.lerp(Offset.zero, endOffset, _swipeOffset.abs())!;
  }

  // Merkez sayfanın sürükleme sırasındaki ölçeği - DEĞİŞİKLİK YOK
  double _getCenterPageScaleWhileSwiping() {
    if (_currentSwipeDirection == null) return 1.0;
    // widget.zoomOutScale kullanılır
    return lerpDouble(1.0, widget.zoomOutScale, _swipeOffset.abs())!;
  }

  // Kayan sayfanın sürükleme sırasındaki offsetini hesaplar - DEĞİŞİKLİK YOK
  Offset _getSwipingPageOffset() {
    if (_currentSwipeDirection == null) return Offset.zero;
    final size = MediaQuery.of(context).size;
    // Kayan sayfanın başlangıcı (_getOffScreenOffset) ve sonu (0) arasında interpolasyon yap
    final offScreenOffset = _getOffScreenOffset(_currentSwipeDirection!, size);
    return Offset.lerp(offScreenOffset, Offset.zero, _swipeOffset.abs())!;
  }

  // Kayan sayfanın sürükleme sırasındaki ölçeği - DEĞİŞİKLİK YOK
  double _getSwipingPageScale() {
    if (_currentSwipeDirection == null) return widget.zoomOutScale;
    // widget.zoomOutScale kullanılır
    return lerpDouble(widget.zoomOutScale, 1.0, _swipeOffset.abs())!;
  }

  // DEĞİŞTİRİLDİ: Animasyon sırasında merkez sayfanın offsetini hesaplar
  Offset _getAnimatingCenterOffset() {
    if (_currentSwipeDirection == null) return Offset.zero;
    final size = MediaQuery.of(context).size;
    // Merkez sayfanın başlangıcı (0) ve sonu (_getCenterPageEndOffset) arasında animasyon değeriyle interpolasyon yap
    final finalEndOffset =
        _getCenterPageEndOffset(_currentSwipeDirection!, size);
    return Offset.lerp(Offset.zero, finalEndOffset, _swipeAnimation.value)!;
  }

  // Merkez sayfanın animasyon sırasındaki ölçeği - DEĞİŞİKLİK YOK
  double _getAnimatingCenterScale() {
    // widget.zoomOutScale kullanılır
    return lerpDouble(1.0, widget.zoomOutScale, _swipeAnimation.value)!;
  }

  // Kayan sayfanın animasyon sırasındaki offsetini hesaplar - DEĞİŞİKLİK YOK
  Offset _getAnimatingTargetOffset() {
    if (_currentSwipeDirection == null) return Offset.zero;
    final size = MediaQuery.of(context).size;
    // Kayan sayfanın başlangıcı (_getOffScreenOffset) ve sonu (0) arasında animasyon değeriyle interpolasyon yap
    final offScreenOffset = _getOffScreenOffset(_currentSwipeDirection!, size);
    return Offset.lerp(offScreenOffset, Offset.zero, _swipeAnimation.value)!;
  }

  // Kayan sayfanın animasyon sırasındaki ölçeği - DEĞİŞİKLİK YOK
  double _getAnimatingTargetScale() {
    // widget.zoomOutScale kullanılır
    return lerpDouble(widget.zoomOutScale, 1.0, _swipeAnimation.value)!;
  }

  // --- Helper to get current/swiping page widget (Değişiklik yok) ---
  Widget _getCurrentMainPage() {
    switch (_currentPage) {
      case PageType.center:
        return widget.centerPage;
      case PageType.left:
        return widget.leftPage;
      case PageType.right:
        return widget.rightPage;
      case PageType.top:
        return widget.topPage;
      case PageType.bottom:
        return widget.bottomPage;
    }
  }

  Widget _getSwipingPage() {
    switch (_currentSwipeDirection) {
      case SwipeDirection.left:
        return widget.rightPage;
      case SwipeDirection.right:
        return widget.leftPage;
      case SwipeDirection.up:
        return widget.bottomPage;
      case SwipeDirection.down:
        return widget.topPage;
      default:
        return const SizedBox.shrink();
    }
  }
}

// --- Page Wrapper (Değişiklik yok) ---
class PageWrapper extends StatelessWidget {
  final Widget child;
  final PageType pageType;
  final bool showAppBar;
  final VoidCallback? onReturnToCenter;
  const PageWrapper({
    super.key,
    required this.child,
    required this.pageType,
    required this.showAppBar,
    this.onReturnToCenter,
  });
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          onReturnToCenter?.call();
        }
      },
      child: showAppBar
          ? Scaffold(
              appBar: AppBar(
                title: Text(pageType.toString().split('.').last.toUpperCase()),
              ),
              body: child,
            )
          : child,
    );
  }
}

// --- Enums (Değişiklik yok) ---
enum SwipeDirection { left, right, up, down }

enum PageType { center, left, right, top, bottom }
