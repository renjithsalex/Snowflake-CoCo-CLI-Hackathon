import pandas as pd
import altair as alt
import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="OEE Command Center", page_icon="\U0001f3ed", layout="wide")

session = get_active_session()

# =============================================================================
# Theme / CSS
# =============================================================================
st.markdown("""
<style>
.block-container {padding-top: 1.2rem;}
[data-testid="stSidebar"] {background: linear-gradient(180deg,#0f172a 0%,#1e293b 100%);}
[data-testid="stSidebar"] * {color: #e2e8f0 !important;}
.hero {background: linear-gradient(90deg,#0ea5e9 0%,#6366f1 100%);
       border-radius: 14px; padding: 18px 24px; color: white; margin-bottom: 18px;}
.hero h1 {font-size: 26px; margin: 0; color: white;}
.hero p {margin: 4px 0 0 0; opacity: .9; font-size: 13px;}
.kpi {background: white; border-radius: 12px; padding: 16px 18px;
      border: 1px solid #e5e7eb; box-shadow: 0 1px 3px rgba(0,0,0,.06); height: 100%;}
.kpi .lbl {font-size: 11px; text-transform: uppercase; letter-spacing: .06em;
           color: #64748b; font-weight: 600;}
.kpi .val {font-size: 28px; font-weight: 800; margin-top: 4px; color: #0f172a;}
.kpi .sub {font-size: 12px; color: #94a3b8; margin-top: 2px;}
.kpi.red {border-left: 5px solid #ef4444;}
.kpi.amber {border-left: 5px solid #f59e0b;}
.kpi.blue {border-left: 5px solid #3b82f6;}
.kpi.green {border-left: 5px solid #22c55e;}
.kpi.cyan {border-left: 5px solid #06b6d4;}
.kpi.violet {border-left: 5px solid #8b5cf6;}
.badge {padding: 2px 10px; border-radius: 999px; font-size: 11px; font-weight: 700;}
.b-CRITICAL {background:#fee2e2;color:#b91c1c;}
.b-WARNING {background:#fef3c7;color:#b45309;}
.b-WATCH {background:#dbeafe;color:#1d4ed8;}
.b-HEALTHY {background:#dcfce7;color:#15803d;}
.b-INFO {background:#e0f2fe;color:#0369a1;}
.alert-card {background:white;border:1px solid #e5e7eb;border-radius:10px;
             padding:10px 14px;margin-bottom:8px;}
.alert-card .t {font-size:11px;color:#94a3b8;}
.section {font-size: 15px; font-weight: 700; color: #0f172a; margin: 6px 0 8px 0;}
.asset-tile {border-radius:10px;padding:8px;text-align:center;font-size:11px;
             font-weight:700;color:white;margin-bottom:6px;}
</style>
""", unsafe_allow_html=True)

COLORS = {
    "CRITICAL": "#ef4444",
    "WARNING": "#f59e0b",
    "WATCH": "#3b82f6",
    "HEALTHY": "#22c55e",
}


def kpi(col, label, value, sub="", tone="cyan"):
    col.markdown(
        f'<div class="kpi {tone}"><div class="lbl">{label}</div>'
        f'<div class="val">{value}</div><div class="sub">{sub}</div></div>',
        unsafe_allow_html=True,
    )


def hero(title, subtitle):
    st.markdown(
        f'<div class="hero"><h1>{title}</h1><p>{subtitle}</p></div>',
        unsafe_allow_html=True,
    )


def badge(s):
    return f'<span class="badge b-{s}">{s}</span>'


def pct(v):
    return "\u2014" if pd.isna(v) else f"{v:.1%}"


# =============================================================================
# Data loaders
# =============================================================================
def q(sql):
    return session.sql(sql).to_pandas()


@st.cache_data(ttl=120)
def load_oee_plant():
    return q("SELECT * FROM MFG_PDM_DB.CURATED.DT_OEE_PLANT_DAILY ORDER BY SHIFT_DATE")


@st.cache_data(ttl=120)
def load_oee_line():
    return q("SELECT * FROM MFG_PDM_DB.CURATED.DT_OEE_LINE_DAILY ORDER BY SHIFT_DATE")


@st.cache_data(ttl=60)
def load_health():
    return q("SELECT * FROM MFG_PDM_DB.CURATED.DT_ASSET_HEALTH ORDER BY HEALTH_SCORE ASC")


@st.cache_data(ttl=120)
def load_360():
    return q("SELECT * FROM MFG_PDM_DB.CURATED.DT_ASSET_360 ORDER BY DOWNTIME_COST_30D DESC")


@st.cache_data(ttl=120)
def load_downtime():
    return q("SELECT * FROM MFG_PDM_DB.CURATED.DT_DOWNTIME_PARETO ORDER BY DOWNTIME_MIN DESC")


