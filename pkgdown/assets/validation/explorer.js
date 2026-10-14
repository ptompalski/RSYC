/* RSYC yield curve explorer.
 *
 * Maps every published RSYC curve and shows, for a selected area, its yield
 * curves, parameters, and validation results. Renders
 * the web bundle exported by RSYC-Canada/R/5900_export_validation_web_bundle.R;
 * the bundle version is read from versions.json next to this script.
 * Validation figures follow the RSYC-Canada styles (5210 scatterplots, 5240
 * curves vs plots, 5270 metric maps).
 *
 * Requires d3 (v7) and Observable Plot (v0.6) as globals.
 */
(function () {
  "use strict";

  const root = document.getElementById("rsyc-curve-explorer");
  if (!root) return;

  const scriptBase = (function () {
    const src = document.currentScript && document.currentScript.src;
    return src ? src.replace(/[^/]*$/, "") : root.dataset.base || "../validation/";
  })();

  const LEVELS = ["tile", "ecozone", "ecoprovince", "ecoregion", "ecodistrict"];
  const LEVEL_LABELS = {
    tile: "Tile",
    ecozone: "Ecozone",
    ecoprovince: "Ecoprovince",
    ecoregion: "Ecoregion",
    ecodistrict: "Ecodistrict"
  };
  const SCALES = ["national", "regional"];
  const SCALE_LABELS = { national: "National", regional: "Regional" };
  const RESPONSES = {
    agb: { label: "AGB", name: "Aboveground biomass", units: "Mg/ha", ymax: 300 },
    volume: { label: "Volume", name: "Total volume", units: "m³/ha", ymax: 800 }
  };
  const COLOR_NO_MODEL = "#F0F0F0";
  const COLOR_NOT_VALIDATED = "#C9C9C9";
  const COLOR_NA = "#9E9E9E";
  const COMPARE_COLORS = d3.schemeTableau10;

  // Maximum yield is searched over ages 1..AGE_LIMIT.
  const AGE_LIMIT = 300;
  // Curves are plotted for ages up to AGE_PLOT.
  const AGE_PLOT = 150;

  // units: true = response units.
  const METRICS = {
    b1: { group: "curve", label: "b1 (asymptote)", kind: "sequential", format: ".1f", units: true, zero: true },
    ccc: { group: "validation", label: "CCC", kind: "sequential", format: ".2f", domain: [0, 1] },
    rsq: { group: "validation", label: "R²", kind: "sequential", format: ".2f", domain: [0, 1] },
    md: { group: "validation", label: "Bias", kind: "diverging", format: ".1f", units: true },
    rmd: { group: "validation", label: "Bias (%)", kind: "diverging", format: ".1f", suffix: "%" },
    rmse: { group: "validation", label: "RMSE", kind: "sequential", format: ".1f", units: true },
    rrmse: { group: "validation", label: "RMSE (%)", kind: "sequential", format: ".1f", suffix: "%" }
  };
  const METRIC_GROUPS = [
    ["curve", "Curve"],
    ["validation", "Validation"]
  ];

  const DEFAULT_STATE = {
    response: "agb",
    scale: "national",
    level: "ecoregion",
    species: "generic",
    metric: "b1",
    strata: null,
    compare: ""
  };

  const keyOf = (...parts) => parts.join("|");
  const fmt = (spec, v) =>
    v == null || Number.isNaN(v) ? "–" : d3.format(spec)(v);
  const esc = (s) =>
    String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

  // Data ------------------------------------------------------------------

  const data = {
    version: null,
    manifest: null,
    species: new Map(),
    models: [],
    statsByKey: new Map(),
    ageByKey: new Map(),
    groups: new Map(),
    strata: new Map(),
    areas: new Map(),
    geometry: new Map()
  };

  async function getJSON(path) {
    const response = await fetch(scriptBase + path);
    if (!response.ok) {
      throw new Error("Could not load " + path + " (" + response.status + ")");
    }
    return response.json();
  }

  function columnsToRows(columns) {
    const fields = Object.keys(columns);
    const n = fields.length ? columns[fields[0]].length : 0;
    const rows = new Array(n);
    for (let i = 0; i < n; i++) {
      const row = {};
      for (const f of fields) row[f] = columns[f][i];
      rows[i] = row;
    }
    return rows;
  }

  function curveValue(m, age) {
    return m.b1 * Math.exp(-m.b4 * age) * Math.pow(1 - Math.exp(-m.b2 * age), m.b3);
  }

  function deriveCurve(m) {
    let ymax = -Infinity;
    let ageY = NaN;
    for (let age = 1; age <= AGE_LIMIT; age++) {
      const y = curveValue(m, age);
      if (y > ymax) {
        ymax = y;
        ageY = age;
      }
    }
    m.ymax = Number.isFinite(ymax) ? ymax : NaN;
    m.age_ymax = ageY;
  }

  async function loadBundle(version) {
    const dir = version + "/";
    const [manifest, models, stats, age] = await Promise.all([
      getJSON(dir + "manifest.json"),
      getJSON(dir + "models.json"),
      getJSON(dir + "validation_stats.json"),
      getJSON(dir + "validation_age.json")
    ]);

    data.version = version;
    data.manifest = manifest;
    data.species = new Map(manifest.species.map((s) => [s.species, s]));
    data.models = columnsToRows(models);
    data.models.forEach(deriveCurve);
    data.statsByKey = new Map(columnsToRows(stats).map((s) => [s.key, s]));
    data.ageByKey = d3.group(columnsToRows(age), (a) => a.key);
    // CCC is not in the bundle; compute it per curve from the age-class means.
    for (const [key, s] of data.statsByKey) {
      const m = scatterMetrics(data.ageByKey.get(key) || []);
      s.ccc = m ? m.ccc : NaN;
    }
    data.groups = d3.group(data.models, (m) =>
      keyOf(m.response, m.scale, m.parameter_level, m.species)
    );
    data.areas = d3.group(data.models, (m) =>
      keyOf(m.response, m.scale, m.parameter_level, m.strata_id)
    );
    data.strata = new Map();
    for (const m of data.models) {
      const k = keyOf(m.response, m.parameter_level, m.species, m.strata_id);
      if (!data.strata.has(k)) data.strata.set(k, {});
      data.strata.get(k)[m.scale] = m;
    }
    data.geometry = new Map();
  }

  // GeoJSON written with RFC 7946 winding (counterclockwise exterior rings)
  // must be rewound for d3-geo, which treats rings as spherical polygons.
  function rewind(feature) {
    const fixPolygon = (rings) => {
      const area = d3.geoArea({ type: "Polygon", coordinates: rings });
      return area > 2 * Math.PI ? rings.map((r) => r.slice().reverse()) : rings;
    };
    const g = feature.geometry;
    if (!g) return feature;
    if (g.type === "Polygon") g.coordinates = fixPolygon(g.coordinates);
    if (g.type === "MultiPolygon") g.coordinates = g.coordinates.map(fixPolygon);
    return feature;
  }

  async function loadGeometry(level) {
    if (!data.geometry.has(level)) {
      const path = data.manifest.geometry.layers[level];
      const promise = getJSON(data.version + "/" + path).then((fc) => {
        fc.features.forEach(rewind);
        return fc;
      });
      data.geometry.set(level, promise);
    }
    return data.geometry.get(level);
  }

  const speciesName = (code) =>
    (data.species.get(code) && data.species.get(code).species_name) || code;

  const strataName = (strataId) => String(strataId).split("/").pop();

  function sortSpecies(codes) {
    const groups = ["generic", "coniferous", "broadleaf"].filter((c) => codes.has(c));
    const species = [...codes]
      .filter((c) => !groups.includes(c))
      .sort((a, b) => d3.ascending(speciesName(a), speciesName(b)));
    return [...groups, ...species];
  }

  function speciesOptions(response) {
    return sortSpecies(
      new Set(data.models.filter((m) => m.response === response).map((m) => m.species))
    );
  }

  function selectionModels(state) {
    return (
      data.groups.get(
        keyOf(state.response, state.scale, state.level, state.species)
      ) || []
    );
  }

  function areaPair(state) {
    return (
      data.strata.get(
        keyOf(state.response, state.level, state.species, state.strata)
      ) || {}
    );
  }

  // Other species with a curve for the selected area at the selected scale.
  function compareOptions(state) {
    if (!state.strata) return [];
    const models = data.areas.get(
      keyOf(state.response, state.scale, state.level, state.strata)
    ) || [];
    return sortSpecies(
      new Set(models.map((m) => m.species).filter((s) => s !== state.species))
    );
  }

  const compareList = (state) => (state.compare ? state.compare.split(",") : []);

  function metricValue(model, metric) {
    if (!model) return null;
    if (METRICS[metric].group === "curve") return model[metric];
    if (!model.validated) return null;
    const s = data.statsByKey.get(model.key);
    return s ? s[metric] : null;
  }

  const unitsFor = (spec) => (spec.units ? RESPONSES[state.response].units : null);

  const metricLabel = (metric) => METRICS[metric].label;

  function formatMetric(metric, value) {
    const spec = METRICS[metric];
    let text = fmt(spec.format, value);
    if (value == null || Number.isNaN(value)) return text;
    if (spec.suffix) text += spec.suffix;
    const units = unitsFor(spec);
    if (units) text += " " + units;
    return text;
  }

  const niceUpper = (v) => d3.scaleLinear().domain([0, v]).nice().domain()[1];

  // Shared colour domain across scales and levels for the response and
  // species, so maps remain comparable when switching level or scale.
  function colorScale(state) {
    const spec = METRICS[state.metric];
    const values = data.models
      .filter((m) => m.response === state.response && m.species === state.species)
      .map((m) => metricValue(m, state.metric))
      .filter((v) => v != null && Number.isFinite(v))
      .sort(d3.ascending);

    if (spec.kind === "diverging") {
      const limit = d3.quantile(values.map(Math.abs).sort(d3.ascending), 0.95) || 1;
      const L = niceUpper(limit);
      return d3
        .scaleDiverging(d3.interpolateRgbBasis(["#2C7BB6", "#F7F7F7", "#D7191C"]))
        .domain([-L, 0, L])
        .clamp(true);
    }
    let domain = spec.domain;
    if (!domain) {
      domain = [0, niceUpper(d3.quantile(values, 0.95) || 1)];
    }
    return d3
      .scaleSequential(d3.interpolateViridis)
      .domain(domain)
      .clamp(true);
  }

  // State -----------------------------------------------------------------

  let state = Object.assign({}, DEFAULT_STATE);

  function readHash() {
    const params = new URLSearchParams(window.location.hash.replace(/^#/, ""));
    const next = Object.assign({}, DEFAULT_STATE);
    for (const k of Object.keys(DEFAULT_STATE)) {
      if (params.has(k)) next[k] = params.get(k);
    }
    if (!RESPONSES[next.response]) next.response = DEFAULT_STATE.response;
    if (!SCALES.includes(next.scale)) next.scale = DEFAULT_STATE.scale;
    if (!LEVELS.includes(next.level)) next.level = DEFAULT_STATE.level;
    if (!METRICS[next.metric]) next.metric = DEFAULT_STATE.metric;
    return next;
  }

  function writeHash() {
    const params = new URLSearchParams();
    for (const k of Object.keys(DEFAULT_STATE)) {
      if (state[k] != null && state[k] !== "" && state[k] !== DEFAULT_STATE[k]) {
        params.set(k, state[k]);
      }
    }
    history.replaceState(null, "", "#" + params.toString());
  }

  function setState(patch) {
    const levelChanged = patch.level && patch.level !== state.level;
    state = Object.assign({}, state, patch);
    if (levelChanged && !("strata" in patch)) state.strata = null;
    validateState();
    writeHash();
    render();
  }

  function validateState() {
    if (!speciesOptions(state.response).includes(state.species)) {
      state.species = "generic";
    }
    if (
      state.strata &&
      !selectionModels(state).some((m) => m.strata_id === state.strata)
    ) {
      state.strata = null;
    }
    const available = compareOptions(state);
    state.compare = compareList(state).filter((s) => available.includes(s)).join(",");
  }

  // Layout ----------------------------------------------------------------

  root.innerHTML = `
    <div class="rve-status">Loading RSYC curves…</div>
    <div class="rve-body" hidden>
      <form class="rve-controls" onsubmit="return false">
        <label>Response <select name="response"></select></label>
        <label>Scale <select name="scale"></select></label>
        <label>Spatial level <select name="level"></select></label>
        <label>Model <select name="species"></select></label>
        <label>Map colour <select name="metric"></select></label>
      </form>
      <div class="rve-map-card">
        <div class="rve-map-header">
          <div class="rve-map-title"></div>
          <button type="button" class="rve-reset" title="Reset zoom">Reset zoom</button>
        </div>
        <div class="rve-map"></div>
        <div class="rve-legend"></div>
        <div class="rve-map-summary"></div>
      </div>
      <label class="rve-strata-picker">Selected area
        <select name="strata"></select>
      </label>
      <section class="rve-detail">
        <div class="rve-detail-header"></div>
        <div class="rve-curves-section">
          <form class="rve-chart-controls" onsubmit="return false">
            <div class="rve-compare"></div>
          </form>
          <div class="rve-charts">
            <figure class="rve-curve"></figure>
          </div>
          <div class="rve-curve-info"></div>
        </div>
        <h3 class="rve-section-title">Validation</h3>
        <div class="rve-validation-note"></div>
        <div class="rve-validation">
          <figure class="rve-scatter"></figure>
          <div class="rve-tables"></div>
        </div>
      </section>
    </div>
    <div class="rve-tooltip" hidden></div>`;

  const q = (sel) => root.querySelector(sel);
  const els = {
    status: q(".rve-status"),
    body: q(".rve-body"),
    controls: q(".rve-controls"),
    mapTitle: q(".rve-map-title"),
    map: q(".rve-map"),
    reset: q(".rve-reset"),
    legend: q(".rve-legend"),
    mapSummary: q(".rve-map-summary"),
    strata: q("select[name=strata]"),
    detailHeader: q(".rve-detail-header"),
    curvesSection: q(".rve-curves-section"),
    chartControls: q(".rve-chart-controls"),
    compare: q(".rve-compare"),
    curve: q(".rve-curve"),
    curveInfo: q(".rve-curve-info"),
    validationNote: q(".rve-validation-note"),
    scatter: q(".rve-scatter"),
    tables: q(".rve-tables"),
    tooltip: q(".rve-tooltip")
  };

  function fillSelect(select, options, value) {
    select.innerHTML = "";
    for (const [v, label] of options) {
      const option = document.createElement("option");
      option.value = v;
      option.textContent = label;
      option.selected = v === value;
      select.appendChild(option);
    }
  }

  function fillMetricSelect(select, value) {
    select.innerHTML = "";
    for (const [group, label] of METRIC_GROUPS) {
      const optgroup = document.createElement("optgroup");
      optgroup.label = label;
      for (const [k, spec] of Object.entries(METRICS)) {
        if (spec.group !== group) continue;
        const option = document.createElement("option");
        option.value = k;
        option.textContent = spec.label;
        option.selected = k === value;
        optgroup.appendChild(option);
      }
      select.appendChild(optgroup);
    }
  }

  function onControlChange(event) {
    const { name, value, type } = event.target;
    if (name === "compare") {
      const selected = [...els.compare.querySelectorAll("input[name=compare]:checked")].map(
        (input) => input.value
      );
      setState({ compare: selected.join(",") });
    } else if (type !== "checkbox") {
      setState({ [name]: value });
    }
  }

  els.controls.addEventListener("change", onControlChange);
  els.chartControls.addEventListener("change", onControlChange);
  els.strata.addEventListener("change", (event) => {
    setState({ strata: event.target.value || null });
  });

  // Map -------------------------------------------------------------------

  const MAP_W = 960;
  const MAP_H = 640;
  const projection = d3.geoConicConformal().parallels([49, 77]).rotate([96, 0]);
  const geoPath = d3.geoPath(projection);
  const svg = d3
    .select(els.map)
    .append("svg")
    .attr("viewBox", [0, 0, MAP_W, MAP_H])
    .attr("role", "img")
    .attr("aria-label", "Map of RSYC curves");
  const zoomLayer = svg.append("g");
  const baseLayer = zoomLayer.append("g").attr("class", "rve-base");
  const unitLayer = zoomLayer.append("g").attr("class", "rve-units");
  const selectedLayer = zoomLayer.append("g").attr("class", "rve-selected-layer");
  const zoom = d3
    .zoom()
    .scaleExtent([1, 16])
    .translateExtent([
      [0, 0],
      [MAP_W, MAP_H]
    ])
    .on("zoom", (event) => zoomLayer.attr("transform", event.transform));
  svg.call(zoom);
  els.reset.addEventListener("click", () =>
    svg.transition().duration(400).call(zoom.transform, d3.zoomIdentity)
  );

  let projectionFitted = false;

  function showTooltip(event, html) {
    els.tooltip.innerHTML = html;
    els.tooltip.hidden = false;
    const rect = root.getBoundingClientRect();
    let x = event.clientX - rect.left + 14;
    const y = event.clientY - rect.top + 14;
    if (x + els.tooltip.offsetWidth > rect.width) {
      x = event.clientX - rect.left - els.tooltip.offsetWidth - 14;
    }
    els.tooltip.style.left = x + "px";
    els.tooltip.style.top = y + "px";
  }

  function hideTooltip() {
    els.tooltip.hidden = true;
  }

  async function renderMap(token) {
    const [base, layer] = await Promise.all([
      loadGeometry("ecozone"),
      loadGeometry(state.level)
    ]);
    if (token !== renderToken) return;

    if (!projectionFitted) {
      projection.fitExtent(
        [
          [10, 10],
          [MAP_W - 10, MAP_H - 10]
        ],
        base
      );
      projectionFitted = true;
      baseLayer
        .selectAll("path")
        .data(base.features)
        .join("path")
        .attr("d", geoPath);
    }

    const models = new Map(selectionModels(state).map((m) => [m.strata_id, m]));
    const color = colorScale(state);
    const curveMetric = METRICS[state.metric].group === "curve";

    const fillFor = (feature) => {
      const m = models.get(feature.properties.strata_id);
      if (!m) return COLOR_NO_MODEL;
      if (!curveMetric && !m.validated) return COLOR_NOT_VALIDATED;
      const v = metricValue(m, state.metric);
      if (v == null || !Number.isFinite(v)) return COLOR_NA;
      return color(v);
    };

    unitLayer
      .selectAll("path")
      .data(layer.features, (f) => f.properties.strata_id)
      .join("path")
      .attr("d", geoPath)
      .attr("fill", fillFor)
      .classed("rve-has-model", (f) => models.has(f.properties.strata_id))
      .on("mousemove", (event, f) => {
        const m = models.get(f.properties.strata_id);
        let html = `<strong>${esc(f.properties.name)}</strong>`;
        if (!m) {
          html += "<br>No model";
        } else {
          if (curveMetric || m.validated) {
            html += `<br>${esc(metricLabel(state.metric))}: ${formatMetric(state.metric, metricValue(m, state.metric))}`;
          }
          if (m.validated) {
            const s = data.statsByKey.get(m.key);
            html += `<br>Validated with ${fmt(",d", s && s.n_plots)} plots`;
          } else {
            html += "<br>Not validated";
          }
        }
        showTooltip(event, html);
      })
      .on("mouseleave", hideTooltip)
      .on("click", (event, f) => {
        if (models.has(f.properties.strata_id)) setState({ strata: f.properties.strata_id });
      });

    selectedLayer
      .selectAll("path")
      .data(layer.features.filter((f) => f.properties.strata_id === state.strata))
      .join("path")
      .attr("d", geoPath);

    renderLegend(color, curveMetric);

    const all = [...models.values()];
    const validated = all.filter((m) => m.validated);
    const unit = LEVEL_LABELS[state.level].toLowerCase();
    els.mapSummary.textContent = all.length
      ? `Models available in ${all.length} of ${layer.features.length} ${unit}s; ` +
        `${validated.length} validated. Click an area to see its curves.`
      : `There are no ${SCALE_LABELS[state.scale].toLowerCase()} ${unit} ` +
        `${RESPONSES[state.response].label} models for ${speciesName(state.species)}. ` +
        "Try another scale or spatial level.";
  }

  function renderLegend(color, curveMetric) {
    const spec = METRICS[state.metric];
    els.legend.innerHTML = "";
    const legend = d3.select(els.legend);
    const units = unitsFor(spec);
    const title = metricLabel(state.metric) + (units ? ` [${units}]` : "");

    const width = 260;
    const height = 44;
    const ramp = legend
      .append("svg")
      .attr("width", width + 30)
      .attr("height", height);
    ramp
      .append("text")
      .attr("x", 15)
      .attr("y", 11)
      .attr("class", "rve-legend-title")
      .text(title);
    const domain = color.domain();
    const lo = domain[0];
    const hi = domain[domain.length - 1];
    const axisScale = d3
      .scaleLinear()
      .domain([lo, hi])
      .range([15, 15 + width]);
    const steps = 64;
    ramp
      .append("g")
      .selectAll("rect")
      .data(d3.range(steps))
      .join("rect")
      .attr("x", (i) => 15 + (i * width) / steps)
      .attr("y", 16)
      .attr("width", width / steps + 0.5)
      .attr("height", 10)
      .attr("fill", (i) => color(axisScale.invert(15 + ((i + 0.5) * width) / steps)));
    const tickFormat = d3.format("~g");
    ramp
      .append("g")
      .attr("transform", "translate(0,26)")
      .call(d3.axisBottom(axisScale).ticks(5).tickSize(4).tickFormat(tickFormat))
      .call((g) => g.select(".domain").remove());

    const extra = legend.append("div").attr("class", "rve-swatches");
    const swatches = [["No model", COLOR_NO_MODEL]];
    if (!curveMetric) swatches.push(["Model not validated", COLOR_NOT_VALIDATED]);
    for (const [label, fill] of swatches) {
      const item = extra.append("span").attr("class", "rve-swatch");
      item.append("i").style("background", fill);
      item.append("span").text(label);
    }
  }

  // Curves ----------------------------------------------------------------

  function axisLabel(kind) {
    const r = RESPONSES[state.response];
    if (kind === "plot") return `${r.label} plot [${r.units}]`;
    if (kind === "rsyc") return `${r.label} RSYC [${r.units}]`;
    return `${r.label} [${r.units}]`;
  }

  // Curves shown for the selected area: the selected model at both scales
  // (black), plus compared species at the selected scale (colours).
  function displayedCurves() {
    if (!state.strata) return [];
    const pair = areaPair(state);
    const curves = SCALES.filter((s) => pair[s]).map((s) => ({
      model: pair[s],
      label: `${speciesName(state.species)} – ${SCALE_LABELS[s]}`,
      color: "black",
      dash: s === "regional" ? "6,4" : null
    }));
    compareList(state).forEach((sp, i) => {
      const m = (data.strata.get(keyOf(state.response, state.level, sp, state.strata)) || {})[state.scale];
      if (m) {
        curves.push({
          model: m,
          label: `${speciesName(sp)} – ${SCALE_LABELS[state.scale]}`,
          color: COMPARE_COLORS[i % COMPARE_COLORS.length],
          dash: state.scale === "regional" ? "6,4" : null
        });
      }
    });
    return curves;
  }

  function curveSeries(curve) {
    const out = [{ age: 0, y: 0, label: curve.label }];
    for (let age = 1; age <= AGE_PLOT; age++) {
      out.push({ age, y: curveValue(curve.model, age), label: curve.label });
    }
    return out;
  }

  function curveMarks(curves) {
    const marks = [];
    const all = [];
    for (const c of curves) {
      const series = curveSeries(c);
      all.push(...series);
      marks.push(
        Plot.line(series, {
          x: "age",
          y: "y",
          stroke: c.color,
          strokeWidth: 1.5,
          strokeDasharray: c.dash
        })
      );
    }
    marks.push(
      Plot.tip(
        all,
        Plot.pointer({
          x: "age",
          y: "y",
          maxRadius: 30,
          title: (d) => `${d.label}\nAge ${d.age}: ${fmt(".1f", d.y)}`
        })
      )
    );
    return { marks, all };
  }

  function curveKeys(curves, extra) {
    return (
      (extra || "") +
      curves
        .map(
          (c) =>
            `<span class="rve-key"><svg width="26" height="10"><line x1="0" y1="5" x2="26" y2="5" stroke="${c.color}" stroke-width="1.5" ${c.dash ? `stroke-dasharray="${c.dash}"` : ""}/></svg> ${esc(c.label)}</span>`
        )
        .join("")
    );
  }

  function renderCurves() {
    els.curve.innerHTML = "";
    els.curveInfo.innerHTML = "";
    if (!state.strata) {
      els.chartControls.hidden = true;
      els.curve.innerHTML =
        '<div class="rve-empty">Select an area on the map to see its yield curves, parameters, and validation data.</div>';
      return;
    }
    els.chartControls.hidden = false;

    const curves = displayedCurves();
    const selected = areaPair(state)[state.scale];
    const ages = selected && selected.validated ? data.ageByKey.get(selected.key) || [] : [];
    const reference = ages.map((a) => Object.assign({ x: a.age_class + 10 }, a));

    // Yield curves with plot means (5240 style).
    const yieldMarks = curveMarks(curves);
    const ymax = Math.max(
      d3.max(reference, (d) => d.ci_upper) || 0,
      d3.max(yieldMarks.all, (d) => d.y) || 0
    );
    const yieldPlot = Plot.plot({
      width: 420,
      height: 320,
      marginLeft: 50,
      marginBottom: 40,
      style: { fontSize: "11px", background: "transparent" },
      x: { domain: [0, AGE_PLOT], label: "Age [years]", labelAnchor: "center", labelArrow: "none" },
      y: { domain: [0, ymax * 1.05 || 1], label: axisLabel(), labelAnchor: "center", labelArrow: "none", nice: true },
      marks: [
        Plot.frame(),
        Plot.ruleX(reference, { x: "x", y1: "ci_lower", y2: "ci_upper", stroke: "red", strokeWidth: 1 }),
        Plot.dot(reference, {
          x: "x",
          y: "obs_mean",
          fill: "red",
          r: 2.5,
          channels: {
            "Age class": (d) => `${d.age_class}–${d.age_class + 20}`,
            Plots: "n_plots",
            "Plot mean": "obs_mean",
            "95% CI": (d) => `${fmt(".1f", d.ci_lower)}–${fmt(".1f", d.ci_upper)}`,
            "RSYC mean": "pred_mean"
          },
          tip: { format: { x: false, y: false } }
        }),
        ...yieldMarks.marks
      ]
    });
    const yieldCaption = document.createElement("figcaption");
    yieldCaption.innerHTML = curveKeys(
      curves,
      reference.length
        ? `<span class="rve-key"><svg width="22" height="10"><line x1="0" y1="5" x2="22" y2="5" stroke="red"/><circle cx="11" cy="5" r="3" fill="red"/></svg> Validation plot mean and 95% CI (${SCALE_LABELS[state.scale].toLowerCase()} curve)</span>`
        : ""
    );
    els.curve.append(yieldPlot, yieldCaption);

    renderCurveInfo();
  }

  function renderCompare() {
    const options = compareOptions(state);
    const chosen = compareList(state);
    if (!state.strata || !options.length) {
      els.compare.innerHTML = "";
      return;
    }
    els.compare.innerHTML =
      `<details${chosen.length ? " open" : ""}><summary>Compare with other ${SCALE_LABELS[state.scale].toLowerCase()} models in this area (${options.length})</summary><div class="rve-compare-list">` +
      options
        .map(
          (sp) =>
            `<label class="rve-check"><input type="checkbox" name="compare" value="${esc(sp)}"${chosen.includes(sp) ? " checked" : ""}> ${esc(speciesName(sp))}</label>`
        )
        .join("") +
      "</div></details>";
  }

  function renderCurveInfo() {
    const pair = areaPair(state);
    const scales = SCALES.filter((s) => pair[s]);
    const r = RESPONSES[state.response];
    const yieldAt = (age) => (m) => fmt(".1f", curveValue(m, age));
    const rows = [
      [`${r.label} at age 50 [${r.units}]`, yieldAt(50)],
      [`${r.label} at age 100 [${r.units}]`, yieldAt(100)],
      [`Maximum ${r.label} [${r.units}]`, (m) => `${fmt(".1f", m.ymax)} at age ${fmt(",d", m.age_ymax)}`],
      ["b1", (m) => fmt(".4~g", m.b1)],
      ["b2", (m) => fmt(".4~g", m.b2)],
      ["b3", (m) => fmt(".4~g", m.b3)],
      ["b4", (m) => fmt(".4~g", m.b4)],
      ["Residual SD (sigma)", (m) => fmt(".3~g", m.sigma)],
      ["Validated", (m) => (m.validated ? "Yes" : "No")],
      ["Model ID", (m) => `<code>${esc(m.model_id)}</code>`]
    ];
    const table =
      `<table class="table rve-table"><caption>${esc(speciesName(state.species))} curves (maximum searched up to age ${AGE_LIMIT})</caption><thead><tr><th></th>` +
      scales.map((s) => `<th>${SCALE_LABELS[s]}${s === state.scale ? " (mapped)" : ""}</th>`).join("") +
      "</tr></thead><tbody>" +
      rows
        .map(([label, f]) => `<tr><th scope="row">${label}</th>` + scales.map((s) => `<td>${f(pair[s])}</td>`).join("") + "</tr>")
        .join("") +
      "</tbody></table>";

    els.curveInfo.innerHTML = `<div class="rve-curve-table">${table}</div>`;
  }

  // Validation ------------------------------------------------------------

  function scatterMetrics(points) {
    const n = points.length;
    if (n < 2) return null;
    const obs = points.map((d) => d.obs_mean);
    const pred = points.map((d) => d.pred_mean);
    const meanObs = d3.mean(obs);
    const meanPred = d3.mean(pred);
    let sxy = 0;
    let sxx = 0;
    let syy = 0;
    let sse = 0;
    let sd = 0;
    for (let i = 0; i < n; i++) {
      const dx = obs[i] - meanObs;
      const dy = pred[i] - meanPred;
      sxy += dx * dy;
      sxx += dx * dx;
      syy += dy * dy;
      sd += pred[i] - obs[i];
      sse += (pred[i] - obs[i]) ** 2;
    }
    const md = sd / n;
    const rmse = Math.sqrt(sse / n);
    // Lin's CCC with n - 1 denominators, matching yardstick::ccc().
    const cccDenom = sxx + syy + (n - 1) * (meanObs - meanPred) ** 2;
    return {
      ccc: cccDenom ? (2 * sxy) / cccDenom : NaN,
      rsq: sxx && syy ? (sxy * sxy) / (sxx * syy) : NaN,
      md,
      rmd: (md / meanObs) * 100,
      rmse,
      rrmse: (rmse / meanObs) * 100
    };
  }

  function renderValidationNote(models) {
    const group = `${SCALE_LABELS[state.scale].toLowerCase()} ${LEVEL_LABELS[state.level].toLowerCase()} ${esc(speciesName(state.species))} curves`;
    const nValidated = models.filter((m) => m.validated).length;
    let text =
      `Validation compares curves with independent ground plots (${esc(data.manifest.validation.reference)}). ` +
      `${nValidated} of ${models.length} ${group} had enough plots to be validated. ` +
      'See <a href="validation.html">Model validation</a> for the method.';
    if (state.strata) {
      const m = areaPair(state)[state.scale];
      if (m && m.validated) {
        const s = data.statsByKey.get(m.key);
        text += ` The selected curve was validated with ${fmt(",d", s && s.n_plots)} plots in ${fmt(",d", s && s.n_age_classes)} age classes.`;
      } else if (m) {
        text += " <strong>The selected curve was not validated</strong> because too few suitable plots were available in its area.";
      }
    }
    els.validationNote.innerHTML = `<p>${text}</p>`;
  }

  function renderScatter(models) {
    els.scatter.innerHTML = "";
    const points = [];
    for (const m of models) {
      if (!m.validated) continue;
      for (const a of data.ageByKey.get(m.key) || []) {
        if (
          Number.isFinite(a.obs_mean) &&
          Number.isFinite(a.pred_mean) &&
          a.obs_mean > 0 &&
          (state.response !== "agb" || a.obs_mean < 400)
        ) {
          points.push(Object.assign({ name: strataName(m.strata_id), strata_id: m.strata_id }, a));
        }
      }
    }
    if (points.length === 0) {
      els.scatter.innerHTML = '<div class="rve-empty">No validation points for this selection.</div>';
      return;
    }

    const metrics = scatterMetrics(points);
    const max =
      state.response === "volume"
        ? 800
        : niceUpper(d3.max(points, (d) => Math.max(d.obs_mean, d.pred_mean)));
    const selected = points.filter((d) => d.strata_id === state.strata);
    const metricText = metrics
      ? [
          `CCC: ${fmt(".2f", metrics.ccc)}`,
          `R2: ${fmt(".2f", metrics.rsq)}`,
          `bias: ${fmt(".2f", metrics.md)}`,
          `bias%: ${fmt(".2f", metrics.rmd)}`,
          `RMSE: ${fmt(".2f", metrics.rmse)}`,
          `RMSE%: ${fmt(".2f", metrics.rrmse)}`
        ].join("\n")
      : "";

    const plot = Plot.plot({
      width: 340,
      height: 340,
      marginLeft: 50,
      marginBottom: 40,
      style: { fontSize: "11px", background: "transparent" },
      x: { domain: [0, max], label: axisLabel("plot"), labelAnchor: "center", labelArrow: "none" },
      y: { domain: [0, max], label: axisLabel("rsyc"), labelAnchor: "center", labelArrow: "none" },
      marks: [
        Plot.frame(),
        Plot.line(
          [
            [0, 0],
            [max, max]
          ],
          { stroke: "grey", strokeWidth: 1 }
        ),
        Plot.dot(points, { x: "obs_mean", y: "pred_mean", r: 2.2, stroke: "black", strokeWidth: 0.8 }),
        Plot.dot(selected, { x: "obs_mean", y: "pred_mean", r: 3.2, fill: "red", stroke: "white", strokeWidth: 0.6 }),
        Plot.text([metricText], {
          frameAnchor: "top-left",
          dx: 8,
          dy: 8,
          lineAnchor: "top",
          textAnchor: "start",
          fontSize: 10
        }),
        Plot.tip(
          points,
          Plot.pointer({
            x: "obs_mean",
            y: "pred_mean",
            channels: {
              Area: "name",
              "Age class": (d) => `${d.age_class}–${d.age_class + 20}`
            },
            format: { x: ".1f", y: ".1f" }
          })
        )
      ]
    });
    plot.addEventListener("click", () => {
      if (plot.value && plot.value.strata_id) {
        setState({ strata: plot.value.strata_id });
      }
    });

    const caption = document.createElement("figcaption");
    caption.textContent =
      `All validated ${speciesName(state.species)} curves – ${SCALE_LABELS[state.scale]} – ${LEVEL_LABELS[state.level]}: ` +
      `${points.length} age-class points from ${new Set(points.map((d) => d.key)).size} curves` +
      (selected.length ? "; selected area in red." : ".");
    els.scatter.append(plot, caption);
  }

  function renderTables() {
    els.tables.innerHTML = "";
    if (!state.strata) return;
    const pair = areaPair(state);
    const scales = SCALES.filter((s) => pair[s]);
    if (!scales.some((s) => pair[s].validated)) return;

    const units = RESPONSES[state.response].units;
    const rows = [
      ["Validated", (m, s) => (m.validated ? "Yes" : "No")],
      ["Validation plots", (m, s) => fmt(",d", s && s.n_plots)],
      ["Age classes", (m, s) => fmt(",d", s && s.n_age_classes)],
      ["CCC", (m, s) => fmt(".2f", s && s.ccc)],
      ["R²", (m, s) => fmt(".2f", s && s.rsq)],
      [`Bias [${units}]`, (m, s) => fmt(".1f", s && s.md)],
      ["Bias (%)", (m, s) => fmt(".1f", s && s.rmd)],
      [`RMSE [${units}]`, (m, s) => fmt(".1f", s && s.rmse)],
      ["RMSE (%)", (m, s) => fmt(".1f", s && s.rrmse)],
      ["Age classes inside plot CI", (m, s) => fmt(".0%", s && s.prop_inside_ci)]
    ];
    const statsOf = (m) => (m.validated ? data.statsByKey.get(m.key) : null);

    const statsTable =
      `<table class='table rve-table'><caption>Selected area: ${esc(strataName(state.strata))}</caption><thead><tr><th></th>` +
      scales.map((s) => `<th>${SCALE_LABELS[s]}${s === state.scale ? " (mapped)" : ""}</th>`).join("") +
      "</tr></thead><tbody>" +
      rows
        .map(
          ([label, f]) =>
            `<tr><th scope="row">${label}</th>` +
            scales.map((s) => `<td>${f(pair[s], statsOf(pair[s]))}</td>`).join("") +
            "</tr>"
        )
        .join("") +
      "</tbody></table>";

    const selected = pair[state.scale];
    const ages = selected && selected.validated ? data.ageByKey.get(selected.key) || [] : [];
    const ageTable = ages.length
      ? "<details><summary>Age-class data (" + SCALE_LABELS[state.scale].toLowerCase() +
        " curve)</summary><table class='table rve-table'><thead><tr>" +
        "<th>Age class</th><th>Plots</th><th>Plot mean</th><th>95% CI</th><th>RSYC mean</th><th>Inside CI</th>" +
        "</tr></thead><tbody>" +
        ages
          .map(
            (a) =>
              `<tr><td>${a.age_class}–${a.age_class + 20}</td><td>${fmt(",d", a.n_plots)}</td>` +
              `<td>${fmt(".1f", a.obs_mean)}</td><td>${fmt(".1f", a.ci_lower)}–${fmt(".1f", a.ci_upper)}</td>` +
              `<td>${fmt(".1f", a.pred_mean)}</td><td>${a.inside_ci == null ? "–" : a.inside_ci ? "Yes" : "No"}</td></tr>`
          )
          .join("") +
        "</tbody></table></details>"
      : "";

    els.tables.innerHTML = statsTable + ageTable;
  }

  function renderDetailHeader() {
    if (!state.strata) {
      els.detailHeader.innerHTML = "";
      return;
    }
    const sp = data.species.get(state.species);
    const latin = sp && sp.scientific_name ? ` (<em>${esc(sp.scientific_name)}</em>)` : "";
    const path = String(state.strata).split("/");
    els.detailHeader.innerHTML =
      `<h3>${esc(path[path.length - 1])}</h3>` +
      (path.length > 1 ? `<div class="rve-path">${path.slice(0, -1).map(esc).join(" › ")}</div>` : "") +
      `<div class="rve-path">${RESPONSES[state.response].name} · ${esc(speciesName(state.species))}${latin} · ${LEVEL_LABELS[state.level]}</div>`;
  }

  // Render ----------------------------------------------------------------

  let renderToken = 0;

  function render() {
    renderToken += 1;
    const token = renderToken;
    hideTooltip();

    const form = els.controls.elements;
    fillSelect(form.response, Object.entries(RESPONSES).map(([k, v]) => [k, v.label]), state.response);
    fillSelect(form.scale, SCALES.map((s) => [s, SCALE_LABELS[s]]), state.scale);
    fillSelect(form.level, LEVELS.map((l) => [l, LEVEL_LABELS[l]]), state.level);
    fillSelect(
      form.species,
      speciesOptions(state.response).map((c) => [c, speciesName(c)]),
      state.species
    );
    fillMetricSelect(form.metric, state.metric);

    const models = selectionModels(state);
    const strataOptions = models
      .slice()
      .sort((a, b) => d3.ascending(strataName(a.strata_id), strataName(b.strata_id)))
      .map((m) => [m.strata_id, strataName(m.strata_id) + (m.validated ? "" : " (not validated)")]);
    fillSelect(els.strata, [["", "— none —"], ...strataOptions], state.strata || "");

    els.mapTitle.textContent =
      `${RESPONSES[state.response].label} | ${speciesName(state.species)} | ` +
      `${SCALE_LABELS[state.scale]} | ${LEVEL_LABELS[state.level]}`;

    renderMap(token).catch(showError);
    renderDetailHeader();
    renderCompare();
    renderCurves();
    renderValidationNote(models);
    renderScatter(models);
    renderTables();
  }

  function showError(error) {
    els.status.hidden = false;
    els.status.classList.add("rve-error");
    if (window.location.protocol === "file:") {
      els.status.innerHTML =
        "The curve explorer loads its data with the browser's fetch API, " +
        "which is blocked for pages opened directly from disk (<code>file://</code>). " +
        "Preview the site through a local web server instead, for example in R: " +
        '<code>servr::httd("docs")</code>, or view the published site.';
    } else {
      els.status.textContent = "Could not load the curve explorer: " + error.message;
    }
    console.error(error);
  }

  async function init() {
    if (typeof d3 === "undefined" || typeof Plot === "undefined") {
      throw new Error("d3 and Observable Plot must be loaded first.");
    }
    const versions = await getJSON("versions.json");
    const params = new URLSearchParams(window.location.hash.replace(/^#/, ""));
    const version =
      params.get("version") && versions.versions.includes(params.get("version"))
        ? params.get("version")
        : versions.latest;
    await loadBundle(version);
    state = readHash();
    validateState();

    els.status.hidden = true;
    els.body.hidden = false;
    render();

    // replaceState() in writeHash() does not fire hashchange, so this only
    // responds to links, edits in the address bar, and back/forward.
    window.addEventListener("hashchange", () => {
      state = readHash();
      validateState();
      writeHash();
      render();
    });
  }

  init().catch(showError);
})();
