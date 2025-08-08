// lib/helpers/kakaoAddressHelper.dart
import 'package:web/web.dart' as web;
import 'package:js/js.dart'; // allowInterop

class KakaoAddressHelper {
  static void openAddressPopup(Function(String address) onAddressSelected) {
    final popup = web.window.open(
      '/kakaoAddressSearch.html',
      '주소 검색',
      'width=600,height=600',
    );

    // removeEventListener에 넘기기 위해 같은 함수 객체를 보관
    late web.EventListener listenerWrapped;

    void listener(web.Event e) {
      if (e is web.MessageEvent) {
        // JSAny? -> dynamic 로 받아서 안전하게 처리
        final dynamic data = e.data;
        if (data is String) {
          final addr = data.trim(); // 여기서는 non-null String
          if (addr.isNotEmpty) {
            onAddressSelected(addr);
            web.window.removeEventListener('message', listenerWrapped);
            popup?.close();
          }
        }
      }
    }

    // Dart 콜백을 JS에서 호출 가능하도록 래핑 + 정확한 타입으로 캐스팅
    listenerWrapped = allowInterop(listener) as web.EventListener;
    web.window.addEventListener('message', listenerWrapped);
  }
}