@st.cache_data(ttl=60)
def load_anomalies():
    return q("SELECT * FROM MFG_PDM_DB.ML.ANOMALY_SCORES ORDER BY TS")


@st.cache_data(ttl=60)
def load_alerts():
    return q("SELECT * FROM MFG_PDM_DB.OPS.ALERT_HISTORY ORDER BY ALERT_TS DESC LIMIT 200")


@st.cache_data(ttl=60)
def load_wo():
    return q("SELECT * FROM MFG_PDM_DB.OPS.WORK_ORDER_DRAFTS ORDER BY CREATED_AT DESC")


@st.cache_data(ttl=300)
def load_sensor_trend(asset_id):
    return session.sql(
        """SELECT WINDOW_START, AVG_VIBRATION, AVG_TEMPERATURE,
                  MAX_VIBRATION_MM_S, MAX_TEMP_C
           FROM MFG_PDM_DB.CURATED.DT_SENSOR_FEATURES_15M
           WHERE ASSET_ID = ?
             AND WINDOW_START >= DATEADD('day', -7, CURRENT_TIMESTAMP())
           ORDER BY WINDOW_START""",
        params=[asset_id],
    ).to_pandas()


# =============================================================================
# Sidebar
# =============================================================================
with st.sidebar:
    st.markdown("## \U0001f3ed OEE Command Center")
    st.caption("Predictive Maintenance \u00b7 Snowflake")

    page = st.radio(
        "Navigate",
        [
            "\U0001f4ca Executive Overview",
            "\U0001f493 Asset Health",
            "\u23f1 Downtime Analysis",
            "\U0001f50d Asset 360",
            "\u26a1 Anomaly Monitor",
            "\U0001f6a8 Alerts & Work Orders",
            "\U0001f916 AI Assistant",
        ],
        label_visibility="collapsed",
    )

    st.markdown("---")
    plants_df = load_oee_plant()
    plant_opts = ["All plants"] + sorted(plants_df["PLANT_NAME"].dropna().unique().tolist())
    plant_sel = st.selectbox("Plant filter", plant_opts)
    days = st.slider("Trend window (days)", 7, 90, 30)

    if st.button("\U0001f504 Refresh data"):
        st.cache_data.clear()

    st.markdown("---")
    st.caption("Data refreshes every 1\u20132 min from Dynamic Tables. ML scoring runs every 15 min.")


def plant_filter(df, col="PLANT_NAME"):
    if plant_sel == "All plants" or col not in df.columns:
        return df
    return df[df[col] == plant_sel]


