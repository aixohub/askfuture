# 首页"开始起卦"功能逆向分析与实现说明

## 一、取证对象与方式

| 项目 | 值 |
| --- | --- |
| 官方包 | `/Users/jupyter/app/ipa/yishihui/RN0615.app/main.jsbundle` |
| 包类型 | React Native 生产包（未压缩源码 + `\uXXXX` 转义） |
| 模块格式 | `__d(function(g, r, i, a, m, e, d){ ... }, <模块ID>, [<依赖模块ID>])`，共 4439 个模块 |
| 取证脚本 | `tools/reverse/extract_rn_bundle.py`（解码整包 + 按模块 ID 切分导出） |

```bash
python3 tools/reverse/extract_rn_bundle.py \
  --bundle /Users/jupyter/app/ipa/yishihui/RN0615.app/main.jsbundle \
  --out /tmp/ysh_re --pretty
```

模块与页面的对应关系由模块 2196 的路由表给出：

```
首页        -> 2416        paiPanType  -> 2501
wenGuaPage  -> 2324        yaoGua      -> 2400
wenGua_input-> 2398        guaXiangPage-> 2441
```

## 二、首页（模块 2416）结构

首页即底部 Tab 第一项"首页"（`tabPages.首页 = d[28] = 2416`），埋点
`Page_SuanGuaHome / 页面_首页_占卜`。渲染骨架（`render()` 方法）：

1. 渐变容器 `colors: ["#28B7A3", "#fff"]` + 居中标题 **"易占师算卦大师"**（20 / #fff / bold）
2. 白色圆角卡片（`borderRadius: 20` + 阴影），内部 Tab
   `renderTabBar` → `["在线起卦", "八字轻测", "紫微斗数"]`，内容高度
   `heightArr = [480, 430, 360]`
3. "我的咨询" / "起卦记录" 双按钮（`#f5b772`，宽度 46%，分别跳
   `tabHistory` / `HistoryNoPay`）
4. 话题轮播（`getForumTopics`）、**热门六爻占问**、热门老师、八字轻测推荐、评价列表

其中与"起卦"直接相关的是第 2、4 项。

### 2.1 起卦表单 `_geZhanBuBox()`

```
占事分类:                                     正确的分类可提高预测准确性
┌────────┬────────┬────────┐
│ 婚姻情感 │ 单身姻缘 │ 财运生意 │   ← FlatList numColumns=3，圆角胶囊
└────────┴────────┴────────┘   …共 18 项
问题:   [请输入求测问题，一事一测]      ← maxLength=100，multiline
性别:   (♂男)  (♀女)                 ← 26×26 圆形，选中 #1296db
        [      开 始 起 卦      ]      ← #00ABAE，宽度 0.9×屏宽
```

分类数据源为模块 2419 `typeDataNew`（18 项，实现见
`lib/models/divination_models.dart` 的 `kDivinationCategories`）：

```
婚姻情感3 单身姻缘30 财运生意4 事业官运1 怀孕子女5 学业考试6
年运终身9 短期运势10 官司诉讼11 疾病医药7 找寻失物13 股票期货26
求职应聘15 测手机号25 家宅风水18 出行平安12 消息联络17 其它杂占28
```

### 2.2 点击"开 始 起 卦" → `_checkInput()`

```js
l._checkInput = function (t) {
  W.default.logEvent("Home_Btn_PaiPan", "首页_按钮_排盘点击总数", null);
  if (null != c && "" != c && 0 != c) {                 // c = state.quetype
    if (null == s || "" == s || s.length < 2) C.default.warn("请输入求测问题~");
    else if (-1 != n) {                                 // n = state.sex
      (30 == c && (c = 3), 3 == c && 1 == l.state.sex && (c = 2));
      var u = { sex: l.state.sex, question: o + ".", quetitle: s, quetype: c, type: l.state.type };
      (0, T.gotoCheck)("paiPanType", null, u);
      W.default.logEvent("Home_Btn_PaiPan_SUCC", "首页_按钮_进入排盘方式页", null);
      l._clearInput();
    } else C.default.warn("请选择性别!");
  } else C.default.warn("问题分类可提高预测准确性，请仔细选择");
};
```

关键规则（已在 `lib/widgets/divination_card.dart` 中 1:1 实现）：

