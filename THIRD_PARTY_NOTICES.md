# Third-party notices

## microsoft/skills-for-fabric (MIT)

The following skills in `skills/fabric/` are copied from https://github.com/microsoft/skills-for-fabric at tag v0.3.18 (commit 6c11ad5): azmon-mirroredcatalogs-operations-cli, deployment-pipelines-authoring-cli, e2e-fabric-cost-estimation, eventschemaset-cli, git-integration-operations-cli, onelake-catalog-govern-cli, project-osmos, sqldb-cli, variable-library-cli, plus the `*-cli` skills that replace earlier split skills. Shared `common/` docs were copied into each skill's `references/common/` and links rewritten; `apm.yml` files were not copied.

```
MIT License

Copyright (c) 2026 Microsoft Corporation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

```

## Local modifications to upstream skills

- `skills/fabric/fabriciq-ontology-cli` (from microsoft/skills-for-fabric v0.3.18): added generation notes to the authoring and consumption references, a generation-2 TMDL spec (`references/authoring/tmdl-definition.md`), an offline helper and tests (`references/scripts/ontology_tmdl.py`, `test_ontology_tmdl.py`), a reconstructed example tree (`references/authoring/tmdl-example/`), an "Ontology generations" section and an updated description in `SKILL.md`. Upstream content was kept; changes are additive. Reapply these on the next upstream sync (patch list: `_inbox/ontology-tmdl-patch-list.md`).