# =============================================================================
# 1. Executive Overview
# =============================================================================
if page.endswith("Executive Overview"):
    hero("Executive Overview", "Plant performance, asset risk and open issues at a glance")

    p = plant_filter(load_oee_plant())
    lines = plant_filter(load_oee_line())
    health = load_health()
    alerts = load_alerts()

    if p.empty:
        st.info("No OEE plant data available yet. Data will appear once the Dynamic Tables refresh.")
        st.stop()

    p["SHIFT_DATE"] = pd.to_datetime(p["SHIFT_DATE"])
    dates = sorted(p["SHIFT_DATE"].unique())
    latest_d = dates[-1]
    prev_d = dates[-2] if len(dates) > 1 else latest_d

    cur = p[p["SHIFT_DATE"] == latest_d]
    prv = p[p["SHIFT_DATE"] == prev_d]

    def delta(k):
        c_mean = cur[k].mean()
        p_mean = prv[k].mean()
        if pd.isna(c_mean) or pd.isna(p_mean):
            return ""
        d = c_mean - p_mean
        arrow = "\u25b2" if d >= 0 else "\u25bc"
        return f"{arrow} {abs(d):.1%} vs prior day"

    c = st.columns(6)
    kpi(c[0], "OEE", pct(cur["OEE"].mean()), delta("OEE"), "cyan")
    kpi(c[1], "Availability", pct(cur["AVAILABILITY"].mean()), delta("AVAILABILITY"), "green")
    kpi(c[2], "Performance", pct(cur["PERFORMANCE"].mean()), delta("PERFORMANCE"), "amber")
    kpi(c[3], "Quality", pct(cur["QUALITY"].mean()), delta("QUALITY"), "violet")

    at_risk = int(health["RULE_STATUS"].isin(["CRITICAL", "WARNING"]).sum())
    kpi(c[4], "Assets at Risk", at_risk, f"of {len(health)} monitored",
        "red" if at_risk else "green")

    crit_alerts = int((alerts["SEVERITY"] == "CRITICAL").sum()) if not alerts.empty else 0
    kpi(c[5], "Critical Alerts", crit_alerts, f"{len(alerts)} total alerts",
        "red" if crit_alerts else "green")

    st.write("")
    left, right = st.columns([2, 1])

    with left:
        st.markdown('<div class="section">OEE trend by plant</div>', unsafe_allow_html=True)
        trend = p[p["SHIFT_DATE"] >= latest_d - pd.Timedelta(days=days)]
        chart = (
            alt.Chart(trend)
            .mark_line(point=False, strokeWidth=2.5)
            .encode(
                x=alt.X("SHIFT_DATE:T", title=None),
                y=alt.Y("OEE:Q", title="OEE", axis=alt.Axis(format="%"),
                         scale=alt.Scale(zero=False)),
                color=alt.Color("PLANT_NAME:N", title="Plant"),
                tooltip=[
                    "PLANT_NAME",
                    alt.Tooltip("SHIFT_DATE:T"),
                    alt.Tooltip("OEE:Q", format=".1%"),
                ],
            )
            .properties(height=300)
        )
        target = (
            alt.Chart(pd.DataFrame({"y": [0.85]}))
            .mark_rule(strokeDash=[6, 4], color="#ef4444")
            .encode(y="y:Q")
        )
        st.altair_chart(chart + target, use_container_width=True)
        st.caption("Red dashed line = 85% world-class OEE target")

    with right:
        st.markdown('<div class="section">Fleet health mix</div>', unsafe_allow_html=True)
        mix = health["RULE_STATUS"].value_counts().reset_index()
        mix.columns = ["STATUS", "COUNT"]
        donut = (
            alt.Chart(mix)
            .mark_arc(innerRadius=60)
            .encode(
                theta="COUNT:Q",
                color=alt.Color(
                    "STATUS:N",
                    scale=alt.Scale(domain=list(COLORS), range=list(COLORS.values())),
                ),
                tooltip=["STATUS", "COUNT"],
            )
            .properties(height=300)
        )
        st.altair_chart(donut, use_container_width=True)

    l2, r2 = st.columns([2, 1])

    with l2:
        st.markdown(
            '<div class="section">OEE loss breakdown by line (latest day)</div>',
            unsafe_allow_html=True,
        )
        lines["SHIFT_DATE"] = pd.to_datetime(lines["SHIFT_DATE"])
        if not lines.empty:
            ll = lines[lines["SHIFT_DATE"] == lines["SHIFT_DATE"].max()]
            melted = ll.melt(
                id_vars=["LINE_NAME"],
                value_vars=["AVAILABILITY", "PERFORMANCE", "QUALITY", "OEE"],
                var_name="METRIC",
                value_name="VALUE",
            )
            base = alt.Chart(melted).encode(
                x=alt.X(
                    "METRIC:N",
                    title=None,
                    sort=["AVAILABILITY", "PERFORMANCE", "QUALITY", "OEE"],
                ),
                y=alt.Y("LINE_NAME:N", title=None),
            )
            heat = base.mark_rect().encode(
                color=alt.Color(
                    "VALUE:Q",
                    scale=alt.Scale(scheme="redyellowgreen", domain=[0.6, 1.0]),
                    legend=None,
                ),
                tooltip=[
                    "LINE_NAME",
                    "METRIC",
                    alt.Tooltip("VALUE:Q", format=".1%"),
                ],
            )
            labels = base.mark_text(fontWeight="bold").encode(
                text=alt.Text("VALUE:Q", format=".0%")
            )
            st.altair_chart(
                (heat + labels).properties(height=280), use_container_width=True
            )
        else:
            st.info("No line-level OEE data available yet.")

    with r2:
        st.markdown('<div class="section">Latest alerts</div>', unsafe_allow_html=True)
        if alerts.empty:
            st.success("No active alerts")
        else:
            for _, a in alerts.head(6).iterrows():
                st.markdown(
                    f'<div class="alert-card">{badge(a["SEVERITY"])} '
                    f'<b>{a["ASSET_ID"]}</b> \u00b7 {a["ALERT_TYPE"]}'
                    f'<div class="t">{a["ALERT_TS"]}</div>'
                    f'<div style="font-size:12px">{a["MESSAGE"]}</div></div>',
                    unsafe_allow_html=True,
                )

