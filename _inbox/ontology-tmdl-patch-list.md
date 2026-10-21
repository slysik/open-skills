# Patch list: fabriciq-ontology-cli local additions (2026-10-21)

Reapply after any upstream sync of `skills/fabric/fabriciq-ontology-cli`:
1. `SKILL.md`: description sentence about generations; new section "Ontology generations (read before any write)" before "## Rules".
2. First-heading "Format note" / "Generation note" blockquotes in: `references/authoring.md`, `references/authoring/ONTOLOGY-AUTHORING-CORE.md`, `references/authoring/definition-script-templates.md`, `references/authoring/examples.md`, `references/authoring/preview-and-confirm.md`, `references/authoring/authoring-mechanics.md`, `references/consumption.md`, `references/consumption/graph-walks.md`, `references/consumption/grounding-extraction.md`, `references/consumption/routing.md`.
3. New files: `references/authoring/tmdl-definition.md`, `references/authoring/tmdl-example/**`, `references/scripts/ontology_tmdl.py`, `references/scripts/test_ontology_tmdl.py`.

Open verification (needs a real Fabric item): TMDL property names and indentation in each block; accepted `format` values; which `properties.generation` value is the new experience; typed `/ontologies/...` versus generic `/items/...` behaviour.
Correction to the earlier plan message: Learn does document a migration route (in-product "create a copy in the new experience"); there is still no migration API.
