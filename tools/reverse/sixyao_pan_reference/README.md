# 六爻装盘对照数据（sixyao-main）

`test/fixtures/sixyao_pan_reference.json` 是**参考实现直接运行导出**的六爻装盘结果，
用于逐字段校验本工程的 `lib/models/liuyao.dart`（纳甲 / 六亲 / 六神 / 世应 / 伏神 /
宫内八名 / 世应关系 / 本卦·变卦）。

参考工程：`/Users/jupyter/Downloads/tradeview/sixyao-main`
（`com.aixohub.sixyao.yi.service.impl.GuaExecServiceImpl.queryGua`）。

## 数据内容

共 320 条记录：

* 64 卦 × 3 个起卦时刻（2026-09-18 10:30 / 2000-01-01 00:30 / 1990-06-15 06:20，静卦）
* 64 卦 × {初爻动、上爻动}（2024-02-10 00:30，含变卦）

每条记录包含 `main`（本卦）与 `bian`（变卦）的卦名、卦宫 + 宫内八名、世应关系，
以及六爻的六神 / 伏神 / 六亲 / 纳甲地支 / 五行 / 世应 / 动爻。

## 重新生成

参考工程依赖 Spring / Lombok 注解，脚本用最小桩件编译（只为跑通
`GuaExecServiceImpl` 的装盘链路，不启动 Spring 容器）：

```bash
REF=/Users/jupyter/Downloads/tradeview/sixyao-main/src/main/java
mkdir -p /tmp/sixyao_ref/{stubs,out} && cd /tmp/sixyao_ref

# 1. 桩件：@Service / @Resource / BeanUtils / StringUtils / slf4j / Jackson / lombok
#    （见下方"桩件"说明，任选等价实现即可）
# 2. 复制参考源码并补上 lombok @Data 的等价 getter/setter（YaoCalcInfo）
cp -R "$REF" /tmp/sixyao_ref/src
#    把 src/.../yi/model/YaoCalcInfo.java 改为显式 getter/setter

# 3. 编译 + 导出
SRC=/tmp/sixyao_ref/src
javac -encoding UTF-8 -d out \
  $(find $SRC/com/aixohub/sixyao/tools $SRC/com/aixohub/sixyao/yi/enums \
        $SRC/com/aixohub/sixyao/yi/model $SRC/com/aixohub/sixyao/yi/utils \
        $SRC/com/aixohub/sixyao/yi/service -name '*.java') \
  $(find /tmp/sixyao_ref/stubs -name '*.java') PanFixture.java
java -Dstdout.encoding=UTF-8 -cp out PanFixture \
  /Users/jupyter/work/code/flutter/divination/test/fixtures/sixyao_pan_reference.json
```

### 桩件

`stubs/` 下需要以下最小实现（只为编译通过）：

| 桩件 | 说明 |
| --- | --- |
| `org.springframework.stereotype.Service` | 空注解 |
| `javax.annotation.Resource` | 空注解 |
| `org.springframework.beans.BeanUtils.copyProperties` | 反射拷贝同名属性 |
| `org.springframework.util.StringUtils.hasLength` | `s != null && !s.isEmpty()` |
| `org.slf4j.Logger` / `LoggerFactory` | `info()` 空实现 |
| `com.fasterxml.jackson.databind.ObjectMapper` | 返回 `"{}"`（仅日志用） |
| `lombok.Data` | 空注解（`YaoCalcInfo` 需手写 getter/setter） |

## 校验

```bash
flutter test test/sixyao_pan_reference_test.dart
```