# =============================================================================
# 2. Asset Health
# =============================================================================
elif page.endswith("Asset Health"):
    hero("Asset Health Monitor",
         "Rule thresholds + ML failure probability + remaining useful life")

    h = load_health()

    if h.empty:
        st.info("No asset health data available yet.")
        st.stop()

    c = st.columns(4)
    for col, s, tone in zip(
        c, ["CRITICAL", "WARNING", "WATCH", "HEALTHY"],
        ["red", "amber", "blue", "green"],
    ):
        kpi(col, s.title(), int((h["RULE_STATUS"] == s).sum()), "assets", tone)

    st.write("")

    f1, f2, f3 = st.columns(3)
    status_f = f1.multiselect("Status", list(COLORS), default=list(COLORS))
    type_f = f2.multiselect(
        "Asset type",
        sorted(h["ASSET_TYPE"].unique()),
        default=sorted(h["ASSET_TYPE"].unique()),
    )
    crit_f = f3.multiselect(
        "Criticality",
        sorted(h["CRITICALITY"].unique()),
        default=sorted(h["CRITICALITY"].unique()),
    )

    fh = h[
        h["RULE_STATUS"].isin(status_f)
        & h["ASSET_TYPE"].isin(type_f)
        & h["CRITICALITY"].isin(crit_f)
    ]

    tab_map, tab_risk, tab_table = st.tabs(
        ["\U0001f5fa Fleet heat-map", "\U0001f3af Risk matrix", "\U0001f4cb Detail table"]
    )

    with tab_map:
        st.caption(
            "Each tile is one asset, colored by status. Hover the risk matrix for details."
        )
        per_row = 10
        rows = [fh.iloc[i : i + per_row] for i in range(0, len(fh), per_row)]
        for chunk in rows:
            cols = st.columns(per_row)
            for col, (_, r) in zip(cols, chunk.iterrows()):
                col.markdown(
                    f'<div class="asset-tile" '
                    f'style="background:{COLORS.get(r["RULE_STATUS"], "#94a3b8")}">'
                    f'{r["ASSET_ID"]}<br>'
                    f'<span style="font-weight:400">{r["HEALTH_SCORE"]:.0f}</span></div>',
                    unsafe_allow_html=True,
                )

    with tab_risk:
        scatter = (
            alt.Chart(fh)
            .mark_circle(opacity=0.85, stroke="white")
            .encode(
                x=alt.X("VIB_PCT_OF_LIMIT:Q", title="Vibration % of limit",
                         axis=alt.Axis(format="%")),
                y=alt.Y("FAILURE_PROB:Q", title="Failure probability (24h)",
                         axis=alt.Axis(format="%")),
                size=alt.Size("HOURLY_DOWNTIME_COST_USD:Q", title="Downtime $/hr",
                              scale=alt.Scale(range=[60, 600])),
                color=alt.Color(
                    "RULE_STATUS:N",
                    scale=alt.Scale(domain=list(COLORS), range=list(COLORS.values())),
                ),
                tooltip=[
                    "ASSET_ID", "ASSET_TYPE", "RULE_STATUS",
                    alt.Tooltip("VIB_PCT_OF_LIMIT:Q", format=".1%"),
                    alt.Tooltip("FAILURE_PROB:Q", format=".1%"),
                    alt.Tooltip("RUL_HOURS:Q", format=",.0f"),
                    "HOURLY_DOWNTIME_COST_USD",
                ],
            )
            .properties(height=420)
            .interactive()
        )
        st.altair_chart(scatter, use_container_width=True)
        st.caption("Top-right = highest priority. Bubble size = cost of downtime per hour.")

    with tab_table:
        show = fh[
            [
                "ASSET_ID", "ASSET_TYPE", "CRITICALITY", "RULE_STATUS",
                "HEALTH_SCORE", "AVG_VIBRATION", "VIB_PCT_OF_LIMIT",
                "AVG_TEMPERATURE", "TEMP_PCT_OF_LIMIT", "FAILURE_PROB", "RUL_HOURS",
            ]
        ].copy()
        st.dataframe(
            show.style.format(
                {
                    "HEALTH_SCORE": "{:.1f}",
                    "AVG_VIBRATION": "{:.2f}",
                    "AVG_TEMPERATURE": "{:.1f}",
                    "VIB_PCT_OF_LIMIT": "{:.1%}",
                    "TEMP_PCT_OF_LIMIT": "{:.1%}",
                    "FAILURE_PROB": "{:.1%}",
                    "RUL_HOURS": "{:,.0f}",
                },
                na_rep="\u2014",
            ),
            use_container_width=True,
            height=460,
        )
        st.download_button(
            "\u2b07 Download CSV", show.to_csv(index=False),
            "asset_health.csv", "text/csv",
        )

