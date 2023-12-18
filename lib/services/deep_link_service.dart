// ignore_for_file: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member

import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

class DeepLinkService {
  DeepLinkService._();
  static DeepLinkService? _instance;

  static DeepLinkService? get instance {
    _instance ??= DeepLinkService._();
    return _instance;
  }

  ValueNotifier<String> referrerCode = ValueNotifier<String>('');

  final dynamicLink = FirebaseDynamicLinks.instance;

  Future<void> handleDynamiclinks() async {
    final data = await dynamicLink.getInitialLink();
    if (data != null) {
      _handleDeeplink(data);
    }

    dynamicLink.onLink.listen((event) {
      _handleDeeplink(event);
    }).onError((v) {
      debugPrint('Failed: $v');
    });
  }

  Future<String> createReferlink(String referCode, String referrerCode) async {
    final DynamicLinkParameters dynamicLinkParameters = DynamicLinkParameters(
      uriPrefix: 'https://avnik.page.link',
      link: Uri.parse('https://avnik.page.link/refer?code=$referCode'),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.demo',
        minimumVersion: 1,
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'REFER A FRIEND & EARN',
        description: 'Earn 1,000USD on every referral',
      ),
    );
    final shortLink = await dynamicLink.buildShortLink(dynamicLinkParameters);

    return shortLink.shortUrl.toString();
  }

  Future<void> _handleDeeplink(PendingDynamicLinkData data) async {
    final Uri deepLink = data.link;
    var isRefer = deepLink.pathSegments.contains('refer');
    if (isRefer) {
      var code = deepLink.queryParameters['code'];
      if (code != null) {
        referrerCode.value = code;
        debugPrint('ReferrerCode $referrerCode');
        referrerCode.notifyListeners();
      }
    }
  }
}
