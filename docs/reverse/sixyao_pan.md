# 农历/公历日期转换与六爻装盘（对照 sixyao-main）

## 一、参考工程

| 项目 | 值 |
| --- | --- |
| 参考实现 | `/Users/jupyter/Downloads/tradeview/sixyao-main`（Java / Spring Boot） |
| 装盘入口 | `com.aixohub.sixyao.yi.service.impl.GuaExecServiceImpl#queryGua` |
| 装盘数据表 | `com.aixohub.sixyao.yi.utils.YaoUtil`（纳甲 / 六亲 / 六神 / 世应 / 64 卦表） |
| 农历换算 | 前端 `src/main/resources/static/liuyao.js` + `lunar.js`（寿星万年历），Java 侧 `EightWordCalculator` 出四柱 |

本工程（Flutter）原先的装盘与农历换算分别来自官方易占师 RN bundle
（模块 2293 六十四卦表、模块 1898 农历表）与传统六爻装卦法。本次按 sixyao-main
**逐字段校验并补齐**，两处实现互为佐证。

## 二、六爻装盘

### 2.1 参考实现的装盘步骤

```
六爻爻值(0 少阴 / 1 少阳 / 2 老阴 / 3 老阳，自下而上)
  → 上下卦序号：sanYaoToBaGuaIndex(初,二,三)、sanYaoToBaGuaIndex(四,五,六)
  → 卦宫与宫内序号：Array64Gua[i] = {卦名, 卦宫, 宫内侧序, 世应关系}
  → 纳甲：naJiaTianGan / naJiaDiZhi（内卦 初~三、外卦 四~六）
  → 六亲：(地支五行 + 5 - 卦宫五行) % 5  → 兄弟/子孙/妻财/官鬼/父母
  → 六神：日干起（甲乙青龙、丙丁朱雀、戊勾陈、己腾蛇、庚辛白虎、壬癸玄武）
  → 世应：AnShiYao[宫内侧序] 定世爻，应爻 = 世爻 + 3 位
  → 伏神：本宫纯卦中"五行不上卦"的爻伏于同爻位
  → 变卦：动爻（老阳/老阴）阴阳互变后，按同样流程再装一遍
```

### 2.2 对照结果

对照数据由参考实现直接运行导出（`tools/reverse/sixyao_pan_reference/`）：

* 64 卦 × 3 个起卦时刻（静卦）
* 64 卦 × {初爻动、上爻动}（含变卦）

共 **320 条记录**，逐条比对 本卦 + 变卦 的
卦名 / 卦宫 / 宫内八名 / 世应关系 / 六爻（六神、伏神、六亲、纳甲地支、五行、世应、动爻）：

```bash
flutter test test/sixyao_pan_reference_test.dart
```

**发现并修复的问题**：变卦此前没有计算伏神（只有本卦计算），
与参考实现不符——`genFullLiuYaoPaiPan()` 对本卦与变卦各自按自身卦宫、
自身六亲集合计算伏神。修复后 320 条全部一致（`lib/models/liuyao.dart::_withFuShen`）。

### 2.3 补入的参考实现字段

| 字段 | 取值 | 说明 |
| --- | --- | --- |
| `GuaZhuang.gongNeiName` | 纯卦 / 初世 / 二世 / 三世 / 四世 / 五世 / 游魂 / 归魂 | `YaoUtil.GongNeiBaGuaMingChen` |
| `GuaZhuang.relation` | 六冲比 / 六合生 / 世克应 / 应生世 / 世生应 / 应克世 / 世应比 / 六冲克 / 六合克 | `YaoUtil.Array64Gua[i][3]` |
| `GuaZhuang.desc` | 例如 `坤宫游魂·世生应` | 上述两者组合，卦象页表头小字展示 |

## 三、六爻神煞（校正）

### 3.1 参考实现的口径

sixyao-main 的神煞写在 `src/main/resources/static/liuyaodata.js`，四张表全部以
**日柱**起，用法（原文）：

```js
var riGan = bzpp.iRiJZ % 10;   // 日干序号 0~9
var riZhi = bzpp.iRiJZ % 12;   // 日支序号 0~11
strTemp = "神煞：贵人→" + TGGuiRenStrs[riGan]
    + "，驿马→" + DZYiMaStrs[riZhi % 4]
    + "，桃花→" + DZTaoHuaStrs[riZhi % 4]
    + "，日禄→" + TGLuStrs[riGan];
```

| 神煞 | 查法 | 表（原文） |
| --- | --- | --- |
| 天乙贵人 | 日干 | 甲戊→丑、未；乙己→子、申；丙丁→亥、酉；庚辛→午、寅；壬癸→卯、巳 |
| 驿马 | 日支序号 % 4 | 寅（申子辰）、亥（巳酉丑）、申（寅午戌）、巳（亥卯未） |
| 桃花（咸池） | 日支序号 % 4 | 酉（申子辰）、午（巳酉丑）、卯（寅午戌）、子（亥卯未） |
| 日禄 | 日干 | 甲寅、乙卯、丙巳、丁午、戊巳、己午、庚申、辛酉、壬亥、癸子 |

参考工程自带排盘样例（`templates/home.ftl`，2023-06-04 09:49 癸巳日）：