# =============================================================================
# 3. Downtime
# =============================================================================
elif page.endswith("Downtime Analysis"):
    hero("Downtime Pareto Analysis",
         "Where are we losing time \u2014 and what should we fix first?")

    d = load_downtime()

    if d.empty:
        st.info("No downtime data available yet. Data will appear once the Dynamic Tables refresh.")
        st.stop()

    unpl = d[~d["IS_PLANNED"]]

    c = st.columns(4)
    total_dt = d["DOWNTIME_HOURS"].sum()
    kpi(c[0], "Total downtime", f"{total_dt:,.0f} h", "last 30 days", "blue")
    kpi(
        c[1], "Unplanned", f'{unpl["DOWNTIME_HOURS"].sum():,.0f} h',
        f'{unpl["DOWNTIME_HOURS"].sum() / max(total_dt, 1):.0%} of total', "red",
    )
    kpi(c[2], "Events", f'{int(d["EVENT_COUNT"].sum()):,}', "all reasons", "violet")

    top = (
        unpl.groupby("REASON_CODE")["DOWNTIME_MIN"].sum().idxmax()
        if not unpl.empty
        else "\u2014"
    )
    kpi(c[3], "Top unplanned cause", top, "fix this first", "amber")

    st.write("")

    if not unpl.empty:
        st.markdown(
            '<div class="section">Pareto \u2014 unplanned downtime by reason</div>',
            unsafe_allow_html=True,
        )
        par = (
            unpl.groupby("REASON_CODE", as_index=False)["DOWNTIME_MIN"]
            .sum()
            .sort_values("DOWNTIME_MIN", ascending=False)
        )
        par["CUM_PCT"] = par["DOWNTIME_MIN"].cumsum() / par["DOWNTIME_MIN"].sum()
        base = alt.Chart(par).encode(x=alt.X("REASON_CODE:N", sort=None, title=None))
        bar = base.mark_bar(
            color="#ef4444", cornerRadiusTopLeft=4, cornerRadiusTopRight=4
        ).encode(
            y=alt.Y("DOWNTIME_MIN:Q", title="Minutes"),
            tooltip=["REASON_CODE", "DOWNTIME_MIN"],
        )
        line = base.mark_line(color="#0f172a", point=True).encode(
            y=alt.Y("CUM_PCT:Q", title="Cumulative %", axis=alt.Axis(format="%")),
            tooltip=[alt.Tooltip("CUM_PCT:Q", format=".0%")],
        )
        st.altair_chart(
            alt.layer(bar, line).resolve_scale(y="independent").properties(height=340),
            use_container_width=True,
        )

        st.markdown(
            '<div class="section">Heat-map \u2014 line \u00d7 reason (minutes)</div>',
            unsafe_allow_html=True,
        )
        heat = (
            alt.Chart(unpl)
            .mark_rect()
            .encode(
                x=alt.X("REASON_CODE:N", title=None),
                y=alt.Y("LINE_NAME:N", title=None),
                color=alt.Color(
                    "DOWNTIME_MIN:Q",
                    scale=alt.Scale(scheme="orangered"),
                    title="Minutes",
                ),
                tooltip=["LINE_NAME", "REASON_CODE", "DOWNTIME_MIN", "EVENT_COUNT"],
            )
            .properties(height=300)
        )
        st.altair_chart(heat, use_container_width=True)
    else:
        st.success("No unplanned downtime events recorded.")

    with st.expander("\U0001f4cb Full downtime table"):
        st.dataframe(d, use_container_width=True)

