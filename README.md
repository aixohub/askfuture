# divination

占卜

## 首页"开始起卦"

对齐官方易占师 iOS 包（`RN0615.app/main.jsbundle`）首页起卦链路实现：

1. **首页**（`lib/pages/divination_page.dart` + `lib/widgets/divination_card.dart`）
   —— 占事分类（18 项）、求测问题、性别，点击"开 始 起 卦"后按官方规则校验：
   未选分类 → `问题分类可提高预测准确性，请仔细选择`；标题空或不足 2 字 →
   `请输入求测问题~`；未选性别 → `请选择性别!`；随后分类按 `30 → 3`、
   `婚姻情感 + 男 → 2` 换算并跳转排盘方式选择页。
2. **排盘方式选择页**（`lib/pages/pai_pan_type_page.dart`）—— 占事信息 +
   8 种起卦方式（在线起卦 / 电脑自动 / 手工指定 / 时间 / 单数 / 双数 / 汉字 / 卦名），
   默认选中**手工指定**；手工指定下逐爻滚轮选择（选项同官方 `Config.yaoMap`），
   面板内实时预览六爻与本卦/变卦，校验与提示文案与官方一致。
3. **卦象结果页**（`lib/pages/gua_xiang_page.dart`）—— 按照易占师官方视觉原型 1:1 实现：
   * 顶部导航：墨绿色 AppBar（`#23B59B`），左侧「关闭」文本按钮直接返回，居中加粗「易占师」标题。
   * 占事信息区：问占（加粗）/ 占类 / 卦主 / 起卦时间（附带农历月日，如 `(八月初七)`），右侧浮动褐色「干支历」卡片按钮。
   * 干支与旬空：四柱干支中**月柱与日柱标红突出**（如 `丁酉 甲午`），后随旬空。
   * 卦身与世身：自动推导卦身与世身并**红字高亮**展示（如 `卦身： 无  世身： 巳`）。
   * 神煞栏：**贵人、驿马、桃花、日禄**（口径对齐开源参考实现 sixyao-main
     `liuyaodata.js` 的四张表，全部以日柱起），折叠时显示前 3 项，右侧青绿色
     「展开 / 收起」按钮展示全部 4 项。
   * 六爻排盘表：六神、本卦（六亲干支五行 + 爻线 + 世应动标 + 伏神红字）与变卦对照，阳爻纯黑实心长块、阴爻双断块。
   * 卦辞爻辞：展示当前卦名与易经卦辞，点击唤起底部弹层查看爻辞详解。
   * 解卦笔记：支持点击弹出笔记编辑面板输入并持久化解卦思路。
   * 工具胶囊行：`⇄ 梅花盘`、`☆ 收藏`、`📋 复制`、`📷 截图` 4 个药丸胶囊按钮。
   * 卦辞诗区域：居中青绿卦名 + 64 卦经典断易天机两句诗排版。
   * 吸底操作栏：左侧 65% 蓝色「保存排盘」，右侧 35% 红色「关闭」（点击跳到首页）。

   装卦（纳甲 / 六亲 / 六神 / 世应 / 伏神 / 旬空）见 `lib/models/liuyao.dart`，
   干支算法见 `lib/models/ganzhi.dart`，
   农历与神煞/卦身计算见 `lib/models/lunar_and_shensha.dart`，
   六十四卦卦辞与诗文见 `lib/models/hexagram_text.dart`。
   装盘已与开源参考实现 **sixyao-main** 逐字段对齐：320 条对照记录
   （64 卦 × 静卦/初爻动/上爻动，本卦 + 变卦）覆盖卦名、卦宫、宫内八名、世应关系、
   六神、六亲、纳甲地支、五行、世应、伏神，见 `test/sixyao_pan_reference_test.dart`
   与 [`docs/reverse/sixyao_pan.md`](docs/reverse/sixyao_pan.md)。
4. **起卦记录**（`lib/widgets/divination_dialog.dart` + `lib/models/qi_gua_record.dart`）
   —— 卦象页"保存排盘"后，首页"起卦记录"可查看列表；**点击任意一条记录即回看该卦的
   卦象页**（回看时底部按钮显示「已保存排盘」，不会重复保存）。

## 农历 / 公历日期转换

