import com.aixohub.sixyao.yi.model.*;
import com.aixohub.sixyao.yi.service.impl.GuaExecServiceImpl;
import com.aixohub.sixyao.yi.service.impl.UseGodServiceImpl;
import java.io.*;
import java.nio.charset.StandardCharsets;

/**
 * 用 sixyao-main 的 GuaExecServiceImpl（六爻装盘参考实现）导出对照数据。
 *
 * 输出 JSON 数组，每条记录：
 *   { time, code, yaoValues, main:{name,desc,belong,yaos[...]}, bian:{...} }
 *
 * code 为 6 位卦码（[六爻…一爻]，1 阳 0 阴），静态卦即由该卦码直接生成；
 * 动爻记录在静态卦码基础上把指定爻改为老阳（3）/老阴（2）。
 */
public class PanFixture {
    static String esc(String s) {
        return s == null ? "null" : "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"") + "\"";
    }

    static String yaoJson(YaoLineDetailInfo y) {
        if (y == null) return "null";
        return "{" + "\"liuShen\":" + esc(y.getSixGodBeast())
                + ",\"fuShen\":" + esc(y.getFuShen())
                + ",\"liuQin\":" + esc(y.getSixQinInfo())
                + ",\"zhi\":" + esc(y.getBranchInfo())
                + ",\"wuXing\":" + esc(y.getBranchFiveProperty())
                + ",\"launch\":" + esc(y.getLaunch())
                + ",\"shiYing\":" + esc(y.getShiYing()) + "}";
    }

    static String guaJson(YaoLineInfo g) {
        YaoLineDetailInfo[] ys = {g.getOneYao(), g.getTwoYao(), g.getThreeYao(),
                g.getFourYao(), g.getFiveYao(), g.getSixYao()};
        StringBuilder sb = new StringBuilder();
        sb.append("{\"name\":").append(esc(g.getName()))
                .append(",\"desc\":").append(esc(g.getDesc()))
                .append(",\"belong\":").append(esc(g.getBelong()))
                .append(",\"yaos\":[");
        for (int i = 0; i < 6; i++) {
            if (i > 0) sb.append(",");
            sb.append(yaoJson(ys[i]));
        }
        sb.append("]}");
        return sb.toString();
    }

    /** 由卦码（[六爻…一爻]）与动爻（1 初爻 … 6 上爻，0 表示不动）生成六爻输入。 */
    static String[] codesToYaos(String code, int movingPos) {
        String[] out = new String[6];
        for (int i = 0; i < 6; i++) {
            boolean yang = code.charAt(5 - i) == '1'; // i = 0 为初爻
            boolean moving = movingPos == i + 1;
            if (!moving) {
                out[i] = yang ? "1" : "0";
            } else {
                out[i] = yang ? "3" : "2"; // 老阳 / 老阴
            }
        }
        return out;
    }

    static String caseJson(int[] t, String code, int movingPos) {
        YaoRequest req = new YaoRequest();
        req.setYearNum(String.valueOf(t[0]));
        req.setMonthNum(String.valueOf(t[1]));
        req.setDayNum(String.valueOf(t[2]));
        req.setHourNum(String.valueOf(t[3]));
        req.setMinuteNum(String.valueOf(t[4]));
        String[] ys = codesToYaos(code, movingPos);
        req.setOneYao(ys[0]); req.setTwoYao(ys[1]); req.setThreeYao(ys[2]);
        req.setFourYao(ys[3]); req.setFiveYao(ys[4]); req.setSixYao(ys[5]);
        GuaExecServiceImpl svc = new GuaExecServiceImpl(new UseGodServiceImpl());
        YaoGuaInfo info = svc.queryGua(req);
        StringBuilder sb = new StringBuilder();
        sb.append("  {\"time\":\"")
                .append(String.format("%04d-%02d-%02d %02d:%02d", t[0], t[1], t[2], t[3], t[4]))
                .append("\",\"code\":").append(esc(code))
                .append(",\"movingPos\":").append(movingPos)
                .append(",\"yaos\":[");
        for (int i = 0; i < 6; i++) {
            if (i > 0) sb.append(",");
            sb.append(esc(ys[i]));
        }
        sb.append("]")
                .append(",\"main\":").append(guaJson(info.getMain()))
                .append(",\"bian\":").append(guaJson(info.getBian()))
                .append("}");
        return sb.toString();
    }

    public static void main(String[] args) throws Exception {
        int[][] staticTimes = {{2026, 9, 18, 10, 30}, {2000, 1, 1, 0, 30}, {1990, 6, 15, 6, 20}};
        int[] movingTime = {2024, 2, 10, 0, 30};
        StringBuilder out = new StringBuilder("[\n");
        boolean first = true;
        int count = 0;
        for (int i = 0; i < 64; i++) {
            String code = String.format("%6s", Integer.toBinaryString(i)).replace(' ', '0');
            for (int[] t : staticTimes) {
                if (!first) out.append(",\n");
                first = false;
                out.append(caseJson(t, code, 0));
                count++;
            }
            // 初爻动 / 上爻动 两组变卦样本
            for (int movingPos : new int[]{1, 6}) {
                if (!first) out.append(",\n");
                first = false;
                out.append(caseJson(movingTime, code, movingPos));
                count++;
            }
        }
        out.append("\n]\n");
        String target = args.length > 0 ? args[0] : "/tmp/sixyao_ref/pan_fixture.json";
        try (Writer w = new OutputStreamWriter(new FileOutputStream(target), StandardCharsets.UTF_8)) {
            w.write(out.toString());
        }
        System.out.println("records=" + count + " bytes=" + out.length());
    }
}
