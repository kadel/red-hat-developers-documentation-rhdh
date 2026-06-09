#!/usr/bin/env bash
#
# Copyright (c) Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Resolves AsciiDoc titles into standalone files with all includes inlined
# and attributes substituted, then converts to GitHub-flavored Markdown.
# Runs the build inside a container via Podman — no local tool installation needed.
#
# Usage:
#   Run from the repository root:
#     ./build/scripts/build-resolved.sh [--rebuild]
#
#   --rebuild  Force rebuild of the container image
#
# Input:  titles/*/master.adoc  (each title's entrypoint)
# Output: titles-resolved/adoc/  (resolved .adoc files)
#         titles-resolved/md/    (converted .md files)

set -e

IMAGE_NAME="rhdh-docs-build-resolved"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONTAINER_DIR="${SCRIPT_DIR}/../containers/build-resolved"

if ! command -v podman &> /dev/null; then
    echo "Error: podman is not installed."
    exit 1
fi

if [[ "${1:-}" == "--rebuild" ]]; then
    echo "Forcing image rebuild..."
    podman rmi -f "${IMAGE_NAME}" 2>/dev/null || true
    shift
fi

if ! podman image exists "${IMAGE_NAME}" 2>/dev/null; then
    echo "Building container image ${IMAGE_NAME}..."
    podman build -t "${IMAGE_NAME}" "${CONTAINER_DIR}"
    echo ""
fi

podman run --rm \
    -v "${REPO_ROOT}:/workspace:Z" \
    "${IMAGE_NAME}"
