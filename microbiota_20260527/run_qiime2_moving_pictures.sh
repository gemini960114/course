#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# QIIME 2 Moving Pictures tutorial pipeline
# ============================================================
# Requirement:
#   1. QIIME 2 environment is already installed
#   2. Run this script inside an activated QIIME 2 environment
#
# Example:
#   conda activate qiime2-amplicon-2024.x
#   bash run_qiime2_moving_pictures.sh
# ============================================================

WORKDIR="${PWD}/moving-pictures-run"
THREADS="${THREADS:-2}"
echo "THREADS=${THREADS}"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "============================================================"
echo "QIIME 2 Moving Pictures tutorial"
echo "Workdir: $WORKDIR"
echo "Started at: $(date '+%F %T')"
echo "============================================================"

echo
echo "==> Checking qiime command..."
if ! command -v qiime >/dev/null 2>&1; then
  echo "ERROR: qiime command not found."
  echo "Please activate your QIIME 2 environment first."
  echo "Example:"
  echo "  conda activate qiime2-amplicon-2024.x"
  exit 1
fi

qiime --version

echo
echo "==> Step 1: Check sample metadata..."

if [ ! -f sample-metadata.tsv ]; then
  echo "sample-metadata.tsv does not exist."
  exit 1
else
  echo "sample-metadata.tsv already exists, continue."
fi

echo
echo "==> Step 2: Visualize metadata..."
if [ ! -f sample-metadata-viz.qzv ]; then
  qiime metadata tabulate \
    --m-input-file sample-metadata.tsv \
    --o-visualization sample-metadata-viz.qzv
else
  echo "sample-metadata-viz.qzv already exists, skip."
fi

echo
echo "==> Step 3: Check EMP single-end sequences directory and files..."

if [ ! -d emp-single-end-sequences ]; then
  echo "ERROR: emp-single-end-sequences directory does not exist."
  exit 1
fi

if [ ! -f emp-single-end-sequences/barcodes.fastq.gz ]; then
  echo "ERROR: emp-single-end-sequences/barcodes.fastq.gz does not exist."
  exit 1
fi

if [ ! -f emp-single-end-sequences/sequences.fastq.gz ]; then
  echo "ERROR: emp-single-end-sequences/sequences.fastq.gz does not exist."
  exit 1
fi

echo "emp-single-end-sequences directory and required files already exist, continue."

echo
echo "==> Step 4: Import EMP single-end sequences..."
if [ ! -f emp-single-end-sequences.qza ]; then
  qiime tools import \
    --type 'EMPSingleEndSequences' \
    --input-path emp-single-end-sequences \
    --output-path emp-single-end-sequences.qza
else
  echo "emp-single-end-sequences.qza already exists, skip."
fi

echo
echo "==> Step 5: Demultiplex sequences..."
if [ ! -f demux.qza ]; then
  qiime demux emp-single \
    --i-seqs emp-single-end-sequences.qza \
    --m-barcodes-file sample-metadata.tsv \
    --m-barcodes-column barcode-sequence \
    --o-per-sample-sequences demux.qza \
    --o-error-correction-details demux-details.qza
else
  echo "demux.qza already exists, skip."
fi

echo
echo "==> Step 6: Summarize demux results..."
if [ ! -f demux.qzv ]; then
  qiime demux summarize \
    --i-data demux.qza \
    --o-visualization demux.qzv
else
  echo "demux.qzv already exists, skip."
fi

echo
echo "==> Step 7: DADA2 denoise single-end reads..."
if [ ! -f table.qza ] || [ ! -f rep-seqs.qza ]; then
  qiime dada2 denoise-single \
    --i-demultiplexed-seqs demux.qza \
    --p-trim-left 0 \
    --p-trunc-len 120 \
	--p-n-threads "$THREADS" \
    --o-representative-sequences rep-seqs.qza \
    --o-table table.qza \
    --o-denoising-stats denoising-stats.qza \
    --o-base-transition-stats base-transition-stats.qza
else
  echo "table.qza and rep-seqs.qza already exist, skip DADA2."
fi

echo
echo "==> Step 8: Visualize DADA2 denoising stats..."
if [ ! -f denoising-stats.qzv ]; then
  qiime metadata tabulate \
    --m-input-file denoising-stats.qza \
    --o-visualization denoising-stats.qzv
else
  echo "denoising-stats.qzv already exists, skip."
fi

echo
echo "==> Step 9: Feature table and representative sequence summaries..."
if [ ! -f table.qzv ]; then
  qiime feature-table summarize \
    --i-table table.qza \
    --m-metadata-file sample-metadata.tsv \
    --o-summary table.qzv \
    --o-feature-frequencies feature-frequencies.qza \
    --o-sample-frequencies sample-frequencies.qza