| 规则 | 取值 |
| --- | --- |
| 未选分类 | 提示 `问题分类可提高预测准确性，请仔细选择` |
| 标题为空或长度 < 2 | 提示 `请输入求测问题~` |
| 未选性别 | 提示 `请选择性别!` |
| 分类换算 | `30 → 3`（单身姻缘归入感情/婚姻）；`3 且性别=男 → 2` |
| 跳转参数 | `{sex, question, quetitle, quetype, type}`，`type = Config.yaoGuaProIdSet = "169"` |
| 初始状态 | `quetype = ""`、`sex = -1`（均未选中，因此三项校验都会真实触发） |

分类换算后的展示名取自模块 2325 `typeData` 顶层分类：
`2 → 感情/婚姻(男)`、`3 → 感情/婚姻(女)`、`4 → 财运/生意` …（见 `kQueTypeNames`）。

### 2.3 热门六爻占问

```
情感婚恋 #ff6262   事业工作 #46c7bf
财运生意 #F60      兔年运程 #7B68EE
```

点击走 `_toWenGuaPageByHome(titleIndex)`：先 `yjhapp/toYuce` 取产品数据，再跳
`wenGua_input`（模块 2398）。同模块内的 `Q` 表给出官方求测标题，并在 19 点后把
"今天"替换为"明天"（`if (l.state.nowHour >= 19) s = s.replace("今天", "明天")`）：

```
{type:30, title:"我今天的桃花姻缘运势如何？"}
{type:3,  title:"我今天的婚姻感情运势如何？"}
{type:4,  title:"我今天的财富生意运势如何？"}
{type:1,  title:"我今天的事业工作运势如何？"}
```

实现里用该标题表作为快捷入口的预设求测标题（`_openHotEntry`），并同样应用
19 点规则。

## 三、排盘方式选择页（模块 2501，路由 `paiPanType`）

### 3.1 占事信息卡片

```
                占事信息
占卜问题：<quetitle>
占事分类：<getQueTypeName(quetype)>            卦主性别：男/女
起卦时间：[ 2016-08-01 12:00 ]
起卦方式：
在线起卦 电脑自动 手工指定 时间起卦 单数起卦 双数起卦 汉字起卦 卦名起卦
```

方式取值（服务端 `qigua` 字段）：
`2 在线起卦 / 6 电脑自动 / 1 手工指定 / 5 时间起卦 / 3 单数起卦 /
4 双数起卦 / 9 汉字起卦 / 8 卦名起卦`。

### 3.2 各方式面板

| 方式 | 关键交互 | 校验提示 |
| --- | --- | --- |
| 在线起卦 | 点击铜钱开始/停止，累计 6 次 | `摇卦数据不正确，请重新摇卦！` |
| 电脑自动 | 直接起卦 | — |
| 手工指定 | 六爻→一爻 6 个下拉（`Config.yaoMap`） | `摇卦不能为空，每一次摇卦都需要记录~` |
| 时间起卦 | 时间选择器 | `请选择起卦时间！` / `您选择的时间大于当前时间` |
| 单数起卦 | 一个数字输入 | `请输入一组数字` / `请输入纯数字(10位以内)` |
| 双数起卦 | 两个数字输入 | `请输入第一组数字` / `请输入第二组数字` / `请输入纯数字(10位以内)` |
| 汉字起卦 | 2–10 个汉字 | `请输入起卦汉字` / `请输入纯汉字(10位以内)` |
| 卦名起卦 | 本卦 / 变卦选择器 | `请选择本卦卦名` / `请选择变卦卦名` |

面板内固定文案也按官方原文落地，例如：

* 在线起卦：`在线起卦：请让内心平静，摒除杂念，集中注意力默想自己占卜之事，每次摇卦时在心中默数3秒，会更加准确哦！`
* 手工指定：`正反约定：`（加粗）`铜钱有汉字（或硬币有数字1）的一面为正；铜钱无字（或硬币的菊花、国徽）图案一面为 背`、`摇卦顺序：`（加粗）`从下往上，一爻到六爻，依次为第一次到第六次摇卦的正反信息。`
* 时间起卦：`起卦原理：1、（年+月+日）除以８取余数做上卦；2、（年+月+日+时）除以８取余数做下卦；3、（年+月+日+时）除以６取余数做动爻。`
* 卦名起卦：`卦名起卦：可直接指定本卦与变卦快速起卦，虽然业界持有赞否两论，善用者用之。`

### 3.3 `_toPaiPan()` 提交参数组装

