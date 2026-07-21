/*
 * OASF Taxonomy Builder — fully data-driven.
 *
 * Everything the UI knows comes from module.taxonomy.yaml:
 *   - the palette blocks               (from `modules`)
 *   - the drag-and-drop nesting rules  (derived generically from `role`/`kind`)
 *   - the natural-language translation  (from `kinds` + `language` + phrase/attach)
 *
 * There are NO hard-coded module names here, so editing the YAML and hitting
 * "Reload taxonomy" is enough to add/rename/remove blocks and their meaning.
 */

const YAML_URL = "module.taxonomy.yaml";

// ---- taxonomy state (filled from YAML) ------------------------------------
let TAX = null;                 // full parsed YAML
let DEFS = {};                  // type -> module def
let KINDS = {};                 // kind id -> kind def
let LANG = { connectors: {} };  // language block

// ---- record state ----------------------------------------------------------
let TREE = { id: "root", type: "__root__", children: [] };
let idSeq = 0;
let DRAG = null;                // { type }

// ===========================================================================
// Loading
// ===========================================================================
async function loadTaxonomy() {
  try {
    const res = await fetch(YAML_URL, { cache: "no-store" });
    if (!res.ok) throw new Error("HTTP " + res.status);
    applyTaxonomy(jsyaml.load(await res.text()));
    document.getElementById("loadError").hidden = true;
  } catch (err) {
    console.warn("fetch failed, offering file picker:", err);
    document.getElementById("loadError").hidden = false;
  }
}

function applyTaxonomy(parsed) {
  TAX = parsed;
  KINDS = parsed.kinds || {};
  LANG = parsed.language || { connectors: {} };
  LANG.connectors = LANG.connectors || {};
  DEFS = {};
  (parsed.modules || []).forEach((m) => (DEFS[m.type] = m));
  renderPalette();
  render();
}

// ===========================================================================
// Nesting rules — generic, based purely on role/kind (no type literals)
// ===========================================================================
function roleOf(type) { return DEFS[type] ? DEFS[type].role : undefined; }
function kindOf(type) { return DEFS[type] ? DEFS[type].kind : undefined; }

// Can a `childType` be dropped inside a node of `parentType`?
function canAccept(parentType, childType) {
  const c = DEFS[childType];
  if (!c) return false;
  const cr = c.role;

  if (parentType === "__root__") {
    // The record holds exactly ONE top-level item (an owner or collection).
    // Everything else must be nested inside that item, not dropped at the root.
    return TREE.children.length === 0 && (cr === "owner" || cr === "collection");
  }
  const p = DEFS[parentType];
  if (!p) return false;

  switch (p.role) {
    case "owner":
      // its own kind's interfaces/payloads, any trait, plus sub-records of
      // kinds this kind is allowed to contain (cross-kind composition)
      return (
        ((cr === "interface" || cr === "payload") && c.kind === p.kind) ||
        cr === "trait" ||
        (cr === "owner" && (KINDS[p.kind]?.contains || []).includes(c.kind))
      );
    case "collection":
      // members are entry-wrapped owners of the same kind
      return cr === "owner" && c.kind === p.kind;
    case "interface":
    case "payload":
      return cr === "trait";
    default:
      return false; // traits are leaves
  }
}

function isContainer(type) {
  if (type === "__root__") return true;
  const r = roleOf(type);
  return r === "owner" || r === "collection" || r === "interface" || r === "payload";
}

// ===========================================================================
// Tree helpers
// ===========================================================================
function findNode(id, node = TREE) {
  if (node.id === id) return node;
  for (const ch of node.children) {
    const hit = findNode(id, ch);
    if (hit) return hit;
  }
  return null;
}
function removeNode(id, node = TREE) {
  const i = node.children.findIndex((c) => c.id === id);
  if (i >= 0) { node.children.splice(i, 1); return true; }
  return node.children.some((c) => removeNode(id, c));
}
function addNode(parentId, type) {
  const parent = findNode(parentId);
  if (!parent) return;
  parent.children.push({ id: "n" + ++idSeq, type, children: [] });
  render();
}

