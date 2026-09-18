#!/usr/bin/env node
/**
 * 从官方 RN bundle 中导出「干支历」所需的精确数据。
 *
 * 官方模块：
 *   * 2111 GanZhi / Sizhu / Calendar  —— 干支取法
 *   * 2112 SolarTerm / SolarDay       —— 精确节气（含时刻）与四柱
 *   * 1898 calendar                   —— 标准农历表 solar2lunar / lunarInfo
 *
 * 用法：
 *   node tools/reverse/extract_official_calendar.js \
 *        --bundle /Users/jupyter/app/ipa/yishihui/RN0615.app/main.jsbundle \
 *        --out /tmp/ysh_calendar
 *
 * 产物：
 *   jieqi_1901_2099.dart   精确节气表 Dart 源码（可直接拷入 lib/models/）
 *   vectors.json           官方四柱 / 农历 / 节气对照向量（用于单元测试）
 */

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const moduleCache = new Map();

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {};
  for (let i = 0; i < args.length; i += 2) {
    out[args[i].replace(/^--/, '')] = args[i + 1];
  }
  return out;
}

/** 把 bundle 解码为可切分的源码。 */
function decodeBundle(raw) {
  return raw
    .replace(/\\u([0-9a-fA-F]{4})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)))
    .replace(/[\uD800-\uDFFF]/g, '');
}