else
  echo "table.qzv already exists, skip."
fi

if [ ! -f rep-seqs.qzv ]; then
  qiime feature-table tabulate-seqs \
    --i-data rep-seqs.qza \
    --o-visualization rep-seqs.qzv
else
  echo "rep-seqs.qzv already exists, skip."
fi

echo
echo "==> Step 10: Generate phylogenetic tree..."
if [ ! -f rooted-tree.qza ]; then
  qiime phylogeny align-to-tree-mafft-fasttree \
    --i-sequences rep-seqs.qza \
    --o-alignment aligned-rep-seqs.qza \
    --o-masked-alignment masked-aligned-rep-seqs.qza \
    --o-tree unrooted-tree.qza \
    --o-rooted-tree rooted-tree.qza
else
  echo "rooted-tree.qza already exists, skip."
fi

echo
echo "==> Step 11: Core diversity metrics..."
if [ ! -d diversity-core-metrics-phylogenetic ]; then
  qiime diversity core-metrics-phylogenetic \
    --i-phylogeny rooted-tree.qza \
    --i-table table.qza \
    --p-sampling-depth 1103 \
    --m-metadata-file sample-metadata.tsv \
    --output-dir diversity-core-metrics-phylogenetic
else
  echo "diversity-core-metrics-phylogenetic already exists, skip."
fi

echo
echo "==> Step 12: Alpha diversity group significance..."
if [ ! -f faith-pd-group-significance.qzv ]; then
  qiime diversity alpha-group-significance \
    --i-alpha-diversity diversity-core-metrics-phylogenetic/faith_pd_vector.qza \
    --m-metadata-file sample-metadata.tsv \
    --o-visualization faith-pd-group-significance.qzv
else
  echo "faith-pd-group-significance.qzv already exists, skip."
fi

if [ ! -f evenness-group-significance.qzv ]; then
  qiime diversity alpha-group-significance \
    --i-alpha-diversity diversity-core-metrics-phylogenetic/evenness_vector.qza \
    --m-metadata-file sample-metadata.tsv \
    --o-visualization evenness-group-significance.qzv
else
  echo "evenness-group-significance.qzv already exists, skip."
fi

echo
echo "==> Step 13: Beta diversity group significance..."
if [ ! -f unweighted-unifrac-body-site-group-significance.qzv ]; then
  qiime diversity beta-group-significance \
    --i-distance-matrix diversity-core-metrics-phylogenetic/unweighted_unifrac_distance_matrix.qza \
    --m-metadata-file sample-metadata.tsv \
    --m-metadata-column body-site \
    --p-pairwise \
    --o-visualization unweighted-unifrac-body-site-group-significance.qzv
else
  echo "unweighted-unifrac-body-site-group-significance.qzv already exists, skip."
fi

if [ ! -f unweighted-unifrac-subject-group-significance.qzv ]; then
  qiime diversity beta-group-significance \
    --i-distance-matrix diversity-core-metrics-phylogenetic/unweighted_unifrac_distance_matrix.qza \
    --m-metadata-file sample-metadata.tsv \
    --m-metadata-column subject \
    --p-pairwise \
    --o-visualization unweighted-unifrac-subject-group-significance.qzv
else
  echo "unweighted-unifrac-subject-group-significance.qzv already exists, skip."
fi

echo
echo "==> Step 14: Emperor plots with days-since-experiment-start..."
if [ ! -f unweighted-unifrac-emperor-days-since-experiment-start.qzv ]; then
  qiime emperor plot \
    --i-pcoa diversity-core-metrics-phylogenetic/unweighted_unifrac_pcoa_results.qza \
    --m-metadata-file sample-metadata.tsv \
    --p-custom-axes days-since-experiment-start \
    --o-visualization unweighted-unifrac-emperor-days-since-experiment-start.qzv
else
  echo "unweighted-unifrac-emperor-days-since-experiment-start.qzv already exists, skip."
fi

if [ ! -f bray-curtis-emperor-days-since-experiment-start.qzv ]; then
  qiime emperor plot \
    --i-pcoa diversity-core-metrics-phylogenetic/bray_curtis_pcoa_results.qza \
    --m-metadata-file sample-metadata.tsv \
    --p-custom-axes days-since-experiment-start \
    --o-visualization bray-curtis-emperor-days-since-experiment-start.qzv
else
  echo "bray-curtis-emperor-days-since-experiment-start.qzv already exists, skip."
fi

echo
echo "==> Step 15: Alpha rarefaction..."
if [ ! -f alpha-rarefaction.qzv ]; then
  qiime diversity alpha-rarefaction \
    --i-table table.qza \
    --i-phylogeny rooted-tree.qza \
    --p-max-depth 4000 \
    --m-metadata-file sample-metadata.tsv \
    --o-visualization alpha-rarefaction.qzv