// ===========================================================================
// Palette
// ===========================================================================
function renderPalette() {
  const host = document.getElementById("palette");
  host.innerHTML = "";

  // Group order: each kind (in declared order), then a Traits group.
  const groups = [];
  Object.keys(KINDS).forEach((k) =>
    groups.push({ key: k, label: KINDS[k].label + " blocks", test: (m) => m.kind === k && m.role !== "trait" })
  );
  groups.push({ key: "trait", label: "Traits (attach anywhere)", test: (m) => m.role === "trait" });

  groups.forEach((g) => {
    const mods = (TAX.modules || []).filter(g.test);
    if (!mods.length) return;
    const wrap = document.createElement("div");
    wrap.className = "palette-group";
    wrap.innerHTML = `<div class="group-label">${g.label}</div>`;
    mods.forEach((m) => wrap.appendChild(paletteBlock(m)));
    host.appendChild(wrap);
  });
}

function paletteBlock(m) {
  const el = document.createElement("div");
  el.className = "block " + (m.role === "trait" ? "k-trait" : "k-" + m.kind);
  el.draggable = true;
  el.innerHTML = `
    <span class="b-label">${m.label}</span>
    <span class="b-type">${m.type}</span>
    ${m.hint ? `<span class="b-hint">${m.hint}</span>` : ""}`;
  el.addEventListener("dragstart", (e) => {
    DRAG = { type: m.type };
    e.dataTransfer.setData("text/plain", m.type);
    e.dataTransfer.effectAllowed = "copy";
  });
  return el;
}

// ===========================================================================
// Record rendering
// ===========================================================================
function render() {
  const root = document.getElementById("record");
  root.innerHTML = "";
  if (TREE.children.length === 0) {
    root.innerHTML =
      '<p class="placeholder">Drag an <strong>Agent</strong>, <strong>Model</strong> or <strong>Resource</strong> block here.</p>';
  } else {
    TREE.children.forEach((n) => root.appendChild(renderNode(n)));
  }
  translate();
  emitJson();
}

function renderNode(node) {
  const def = DEFS[node.type] || { label: node.type, fields: [] };
  const el = document.createElement("div");
  el.className = "node r-" + (def.role || "unknown");
  if (def.kind) el.dataset.kind = def.kind;

  const head = document.createElement("div");
  head.className = "node-head";
  head.innerHTML = `
    <span class="n-label">${def.label || node.type}</span>
    <span class="n-type">${node.type}</span>`;
  const rm = document.createElement("button");
  rm.className = "rm";
  rm.textContent = "\u00d7";
  rm.title = "Remove";
  rm.addEventListener("click", () => { removeNode(node.id); render(); });
  head.appendChild(rm);
  el.appendChild(head);

  if (def.fields && def.fields.length) {
    const f = document.createElement("div");
    f.className = "n-fields";
    f.textContent = "data: " + def.fields.join(", ");
    el.appendChild(f);
  }

  if (isContainer(node.type)) {
    const zone = document.createElement("div");
    zone.className = "dropzone children";
    zone.dataset.nodeId = node.id;
    zone.dataset.type = node.type;
    node.children.forEach((ch) => zone.appendChild(renderNode(ch)));
    el.appendChild(zone);
  }
  return el;
}

// ===========================================================================
// Drag & drop (event-delegated, works with dynamically rendered nodes)
// ===========================================================================
function clearHighlights() {
  document.querySelectorAll(".dropzone.drag-over").forEach((z) => z.classList.remove("drag-over"));
}

// Resolve the drop target: start at the zone under the cursor and walk UP the
// nesting until we find a dropzone that accepts the dragged block. This lets
// e.g. a resource dropped anywhere inside a model "fall through" the language
// payload (which only takes traits) onto the model owner that does accept it.
function acceptingZone(target, type) {
  let zone = target.closest(".dropzone");
  while (zone) {
    if (canAccept(zone.dataset.type, type)) return zone;
    zone = zone.parentElement ? zone.parentElement.closest(".dropzone") : null;
  }
  return null;
}

// Auto-scroll the window while dragging near the viewport edges. Native HTML5
// drag doesn't reliably auto-scroll, so we drive it from a RAF loop that reads
// the last pointer Y (kept fresh by dragover, which fires even while hovering).
const EDGE = 80;        // px zone at top/bottom that triggers scrolling
const MAX_SPEED = 22;   // px per frame at the very edge
let dragY = null;
let autoScrollRAF = null;
function autoScrollTick() {
  if (dragY == null) { autoScrollRAF = null; return; }
  const h = window.innerHeight;
  let dy = 0;
  if (dragY < EDGE) dy = -MAX_SPEED * (1 - dragY / EDGE);
  else if (dragY > h - EDGE) dy = MAX_SPEED * (1 - (h - dragY) / EDGE);
  if (dy) window.scrollBy(0, dy);
  autoScrollRAF = requestAnimationFrame(autoScrollTick);
}
function startAutoScroll() {
  if (autoScrollRAF == null) autoScrollRAF = requestAnimationFrame(autoScrollTick);
}
function stopAutoScroll() {
  dragY = null;
  if (autoScrollRAF != null) { cancelAnimationFrame(autoScrollRAF); autoScrollRAF = null; }
}

