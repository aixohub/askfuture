/**
 * 生成紫微斗数基准数据（test/fixtures/ziwei_reference.json）。
 *
 * 官方 App 的命盘由服务端 `yjhapp/ziWeiQiGua` 生成，客户端不含排盘算法
 * （模块 2430/2568/2569 只有表单与命盘渲染），因此这里用开源实现 iztro
 * （https://github.com/SylarLong/iztro，默认「中州派」配置）作为校验基准，
 * 导出农历、四柱、五行局、命主身主、十二宫星曜（含庙旺 / 四化）与
 * 长生·博士·将前·岁前四组十二神，由 `test/ziwei_test.dart` 逐宫比对。
 *
 * 用法：
 *   npm init -y && npm i iztro
 *   node tools/reverse/generate_ziwei_reference.mjs test/fixtures/ziwei_reference.json
 */
import { astro } from 'iztro';
import fs from 'fs';

const samples = [
  // [公历 'YYYY-M-D', 时辰序号 0..12, 性别, 说明]
  ['2000-8-16', 2, '女', '基准样例'],
  ['1990-1-1', 0, '男', '早子时·阳历年首'],
  ['1990-1-1', 12, '男', '晚子时'],
  ['1984-2-4', 6, '男', '甲子年·立春前后'],
  ['1985-2-20', 7, '女', '乙丑年·正月'],
  ['1986-6-15', 9, '男', '丙寅年'],
  ['1987-12-31', 11, '女', '丁卯年·亥时'],
  ['1988-3-3', 3, '男', '戊辰年·闰月前后'],
  ['1991-8-8', 5, '女', '辛未年'],
  ['1976-7-28', 4, '男', '丙辰年·闰八月'],
  ['1995-10-10', 10, '女', '乙亥年·闰八月十六'],
  ['2001-2-14', 1, '男', '辛巳年·丑时'],
  ['2010-5-20', 8, '女', '庚寅年'],
  ['2015-9-9', 6, '男', '乙未年'],
  ['2020-2-29', 4, '女', '庚子年·闰日'],
  ['2023-1-22', 0, '男', '癸卯年·春节'],
  ['2023-3-22', 12, '女', '癸卯年·晚子时'],
  ['1960-12-25', 7, '男', '庚子年·子月'],
  ['1970-6-1', 11, '女', '庚戌年'],
  ['1955-11-11', 5, '男', '乙未年'],
  ['1949-10-1', 8, '男', '己丑年'],
  ['2033-1-31', 3, '女', '癸丑年（远期历表）'],
  ['1901-2-19', 2, '男', '辛丑年（历表起始）'],
  ['2099-12-31', 9, '女', '己未年（历表结束）'],
];

const out = [];
for (const [solar, timeIndex, gender, note] of samples) {
  const astrolabe = astro.bySolar(solar, timeIndex, gender, true, 'zh-CN');
  out.push({
    note,
    input: { solar, timeIndex, gender },
    lunarDate: astrolabe.lunarDate,
    chineseDate: astrolabe.chineseDate,
    fiveElementsClass: astrolabe.fiveElementsClass,
    soul: astrolabe.soul,
    body: astrolabe.body,
    soulBranch: astrolabe.earthlyBranchOfSoulPalace,
    bodyBranch: astrolabe.earthlyBranchOfBodyPalace,
    palaces: astrolabe.palaces.map((palace) => ({
      name: palace.name,
      stem: palace.heavenlyStem,
      branch: palace.earthlyBranch,
      isBodyPalace: palace.isBodyPalace,
      major: palace.majorStars.map((star) => ({
        name: star.name,
        brightness: star.brightness,
        mutagen: star.mutagen,
      })),
      minor: palace.minorStars.map((star) => ({
        name: star.name,
        brightness: star.brightness || '',
        mutagen: star.mutagen || '',
      })),
      changsheng12: palace.changsheng12,
      boshi12: palace.boshi12,
      jiangqian12: palace.jiangqian12,
      suiqian12: palace.suiqian12,
      decadal: palace.decadal ? { range: palace.decadal.range } : null,
    })),
  });
}

const target = process.argv[2] || 'test/fixtures/ziwei_reference.json';
fs.writeFileSync(target, `${JSON.stringify(out, null, 1)}\n`);
console.log(`已生成 ${out.length} 组基准数据 → ${target}`);