else
  echo "alpha-rarefaction.qzv already exists, skip."
fi

echo
echo "==> Step 16: Check reference taxonomy and sequences..."

if [ ! -f reference-sequences.qza ]; then
  echo "ERROR: reference-sequences.qza does not exist. Please prepare it first."
  exit 1
else
  echo "reference-sequences.qza already exists, continue."
fi

if [ ! -f reference-taxonomy.qza ]; then
  echo "ERROR: reference-taxonomy.qza does not exist. Please prepare it first."
  exit 1
else
  echo "reference-taxonomy.qza already exists, continue."
fi

echo
echo "==> Step 17: Train suboptimal 16S rRNA classifier..."
if [ ! -f suboptimal-16S-rRNA-classifier.qza ]; then
  qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads reference-sequences.qza \
    --i-reference-taxonomy reference-taxonomy.qza \
    --o-classifier suboptimal-16S-rRNA-classifier.qza
else
  echo "suboptimal-16S-rRNA-classifier.qza already exists, skip."
fi

echo
echo "==> Step 18: Classify taxonomy..."
if [ ! -f taxonomy.qza ]; then
  qiime feature-classifier classify-sklearn \
    --i-classifier suboptimal-16S-rRNA-classifier.qza \
    --i-reads rep-seqs.qza \
	--p-n-jobs "$THREADS" \
	--o-classification taxonomy.qza
else
  echo "taxonomy.qza already exists, skip."
fi

if [ ! -f taxonomy.qzv ]; then
  qiime metadata tabulate \
    --m-input-file taxonomy.qza \
    --o-visualization taxonomy.qzv
else
  echo "taxonomy.qzv already exists, skip."
fi

echo
echo "==> Step 19: Taxa bar plot..."
if [ ! -f taxa-bar-plots.qzv ]; then
  qiime taxa barplot \
    --i-table table.qza \
    --i-taxonomy taxonomy.qza \
    --m-metadata-file sample-metadata.tsv \
    --o-visualization taxa-bar-plots.qzv
else
  echo "taxa-bar-plots.qzv already exists, skip."
fi

echo
echo "==> Step 20: Filter gut samples..."
if [ ! -f gut-table.qza ]; then
  qiime feature-table filter-samples \
    --i-table table.qza \
    --m-metadata-file sample-metadata.tsv \
    --p-where '[body-site]="gut"' \
    --o-filtered-table gut-table.qza
else
  echo "gut-table.qza already exists, skip."
fi

echo
echo "==> Step 21: ANCOM-BC on subject..."
if [ ! -f ancombc-subject.qza ]; then
  qiime composition ancombc \
    --i-table gut-table.qza \
    --m-metadata-file sample-metadata.tsv \
    --p-formula subject \
    --o-differentials ancombc-subject.qza
else
  echo "ancombc-subject.qza already exists, skip."
fi

if [ ! -f da-barplot-subject.qzv ]; then
  qiime composition da-barplot \
    --i-data ancombc-subject.qza \
    --p-significance-threshold 0.001 \
    --o-visualization da-barplot-subject.qzv
else
  echo "da-barplot-subject.qzv already exists, skip."
fi

echo
echo "==> Step 22: Collapse taxonomy at level 6 and run ANCOM-BC..."
if [ ! -f gut-table-l6.qza ]; then
  qiime taxa collapse \
    --i-table gut-table.qza \
    --i-taxonomy taxonomy.qza \
    --p-level 6 \
    --o-collapsed-table gut-table-l6.qza
else
  echo "gut-table-l6.qza already exists, skip."
fi

if [ ! -f l6-ancombc-subject.qza ]; then
  qiime composition ancombc \
    --i-table gut-table-l6.qza \
    --m-metadata-file sample-metadata.tsv \
    --p-formula subject \
    --o-differentials l6-ancombc-subject.qza
else
  echo "l6-ancombc-subject.qza already exists, skip."
fi

if [ ! -f l6-da-barplot-subject.qzv ]; then
  qiime composition da-barplot \
    --i-data l6-ancombc-subject.qza \
    --p-significance-threshold 0.001 \
    --o-visualization l6-da-barplot-subject.qzv
else
  echo "l6-da-barplot-subject.qzv already exists, skip."
fi

echo
echo "============================================================"
echo "Pipeline completed at: $(date '+%F %T')"
echo "Results directory:"
echo "  $WORKDIR"
echo
echo "Important QZV files:"
find "$WORKDIR" -maxdepth 2 -name "*.qzv" | sort
echo
echo "To view QZV files, use QIIME 2 View:"
echo "  https://view.qiime2.org/"
echo "============================================================"