`lib/models/lunar_calendar.dart`（官方 RN 模块 1898 的 1:1 移植）提供双向换算：

* `solar2Lunar` / `lunarDateOf` —— 公历 → 农历（年/月/日、闰月、月大月小、农历日名、
  农历年干支与生肖）；
* `lunar2Solar` / `solarDateOfLunar` / `LunarDate.solarDate` —— 农历 → 公历（支持闰月）；
* `lunarMonthsOf` / `lunarDaysInMonth` —— 农历月份列表（含闰月）与大小月；
* 官方模块 2235 的农历月名与十二时辰文案（`kLunarMonthNames` / `kLunarHourNames`、
  `lunarHourIndex` / `hourOfLunarHourIndex`）。

六爻"起卦时间"因此支持 **公历 / 农历切换**（对齐官方 `DatePick` 的 `isShowLunar`）：
农历模式下按月/日/时辰滚轮选择、闰年可勾选闰月，确定后按 `lunar2solar` 换算成公历
再排盘；起卦时间字段与卦象页同时展示公历与农历。

校验：1736 条官方农历对照（`test/fixtures/official_lunar_reference.json`，含
2023 闰二月 / 2025 闰六月与 1900–2100 全部春节、闰月初一）+
1900-01-31 ~ 2100-12-31 逐日往返 73384 次，见 `test/lunar_calendar_test.dart`、
`test/lunar_roundtrip_test.dart`。

## 首页"八字轻测"与八字排盘

首页卡片第二个 Tab「八字轻测」（`lib/widgets/bazi_qingce_tab.dart`）对齐官方首页
模块 2423：命主性别（男/女）、日期类型（阴历/阳历）、出生日期（滚轮选择）、
出生城市（省市选择 + 使用真太阳时 + 什么是真太阳时说明）、问题描述（限 100 字）
与三条填写提示，点击「立即查询」按官方文案校验后进入八字排盘页。

**八字排盘页**（`lib/pages/bazi_paipan_page.dart`）包含两个页签（默认展示**专业命盘**，选中指示色 `#EA5A3D`，底部吸底栏与卦象页保持一致：65% 蓝色「保存排盘」 + 35% 红色「关闭」）：

* **基本信息**（模块 2510）—— 命主信息条 + 节气/中气 + 命盘简表（十神/天干/地支）+
  日主衰旺、后天喜用、五行力量条、适宜五行/生肖/颜色/方位；
* **专业命盘**（模块 2514）—— 命主信息 + 5 行交替底色命主条 + 7 列主对照表（流年/大运/四柱）、
  五行色彩干支、遁藏藏干、起运交运与十步大运/十年流年交互切换。

排盘数据本地计算：

* 四柱（年/月/日/时）来自官方同一套干支与精确节气规则（`lib/models/ganzhi.dart`、
  `lib/models/jieqi.dart`）；
* 十神 / 藏干 / 纳音 / 长生十二神表 1:1 取自官方模块 2472（`lib/models/bazi.dart`），
  并据此给出四柱表、地势（长生十二神）、生肖、日主、旬空、胎元、命宫与小运；
* 大运按传统子平法「阳年男、阴年女顺排；三天折一年」起运，自月柱顺/逆推十步，
  并标注当前流年；
* 五行力量按「天干各一份、地支按藏干天数折算」统计，并据此给出日主衰旺（身强/身弱）、
  后天喜用五行与适宜五行/生肖/颜色/方位；
* 勾选「阴历」时先用农历库（`lib/models/lunar_calendar.dart`）换算成公历再排盘；
* 出生地省市数据取自官方模块 2427（`lib/models/china_area.dart`）。

## 首页"紫微斗数"与命盘排盘

首页卡片第三个 Tab「紫微斗数」（`lib/widgets/ziwei_form.dart`）对齐官方首页模块
2430：命主性别（男/女）、日期类型（阴历/阳历）、出生日期（滚轮选择，默认当前
时间）、出生城市（省市选择 + 使用真太阳时 + 什么是真太阳时说明）、求测问题与
「立即查询」按钮。其中求测问题按需求移到出生城市之后，并与「八字轻测」面板
保持同款版式（多行输入框 + 三条填写提示）。

