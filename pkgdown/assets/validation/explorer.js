/* RSYC validation explorer.
 *
 * Renders the validation web bundle exported by
 * RSYC-Canada/R/5900_export_validation_web_bundle.R. The bundle version is
 * read from versions.json next to this script. Figure styling follows the
 * RSYC-Canada validation figures (5210 scatterplots, 5240 curves vs plots,
 * 5270 metric maps).
 *
 * Requires d3 (v7) and Observable Plot (v0.6) as globals.
 */
(function () {
  "use strict";

  const root = document.getElementById("rsyc-validation-explorer");
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

  const METRICS = {
    rsq: { label: "R²", kind: "sequential", format: ".2f", domain: [0, 1] },
    rmd: { label: "Bias (%)", kind: "diverging", format: ".1f", suffix: "%" },
    md: { label: "Bias", kind: "diverging", format: ".1f", units: true },
    rrmse: { label: "RMSE (%)", kind: "sequential", format: ".1f", suffix: "%" },
    rmse: { label: "RMSE", kind: "sequential", format: ".1f", units: true },
    prop_inside_ci: {
      label: "Age classes inside plot CI",
      kind: "sequential",
      format: ".0%",
      domain: [0, 1]
    },
    n_plots: { label: "Validation plots", kind: "sqrt", format: ",d" }
  };

  const DEFAULT_STATE = {
    response: "agb",
    scale: "national",
    level: "ecoregion",
    species: "generic",
    metric: "rsq",
    strata: null
  };

  const keyOf = (...parts) => parts.join("|");
  const fmt = (spec, v) =>
    v == null || Number.isNaN(v) ? "–" : d3.format(spec)(v);

  // Data ------------------------------------------------------------------

  const data = {
    version: null,
    manifest: null,
    species: new Map(),
    models: [],
    modelsByKey: new Map(),
    statsByKey: new Map(),
    ageByKey: new Map(),
    groups: new Map(),
    strata: new Map(),
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
    data.modelsByKey = new Map(data.models.map((m) => [m.key, m]));
    data.statsByKey = new Map(columnsToRows(stats).map((s) => [s.key, s]));
    data.ageByKey = d3.group(columnsToRows(age), (a) => a.key);
    data.groups = d3.group(data.models, (m) =>
      keyOf(m.response, m.scale, m.parameter_level, m.species)
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

  function speciesOptions(response) {
    const codes = new Set(
      data.models
        .filter((m) => m.response === response && m.validated)
        .map((m) => m.species)
    );
    const groups = ["generic", "coniferous", "broadleaf"].filter((c) => codes.has(c));
    const species = [...codes]
      .filter((c) => !groups.includes(c))
      .sort((a, b) => d3.ascending(speciesName(a), speciesName(b)));
    return [...groups, ...species];
  }

  function selectionModels(state) {
    return (
      data.groups.get(
        keyOf(state.response, state.scale, state.level, state.species)
      ) || []
    );
  }

  function metricValue(stats, metric) {
    return stats ? stats[metric] : null;
  }

  // Shared colour domain across scales and levels for the response and
  // species, so maps remain comparable when switching level or scale.
  function colorScale(state) {
    const spec = METRICS[state.metric];
    const values = data.models
      .filter(
        (m) =>
          m.validated &&
          m.response === state.response &&
          m.species === state.species
      )
      .map((m) => metricValue(data.statsByKey.get(m.key), state.metric))
      .filter((v) => v != null && Number.isFinite(v));

    let scale;
    if (spec.kind === "diverging") {
      const limit =
        d3.quantile(values.map(Math.abs).sort(d3.ascending), 0.95) || 1;
      const L = d3.scaleLinear().domain([0, limit]).nice().domain()[1];
      scale = d3
        .scaleDiverging(d3.interpolateRgbBasis(["#2C7BB6", "#F7F7F7", "#D7191C"]))
        .domain([-L, 0, L])
        .clamp(true);
    } else {
      let domain = spec.domain;
      if (!domain) {
        const upper = d3.quantile(values.slice().sort(d3.ascending), 0.95) || 1;
        domain = [0, d3.scaleLinear().domain([0, upper]).nice().domain()[1]];
      }
      scale = (spec.kind === "sqrt" ? d3.scaleSequentialSqrt : d3.scaleSequential)(
        d3.interpolateViridis
      )
        .domain(domain)
        .clamp(true);
    }
    return scale;
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
      if (state[k] != null) params.set(k, state[k]);
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
  }

  // Layout ----------------------------------------------------------------

  root.innerHTML = `
    <div class="rve-status">Loading validation data…</div>
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
      <div class="rve-detail">
        <div class="rve-detail-header"></div>
        <div class="rve-charts">
          <figure class="rve-curve"></figure>
          <figure class="rve-scatter"></figure>
        </div>
        <div class="rve-tables"></div>
      </div>
      <p class="rve-footer"></p>
    </div>
    <div class="rve-tooltip" hidden></div>`;

  const els = {
    status: root.querySelector(".rve-status"),
    body: root.querySelector(".rve-body"),
    controls: root.querySelector(".rve-controls"),
    mapTitle: root.querySelector(".rve-map-title"),
    map: root.querySelector(".rve-map"),
    reset: root.querySelector(".rve-reset"),
    legend: root.querySelector(".rve-legend"),
    mapSummary: root.querySelector(".rve-map-summary"),
    strata: root.querySelector("select[name=strata]"),
    detailHeader: root.querySelector(".rve-detail-header"),
    curve: root.querySelector(".rve-curve"),
    scatter: root.querySelector(".rve-scatter"),
    tables: root.querySelector(".rve-tables"),
    footer: root.querySelector(".rve-footer"),
    tooltip: root.querySelector(".rve-tooltip")
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

  els.controls.addEventListener("change", (event) => {
    const { name, value } = event.target;
    setState({ [name]: value });
  });
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
    .attr("aria-label", "Map of validation results");
  const zoomLayer = svg.append("g");
  const baseLayer = zoomLayer.append("g").attr("class", "rve-base");
  const unitLayer = zoomLayer.append("g").attr("class", "rve-units");
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

  function formatMetric(metric, value) {
    const spec = METRICS[metric];
    let text = fmt(spec.format, value);
    if (value != null && spec.suffix) text += spec.suffix;
    if (value != null && spec.units) text += " " + RESPONSES[state.response].units;
    return text;
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

    const fillFor = (feature) => {
      const m = models.get(feature.properties.strata_id);
      if (!m) return COLOR_NO_MODEL;
      if (!m.validated) return COLOR_NOT_VALIDATED;
      const v = metricValue(data.statsByKey.get(m.key), state.metric);
      if (v == null || (typeof v === "number" && !Number.isFinite(v))) return COLOR_NA;
      return color(v);
    };

    unitLayer
      .selectAll("path")
      .data(layer.features, (f) => f.properties.strata_id)
      .join("path")
      .attr("d", geoPath)
      .attr("fill", fillFor)
      .classed("rve-validated", (f) => {
        const m = models.get(f.properties.strata_id);
        return Boolean(m && m.validated);
      })
      .classed("rve-selected", (f) => f.properties.strata_id === state.strata)
      .on("mousemove", (event, f) => {
        const m = models.get(f.properties.strata_id);
        let html = `<strong>${f.properties.name}</strong>`;
        if (!m) {
          html += "<br>No model";
        } else if (!m.validated) {
          html += "<br>Model not validated";
        } else {
          const s = data.statsByKey.get(m.key);
          html +=
            `<br>${METRICS[state.metric].label}: ${formatMetric(state.metric, metricValue(s, state.metric))}` +
            `<br>Plots: ${fmt(",d", s.n_plots)}`;
        }
        showTooltip(event, html);
      })
      .on("mouseleave", hideTooltip)
      .on("click", (event, f) => {
        const m = models.get(f.properties.strata_id);
        if (m) setState({ strata: f.properties.strata_id });
      });
    unitLayer.selectAll("path.rve-selected").raise();

    renderLegend(color);

    const all = [...models.values()];
    const validated = all.filter((m) => m.validated);
    const missingGeometry = validated.filter(
      (m) => !layer.features.some((f) => f.properties.strata_id === m.strata_id)
    ).length;
    els.mapSummary.textContent = all.length
      ? `Models available in ${all.length} of ${layer.features.length} ` +
        `${LEVEL_LABELS[state.level].toLowerCase()}s; ${validated.length} validated.` +
        (missingGeometry ? ` ${missingGeometry} validated area(s) have no map geometry.` : "") +
        " Click an area to see its validation data."
      : `There are no ${SCALE_LABELS[state.scale].toLowerCase()} ` +
        `${LEVEL_LABELS[state.level].toLowerCase()} ${RESPONSES[state.response].label} ` +
        `models for ${speciesName(state.species)}. Try another scale or spatial level.`;
  }

  function renderLegend(color) {
    const spec = METRICS[state.metric];
    els.legend.innerHTML = "";
    const legend = d3.select(els.legend);
    const title = spec.units
      ? `${spec.label} [${RESPONSES[state.response].units}]`
      : spec.label;

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
    const axisScale = (spec.kind === "sqrt" ? d3.scaleSqrt() : d3.scaleLinear())
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
      .attr("fill", (i) =>
        color(axisScale.invert(15 + ((i + 0.5) * width) / steps))
      );
    const tickFormat = spec.format.includes("%")
      ? d3.format(".0%")
      : d3.format(spec.kind === "sqrt" ? ",d" : "~g");
    ramp
      .append("g")
      .attr("transform", "translate(0,26)")
      .call(d3.axisBottom(axisScale).ticks(5).tickSize(4).tickFormat(tickFormat))
      .call((g) => g.select(".domain").remove());

    const extra = legend.append("div").attr("class", "rve-swatches");
    for (const [label, fill] of [
      ["No model", COLOR_NO_MODEL],
      ["Model not validated", COLOR_NOT_VALIDATED]
    ]) {
      const item = extra.append("span").attr("class", "rve-swatch");
      item.append("i").style("background", fill);
      item.append("span").text(label);
    }
  }

  // Detail: curve vs plots (5240) and scatterplot (5210) --------------------

  function curvePoints(model) {
    return d3.range(0, 151, 1).map((age) => ({
      age,
      y:
        model.b1 *
        Math.exp(-model.b4 * age) *
        Math.pow(1 - Math.exp(-model.b2 * age), model.b3),
      scale: model.scale
    }));
  }

  function axisLabel(kind) {
    const r = RESPONSES[state.response];
    if (kind === "plot") return `${r.label} plot [${r.units}]`;
    if (kind === "rsyc") return `${r.label} RSYC [${r.units}]`;
    return `${r.label} [${r.units}]`;
  }

  function renderCurve(models) {
    els.curve.innerHTML = "";
    if (!state.strata) {
      els.curve.innerHTML =
        '<div class="rve-empty">Select an area on the map to compare its curves with the validation plots.</div>';
      return;
    }
    const pair = data.strata.get(
      keyOf(state.response, state.level, state.species, state.strata)
    ) || {};
    const selected = models.find((m) => m.strata_id === state.strata);
    const ages = selected ? data.ageByKey.get(selected.key) || [] : [];
    const reference = ages.map((a) => Object.assign({ x: a.age_class + 10 }, a));
    const curves = SCALES.filter((s) => pair[s]).map((s) => curvePoints(pair[s]));

    const ymax = Math.max(
      RESPONSES[state.response].ymax,
      d3.max(reference, (d) => d.ci_upper) || 0,
      d3.max(curves.flat(), (d) => d.y) || 0
    );

    const marks = [
      Plot.frame(),
      Plot.ruleX(reference, {
        x: "x",
        y1: "ci_lower",
        y2: "ci_upper",
        stroke: "red",
        strokeWidth: 1
      }),
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
      })
    ];
    for (const curve of curves) {
      marks.push(
        Plot.line(curve, {
          x: "age",
          y: "y",
          stroke: "black",
          strokeWidth: 1.5,
          strokeDasharray: curve[0].scale === "regional" ? "6,4" : null
        })
      );
    }

    const plot = Plot.plot({
      width: 420,
      height: 320,
      marginLeft: 50,
      marginBottom: 40,
      style: { fontSize: "11px", background: "transparent" },
      x: { domain: [0, 150], ticks: [10, 50, 90, 130], label: "Age class", labelAnchor: "center", labelArrow: "none" },
      y: { domain: [0, ymax], label: axisLabel(), labelAnchor: "center", labelArrow: "none", nice: true },
      marks
    });

    const caption = document.createElement("figcaption");
    const scaleKeys = SCALES.filter((s) => pair[s]);
    caption.innerHTML =
      '<span class="rve-key"><svg width="22" height="10"><line x1="0" y1="5" x2="22" y2="5" stroke="red"/><circle cx="11" cy="5" r="3" fill="red"/></svg> Plot mean and 95% CI</span>' +
      scaleKeys
        .map(
          (s) =>
            `<span class="rve-key"><svg width="26" height="10"><line x1="0" y1="5" x2="26" y2="5" stroke="black" stroke-width="1.5" ${s === "regional" ? 'stroke-dasharray="6,4"' : ""}/></svg> ${SCALE_LABELS[s]} curve</span>`
        )
        .join("");
    els.curve.append(plot, caption);
  }

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
    return {
      rsq: sxx && syy ? (sxy * sxy) / (sxx * syy) : NaN,
      md,
      rmd: (md / meanObs) * 100,
      rmse,
      rrmse: (rmse / meanObs) * 100
    };
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
          points.push(
            Object.assign({ name: strataName(m.strata_id), strata_id: m.strata_id }, a)
          );
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
        : d3.scaleLinear()
            .domain([0, d3.max(points, (d) => Math.max(d.obs_mean, d.pred_mean))])
            .nice()
            .domain()[1];
    const selected = points.filter((d) => d.strata_id === state.strata);
    const metricText = metrics
      ? [
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
        Plot.dot(points, {
          x: "obs_mean",
          y: "pred_mean",
          r: 2.2,
          stroke: "black",
          strokeWidth: 0.8
        }),
        Plot.dot(selected, {
          x: "obs_mean",
          y: "pred_mean",
          r: 3.2,
          fill: "red",
          stroke: "white",
          strokeWidth: 0.6
        }),
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
      `${speciesName(state.species)} – ${SCALE_LABELS[state.scale]} – ${LEVEL_LABELS[state.level]}: ` +
      `${points.length} age-class points from ${new Set(points.map((d) => d.key)).size} curves` +
      (selected.length ? "; selected area in red." : ".");
    els.scatter.append(plot, caption);
  }

  function renderTables() {
    els.tables.innerHTML = "";
    if (!state.strata) return;
    const pair = data.strata.get(
      keyOf(state.response, state.level, state.species, state.strata)
    ) || {};
    const scales = SCALES.filter((s) => pair[s]);
    if (!scales.length) return;

    const units = RESPONSES[state.response].units;
    const rows = [
      ["Validated", (m, s) => (m.validated ? "Yes" : "No")],
      ["Validation plots", (m, s) => fmt(",d", s && s.n_plots)],
      ["Age classes", (m, s) => fmt(",d", s && s.n_age_classes)],
      ["R²", (m, s) => fmt(".2f", s && s.rsq)],
      [`Bias [${units}]`, (m, s) => fmt(".1f", s && s.md)],
      ["Bias (%)", (m, s) => fmt(".1f", s && s.rmd)],
      [`RMSE [${units}]`, (m, s) => fmt(".1f", s && s.rmse)],
      ["RMSE (%)", (m, s) => fmt(".1f", s && s.rrmse)],
      ["MAPE (%)", (m, s) => fmt(".1f", s && s.mape)],
      ["Age classes inside plot CI", (m, s) => fmt(".0%", s && s.prop_inside_ci)],
      ["b1", (m) => fmt(".4~g", m.b1)],
      ["b2", (m) => fmt(".4~g", m.b2)],
      ["b3", (m) => fmt(".4~g", m.b3)],
      ["b4", (m) => fmt(".4~g", m.b4)],
      ["Model ID", (m) => `<code>${m.model_id}</code>`]
    ];

    const statsTable =
      "<table class='table rve-table'><thead><tr><th></th>" +
      scales.map((s) => `<th>${SCALE_LABELS[s]}${s === state.scale ? " (mapped)" : ""}</th>`).join("") +
      "</tr></thead><tbody>" +
      rows
        .map(
          ([label, f]) =>
            `<tr><th scope="row">${label}</th>` +
            scales
              .map((s) => `<td>${f(pair[s], data.statsByKey.get(pair[s].key))}</td>`)
              .join("") +
            "</tr>"
        )
        .join("") +
      "</tbody></table>";

    const selected = pair[state.scale];
    const ages = selected ? data.ageByKey.get(selected.key) || [] : [];
    const ageTable = ages.length
      ? "<details><summary>Age-class data (" + SCALE_LABELS[state.scale].toLowerCase() +
        " model)</summary><table class='table rve-table'><thead><tr>" +
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
    const sp = data.species.get(state.species);
    const latin = sp && sp.scientific_name ? ` (<em>${sp.scientific_name}</em>)` : "";
    if (!state.strata) {
      els.detailHeader.innerHTML = "";
      return;
    }
    const path = String(state.strata).split("/");
    els.detailHeader.innerHTML =
      `<h3>${path[path.length - 1]}</h3>` +
      (path.length > 1 ? `<div class="rve-path">${path.slice(0, -1).join(" › ")}</div>` : "") +
      `<div class="rve-path">${RESPONSES[state.response].name} · ${speciesName(state.species)}${latin} · ${LEVEL_LABELS[state.level]}</div>`;
  }

  // Render ----------------------------------------------------------------

  let renderToken = 0;

  function render() {
    renderToken += 1;
    const token = renderToken;
    hideTooltip();

    fillSelect(
      els.controls.elements.response,
      Object.entries(RESPONSES).map(([k, v]) => [k, v.label]),
      state.response
    );
    fillSelect(
      els.controls.elements.scale,
      SCALES.map((s) => [s, SCALE_LABELS[s]]),
      state.scale
    );
    fillSelect(
      els.controls.elements.level,
      LEVELS.map((l) => [l, LEVEL_LABELS[l]]),
      state.level
    );
    fillSelect(
      els.controls.elements.species,
      speciesOptions(state.response).map((c) => [c, speciesName(c)]),
      state.species
    );
    fillSelect(
      els.controls.elements.metric,
      Object.entries(METRICS).map(([k, v]) => [k, v.label]),
      state.metric
    );

    const models = selectionModels(state);
    const strataOptions = models
      .slice()
      .sort((a, b) => d3.ascending(strataName(a.strata_id), strataName(b.strata_id)))
      .map((m) => [
        m.strata_id,
        strataName(m.strata_id) + (m.validated ? "" : " (not validated)")
      ]);
    fillSelect(els.strata, [["", "— none —"], ...strataOptions], state.strata || "");

    els.mapTitle.textContent =
      `${RESPONSES[state.response].label} | ${speciesName(state.species)} | ` +
      `${SCALE_LABELS[state.scale]} | ${LEVEL_LABELS[state.level]}`;

    renderMap(token).catch(showError);
    renderDetailHeader();
    renderCurve(models);
    renderScatter(models);
    renderTables();
  }

  function showError(error) {
    els.status.hidden = false;
    els.status.classList.add("rve-error");
    if (window.location.protocol === "file:") {
      els.status.innerHTML =
        "The validation explorer loads its data with the browser's fetch API, " +
        "which is blocked for pages opened directly from disk (<code>file://</code>). " +
        "Preview the site through a local web server instead, for example in R: " +
        '<code>servr::httd("docs")</code>, or view the published site.';
    } else {
      els.status.textContent = "Could not load the validation explorer: " + error.message;
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

    const m = data.manifest;
    els.footer.innerHTML =
      `Model release <code>${m.model_version}</code>; validation bundle built ` +
      `${m.build_time.slice(0, 10)} from RSYC-Canada commit <code>${String(m.git_commit).slice(0, 7)}</code>. ` +
      `Reference data: ${m.validation.reference}. ${m.counts.validated_models.toLocaleString()} of ` +
      `${m.counts.models.toLocaleString()} curves validated.`;

    els.status.hidden = true;
    els.body.hidden = false;
    render();
  }

  init().catch(showError);
})();