`qiguaData` 为 6 个爻值，顺序 **[六爻, 五爻, 四爻, 三爻, 二爻, 一爻]**：

```js
// 在线起卦：data[0] 是最后一次摇卦（六爻），data[5] 是第一次（一爻）
h = qiguaMapStr[data[0].value].text1;   // 六爻
...
n = qiguaMapStr[data[5].value].text1;   // 一爻
qiguaData = getYaoData([n,o,c,s,f,h]).reverse().join(",");
```

提交体：

```js
{ qiguaData, chatRoomId, limit: 0, indexId: 0, description: quetitle,
  inputTime: submittime, isLeapMonth: false, qigua: qiGuaType,
  sex, type1: quetype, type2: -1, dateType: 0 }
// POST yjhapp/qigua  →  跳转 guaXiangPage
```

### 3.4 摇卦随机算法（模块 1897）

```js
var v = function () {
  for (var t = [], n = 0, u = 0; u < 3; u++) t.push(Math.round(Math.random())), n += t[u];
  return { result: t, yao: 0 == n ? 3 : n - 1 };   // 0正→老阳3、1正→少阴0、2正→少阳1、3正→老阴2
};
```

爻值与 `qiguaMap` 一一对应（`lib/models/divination_models.dart::kYaoTypes`）：

| 值 | 名称 | 阴阳 | 动静 | 铜钱 | 标记 |
| --- | --- | --- | --- | --- | --- |
| 0 | 少阴 | 阴 | 静 | 1 正 2 背 | |
| 1 | 少阳 | 阳 | 静 | 2 正 1 背 | |
| 2 | 老阴 | 阴 | 动 | 3 正 0 背 | x |
| 3 | 老阳 | 阳 | 动 | 0 正 3 背 | o |

## 四、卦象结果页（模块 2441，路由 `guaXiangPage`）

官方该页数据来自服务端 `guaxiang` 字段（卦名、宫位、六神、世应、爻辞、
传统/现代解卦等），本工程无服务端，改为按官方同一套卦码规则本地推卦：

* 卦码来自模块 2293 `divineNameData`（八宫 × 八卦 = 64 条），
  形如 `111111 乾为天`、`010111 水天需`；
* 卦码顺序与 `qiguaData` 一致（`[六爻…一爻]`，`1` 阳 `0` 阴），
  因此可直接由六爻阴阳拼出本卦，再由动爻（2/3）翻转变出变卦。

模块 2196 路由表中另有 `guaXiangPageDoc`（卦师版），本次未涉及。

## 五、本地实现映射与差异说明

| 官方行为 | 本地实现 | 文件 |
| --- | --- | --- |
| 首页标题 / 渐变 / Tab | `DivinationPage` + `DivinationCard` | `lib/pages/divination_page.dart`、`lib/widgets/divination_card.dart` |
| 三项校验 + 分类换算 | `_onStartQiGua()` | `lib/widgets/divination_card.dart` |
| 占事分类表 | `kDivinationCategories` | `lib/models/divination_models.dart` |
| 占事分类展示名 | `kQueTypeNames`（模块 2325） | 同上 |
| 排盘方式选择页 8 种方式 | `PaiPanTypePage` | `lib/pages/pai_pan_type_page.dart` |
| 铜钱摇卦随机算法 | `CoinCastResult.fromCoins` | `lib/models/divination_models.dart` |
| 六爻 → 本卦/变卦/动爻 | `buildGuaResult` 等 | `lib/models/hexagram.dart` |
| 卦象结果页 | `GuaXiangPage` | `lib/pages/gua_xiang_page.dart` |

因本工程无服务端，以下为**明确标注的本地适配**（不是逆向所得，可随时替换为接口实现）：

0. **起卦方式默认值**：官方 `paiPanType` 页 `qiGuaType: 2`（在线起卦），
   本工程按产品需求默认 `kQiGuaTypeManual`（手工指定），进入排盘页即可直接指定六爻；
1. `yjhapp/qigua` 提交与 `guaxiang` 返回 → 本地按卦码推卦并在 `GuaXiangPage` 渲染；
2. 登录校验（官方 `请先登录...` + 跳登录页）未接入；
3. 首页 19 点后"今天→明天"规则保留，但快捷入口的求测标题取自官方 `Q` 表；
   官方真实标题由 `toYuce` 接口下发；
