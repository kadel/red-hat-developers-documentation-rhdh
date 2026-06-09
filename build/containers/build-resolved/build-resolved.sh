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
# This script runs inside the container where all tools are pre-installed.
#
# Input:  titles/*/master.adoc  (each title's entrypoint)
# Output: titles-resolved/adoc/  (resolved .adoc files)
#         titles-resolved/md/    (converted .md files)

set -e

EXCLUDED_TITLES="rhdh-plugins-reference"
ATTR_FILE="artifacts/attributes.adoc"
OUTPUT_DIR="titles-resolved"

PERL_HELPER=$(mktemp)
trap 'rm -f "${PERL_HELPER}"' EXIT

cat > "${PERL_HELPER}" << 'PERL'
use strict;
use warnings;

my $attr_file = shift @ARGV;
my %attrs;

open(my $fh, '<', $attr_file) or die "Cannot open $attr_file: $!\n";
while (<$fh>) {
    chomp;
    next if /^\s*\/\//;
    if (/^:([a-zA-Z_][a-zA-Z0-9_-]*):\s+(.+)$/) {
        $attrs{$1} = $2;
    }
}
close($fh);

for my $pass (1..10) {
    my $changed = 0;
    for my $name (keys %attrs) {
        my $old = $attrs{$name};
        (my $new = $old) =~ s/\{([a-zA-Z_][a-zA-Z0-9_-]*)\}/exists $attrs{$1} ? $attrs{$1} : "{$1}"/ge;
        if ($new ne $old) {
            $attrs{$name} = $new;
            $changed = 1;
        }
    }
    last unless $changed;
}

while (<STDIN>) {
    chomp;
    if (/^:([a-zA-Z_][a-zA-Z0-9_-]*):\s+(.+)$/) {
        my ($name, $value) = ($1, $2);
        $value =~ s/\{([a-zA-Z_][a-zA-Z0-9_-]*)\}/exists $attrs{$1} ? $attrs{$1} : "{$1}"/ge;
        $attrs{$name} = $value;
    } elsif (/^:!([a-zA-Z_][a-zA-Z0-9_-]*):/) {
        delete $attrs{$1};
    }
    s/\{([a-zA-Z_][a-zA-Z0-9_-]*)\}/exists $attrs{$1} ? $attrs{$1} : "{$1}"/ge;
    print "$_\n";
}
PERL

ADOC_DIR="${OUTPUT_DIR}/adoc"
MD_DIR="${OUTPUT_DIR}/md"

rm -rf "${OUTPUT_DIR}"
mkdir -p "${ADOC_DIR}" "${MD_DIR}"

# shellcheck disable=SC2044,SC2013
for t in $(find titles -name master.adoc | sort -uV | grep -E -v "${EXCLUDED_TITLES}"); do
    dir=$(dirname "$t")
    name=${dir#titles/}
    output="${ADOC_DIR}/${name}.adoc"

    echo -n "Resolving ${name}... "
    asciidoctor-reducer "$t" -o - | perl "${PERL_HELPER}" "${ATTR_FILE}" > "${output}"
    echo -n "adoc "

    md_output="${MD_DIR}/${name}.md"
    asciidoctor -b docbook5 "${output}" -o - 2>/dev/null | pandoc -f docbook -t gfm --wrap=none -o "${md_output}" 2>/dev/null || \
        asciidoctor -b html5 -s "${output}" -o - 2>/dev/null | pandoc -f html -t gfm --wrap=none -o "${md_output}"
    perl -i -0777 -pe 's/<div[^>]*>\n?//g; s/<\/div>\n?//g; s/\n{3,}/\n\n/g' "${md_output}"
    echo "-> md"
done

if [[ -d "images" ]]; then
    echo "Copying images..."
    cp -r images/ "${ADOC_DIR}/images/"
    cp -r images/ "${MD_DIR}/images/"
fi

adoc_count=$(find "${ADOC_DIR}" -maxdepth 1 -name "*.adoc" | wc -l | tr -d ' ')
md_count=$(find "${MD_DIR}" -maxdepth 1 -name "*.md" | wc -l | tr -d ' ')
echo ""
echo "Done: ${adoc_count} AsciiDoc files in ${ADOC_DIR}/"
echo "      ${md_count} Markdown files in ${MD_DIR}/"