# =============================================================================
# 4. Asset 360
# =============================================================================
elif page.endswith("Asset 360"):
    hero(
        "Asset 360",
        "Everything about one asset \u2014 reliability, cost, sensors, alerts and work orders",
    )

    a360 = load_360()
    health = load_health()

    if a360.empty:
        st.info("No asset data available yet.")
        st.stop()

    ids = a360["ASSET_ID"].tolist()
    default_idx = 0
    if not health.empty and health.iloc[0]["ASSET_ID"] in ids:
        default_idx = ids.index(health.iloc[0]["ASSET_ID"])
    asset_id = st.selectbox("Select asset", ids, index=default_idx)

    a = a360[a360["ASSET_ID"] == asset_id].iloc[0]
    hrow = health[health["ASSET_ID"] == asset_id]
    status = hrow.iloc[0]["RULE_STATUS"] if not hrow.empty else "HEALTHY"

    st.markdown(f"### {asset_id} &nbsp; {badge(status)}", unsafe_allow_html=True)
    mfr = a["MANUFACTURER"] if "MANUFACTURER" in a.index else ""
    st.caption(
        f'{a["ASSET_TYPE"]} \u00b7 {mfr} \u00b7 Line {a["LINE_ID"]} \u00b7 '
        f'Plant {a["PLANT_ID"]} \u00b7 Criticality {a["CRITICALITY"]}'
    )

    c = st.columns(6)
    kpi(
        c[0], "Health score",
        f'{hrow.iloc[0]["HEALTH_SCORE"]:.0f}' if not hrow.empty else "\u2014",
        "0\u2013100", "cyan",
    )
    kpi(
        c[1], "Failure prob.",
        pct(hrow.iloc[0]["FAILURE_PROB"]) if not hrow.empty else "\u2014",
        "next 24h", "red",
    )
    rul = hrow.iloc[0]["RUL_HOURS"] if not hrow.empty else None
    kpi(
        c[2], "RUL",
        "\u2014" if rul is None or pd.isna(rul) else ("> 1 yr" if rul >= 9999 else f"{rul:,.0f} h"),
        "remaining life", "violet",
    )
    kpi(c[3], "MTBF", f'{a["MTBF_HOURS_30D"]:,.0f} h', "30 days", "green")
    kpi(
        c[4], "MTTR",
        "\u2014" if pd.isna(a["MTTR_HOURS_30D"]) else f'{a["MTTR_HOURS_30D"]:.1f} h',
        "30 days", "amber",
    )
    kpi(
        c[5], "Downtime cost", f'${a["DOWNTIME_COST_30D"]:,.0f}',
        f'maint ${a["MAINT_COST_30D"]:,.0f}', "red",
    )

    st.write("")
    s = load_sensor_trend(asset_id)

    t1, t2 = st.tabs(["\U0001f4c8 Vibration (7 days)", "\U0001f321 Temperature (7 days)"])
    for tab, col_name, lim, color in [
        (t1, "AVG_VIBRATION", "MAX_VIBRATION_MM_S", "#06b6d4"),
        (t2, "AVG_TEMPERATURE", "MAX_TEMP_C", "#f59e0b"),
    ]:
        with tab:
            if s.empty:
                st.info("No sensor data in the last 7 days.")
                continue
            ln = (
                alt.Chart(s)
                .mark_area(
                    line={"color": color},
                    color=alt.Gradient(
                        gradient="linear",
                        stops=[
                            alt.GradientStop(color="white", offset=0),
                            alt.GradientStop(color=color, offset=1),
                        ],
                        x1=1, x2=1, y1=1, y2=0,
                    ),
                    opacity=0.5,
                )
                .encode(
                    x=alt.X("WINDOW_START:T", title=None),
                    y=alt.Y(f"{col_name}:Q", title=None),
                    tooltip=["WINDOW_START:T", col_name],
                )
            )
            lim_rule = (
                alt.Chart(pd.DataFrame({"y": [s[lim].iloc[0]]}))
                .mark_rule(color="#ef4444", strokeDash=[6, 4])
                .encode(y="y:Q")
            )
            st.altair_chart(
                (ln + lim_rule).properties(height=280), use_container_width=True
            )
            st.caption("Red dashed line = asset limit")

    w1, w2 = st.columns(2)

    with w1:
        st.markdown(
            '<div class="section">Alerts for this asset</div>', unsafe_allow_html=True
        )
        al = load_alerts()
        al = al[al["ASSET_ID"] == asset_id]
        if al.empty:
            st.success("No alerts")
        for _, r in al.head(5).iterrows():
            st.markdown(
                f'<div class="alert-card">{badge(r["SEVERITY"])} {r["ALERT_TYPE"]}'
                f'<div class="t">{r["ALERT_TS"]}</div>'
                f'<div style="font-size:12px">{r["MESSAGE"]}</div></div>',
                unsafe_allow_html=True,
            )

    with w2:
        st.markdown(
            '<div class="section">Maintenance</div>', unsafe_allow_html=True
        )
        cc = st.columns(3)
        kpi(cc[0], "WOs (30d)", int(a["WO_COUNT_30D"]), "", "blue")
        kpi(cc[1], "Open PMs", int(a["OPEN_PM_COUNT"]), "", "amber")
        kpi(
            cc[2], "Low-stock parts", int(a["SPARE_PARTS_LOW_STOCK"]),
            "", "red" if a["SPARE_PARTS_LOW_STOCK"] else "green",
        )