4. 单数 / 汉字起卦的推卦规则官方在服务端完成，本地采用可复现的近似规则
   （时间/双数起卦使用官方面板内公开的"取余数"原理），详见
   `lib/models/hexagram.dart` 中各函数注释；
5. 首页性别默认选中"男"（官方 `state.sex` 初值为 -1，即不选中），
   用户仍可切换为"女"，分类换算规则不变；
6. 热门老师、话题榜、评价列表、八字轻测推荐等纯接口区块未实现。

## 五点五、手工指定起卦链路（默认方式）

进入排盘方式选择页后默认停在「手工指定」，完整闭环：

| 步骤 | 实现 |
| --- | --- |
| 选择某一爻 | 六爻 → 一爻 六个选择框，点击弹出底部滚轮（`ListWheelScrollView` + `FixedExtentScrollPhysics`），对齐官方 `react-native-wheel-picker` 交互；选项文案取官方 `Config.yaoMap`（请选择 / 老阴 / 老阳 / 少阳 / 少阴） |
| 已选反馈 | 选择框显示 `少阳(2正1背)` 简写 + 爻线；面板底部「六爻预览」实时显示六爻爻象、`已选 n/6`，六爻齐全后即时显示 `【本卦】变【变卦】卦` |
| 校验 | 未选满六爻 → 官方提示 `摇卦不能为空，每一次摇卦都需要记录~` |
| 起卦 | `getYaoData()` 同序映射为爻值 → 六爻自下而上推本卦 / 变卦 / 动爻 |
| 结果页 | 见下节 |

## 五点六、起卦结果页（手工指定 → 开始起卦 之后）

`GuaXiangPage` 结构（数据来源标注见页面内说明卡）：

1. **占事信息**：占卜问题 / 占事分类 / 卦主性别 / 起卦方式 / 起卦时间 / 起卦信息
   （手工指定时为「一爻 少阳，二爻 少阴 …」）
2. **卦象主卡**：`【本卦】变【变卦】卦`（静卦显示 `【本卦】静卦`）；
   本卦 / 变卦 双列展示卦名、所属宫、`上坎下乾` 上下卦、卦码
3. **六爻表**：六爻 → 一爻 逐行展示 爻位 / 爻题（初九、六二…上九）/ 本卦爻线（动爻带 x、o 标记）/ 变卦爻线，
   动爻行以箭头指示；底部给出 `动爻：九三、上六（共 2 爻动）` 或 `六爻皆静，无动爻，以本卦卦象论之。`
4. **排盘数据**：`qigua / type1 / sex / qiguaData` 四项与官方 `yjhapp/qigua` 提交结构一致，便于接入服务端时比对
5. **保存排盘**：写入本地起卦记录（`QiGuaRecordStore`），提示文案取官方
   `保存成功` / `本次占卦已保存成功，可随时至 个人中心 - 起卦记录 查看。`；
   保存后按钮变为 `已保存到起卦记录`
6. 首页「起卦记录」读取同一存储并列出记录（官方该列表来自服务端）

> 六神、六亲、世应、伏神、爻辞与解卦文本在官方实现中均由服务端 `guaxiang`
> 下发（bundle 内对应字段为渲染态 `t.shiying` / `t.fushen.liuqing` 等），
> 无静态表可对齐，本地不做臆造，页面中已注明。

## 五点七、卦象页对齐官方模块 2441 / 2442 / 2443

### 页面结构

| 区块 | 官方来源 | 本地实现 |
| --- | --- | --- |
| 占事信息：`问占： / 占类： / 卦主： / 时间：` | 模块 2442 | `_buildInfoHeader()` |
| `干支： 年 月 日 时 (旬空 xx)`（月日时红色） | 模块 2443 | `_buildGanZhiLine()` |
| `六神 本卦名(宫-六冲/六合/游魂/归魂)` + 六爻行（六神 / 六亲干支五行 / 爻象 / 世应动标 / `↑ 伏神：…`） + 变卦列 | 模块 2443 | `_buildGuaTable()` |
| 工具条 `分享 / 复制 / 截图` | 模块 2441 `_getToolsButtonView` | `_buildToolsRow()` |
| 截图浮层 `保存到相册`（70%，#28B7A3） + `关闭`（30%，#46a9f0） | 模块 2441 `isSHowSnapShot` | `_buildSnapShotBar()` |
| 保存排盘 → 起卦记录 | 模块 2441 | `_onSave()` |

### 复制（`copyPaiPanInfo`，模块 2449）

文本格式 1:1 移植：

