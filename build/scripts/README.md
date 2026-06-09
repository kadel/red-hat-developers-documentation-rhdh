# Build Scripts

Build, deploy, and content quality tooling for the RHDH documentation project.

## Scripts

| Script | Purpose |
|---|---|
| `build-ccutil.sh` | Wrapper that delegates to `build-orchestrator.js`. Used as a fallback in `pr.yml` on older branches and for local builds. |
| `build-orchestrator.js` | Parallel documentation build orchestrator. Runs ccutil title builds, lychee link validation, and CQA assessment. Produces `build-report.json`. Supports `--no-cqa` and `--no-lychee` flags to skip phases. |
| `build-resolved.sh` | Resolves AsciiDoc titles into standalone files (all includes inlined, all attributes substituted) and converts them to GitHub-flavored Markdown. Runs inside a container via Podman -- no local tool installation needed. Use `--rebuild` to force a container image rebuild. Output goes to `titles-resolved/adoc/` and `titles-resolved/md/`. See [`../containers/build-resolved/`](../containers/build-resolved/) for the Containerfile and inner build script. |
| `deploy-gh-pages.sh` | Deploys build output to the `gh-pages` branch. Handles cleanup of stale PR/branch directories, index regeneration with release notes links, and retry with rebase on push conflicts. |
| `error-patterns.json` | Regex patterns for classifying ccutil build errors into structured messages with cause and fix fields. |
| `update-cqa-resources.sh` | Fetches upstream Red Hat style guide resources into `.claude/resources/`. |

## CQA (`cqa/`)

Content Quality Assessment framework with 19 checks (CQA-00a through CQA-17).

```bash
node build/scripts/cqa/index.js titles/<title>/master.adoc           # report
node build/scripts/cqa/index.js --fix titles/<title>/master.adoc     # auto-fix
node build/scripts/cqa/index.js --check 14 titles/<title>/master.adoc # single check
node build/scripts/cqa/index.js --all                                 # all titles
```

See `.claude/plugins/project-cqa/resources/cqa-spec.md` for the full specification.

## Workflows

These scripts are called by GitHub Actions workflows in `.github/workflows/`:

- **`build-asciidoc.yml`** (push to main/release) -- `build-orchestrator.js --no-cqa` + `deploy-gh-pages.sh`
- **`pr.yml`** (pull requests) -- `build-orchestrator.js` (or `build-ccutil.sh` on older branches) + `deploy-gh-pages.sh`

See `docs/github-publication-workflow.md` for the full architecture documentation.
