# bonfire-tekton

## Project Overview

bonfire-tekton is a reusable Tekton pipeline library that provides standardized pipelines and tasks
for running Insights integration tests (via Bonfire and IQE) in Konflux (Red Hat App Studio). It is
not an application — it is a shared infrastructure component consumed by other repositories via
Tekton's `git` resolver and Konflux `IntegrationTestScenario` resources. Consumer repos reference a
specific `REVISION` (git ref) of this repo and receive pipeline definitions without copying any
files.

## Dependencies

**Runtime:** All pipeline tasks execute inside
`quay.io/redhat-services-prod/hcm-eng-prod-tenant/cicd-tools`, which bundles bonfire, `oc`, IQE,
`login.sh`, `deploy.sh`, `reserve-ns.sh`, `deploy-iqe-cji.sh`, and `parse-snapshot.py`. No local
installation is required or possible.

**Dev/test:** None. There is no package manager, no build system, and no locally executable test
suite. All validation runs in-cluster via Tekton through Pipelines-as-Code (PaC).

## Development Commands

There are no local build, lint, or test commands. The only developer-facing script is:

```bash
# Bulk-update the BONFIRE_IMAGE tag across all YAML files
./update-image.sh <new-image-tag>
```

All other validation occurs automatically in-cluster when a PR touches `.tekton/`, `pipelines/`, or
`tasks/`. See the [project README][readme] for the full usage and consumer integration guide.

## Architecture

### Pipeline structure

Two pipelines are defined under `pipelines/`:

- **`pipelines/basic.yaml`** — Full pipeline: `reserve-namespace` → `deploy` → `run-iqe-cji` →
  (finally) `teardown`. Used when IQE tests are required.
- **`pipelines/basic_no_iqe.yaml`** — Reduced pipeline: `reserve-namespace` → `deploy` → (finally)
  `teardown`. Used when only deployment validation is needed, with no IQE test execution.

### Task roles

Each task under `tasks/` is a standalone Tekton `Task` resource with a single responsibility:

| Task | File | Role |
|---|---|---|
| `reserve-namespace` | `tasks/reserve-namespace.yaml` | Allocates an ephemeral OpenShift namespace via `reserve-ns.sh` |
| `deploy` | `tasks/deploy.yaml` | Deploys the application via `deploy.sh` and `parse-snapshot.py` |
| `run-iqe-cji` | `tasks/run-iqe-cji.yaml` | Deploys and waits on an IQE ClusterJobInvocation (CJI) test job via `deploy-iqe-cji.sh` |
| `teardown` | `tasks/teardown.yaml` | Collects logs, uploads to S3, releases the namespace; always runs as a `finally` task |

`teardown` is unconditionally placed in the `finally` block of both pipelines, guaranteeing
namespace release even on failure.

### Git resolver consumption model

Consumer repositories do not copy pipeline or task YAML. Instead, they reference this repo via a
Tekton `git` resolver in an `IntegrationTestScenario`:

```yaml
resolver: git
params:
  - name: url
    value: https://github.com/RedHatInsights/bonfire-tekton
  - name: revision
    value: main          # or a pinned SHA/tag
  - name: pathInRepo
    value: pipelines/basic.yaml
```

The `REVISION` pipeline parameter (default: `main`) controls which git ref of bonfire-tekton is
used when resolving task references embedded within a pipeline. Consumers pin stability by setting
`revision` to a specific commit SHA or tag rather than `main`.

### PaC self-testing

The `.tekton/` directory contains Pipelines-as-Code `PipelineRun` definitions that act as the
repo's own CI:

- **`.tekton/simple-pipeline-test.yaml`** — Triggers the full pipeline (with IQE) on PRs to `main`
  that touch `.tekton/`, `pipelines/`, or `tasks/`.
- **`.tekton/simple-pipeline-no-iqe-test.yaml`** — Triggers the no-IQE pipeline on the same PR
  conditions.

