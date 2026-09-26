#!/usr/bin/env bash
# Create posts/YYYY-MM-DD-slug/index.qmd as a draft. Usage: scripts/new-post.sh "Post title"
set -euo pipefail

title="${1:?usage: scripts/new-post.sh \"Post title\"}"
slug=$(printf '%s' "$title" | iconv -f utf-8 -t ascii//TRANSLIT \
  | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
[[ -n $slug ]] || { echo "Could not make a slug from: $title" >&2; exit 1; }

today=$(date +%F)
dir="posts/$today-$slug"
[[ -e $dir ]] && { echo "$dir already exists" >&2; exit 1; }

# Escape backslashes and double quotes for the YAML string.
yaml_title=${title//\\/\\\\}
yaml_title=${yaml_title//\"/\\\"}

mkdir -p "$dir"
cat > "$dir/index.qmd" <<QMD
---
title: "$yaml_title"
description: ""
date: $today
categories: []
draft: true
---

QMD
echo "$dir/index.qmd"