# =============================================================================
# 5. Anomaly Monitor
# =============================================================================
elif page.endswith("Anomaly Monitor"):
    hero(
        "ML Anomaly Monitor",
        "Snowflake ML anomaly detection on 15-minute vibration features",
    )

    an = load_anomalies()
    if an.empty:
        st.warning(
            "No anomaly scores yet \u2014 the scoring task runs every 15 minutes."
        )
        st.stop()

    an["TS"] = pd.to_datetime(an["TS"])

    c = st.columns(4)
    n_anom = int(an["IS_ANOMALY"].sum())
    kpi(c[0], "Readings scored", f"{len(an):,}", "last 12h window", "blue")
    kpi(c[1], "Anomalies", n_anom, "outside 99% interval", "red")
    kpi(c[2], "Anomaly rate", f"{n_anom / len(an):.1%}", "", "amber")
    kpi(
        c[3], "Assets affected",
        an[an["IS_ANOMALY"]]["ASSET_ID"].nunique(), "", "violet",
    )

    st.write("")
    by = (
        an[an["IS_ANOMALY"]]
        .groupby("ASSET_ID")
        .size()
        .reset_index(name="N")
        .sort_values("N", ascending=False)
    )
    top_assets = by["ASSET_ID"].head(15).tolist()

    left, right = st.columns([1, 2])

    with left:
        st.markdown(
            '<div class="section">Anomalies by asset</div>', unsafe_allow_html=True
        )
        st.altair_chart(
            alt.Chart(by.head(15))
            .mark_bar(color="#ef4444")
            .encode(
                x=alt.X("N:Q", title=None),
                y=alt.Y("ASSET_ID:N", sort="-x", title=None),
                tooltip=["ASSET_ID", "N"],
            )
            .properties(height=420),
            use_container_width=True,
        )

    with right:
        st.markdown(
            '<div class="section">Actual vs forecast</div>', unsafe_allow_html=True
        )
        pick = st.selectbox(
            "Asset", top_assets or sorted(an["ASSET_ID"].unique())
        )
        sa = an[an["ASSET_ID"] == pick]
        band = (
            alt.Chart(sa)
            .mark_area(opacity=0.2, color="#06b6d4")
            .encode(
                x=alt.X("TS:T", title=None),
                y=alt.Y("LOWER_BOUND:Q", title="Vibration mm/s",
                         scale=alt.Scale(zero=False)),
                y2="UPPER_BOUND:Q",
            )
        )
        fc = (
            alt.Chart(sa)
            .mark_line(color="#06b6d4", strokeDash=[4, 3])
            .encode(x="TS:T", y="FORECAST:Q")
        )
        act = (
            alt.Chart(sa)
            .mark_line(color="#0f172a")
            .encode(x="TS:T", y="VALUE:Q")
        )
        pts = (
            alt.Chart(sa[sa["IS_ANOMALY"]])
            .mark_circle(color="#ef4444", size=90)
            .encode(
                x="TS:T", y="VALUE:Q",
                tooltip=["TS:T", "VALUE", "FORECAST", "DISTANCE"],
            )
        )
        st.altair_chart(
            (band + fc + act + pts).properties(height=380),
            use_container_width=True,
        )
        st.caption(
            "Band = 99% prediction interval \u00b7 dashed = forecast \u00b7 red dots = anomalies"
        )

# =============================================================================
# 6. Alerts & Work Orders
# =============================================================================
elif page.endswith("Alerts & Work Orders"):
    hero(
        "Alerts & Work Orders",
        "Triage queue generated automatically every 15 minutes",
    )

    al = load_alerts()
    wo = load_wo()

    c = st.columns(4)
    kpi(c[0], "Critical",
        int((al["SEVERITY"] == "CRITICAL").sum()) if not al.empty else 0,
        "alerts", "red")
    kpi(c[1], "Warning",
        int((al["SEVERITY"] == "WARNING").sum()) if not al.empty else 0,
        "alerts", "amber")
    kpi(
        c[2], "Unacknowledged",
        int((~al["ACKNOWLEDGED"].fillna(False)).sum()) if not al.empty else 0,
        "", "violet",
    )
    kpi(c[3], "WO drafts", len(wo), "awaiting approval", "blue")

    st.write("")
    ta, tw = st.tabs(["\U0001f6a8 Alerts", "\U0001f6e0 Work order drafts"])

    with ta:
        if al.empty:
            st.success("No alerts")
        else:
            sev = st.multiselect(
                "Severity", ["CRITICAL", "WARNING", "INFO"],
                default=["CRITICAL", "WARNING"],
            )
            timeline = (
                alt.Chart(al)
                .mark_circle(size=120)
                .encode(
                    x=alt.X("ALERT_TS:T", title=None),
                    y=alt.Y("ASSET_ID:N", title=None),
                    color=alt.Color(
                        "SEVERITY:N",
                        scale=alt.Scale(
                            domain=["CRITICAL", "WARNING", "INFO"],
                            range=["#ef4444", "#f59e0b", "#0ea5e9"],
                        ),
                    ),
                    tooltip=["ASSET_ID", "ALERT_TYPE", "SEVERITY", "MESSAGE"],
                )
                .properties(height=300)
            )
            st.altair_chart(timeline, use_container_width=True)

            for _, r in al[al["SEVERITY"].isin(sev)].head(30).iterrows():
                st.markdown(
                    f'<div class="alert-card">{badge(r["SEVERITY"])} '
                    f'<b>{r["ASSET_ID"]}</b> \u00b7 {r["ALERT_TYPE"]}'
                    f'<div class="t">{r["ALERT_TS"]}</div>'
                    f'<div style="font-size:12px">{r["MESSAGE"]}</div></div>',
                    unsafe_allow_html=True,
                )

    with tw:
        if wo.empty:
            st.info(
                "No work order drafts. Drafts are created automatically when "
                "an asset enters WARNING or CRITICAL."
            )
        else:
            for _, r in wo.iterrows():
                with st.expander(
                    f'{r["PRIORITY"]} \u00b7 {r["TITLE"]} \u00b7 {r["STATUS"]}'
                ):
                    st.write(r["DESCRIPTION"])
                    st.markdown(
                        f'**Recommended action:** {r["RECOMMENDED_ACTION"]}'
                    )
                    st.caption(
                        f'Created {r["CREATED_AT"]} \u00b7 source {r["SOURCE"]}'
                    )

