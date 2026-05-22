# Case study: CAD drawings → rendered image (divergent–convergent pass)

Date: 2026-05-19. Method: `METHOD.md` §1.6–1.7 (divergent–convergent + request-and-dispatch). This is a record of the method working — not a tutorial on the domain, but a concrete trace of the moves.

---

## The problem

Turn a building's 2D CAD drawings (floor plans, elevations) into a believable rendered image, without requiring a human to manually model the building in 3D first.

The working assumption going in was "sketching-primary": convert the CAD geometry to a line drawing, hand it to a diffusion model conditioned on the sketch, get a render. That path existed and worked to a degree. The question was whether there was anything better, or anything the team had missed.

---

## R0 — grounding pass (3 parallel research agents)

Before running any divergent reasoning, three research agents ran a broad, shallow grounding pass:

- **Agent 1 (source landscape):** What file formats and geometry representations do CAD files actually contain? What can Python-accessible parsers extract deterministically?
- **Agent 2 (prior art):** What do existing architectural visualization pipelines actually do after they receive a CAD file? How do commercial renderists process the input?
- **Agent 3 (diffusion conditioning):** What conditioning inputs does ControlNet / depth-conditioned diffusion accept? What does the signal look like at the input boundary?

Results were written to disk. Key grounded facts that came back:
- CAD floor plans contain 2D geometry: line entities, arc entities, polylines, layer names that encode element type (walls, windows, doors, columns).
- Existing pipelines either (a) model manually in 3ds Max/Blender from the CAD, or (b) use the CAD file to generate a sketch/line-drawing and condition diffusion on it.
- ControlNet accepts depth maps, normal maps, segmentation masks, and line drawings (Canny, HED, MLSD, lineart) as conditioning signals — each encodes a different geometric property.

---

## D — divergent agent pass

The divergent agent was handed the grounded findings and ran the "strip the name, state the structure" move on each artifact:

**Re-descriptions generated:**

1. *A CAD floor plan* named = a 2D architectural drawing.  
   Described structurally = **a precise vector specification of horizontal cross-sections at a fixed height, with typed geometry per element.**

2. *A sketch line drawing* (what the existing pipeline produced) named = an artistic freehand impression.  
   Described structurally = **a binary-edge image where edges encode object boundaries and interior structure.**

3. *matplotlib / vector graphics renderer* named = a data-plotting library.  
   Described structurally = **a renderer that converts vector geometry to clean 2D line images at arbitrary scale and line weight.**  
   → Bridge: the CAD parser already reads vector geometry; matplotlib can render it directly. The output is structurally identical to an MLSD/lineart ControlNet conditioning image. The "sketch" the pipeline was generating laboriously is just a render of the vector input.

4. *A depth map* (used in ControlNet) named = a grayscale image encoding pixel distance from camera.  
   Described structurally = **a per-pixel encoding of a surface's Z-position in camera space — which any 3D renderer produces as a standard G-buffer pass.**

5. *A building footprint + floor heights* (extractable from CAD + spec sheet) named = metadata.  
   Described structurally = **enough information to reconstruct a primitive 3D model (extruded polygons) that is geometrically correct in plan and massing, even if textureless.**

**Analogy bridges the divergent agent requested research on:**

- **Bridge A (game-engine G-buffers):** Game rendering pipelines produce depth, normal, and segmentation buffers from throwaway geometry as a standard step. What does it cost to generate those buffers from a simple extruded building mesh, without producing a final render? Feasibility request dispatched.
- **Bridge B (OpenStreetMap 2.5D building rendering):** OSM + CityGML pipelines extrude 2D footprints with building heights into simple 3D geometry for city-scale visualization. Does this process generalize to individual buildings from CAD floor-plan geometry + height data? Feasibility request dispatched.
- **Bridge C (matplotlib as ControlNet conditioner):** If the CAD parser outputs vector geometry and matplotlib renders it to a clean line image, does that image serve as a valid ControlNet MLSD or lineart input without any additional "sketch" generation step? Feasibility request dispatched.

---

## C — convergent agent pass (5 parallel feasibility research agents)

Five agents ran in parallel, each scoped to one feasibility question. Results to disk, pointers back:

- **Agent F1 (G-buffer from extruded mesh):** Blender Python API can extrude a floor-plan polygon + height, render a depth pass and a normal pass, and output them as 16-bit EXRs. MIT-licensed. No GPU required for a simple mesh (CPU render, seconds per frame). Depth pass is exactly the Z-depth buffer ControlNet expects.  
  CONFIDENCE: HIGH (primary source: Blender docs + Python API; tested by agent on a synthetic polygon).

