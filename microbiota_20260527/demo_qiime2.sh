#!/usr/bin/env bash

# ====================
# QIIME 2 Moving Pictures tutorial pipeline
# ====================

WORKDIR="${PWD}/moving-pictures-run"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "===================="
echo "QIIME 2 Moving Pictures tutorial"
echo "Workdir: $WORKDIR"
echo "===================="

qiime info