document.addEventListener("dragover", (e) => {
  if (!DRAG) return;
  dragY = e.clientY;
  startAutoScroll();
  const zone = acceptingZone(e.target, DRAG.type);
  clearHighlights();
  if (zone) {
    e.preventDefault();
    e.dataTransfer.dropEffect = "copy";
    zone.classList.add("drag-over");
  }
});
document.addEventListener("drop", (e) => {
  const zone = DRAG ? acceptingZone(e.target, DRAG.type) : null;
  clearHighlights();
  stopAutoScroll();
  if (zone && DRAG) {
    e.preventDefault();
    addNode(zone.dataset.nodeId, DRAG.type);
  }
  DRAG = null;
});
document.addEventListener("dragend", () => { clearHighlights(); stopAutoScroll(); DRAG = null; });

// ===========================================================================
// Translation — data-driven from kinds + language + phrase/attach
// ===========================================================================
function conn(k) { return LANG.connectors[k] || ""; }
function attachText(node) {
  const d = DEFS[node.type];
  return (d && (d.attach || d.phrase || d.label)) || node.type;
}
function traitChildren(node) { return node.children.filter((c) => roleOf(c.type) === "trait"); }
function partChildren(node) {
  return node.children.filter((c) => ["interface", "payload"].includes(roleOf(c.type)));
}

// "MCP protocol reachable via artifact"
function partClause(part) {
  const d = DEFS[part.type];
  const base = (d && (d.phrase || d.label)) || part.type;
  const traits = traitChildren(part).map(attachText);
  return traits.length ? base + " " + traits.join(" " + conn("and") + " ") : base;
}

// body of an owner: " with <parts> and is <ownerTraits> including <sub-records>"
function ownerBody(owner) {
  const parts = partChildren(owner).map(partClause);
  const traits = traitChildren(owner).map(attachText);
  const subs = subOwnerChildren(owner).map(memberInline);
  let out = "";
  if (parts.length) out += " " + conn("with") + " " + parts.join(" " + conn("and") + " ");
  if (traits.length) {
    const glue = parts.length ? " " + conn("and") + " " + conn("is") + " " : " " + conn("is") + " ";
    out += glue + traits.join(conn("listSep"));
  }
  if (subs.length) out += " " + conn("includes") + " " + subs.join(conn("memberSep"));
  return out;
}

function memberInline(owner) {
  const k = KINDS[kindOf(owner.type)] || {};
  return (k.memberPhrase || "an item") + ownerBody(owner);
}

// nested sub-records of other kinds attached to an owner
function subOwnerChildren(node) {
  return node.children.filter(
    (c) => roleOf(c.type) === "owner" && kindOf(c.type) !== kindOf(node.type)
  );
}

function describeRecord() {
  const primary = TREE.children.find((n) => ["owner", "collection"].includes(roleOf(n.type)));
  const looseParts = TREE.children.filter((n) => ["interface", "payload"].includes(roleOf(n.type)));
  const recordTraits = TREE.children.filter((n) => roleOf(n.type) === "trait");

  if (!primary && !looseParts.length && !recordTraits.length) return LANG.empty || "Empty record.";

  let s = "";
  if (primary && roleOf(primary.type) === "owner") {
    s = (KINDS[kindOf(primary.type)] || {}).entryPhrase || "A record";
    s += ownerBody(primary);
  } else if (primary && roleOf(primary.type) === "collection") {
    const k = KINDS[kindOf(primary.type)] || {};
    s = k.catalogPhrase || "A set of records";
    const members = primary.children.filter((n) => roleOf(n.type) === "owner");
    if (members.length) s += " " + conn("memberJoin") + " " + members.map(memberInline).join(conn("memberSep"));
    // traits attached directly to the collection describe the whole record
    const cTraits = traitChildren(primary);
    if (cTraits.length) s += conn("listSep") + conn("recordTrait") + " " + cTraits.map(attachText).join(conn("listSep"));
  } else if (looseParts.length) {
    // entry-default: parts dropped straight on the record
    const k = KINDS[kindOf(looseParts[0].type)] || {};
    s = k.entryPhrase || "A record";
    s += " " + conn("with") + " " + looseParts.map(partClause).join(" " + conn("and") + " ");
  }

  if (recordTraits.length) {
    s += (s ? conn("listSep") : "") + conn("recordTrait") + " " + recordTraits.map(attachText).join(conn("listSep"));
  }
  return s.replace(/\s+/g, " ").trim() + ".";
}

