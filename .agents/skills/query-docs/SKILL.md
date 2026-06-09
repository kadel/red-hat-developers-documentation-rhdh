---
name: query-docs
description: >
  Search the resolved RHDH product documentation for answers about Red Hat
  Developer Hub features, configuration, installation, plugins, authentication,
  authorization, integrations, observability, or any topic covered in the
  published docs. Use when the user asks "what does the docs say about...",
  "how do I configure...", "what authentication providers...", "find in docs...",
  "does RHDH support...", or any question answerable from the product
  documentation. Also use when you need to verify what the documentation
  currently states before editing it.
---

# Query RHDH Product Documentation

Search the resolved Markdown documentation in `titles-resolved/md/` to answer questions about RHDH product documentation content.

These files are the full product docs with all AsciiDoc includes inlined and attributes substituted — they are the single source of truth for what the documentation says.

## Step 1: Ensure resolved docs are up to date

Before searching, check if the resolved docs need rebuilding.

Run this staleness check:

```bash
if [ ! -d titles-resolved/md ] || \
   [ -n "$(find titles/ assemblies/ modules/ artifacts/attributes.adoc images/ -newer titles-resolved/md -maxdepth 0 2>/dev/null)" ] || \
   [ -n "$(git log --oneline --since="$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%S' titles-resolved/md 2>/dev/null || echo '1970-01-01')" -- titles/ assemblies/ modules/ artifacts/attributes.adoc images/ 2>/dev/null | head -1)" ]; then
    echo "REBUILD_NEEDED"
else
    echo "UP_TO_DATE"
fi
```

- If `REBUILD_NEEDED`: run `bash build/scripts/build-resolved.sh` first, then proceed to Step 2.
- If `UP_TO_DATE`: skip straight to Step 2.

If the build script fails (e.g., podman not available), fall back to searching the raw AsciiDoc sources in `titles/`, `assemblies/`, and `modules/` directly — but warn the user that attribute references like `{product-short}` won't be resolved.

## Step 2: Search the resolved docs

Use `grep` to find relevant files, then `Read` the matching files:

```bash
grep -rli "<search terms>" titles-resolved/md/*.md
```

Tips:
- Use multiple search terms separated by `\|` for broader matches
- Search is case-insensitive (`-i`) to catch heading variations
- If grep returns too many matches, narrow with more specific terms
- If grep returns nothing, try synonyms or shorter terms
- Read the most relevant 2-3 files fully rather than skimming many

## Step 3: Answer from the docs

When answering:
- Quote or paraphrase the resolved documentation directly
- Reference the title name (derived from the filename, e.g., `configure_configuring-rhdh.md` → "Configuring RHDH")
- If the docs don't cover the topic, say so explicitly rather than guessing
- Do NOT search the raw `.adoc` sources when resolved Markdown is available — the raw sources have unresolved includes and attribute placeholders that make them harder to read

## File naming convention

Resolved Markdown files follow this pattern:
```
titles-resolved/md/<category>_<title-slug>.md
```

Categories map to documentation sections:
- `configure_*` — Configuration guides
- `control-access_*` — Authentication and authorization
- `develop_*` — Developer workflows
- `discover_*` — Product overview
- `explore_*` — Emerging capabilities
- `extend_*` — Plugins and extensions
- `get-started_*` — Getting started guides
- `install_*` — Installation guides
- `integrate_*` — Integration guides
- `observability_*` — Monitoring, logging, telemetry
- `observe_*` — Diagnostics
- `upgrade_*` — Upgrade procedures

Use these categories to narrow your search when the topic is clear.
