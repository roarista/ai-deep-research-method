# Architect → Renderer file handoff: format priority (worked HEAVY-tier example)

Date: 2026-05-19. Method: `METHOD.md` (HEAVY tier). Tooling: WebSearch breadth + headless browser-harness depth. Stop criterion met at ~18 tool calls, 8+ independent sources.

This is the first re-research pass under the new method, replacing assumption-based format priority with cited evidence.

## Format priority (most → least common in real handoffs)

**Tier 1 — near-universal, every project**
1. **DWG** — single most-cited format across every source. Treated as ground-truth drawing set even when a 3D model also exists. Covers 2D plans/elevations and sometimes 3D.
2. **PDF drawing sets** — second-most cited; complement to DWG, and the sole input from non-CAD clients (small residential, early-stage).

**Tier 2 — common on medium/large or BIM-enabled projects**
3. **SKP (SketchUp)** — dominant early-stage/conceptual modeler, common from smaller firms. Studios convert to FBX or import to 3ds Max.
4. **RVT (Revit)** — common on mid-large commercial / BIM offices; imported via FBX export or direct link.

**Tier 3 — accepted but situational**
5. **FBX** — primary 3D interchange (Revit/Rhino → Max/Blender); usually a requested export, not a native client deliverable.
6. **Reference images / mood boards / site photos** — UNIVERSAL accompaniment, first-class component of every handoff (style, materials, atmosphere).
7. **DXF** — universal CAD interchange, but secondary to DWG; used when DWG unavailable or for cross-software compatibility.
8. **PLN (ArchiCAD)** — situational, geographic (Europe / parts of LatAm).

**Tier 4 — accepted but infrequent as primary input**
9. **OBJ / 3DS / DAE** — occasional, usually individual assets not full scenes.
10. **IFC** — listed in technical guides as the open BIM standard, but NO practitioner account names it as what they actually receive for archviz. It's an AEC coordination format, not the architect→renderer delivery format.
11. **Written brief / material-finish spec (XLS/DOCX/narrative, sometimes COBie)** — UNIVERSAL accompaniment.

## Strategic implications for Previz (read these)

1. **DWG is the real target; DXF is a fallback.** Our DXF-first focus was a *tooling-convenience* choice (ezdxf is easy/MIT), not a market-frequency choice. What actually arrives is DWG. This raises the priority of the DWG→DXF bridge (ODA File Converter) and the acadrust path — DXF parsing alone doesn't meet the most common input.

2. **PDF is co-primary with DWG, not a tier-2 afterthought.** Many clients — especially the small-residential / early-stage / developer segment — send *only* PDF or DWG with no 3D model. The PDF drawing-set handler is near-as-important as the CAD handler.

3. **Non-CAD inputs are universal, not optional.** Reference images, mood boards, site photos, and a written material/finish brief accompany *every* real handoff. Intake must treat these as first-class, which reinforces the doc-intel / spec side, not just geometry parsing.

4. **The 2D-only vs. 3D-model-provided split is the core market question (contradiction C1).** Two real scenarios: (a) client provides a Revit/SketchUp 3D model → high-end/commercial archviz; (b) client provides only 2D DWG/PDF and the renderer models from scratch → small residential / early-stage / developer. **Our "parser-first, no manual 3D modeling" thesis squarely targets scenario (b).** This is where the product creates value; scenario (a) already has a 3D model and needs less of us.

5. **IFC is likely over-weighted in our prior intake design.** `memory/project_dwg_intake_design_2026_05_17.md` lists RVT→IFC and IFC→IFC.js routing as priority handlers. The evidence says IFC is rarely the archviz handoff format. Demote IFC unless a downstream pass contradicts this.

## Contradictions (not resolved silently)
- **C1**: "3D model always provided" (Chaos, 4dviz) vs. "2D-only, renderer models from scratch" (Roomagen, Fenestra). Both real — market-segment split, not opposing facts. Do not collapse.
- **C2**: ArchiCGI's 3D-format table omits RVT/SKP though they're common inputs — likely reflects pipeline-ready (post-FBX-export) formats, not raw client deliverables.
- **C3**: IFC ubiquitous in technical guides, absent from practitioner accounts of what they receive.

## Gaps (need follow-up pass or human)
1. No hard %/proportion data per format (ranking is by citation prominence, not measured frequency). Reddit/CGarchitect forum survey was network-blocked.
2. No geographic breakdown (DWG vs PLN vs RVT ratios by region).
3. Developer (vs architect) handoff packages specifically — under-documented.
4. Material/finish schedule delivery format (XLS vs PDF vs brand deck vs email) — unquantified, matters for intake design.
5. IFC actual frequency in archviz intake — unconfirmed either way.

## Sources
See the 14 URLs in the research run; key tier-1: 3dastudio.com/rendering-business/3d-file-formats, 7cgi.com/archviz, 4dviz.com/blog/file-formats-for-3d-architectural-modeling-projects, archicgi.com 3D rendering guide. Tier-4/5 corroboration: CGarchitect forum + editorial, Chaos blog, SketchUp forum, ArchDaily.