```
易占师
2026年9月17日 10:30
占问：<求测标题>
丙午年 丁酉月 甲午日 己巳时 (旬空：辰巳)
本卦：乾为天/乾宫六冲
变卦：泽天夬/坤宫
龙 　　 子孙甲子水 —  世 子孙癸丑土 —
…
```

* 六神简写：龙 / 雀 / 勾 / 蛇 / 虎 / 玄
* 六亲简写：兄 / 孙 / 父 / 财 / 官
* 伏神位不足时以全角空格 `　　 ` 占位，动爻在爻象后追加 ` x `（阴动）/ ` o `（阳动）
* 复制后 Toast 取官方 `copyEdAlert`：`已复制到剪贴板`

### 截图 / 分享

* 截图对象为 `RepaintBoundary` 包裹的卦象图（`pixelRatio: 3`），等价官方
  `snapShot.animateSnapShot(this._shotView, ...)`
* 截图模式（`isSHowSnapShot`）下隐藏工具条，仅保留卦象图与底部
  `保存到相册 / 关闭`
* `保存到相册` 通过 `gal` 写入系统相册（Android 实测落在
  `/sdcard/Pictures/guaxiang_*.png`）；iOS 已在 `Info.plist` 声明
  `NSPhotoLibraryAddUsageDescription`
* `分享` 通过 `share_plus` 调起系统分享面板发送卦象图

### 六爻装卦（`lib/models/liuyao.dart`）

官方六神 / 六亲 / 世应 / 伏神均为服务端字段（bundle 内无静态装卦表），
本地按传统装卦法推导并用经典排盘自校验：

* 纳甲：八卦内三爻 / 外三爻干支（乾内甲子…外壬戌 等）
* 六亲：以卦宫五行为我（同兄、生我父、我生孙、克我官、我克财）
* 六神：按日干起（甲乙青龙 … 壬癸玄武），自初爻上行
* 世应：按八宫卦序（首卦世六应三 … 游魂世四应一、归魂世三应六）
* 伏神：本宫首卦中不上卦的六亲，伏于本卦同爻位
* 旬空：由日干支推出（甲子旬戌亥空 …）

单测覆盖：乾为天（甲子水子孙 … 壬戌土父母 / 六冲 / 世六应三）、
坤为地、水天需（坤宫游魂 / 世四应一 / 上卦坎纳戊）、天风姤伏神、
日干支（1899-12-22 甲子、2000-01-01 戊午）、年干支立春换年、月干支五虎遁。

### 干支

天干地支与取干支、日干支、时干支、年干支、月干支 1:1 移植官方模块 2111
`GanZhi`（含 JS 取余符号语义）；年月分界官方用内置节气数据（模块 2112
`YEARSDATA`），本地以通用节气公式近似，误差仅在节气当日附近。

### 起卦时间选择器（修复记录）

官方 `DatePick` 配置为 `minDate 1901-01-01 / maxDate 2089-05-01`，起卦时间栏
对应 `DateTimePicker`。Flutter 侧使用 `showDatePicker` + `showTimePicker`，
二者强制依赖 `MaterialLocalizations`：

* `showDatePicker(locale: Locale('zh'))` 会按 zh 解析本地化；
* 若未注册 `GlobalMaterialLocalizations`，`MaterialLocalizations.of(context)`
  直接抛 `No MaterialLocalizations found.`，`DatePickerDialog` 构建失败 → 页面崩溃。

因此工程已引入 `flutter_localizations`，并在 `MaterialApp` 注册
`GlobalMaterialLocalizations / GlobalWidgetsLocalizations / GlobalCupertinoLocalizations`
与 `supportedLocales: [zh_CN, en_US]`、`locale: zh_CN`；
回归用例 `test/widget_test.dart :: 点击起卦时间可正常选择并回填` 覆盖
「点击 → 中文日期选择器 → 选日 → 确定 → 时间选择器 → 确定 → 时间回填」全流程。

## 六、回归验证

* 单元测试 `test/hexagram_test.dart`：分类表/方式表、铜钱算法、六爻→卦码、
  双数/时间/卦名起卦、64 卦表一致性。
* Widget 测试 `test/widget_test.dart`：首页三条校验提示、`3 → 2` 分类换算、
  排盘页跳转与 8 种方式渲染、在线摇卦 6 次成卦、卦象页跳转、小屏无溢出。

```bash
flutter analyze && flutter test
```

