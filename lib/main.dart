import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/bazi_record.dart';
import 'models/qi_gua_record.dart';
import 'models/ziwei_record.dart';
import 'pages/divination_page.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 载入本地保存的起卦记录（含解卦笔记）、八字排盘记录与紫微斗数记录
  QiGuaRecordStore.instance.ensureLoaded();
  BaZiRecordStore.instance.ensureLoaded();
  ZiWeiRecordStore.instance.ensureLoaded();
  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const DivinationApp());
}

class DivinationApp extends StatelessWidget {
  const DivinationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '易占师算卦大师',
      debugShowCheckedModeBanner: false,
      // 起卦时间使用 showDatePicker / showTimePicker，二者依赖
      // MaterialLocalizations；未注册本地化代理时选择器会直接抛
      // "No MaterialLocalizations found." 造成页面崩溃。
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        fontFamilyFallback: const [
          'PingFang SC',
          'Heiti SC',
          'Microsoft YaHei',
          'sans-serif',
        ],
      ),
      home: const DivinationPage(),
    );
  }
}