- **Agent F2 (OSM / CityGML generalization):** OSM building extrusion is mature — `osmnx` + `shapely` + Blender scripting can extrude floor-plan polygons at specified heights. The step that costs money (ODA SDK for native DWG parsing) is separable; if the CAD parser extracts the polygon and height, the extrusion is free.  
  CONFIDENCE: MED (2 independent sources; own-test pending).

- **Agent F3 (matplotlib as ControlNet conditioner):** ezdxf + matplotlib output at 512×512 produces a clean line drawing. ControlNet's lineart preprocessor accepts this format. The gap: ControlNet expects a single-point-perspective or axonometric view, and matplotlib defaults to plan view; perspective requires either a simple camera projection or a Blender render pass. Plan-view MLSD conditioning is valid for floor-plan-flavored generation but limits viewpoint freedom.  
  CONFIDENCE: MED (primary source: ControlNet repo + ezdxf docs; own-test pending for the projection step).

- **Agent F4 (market / prior art check):** No existing publicly available tool chains: CAD floor-plan → extruded mesh → G-buffer render → diffusion conditioning in an end-to-end pipeline. Adjacent tools exist (architectural diffusion models, OSM renderers, Blender ArchViz add-ons) but none close this specific pipeline. Market gap confirmed at time of research.  
  CONFIDENCE: MED (breadth search; absence of evidence, not evidence of absence — dedicated product search not exhaustive).

- **Agent F5 (license / cost):** ezdxf (MIT), matplotlib (PSF/MIT-compatible), Blender (GPL for the application, Python API is Apache 2 for scripts), ControlNet weights (various; most permissive for non-commercial; CreativeML OpenRAIL-M for SD base). Stack is assemblable from MIT/Apache-licensed parts for a non-commercial build; commercial use requires weight license audit.  
  CONFIDENCE: HIGH (primary source: each project's LICENSE file, accessed directly).

---

## What the loop produced

The convergent agent scored the three bridges:

| Bridge | Real-match | Executable | Fits constraints | Verdict |
|---|---|---|---|---|
| A — G-buffer from extruded mesh | HIGH | HIGH (Blender Python, CPU) | HIGH (MIT/Apache) | **SURVIVOR → R2** |
| B — OSM-style 2.5D extrusion | HIGH | HIGH (osmnx + shapely) | HIGH | **SURVIVOR → R2** (overlaps A; fold into A strand) |
| C — matplotlib as ControlNet conditioner | MED | MED (plan-view only without projection step) | HIGH | **SURVIVOR with noted constraint** |

The route nobody had named at the start of the loop: **deterministically extrude the 2D footprint and height data into throwaway geometry, render its depth and normal G-buffers (no texturing, no materials, no manual modeling), feed those buffers as ControlNet conditioning signals into the diffusion pass.** The geometry is discarded immediately after; no 3D model is produced or kept. The render uses the geometry as a proxy for depth and structure, not as a deliverable.

This was assemblable from MIT-licensed parts, had no identified prior art, and required no ODA SDK or manual modeling step.

**Loop iteration note (METHOD.md §1.6 — loop discipline):** the C pass here happened to produce three survivors on the first cycle, which were strong enough to promote directly to R2. In practice the C pass can request a second D cycle. For example: if Agent F3 had returned "plan-view conditioning is incompatible with the perspective required" (instead of "MED, noted constraint"), that invalidated assumption would go back to the divergent agent — which might then generate a new bridge ("project the plan-view linework through a virtual camera before handing to ControlNet"). The orchestrator would then dispatch a new round of feasibility probes on that bridge. The D→C notation is a cycle label, not a one-shot label. Iterate until all bridges either survive to R2 or are logged and rejected.

---

## Why keyword search wouldn't have found this

The team had been running searches on "CAD to render", "sketch conditioned diffusion", "architectural visualization AI pipeline". None of those queries reach "G-buffer from throwaway geometry" because nobody in the space was describing the technique that way. The structural re-description ("a depth map is a G-buffer pass; a G-buffer pass requires only geometry, not a finished model; CAD floor plans encode enough geometry to extrude a primitive mesh") is what created the search target. The divergent agent didn't search for the answer — it created a description precise enough to search for evidence.

---

## Remaining risks (recorded, not resolved)

1. **Height data availability.** Floor plans contain horizontal geometry; heights (floor-to-ceiling, total building height) live in elevations or specs. The pipeline needs both. DXF elevation drawings may encode Z-coordinates directly; PDFs require extraction.
2. **Viewpoint generalization.** G-buffer conditioning produces good results for the camera angles the extruded mesh supports. Complex facades, overhangs, and balconies are underrepresented by simple extrusion.
3. **Commercial weight licensing.** The SD/ControlNet weights used require license review for commercial deployment.

These are the inputs to the next HEAVY research pass, not blockers on the current strand.