/** 按 __d(function(...){...},ID,[deps]) 切分模块。 */
function splitModules(source) {
  const starts = [];
  const re = /__d\(function\(/g;
  let m;
  while ((m = re.exec(source)) !== null) starts.push(m.index);
  const modules = new Map();
  for (let i = 0; i < starts.length; i++) {
    const seg = source.slice(starts[i], i + 1 < starts.length ? starts[i + 1] : source.length);
    const idMatch = /\},\s*(\d+)\s*,\s*\[([0-9,]*)\]/.exec(seg);
    if (idMatch) modules.set(Number(idMatch[1]), seg);
  }
  return modules;
}

/** 以极小的 CommonJS 规则执行官方模块。 */
function runModules(sources, wanted) {
  const sandbox = {
    console,
    Math,
    Date,
    JSON,
    Object,
    Array,
    String,
    Number,
    Boolean,
    RegExp,
    Error,
    isNaN,
    parseInt,
    parseFloat,
    setTimeout,
    clearTimeout,
  };
  sandbox.global = sandbox;
  sandbox.globalThis = sandbox;
  sandbox.__d = (fn, id, deps) => {
    moduleCache.set(id, { fn, deps });
  };
  sandbox.req = (id) => {
    if (moduleCache.has('@' + id)) return moduleCache.get('@' + id);
    const mod = moduleCache.get(id);
    if (!mod) throw new Error('missing module ' + id);
    const exports = {};
    moduleCache.set('@' + id, exports);
    mod.fn(sandbox, sandbox.req, null, null, exports, exports, mod.deps);
    return exports;
  };
  vm.createContext(sandbox);
  const ordered = [...sources.keys()];
  for (const id of ordered) {
    if (!wanted.includes(id)) continue;
    vm.runInContext(sources.get(id), sandbox, { filename: `module_${id}.js` });
  }
  return sandbox.req;
}

function pad(n, width = 2) {
  return String(n).padStart(width, '0');
}

/** 本地墙钟时间戳（YYYYMMDDHHmm），用于按当地年份归类与去重。 */
function localStamp(date) {
  const d = new Date(date);
  return (
    d.getFullYear() * 100000000 +
    (d.getMonth() + 1) * 1000000 +
    d.getDate() * 10000 +
    d.getHours() * 100 +
    d.getMinutes()
  );
}

/** 官方 24 节气名（模块 2112 jqB 顺序：小寒 … 冬至）。 */
const JQ_NAMES = [
  '小寒', '大寒', '立春', '雨水', '惊蛰', '春分',
  '清明', '谷雨', '立夏', '小满', '芒种', '夏至',
  '小暑', '大暑', '立秋', '处暑', '白露', '秋分',
  '寒露', '霜降', '立冬', '小雪', '大雪', '冬至',
];

function main() {
  const args = parseArgs();
  const bundlePath = args.bundle;
  const outDir = args.out || '/tmp/ysh_calendar';
  if (!bundlePath) {
    console.error('usage: node extract_official_calendar.js --bundle <main.jsbundle> [--out dir]');
    process.exit(1);
  }
  fs.mkdirSync(outDir, { recursive: true });

  const bundle = decodeBundle(fs.readFileSync(bundlePath, 'utf8'));
  const modules = splitModules(bundle);
  const req = runModules(modules, [2111, 2112, 1898]);

  const { SolarTerm } = req(2112);
  const calendar = req(1898).calendar;
  const term = new SolarTerm();

  // ---- 1. 精确节气表：每年 24 个节气（含时刻） ----
  const START_YEAR = 1901;
  const END_YEAR = 2099;
  const yearEntries = [];
  for (let year = START_YEAR; year <= END_YEAR; year++) {
    const events = new Map();
    const probes = [];
    for (let month = 1; month <= 12; month++) {
      probes.push([month, 6], [month, 21]);
    }
    for (const [month, day] of probes) {
      const sizhu = term.getSizhu(year, month, day, 12, 0, 0, false);
      const collect = (name, date) => {
        if (!name || !date) return;
        const d = new Date(date);
        // 官方引擎在相邻年份边界处会返回毫秒级重复值，按"当地年份 + 分钟"归并
        if (d.getFullYear() !== year) return;
        const key = `${name}@${localStamp(d)}`;
        if (!events.has(key)) events.set(key, { name, date: d });
      };
      collect(sizhu.prevJq && sizhu.prevJq.name, sizhu.prevJq && sizhu.prevJq.date);
      collect(sizhu.zqName, sizhu.zqDate);
      collect(sizhu.nextJq && sizhu.nextJq.name, sizhu.nextJq && sizhu.nextJq.date);
    }
    const list = [...events.values()].sort((a, b) => a.date - b.date);
    if (list.length !== 24) {
      console.error(`!! ${year} 节气数量异常: ${list.length}`);
    }
    yearEntries.push([year, list]);
  }

  // 校验顺序与官方 24 节气名一致
  const orderOk = yearEntries.every(
    ([, list]) => list.length === 24 && list.every((e, i) => e.name === JQ_NAMES[i]),
  );
  console.log('节气顺序校验:', orderOk ? 'OK' : 'FAIL');

  // 生成 Dart：每年 24 个 "MMddHHmm"（本地时区墙钟时间）
  const dartRows = yearEntries.map(([year, list]) => {
    const codes = list.map((e) => {
      const d = e.date;
      return (
        pad(d.getMonth() + 1) +
        pad(d.getDate()) +
        pad(d.getHours()) +
        pad(d.getMinutes()) +
        pad(d.getSeconds())
      );
    });
    return `  ${year}: '${codes.join(',')}',`;
  });
  const dartFile = [
    '/// 官方精确节气表（1901–2099），数据由 tools/reverse/extract_official_calendar.js 从',
    '/// 官方 RN bundle 模块 2112（SolarTerm）导出，键为公历年，值为 24 个节气的',
    '/// `MMddHHmmss`（本地墙钟时间）。官方引擎的毫秒为进程噪声，故只保留到秒。',
    '/// 顺序与官方 jqB 一致：',
    '/// 小寒 大寒 立春 雨水 惊蛰 春分 清明 谷雨 立夏 小满 芒种 夏至',
    '/// 小暑 大暑 立秋 处暑 白露 秋分 寒露 霜降 立冬 小雪 大雪 冬至',
    'library;',
    '',
    'const Map<int, String> kJieQiTable = <int, String>{',
    ...dartRows,
    '};',
    '',
  ].join('\n');
  fs.writeFileSync(path.join(outDir, 'jieqi_1901_2099.dart'), dartFile, 'utf8');

  // ---- 2. 对照向量（四柱 / 农历 / 节气） ----
  const sampleDates = [
    [2026, 9, 17, 19, 16],
    [2026, 9, 7, 22, 41],
    [2026, 2, 4, 4, 2],
    [2024, 2, 10, 0, 30],
    [2024, 2, 4, 16, 27],
    [2023, 12, 22, 11, 27],
    [2000, 1, 1, 0, 0],
    [1990, 6, 15, 23, 30],
    [1984, 2, 2, 12, 0],
    [1970, 10, 1, 8, 5],
  ];
  const vectors = [];
  for (const [y, m, d, h, mi] of sampleDates) {
    const sizhu = term.getSizhu(y, m, d, h, mi, 0, false);
    const lunar = calendar.solar2lunar(y, m, d);
    const local = (date) => {
      const dt = new Date(date);
      return `${dt.getFullYear()}-${pad(dt.getMonth() + 1)}-${pad(dt.getDate())} ` +
        `${pad(dt.getHours())}:${pad(dt.getMinutes())}`;
    };
    vectors.push({
      date: `${y}-${pad(m)}-${pad(d)} ${pad(h)}:${pad(mi)}`,
      sizhu: `${sizhu.year.gan}${sizhu.year.zhi} ${sizhu.month.gan}${sizhu.month.zhi} ` +
        `${sizhu.day.gan}${sizhu.day.zhi} ${sizhu.hour.gan}${sizhu.hour.zhi}`,
      animal: sizhu.Animal,
      prevJq: { name: sizhu.prevJq.name, date: local(sizhu.prevJq.date) },
      zq: { name: sizhu.zqName, date: local(sizhu.zqDate) },
      nextJq: { name: sizhu.nextJq.name, date: local(sizhu.nextJq.date) },
      lunar: lunar
        ? {
            year: lunar.lYear,
            month: lunar.lMonth,
            day: lunar.lDay,
            isLeap: lunar.isLeap,
            text: `${lunar.lMonth}月${calendar.toChinaDay(lunar.lDay)}`,
            monthCn: calendar.toChinaMonth(lunar.lMonth),
            dayCn: calendar.toChinaDay(lunar.lDay),
          }
        : null,
    });
  }
  fs.writeFileSync(path.join(outDir, 'vectors.json'), JSON.stringify(vectors, null, 2), 'utf8');

  // ---- 3. 农历换算对照表：公历 → 农历（官方模块 1898 solar2lunar） ----
  //
  // 覆盖：
  //   * 2023-01-01 ~ 2026-12-31 逐日（含 2023 闰二月、2025 闰六月）
  //   * 1900–2100 每年春节（正月初一）与每个闰月的初一
  const lunarRows = [];
  const pushLunar = (y, m, d) => {
    const lunar = calendar.solar2lunar(y, m, d);
    if (!lunar) return;
    lunarRows.push({
      y,
      m,
      d,
      ly: lunar.lYear,
      lm: lunar.lMonth,
      ld: lunar.lDay,
      leap: !!lunar.isLeap,
      text: `${calendar.toChinaMonth(lunar.lMonth)}${calendar.toChinaDay(lunar.lDay)}`,
    });
  };
  for (let y = 2023; y <= 2026; y++) {
    for (let m = 1; m <= 12; m++) {
      const dim = new Date(y, m, 0).getDate();
      for (let d = 1; d <= dim; d++) pushLunar(y, m, d);
    }
  }
  for (let y = 1900; y <= 2100; y++) {
    for (let m = 1; m <= 12; m++) {
      const dim = new Date(y, m, 0).getDate();
      for (let d = 1; d <= dim; d++) {
        const lunar = calendar.solar2lunar(y, m, d);
        if (!lunar) continue;
        if (
          (lunar.lDay === 1 && lunar.lMonth === 1 && !lunar.isLeap) ||
          (lunar.lDay === 1 && lunar.isLeap)
        ) {
          pushLunar(y, m, d);
        }
      }
    }
  }
  fs.writeFileSync(
    path.join(outDir, 'lunar_reference.json'),
    JSON.stringify(lunarRows),
    'utf8',
  );
  console.log(`农历对照：${lunarRows.length} 条`);

  // ---- 4. 农历表（lunarInfo）导出，便于 Dart 端 1:1 移植 ----
  const lunarInfo = calendar.lunarInfo;
  fs.writeFileSync(
    path.join(outDir, 'lunar_info.json'),
    JSON.stringify(lunarInfo, null, 0),
    'utf8',
  );

  console.log(`节气表已导出：${START_YEAR}-${END_YEAR}，共 ${yearEntries.length} 年`);
  console.log(`对照向量：${vectors.length} 条`);
  console.log(`农历表长度：${lunarInfo.length}`);
  console.log('样例：', JSON.stringify(vectors[0], null, 2));
}

main();