function translate() {
  document.getElementById("translation").textContent = describeRecord();
}

// ===========================================================================
// JSON output — faithful nested modules skeleton
// ===========================================================================
function nodeToModule(node) {
  const def = DEFS[node.type] || {};
  const m = { type: node.type };
  if (def.fields && def.fields.length) {
    m.data = {};
    def.fields.forEach((f) => (m.data[f] = null));
  }
  if (node.children.length) m.modules = node.children.map(nodeToModule);
  return m;
}
function emitJson() {
  // New schema: promote the single owner/collection to the record root — its
  // `type` sits alongside the metadata and its children become `modules`.
  const primary = TREE.children.find((n) => ["owner", "collection"].includes(roleOf(n.type)));
  let record;
  if (primary) {
    const extraTraits = TREE.children.filter((n) => n !== primary && roleOf(n.type) === "trait");
    record = {
      schema_version: "v1",
      name: "",
      type: primary.type,
      modules: primary.children.concat(extraTraits).map(nodeToModule),
    };
  } else {
    record = { schema_version: "v1", name: "", modules: TREE.children.map(nodeToModule) };
  }
  document.getElementById("jsonOut").textContent = JSON.stringify(record, null, 2);
}

// ===========================================================================
// Examples — load ready-made records from examples/ and fill the record
// ===========================================================================
const EXAMPLES_DIR = "examples/";

async function loadExampleList() {
  const sel = document.getElementById("examples");
  try {
    const res = await fetch(EXAMPLES_DIR + "index.json", { cache: "no-store" });
    if (!res.ok) throw new Error("HTTP " + res.status);
    const list = (await res.json()).examples || [];
    list.forEach((ex) => {
      const opt = document.createElement("option");
      opt.value = ex.file;
      opt.textContent = ex.label;
      sel.appendChild(opt);
    });
  } catch (err) {
    console.warn("examples unavailable (needs a server):", err);
    sel.disabled = true;
    sel.title = "Examples need the folder served over http, e.g. python3 -m http.server";
  }
}

// Turn an example record's module list into record TREE nodes.
function moduleToNode(m) {
  return { id: "n" + ++idSeq, type: m.type, children: (m.modules || []).map(moduleToNode) };
}

async function loadExample(file) {
  try {
    const res = await fetch(EXAMPLES_DIR + file, { cache: "no-store" });
    if (!res.ok) throw new Error("HTTP " + res.status);
    const record = await res.json();
    // New schema: the record itself is the root node — its `type` is the
    // owner/collection and `modules` are that node's children.
    const rootNode = {
      id: "n" + ++idSeq,
      type: record.type,
      children: (record.modules || []).map(moduleToNode),
    };
    TREE = { id: "root", type: "__root__", children: record.type ? [rootNode] : rootNode.children };
    render();
  } catch (err) {
    alert("Failed to load example: " + err.message);
  }
}

// ===========================================================================
// Wiring
// ===========================================================================
document.getElementById("reload").addEventListener("click", loadTaxonomy);
document.getElementById("clear").addEventListener("click", () => {
  TREE = { id: "root", type: "__root__", children: [] };
  render();
});
document.getElementById("examples").addEventListener("change", (e) => {
  const file = e.target.value;
  if (file) loadExample(file);
  e.target.selectedIndex = 0; // reset back to the "Examples…" label
});
document.getElementById("pickFile").addEventListener("click", () =>
  document.getElementById("fileInput").click()
);
document.getElementById("fileInput").addEventListener("change", (e) => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = () => {
    try {
      applyTaxonomy(jsyaml.load(reader.result));
      document.getElementById("loadError").hidden = true;
    } catch (err) {
      alert("Failed to parse YAML: " + err.message);
    }
  };
  reader.readAsText(file);
});

loadTaxonomy();
loadExampleList();