```
神煞：贵人→卯、巳，驿马→亥，桃花→午，日禄→子
```

### 3.2 校正内容

| 项 | 校正前 | 校正后 |
| --- | --- | --- |
| 神煞集合 | 驿马、咸池、贵人（展开另有文昌、华盖） | 贵人、驿马、桃花、日禄（与参考实现一致） |
| 日禄 | 缺失 | 按 `TGLuStrs` 以日干取（如甲日→寅） |
| 桃花命名 | `咸池` | `桃花`（参考实现的取名；二者同义） |
| 数据来源 | 逐条 if/switch 硬编码 | 直接使用参考实现四张表（`kGuiRenByGan` / `kYiMaByZhiMod4` / `kTaoHuaByZhiMod4` / `kRiLuByGan`），索引规则一致 |
| 展示 | 折叠 3 项 | 折叠取前 3 项、展开 4 项（与官方卦象页 `l>2?void 0` 的折叠逻辑一致） |

未采纳的自造神煞（文昌、华盖）已从六爻排盘中移除——参考实现与官方服务端数据中均无此两项。

### 3.3 验证

```bash
flutter test test/shensha_test.dart
```

* 10 日干 × 12 日支 共 120 组，期望值按传统口诀/三合局独立推导后比对；
* 参考工程样例 2023-06-04 09:49（癸巳日）端到端对照
  `贵人→卯、巳，驿马→亥，桃花→午，日禄→子`；
* 四张常量表与 `liuyaodata.js` 逐项一致。

## 四、农历 / 公历日期转换

### 3.1 位置

* 换算核心：`lib/models/lunar_calendar.dart`
  （官方 RN 模块 1898 `calendar` 的 1:1 移植：`lunarInfo` 1900–2100 压缩表、
  `lunarYearDays` / `leapMonth` / `leapDays` / `monthDays`、`solar2lunar` / `lunar2solar`）
* 农历月/日/时辰文案：官方模块 2235 `lunarMonthData` / `lunarHourData`
  （`kLunarMonthNames`、`kLunarHourNames`、`lunarHourIndex` / `hourOfLunarHourIndex`）
* 输入界面：`lib/widgets/date_time_picker.dart`（官方 `DatePick` 的公历/农历切换）

### 3.2 修复与补强

| 项 | 说明 |
| --- | --- |
| 历表边界 | `lunar2Solar(1900, 1, 1..30)` 原本被误判为非法（返回 null），修正后为 1900-01-31 ~ 1900-02-28 |
| 入参校验 | 月必须在 1~12、日必须≥1 且不超过该农历月天数；闰月必须与该年真实闰月一致 |
| 反向换算 | 新增 `lunarDateOf()` / `solarDateOfLunar()` / `LunarDate.solarDate` |
| 月份列表 | 新增 `LunarMonthOption` / `lunarMonthsOf(year)`（含闰月）与 `lunarDaysInMonth()` |

### 3.3 验证

```bash
flutter test test/lunar_calendar_test.dart test/lunar_roundtrip_test.dart
```

* **公历 → 农历**：1736 条官方对照（`test/fixtures/official_lunar_reference.json`，
  由 `tools/reverse/extract_official_calendar.js` 从官方模块 1898 直接导出），
  覆盖 2023-01-01~2026-12-31 逐日（含 2023 闰二月、2025 闰六月）与
  1900–2100 每年春节、每个闰月初一；
* **农历 → 公历**：同一批对照反向换算回原公历日期；另有春节、闰月、
  1900-01-31 起点、非法输入等定点用例；
* **往返一致**：1900-01-31 ~ 2100-12-31 逐日 73384 次往返（`test/lunar_roundtrip_test.dart`）。

## 五、六爻起卦时间支持农历

官方 `DatePick`（模块 2234 + 2236/2238）本身带"公历/农历"切换
（`isShowLunar` / `isLunar` / `LeapMonth_check`），此前本工程未开启。
现在六爻"起卦时间"开启该能力：

* 弹层顶部出现 `公历 / 农历` 切换按钮；
* 农历模式下月滚轮显示 `正月…腊月`、日滚轮显示 `初一…三十`（按农历月大小）、
  时滚轮显示 `子时23:00-00:59 …`（官方折算为偶数小时），闰年出现 `闰X月` 勾选；
* 切换模式会在两种历法间换算，保证选中的是同一时刻；
* 点击"确定"时按 `lunar2solar` 换算成公历返回，排盘（四柱 / 装盘）仍以公历时间为准；
* 起卦时间字段与卦象页同时展示公历与农历（如 `2026-09-18 10:30（八月初八）`）。

## 六、复现命令

```bash
# 1. 六爻装盘对照数据（需要 sixyao-main 与 JDK）
java -cp out PanFixture test/fixtures/sixyao_pan_reference.json   # 见 tools/reverse/sixyao_pan_reference/README.md

# 2. 官方农历对照数据
node tools/reverse/extract_official_calendar.js \
  --bundle /Users/jupyter/app/ipa/yishihui/RN0615.app/main.jsbundle \
  --out /tmp/ysh_calendar

# 3. 全量校验
flutter analyze && flutter test
```