## 七、在线起卦铜钱素材

官方"在线起卦页面"（模块 2400）使用三个铜钱素材，模块 2401/2402/2403 注册、
由铜钱组件（模块 2391）以 `frontImgSource / backImgSource / yingBiGif` 渲染
（`state.yaoCoin ? yingBiGif : (value ? frontImgSource : backImgSource)`）：

| 官方路径（`assets/bus/zyPaipan/public/img/quice/yingBiQiGua/`） | 模块 | 尺寸 | 用途 |
| --- | --- | --- | --- |
| `frontImg.png` | 2401 | 148×148 | 铜钱正面（字面，爻值 1 正时显示） |
| `backImg.png` | 2402 | 148×148 | 铜钱背面（爻值 0 背时显示） |
| `yingBi.gif` | 2403 | 148×148 | 摇卦动画（摇动中三枚铜钱统一显示） |

本工程把三张图原样复制到 `assets/images/qigua/yingBiQiGua/`（`cmp` 校验与官方
文件逐字节一致），由 `lib/widgets/copper_coin.dart` 的 `CopperCoinWidget`
渲染：`isShaking = true` 显示 GIF，否则按 `isFront` 显示正/背面；素材缺失时
回退到手绘 `_CopperCoinPainter`。

同一目录下的 `yinyao.png` / `yangyao.png`（阴/阳爻线，模块 2395/2396）、
`yingBiQiGuaBg.png`、`bagua.png`、`reel.png`、`loading.gif`、`thinkBg.png`
尚未引入，可按需补充。

## 八、起卦时间选择器（DatePick）

排盘方式选择页与"时间起卦"面板的时间栏都使用官方 `DatePick` 组件：

* 通用组件：模块 2234，Props 为 `mode / format / minDate / maxDate /
  confirmBtnText / cancelBtnText / isShowIcon / iconSource / inputTimeText /
  isUpdateDate / timeCallbackValue`；
* 弹层：iOS 为模块 2236，Android 为模块 2238（带"公历/农历"与时辰）；
* 图标：模块 2245 `/assets/public/img/date_icon.png`（100×117，界面按 20×20 显示）。

官方 `Config.DatePick`（模块 430）取值：

```
mode: "datetime"   format: "YYYY-MM-DD HH:mm"
confirmBtnText: "确定"   cancelBtnText: "取消"
minDate: "1876-05-01"    maxDate: "2089-05-01"
```

模块 2236 的弹层结构（底部滑出，点浮层外取消）：

1. 顶栏：左"取消"、右"确定"（`#2AA9B9`，14px）；`isShowLunar` 为真时中间是
   "公历 / 农历"切换胶囊；
2. 标签行：`年 月 日 时 分`，每列宽 `75 × 屏宽 / 375`；
3. 五列滚轮：`setOptions()` 限定 年 ∈ [minYear, maxYear]、
   月/日按边界收敛（选择最小年时月份从 min 月起），时 0–23、分 0–59；
4. "确定"回填 `dateValue + " " + timeValue`，即 `YYYY-MM-DD HH:mm`。

本工程实现见 `lib/widgets/date_time_picker.dart`：

* `DateTimePickerSheet.show()` —— 底部弹层 + 五列滚轮，范围/按钮文案/配色对齐官方；
* `CastingTimeField` —— 官方同款输入框（左侧 `date_icon.png` 20×20，文本
  14px `#747474`），排盘页与时间起卦面板共用；时间起卦面板文本居中，
  对应官方 `inputTimeText.textAlign = "center"`。

差异说明：官方该弹层仅在 `isShowLunar` 为真时显示"公历/农历"切换，排盘页未开启，
因此本地同样不显示；滚轮的时 / 分显示补零（官方 `setTimes()` 未补零，
但其 `format` 与初始值均为补零格式）。

## 九、干支历（万年历）

### 9.1 官方实现