# =============================================================================
# 7. AI Assistant
# =============================================================================
elif page.endswith("AI Assistant"):
    hero(
        "AI Maintenance Assistant",
        "Ask questions about your fleet \u2014 answered by Snowflake Cortex using live data",
    )

    if "chat" not in st.session_state:
        st.session_state.chat = []

    examples = [
        "Which 3 assets should I prioritize today and why?",
        "Summarize today's OEE performance for the plant manager.",
        "What is causing most of our unplanned downtime?",
        "Draft a maintenance plan for the highest-risk asset.",
    ]
    ex = st.columns(len(examples))
    clicked = None
    for col, e in zip(ex, examples):
        if col.button(e):
            clicked = e

    question = st.text_input(
        "Your question", value=clicked or "",
        placeholder="e.g. Why is CNC-05 flagged?",
    )
    ask = st.button("Ask Cortex \u2728", type="primary")

    if (ask or clicked) and question.strip():
        health = load_health()
        dt = load_downtime()
        al = load_alerts()
        p = load_oee_plant()
        p["SHIFT_DATE"] = pd.to_datetime(p["SHIFT_DATE"])

        ctx_parts = []
        if not health.empty:
            ctx_parts.append(
                "ASSET HEALTH (worst 15):\n"
                + health.head(15)[
                    [
                        "ASSET_ID", "ASSET_TYPE", "CRITICALITY", "RULE_STATUS",
                        "HEALTH_SCORE", "VIB_PCT_OF_LIMIT", "TEMP_PCT_OF_LIMIT",
                        "FAILURE_PROB", "RUL_HOURS",
                    ]
                ].to_csv(index=False)
            )
        if not al.empty:
            ctx_parts.append(
                "RECENT ALERTS:\n"
                + al.head(15)[
                    ["ASSET_ID", "SEVERITY", "ALERT_TYPE", "MESSAGE"]
                ].to_csv(index=False)
            )
        if not dt.empty:
            ctx_parts.append(
                "UNPLANNED DOWNTIME BY REASON (minutes):\n"
                + dt[~dt["IS_PLANNED"]]
                .groupby("REASON_CODE")["DOWNTIME_MIN"]
                .sum()
                .sort_values(ascending=False)
                .to_csv()
            )
        if not p.empty:
            ctx_parts.append(
                "LATEST OEE BY PLANT:\n"
                + p[p["SHIFT_DATE"] == p["SHIFT_DATE"].max()][
                    ["PLANT_NAME", "OEE", "AVAILABILITY", "PERFORMANCE", "QUALITY"]
                ].to_csv(index=False)
            )

        ctx = "\n".join(ctx_parts) if ctx_parts else "No data available yet."

        prompt = (
            "You are a senior reliability engineer assisting a manufacturing plant. "
            "Use ONLY the data below. Be concise, use bullet points, cite asset IDs "
            "and numbers, and end with clear recommended actions.\n\n"
            f"DATA:\n{ctx}\n\nQUESTION: {question}"
        )

        with st.spinner("Cortex is analyzing live plant data..."):
            try:
                ans = session.sql(
                    "SELECT SNOWFLAKE.CORTEX.COMPLETE(?, ?) AS R",
                    params=["claude-sonnet-4-5", prompt],
                ).collect()[0]["R"]
            except Exception as e:
                ans = f"Sorry, the AI request failed: {e}"

        st.session_state.chat.insert(0, (question, ans))

    for qq, aa in st.session_state.chat:
        st.markdown(
            f'<div class="alert-card"><b>\U0001f9d1 {qq}</b></div>',
            unsafe_allow_html=True,
        )
        st.markdown(aa)
        st.markdown("---")

    st.caption(
        "For deeper questions (including maintenance manuals), use the Cortex Agent "
        "MFG_PDM_DB.AI.PDM_COMMAND_CENTER in Snowflake Intelligence."
    )