These PipelineRuns use the `git` resolver to reference the PR's own branch, so every PR is
validated against its own changes before merge. There is no external CI system.

### BONFIRE_IMAGE pinning mechanism

All tasks reference the runtime container image via the `BONFIRE_IMAGE` pipeline parameter. The
value is a fully qualified image tag pointing to
`quay.io/redhat-services-prod/hcm-eng-prod-tenant/cicd-tools`. When the cicd-tools image is
updated, `update-image.sh` performs a bulk find-and-replace of the tag across every YAML file in
the repository. Consumers inherit whichever tag was current at their pinned `REVISION`.

## Code Style

There are no active linters, formatters, or pre-commit hooks in this repository. The following are
observed conventions, not enforced rules.

### YAML conventions

- API version is `tekton.dev/v1beta1` throughout. All files use this version consistently.
- Indentation: 2 spaces. No tabs.
- Tekton resources use `kind: Pipeline` or `kind: Task`; `metadata.name` matches the filename
  without extension.
- Parameter definitions include both `name` and `description`.
- Multi-line inline scripts use the `|` block scalar style under `script:`.

### Bash conventions

- Inline task scripts (`script:` fields) use `#!/usr/bin/env bash` shebangs.
- `update-image.sh` uses `sed` for bulk replacement — keep changes POSIX-compatible.
- Scripts source tools from the runtime image (`login.sh`, `deploy.sh`, etc.) — do not assume local
  availability of these tools.

### Tekton-specific patterns

- Tasks reference parameters with `$(params.PARAM_NAME)` syntax inside `script:` blocks.
- Workspace mounts are declared in both the `Pipeline` and referenced `Task` — changes to workspace
  names must be synchronized across both levels.
- The `finally` block in pipelines does not receive outputs from non-finally tasks; `teardown` must
  be self-sufficient using only params and workspaces.

## Common Mistakes

1. **Editing task params without updating pipeline params.** Task parameters and pipeline parameters
   are declared independently. Adding or renaming a param in a `Task` resource does not
   automatically propagate to the `Pipeline` that calls it. Both the `tasks[].params` binding in
   the pipeline and the `spec.params` of the task must be updated together, or the PipelineRun will
   fail with a binding error.

2. **Assuming `v1` Tekton API is valid.** The entire repo uses `tekton.dev/v1beta1`. Upgrading a
   single file to `tekton.dev/v1` while others remain on `v1beta1` causes resolver or validation
   errors in clusters that enforce API consistency. Any API version migration must be done
   atomically across all files.

3. **Modifying inline scripts without accounting for the runtime image.** All script tooling
   (`bonfire`, `oc`, `deploy.sh`, etc.) is provided exclusively by the `cicd-tools` image. Adding
   a script dependency not present in that image will fail silently at runtime — there is no local
   environment to test against.

4. **Using `update-image.sh` for partial updates.** The script performs a global replacement across
   all YAML files. Running it and then manually reverting some files creates inconsistent image tags
   across tasks, which causes different tasks in the same pipeline to run different tool versions.
   Always let the script update everything, then commit the full changeset.

5. **Forgetting that `teardown` cannot read task results.** The `teardown` task runs in the
   `finally` block and cannot access `results` emitted by non-finally tasks (e.g., the namespace
   name from `reserve-namespace`). Any value `teardown` needs must be passed through a shared
   workspace or pipeline parameter — not via task result references.

## Deployment

Consumers integrate bonfire-tekton by creating a Konflux `IntegrationTestScenario` resource in
their application namespace. The scenario uses the Tekton `git` resolver to reference
`pipelines/basic.yaml` or `pipelines/basic_no_iqe.yaml` at the desired `REVISION`. Required
pipeline parameters (`APP_NAME`, `COMPONENTS`, `IQE_PLUGINS`, etc.) are specified in the
scenario's `params` block. See the [project README][readme] for the full `IntegrationTestScenario`
template and parameter reference.

[readme]: ./README.md