| 环节 | 模块 | 说明 |
| --- | --- | --- |
| 入口按钮 | 2442 / 3130 | 占事信息"时间：…"行右侧的日历按钮（`calendarImg2` 图标，皮肤 `calendarButtonStyle`） |
| 弹层容器 | 3131 | 半透明黑底 + 居中卡片 + 右上角白色关闭按钮（`showCalendarModal()`） |
| 万年历 | 2225 | 顶部年月区（2233 / 2246）+ 月历主体（2226） |
| 月历主体 | 2226 | 四柱行（2228）+ 星期表头 + 月历格（2232）+ "回到今天" |
| 四柱行 | 2228 | `[马] 丙午年    丁酉月    甲午日    甲戌时` |
| 日期格 | 2232 | 公历日 + （当天节气名 或 农历日），今天/选中/非本月三态配色 |
| 节气行 | 2227 | `节气:白露 2026年09月7日  22 : 41` / `中气:秋分 2026年09月23日  08 : 05` |
| 数据引擎 | 2112 | `SolarTerm.getSizhu()` —— 精确节气（含时刻）与四柱 |
| 干支规则 | 2111 | `GanZhi` 年/月/日/时干支取法、`Calendar.getAnimals` 生肖 |
| 农历表 | 1898 | `lunarInfo` 压缩位表与 `solar2lunar` 换算 |

配色取官方易占师皮肤（模块 1270 `calendarStyle`）：
`nowDayViewColor #01AAEC`（今天）、`onPressViewColor #B0B0B0`（选中）、
`notMonthColor #BBBBBB`、`restTextColor #E51C23`（周末）、`jieqiColor #28B7A3`、
`jieqiTiText #259B24`、`jieqiText #ABABAB`、`changeBcolor #01AAEC`。

### 9.2 精确数据导出（`tools/reverse/extract_official_calendar.js`）

Node 以极简 `__d` 规则直接运行官方模块 2111 / 2112 / 1898，导出：

* `lib/models/jieqi_data.dart` —— 1901–2099 年 24 节气表，值为 `MMddHHmmss`
  （本地墙钟时间）。官方引擎的毫秒为进程噪声，故只保留到秒；
* `lib/models/lunar_calendar.dart` —— `lunarInfo` 全表（201 项，已逐项校验一致）
  与 `solar2lunar` / `toChinaMonth` / `toChinaDay` / `toGanZhiYear` 移植；
* 官方对照向量（四柱 / 农历 / 节气），落到 `test/official_calendar_test.dart`。

```bash
TZ=Asia/Shanghai node tools/reverse/extract_official_calendar.js \
  --bundle /Users/jupyter/app/ipa/yishihui/RN0615.app/main.jsbundle --out /tmp/ysh_calendar
```

### 9.3 本地实现映射

| 官方行为 | 本地实现 |
| --- | --- |
| 精确节气（年/月柱边界） | `lib/models/jieqi.dart`（`currentJie` / `nextJie` / `currentZhongQi` / `jieQiOnDay`） |
| 四柱（含 23 时归次日、立春换年） | `lib/models/ganzhi.dart::computeSiZhu` / `jieQiMonthOf` |
| 农历换算 | `lib/models/lunar_calendar.dart`（`solar2Lunar` 等） |
| 卦象页时间行 / 干支行 | `时间：2026-9-17 19:16（八月初七）`、`干支：丙午 丁酉 甲午 甲戌（旬空 辰巳）` |
| 干支历弹层 | `lib/widgets/gan_zhi_li_dialog.dart`（入口为卦象页"干支历"按钮） |

### 9.4 对照验证

`test/official_calendar_test.dart` 用官方引擎直接导出的 10 条向量逐条比对
（四柱 / 农历 / 上一个节 · 中气 / 下一个节），覆盖：

* 立春整点边界（2026-02-04 04:02 与 2024-02-04 16:27）；
* 节气当天（2026-09-07 白露）；
* 23 时归次日（1990-06-15 23:30）；
* 跨年（2000-01-01 己卯年 / 丙子月）。

`test/gan_zhi_li_test.dart` 校验弹层结构：四柱行、星期表头、月历农历/节气、
节气·中气行、点击改选中日、"回到今天"、上下月切换。

## 十、八字轻测与八字排盘

### 10.1 官方实现