校验沿用官方 `_ziWeiPaiPan()`：问题不足 2 字 → `请输入求测问题~`；未选性别 →
`请选择性别`；未选阴/阳历 → `请选择阴/阳历`；勾选真太阳时未选出生地 →
`请先选择出生地点`。

**命盘页**（`lib/pages/ziwei_chart_page.dart`）对齐官方模块 2569 / 2570 / 2581 的
4×4 命盘版式：十二宫按地支就位（上排 巳午未申、左右两列 辰卯/酉戌、下排 寅丑子亥），
每宫展示星曜（含庙旺与生年四化）、身宫标记、长生/博士/将前/岁前四组十二神、
大限与宫干支；中宫展示阴阳与五行局、公历/农历、命主身主与四柱。

排盘由本地引擎 `lib/models/ziwei.dart` 按传统安星诀计算：
命身宫（寅起正月，顺数生月、逆/顺数生时）、五虎遁宫干、纳音五行局、起紫微星诀、
十四主星（紫微系逆布 / 天府系顺布）、六吉六煞与禄马、十天干四化、命主身主、
十二宫名、四组十二神与大限（阳男阴女顺行、阴男阳女逆行）；晚子时按次日安星。
农历与干支复用官方模块 1898 / 2111 的移植（`lunar_calendar.dart`、`ganzhi.dart`），
真太阳时按经度差折算（`lib/models/city_longitude.dart`）。

命盘正确性以开源实现 iztro 为基准逐宫校验（24 组固定样例 + 边界场景），
见 `test/ziwei_test.dart`、`test/fixtures/ziwei_reference.json` 与取证文档
[`docs/reverse/home_ziwei.md`](docs/reverse/home_ziwei.md)。

## iOS 真机安装与运行说明（解决 "Debug Mode" 提示）

### 1. 问题原因
在 iOS 14 及更高版本系统中，如果在开发调试时使用 `flutter run`（默认 Debug 模式）将应用安装到真机 iPhone 上，**脱离开发电脑在手机桌面直接点击打开**时，系统会弹出如下警告并阻止运行：
> *In iOS 14+, debug mode Flutter apps can only be launched from Flutter tooling, IDE, or Xcode and cannot be launched from the home screen.*

这是因为 iOS 系统的安全沙盒策略限制了未连接宿主调试器（LLDB / Dart VM）的 JIT（动态即时编译）代码运行。

### 2. 解决方案

真机独立运行必须采用 **Release（正式发布）模式** 或 **Profile 模式** 进行 AOT 机器码编译安装：

#### 方案 A：使用命令行直接安装 Release 模式（推荐）
```bash
# 1. 查询当前已连接的真机设备 ID（通过 USB 或无线局域网配对）
flutter devices

# 2. 直接以 release 模式构建并安装到目标 iPhone（将 <DEVICE_ID> 替换为实际设备标识）
flutter run --release -d <DEVICE_ID>
```

#### 方案 B：使用 Xcode 安装 Release 模式
1. 用 Xcode 打开工程目录下的 iOS 工作区：
   ```bash
   open ios/Runner.xcworkspace
   ```
2. 在 Xcode 顶部菜单栏选择 **Product** -> **Scheme** -> **Edit Scheme...**；
3. 在左侧面板选择 **Run**，将 **Build Configuration** 从 `Debug` 修改为 `Release`；
4. 顶部设备选择您的 iPhone 真机，点击 **Run（运行）**。

#### 方案 C：使用 Apple `devicectl` 命令行工具独立部署
```bash
# 1. 编译 release 包
flutter build ios --release

# 2. 使用 devicectl 直接将构建好的 Runner.app 部署到真机
xcrun devicectl device install app --device <DEVICE_UUID> build/ios/Release-iphoneos/Runner.app

# 3. 启动应用
xcrun devicectl device process launch --device <DEVICE_UUID> com.aixohub.divination.divination
```

采用上述任一方案安装后，App 将使用纯 AOT 二进制运行，脱离电脑随时随地在 iPhone 桌面秒开，不会再有任何 Debug Mode 提示。

---

逆向取证与实现对照见 [`docs/reverse/home_qigua.md`](docs/reverse/home_qigua.md)，
取证脚本见 [`tools/reverse/extract_rn_bundle.py`](tools/reverse/extract_rn_bundle.py)。

```bash
flutter analyze && flutter test
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