| 环节 | 模块 | 说明 |
| --- | --- | --- |
| 首页"八字轻测"面板 | 2423 | 命主性别 / 日期类型 / 出生日期（DatePick 2234）/ 出生城市（2424 选择器 + 2427 省市数据）/ 真太阳时勾选与说明 / 问题描述 / 三条提示 / 「立即查询」 |
| 提交 | 2423 `_baZiPaiPan()` | 组装 `{userName, description, sex(男=1/女=2), city, inputTime, bornTime, dateType, isUseSunTime, ...}` → `yjhapp/bzQiGua` |
| 排盘结果页 | 2505（`ResultPage2`） | 承载三个页签（模块 2508），数据来自服务端 `guaxiang` |
| 页签容器 | 2508 | `tabList = ["基本信息", "基本命盘", "专业命盘"]`；tabBar 高 42、白底、下边框 `#F5F5F5`，选中 `#EA5A3D` 加粗 14px + 56×2 下划线，未选中 `#333` |
| 基本信息页 | 2510 | 节气 + 命盘简表 + 日主衰旺 + 后天喜用 + 五行力量 + 适宜五行/生肖/颜色/方位 |
| 基本命盘页 | 2512 | 旬空 / 地势 / 十神 / 天干 / 地支 / 纳音 / 藏干 / 神煞 + 胎元命宫 + 大运 / 流年 / 小运 |
| 专业命盘页 | 2514 | `流年 / 大运 / 年柱 / 月柱 / 日柱 / 时柱` 横向时间轴，可切换所看大运 |
| 命主信息条 | 2509 | 求测标题 / 姓名(性别) 地点 / 时间（公历 + 农历），行高 28、底色交替 `#fff`/`#F5F6F7` |
| 行样式 | 2470 `ResultStyle` | 行高 28、左右内边距 10；天干/地支 20px `#CD2626`；藏干与纳音值 `#6495ED`；标签 13px 加粗 `#333` |
| 十神·纳音·藏干表 | 2472 | `tianGan` / `diZhi` / `shishen_s` / `nayin`(60) / `status12` / `dizhiCangGan`，含 `getShiShen` / `getNayin` / `getChangShen12` / `getXunkong` |
| 省市数据 | 2427 | `unionAreaData`（33 省）与 `areaTitle = ["省","市"]` |

官方校验文案（2423）：问题描述不足 2 字 → `请输入求测问题~`；未选性别 →
`请选择性别`；未选阴/阳历 → `请选择阴/阳历`；勾选真太阳时但未选出生地 →
`请先选择出生地点`；出生时间晚于当前 → `您选择的时间大于当前时间`。

### 10.2 本地实现

| 官方能力 | 本地实现 |
| --- | --- |
| 八字轻测表单与校验 | `lib/widgets/bazi_qingce_tab.dart` |
| 省市数据 | `lib/models/china_area.dart`（模块 2427 全量移植） |
| 十神 / 藏干 / 纳音 / 长生十二神 / 五行配色 | `lib/models/bazi.dart`（模块 2472 1:1 移植） |
| 四柱（年月日时） | `computeSiZhu()`（模块 2111 + 精确节气表） |
| 阴历输入换算 | `lunar2Solar()`（模块 1898 `lunar2solar` 移植） |
| 大运 / 流年 | `buildBaZiPan()`：阳年男、阴年女顺排，三天折一年起运，自月柱顺/逆十步；流年取当年干支 |
| 排盘页 UI | `lib/pages/bazi_paipan_page.dart`（三页签：基本信息 / 基本命盘 / 专业命盘） |
| 胎元 / 命宫 / 小运 | `buildBaZiPan()`：胎元 = 月干进一、月支进三；命宫按月支时支取宫支、年干起五虎遁取宫干；小运自时柱顺/逆排 |
| 日主衰旺与喜用 | `WuXingPower`：五行力量按「天干 1 份 + 地支藏干天数折算」统计，据此判断身强/身弱并给出喜用五行及适宜五行/生肖/颜色/方位 |

### 10.3 差异说明

1. 官方排盘结果由服务端 `yjhapp/bzQiGua` 下发（含逐柱神煞、格局、专家解读与
   大数据匹配），本地只实现可由官方规则推导的部分：四柱、十神、藏干、纳音、
   地势（长生十二神）、旬空、胎元、命宫、小运、大运与流年；逐柱神煞与专家解读未实现
   （基本命盘的"神煞"行展示日柱旬空神煞：驿马/咸池/贵人/文昌）。
2. 起运岁数官方由服务端给出（`jiaoyunYear`），本地按"三天折一年"换算，
   与官方在少数日期上可能有 1 岁以内差异。
3. 日主衰旺、后天喜用与适宜五行/生肖/颜色/方位，官方为服务端大数据结果，
   本地按传统"五行力量 + 扶抑取用"规则近似（同五行与印星占比≥50% 判身强，
   身强取食伤/财/官、身弱取印/比劫），仅供研究参考。
4. 真太阳时官方按出生地经度修正时间，本地仅记录并展示勾选状态，未做经度换算。
