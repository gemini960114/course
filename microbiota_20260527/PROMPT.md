/bio-microbiome-qiime2-workflow

使用 skill bio-microbiome-qiime2-workflow

我的資料放在 data 資料夾中，包含 single-end 的 sequences.fastq.gz、barcodes.fastq.gz，以及 sample-metadata.tsv、reference-sequences.qza、reference-taxonomy.qza。

請幫我撰寫一個 linux bash script，用 QIIME2 完成分析流程。請依照這批資料的型態建立正確的 import 與 demultiplex 流程，接著執行 demux summarize、DADA2 denoise-single、feature table summary、rep-seqs summary、phylogenetic tree、diversity analysis、taxonomy classification、taxa barplot。

腳本需讓每個步驟在輸出已存在時自動跳過，方便重跑；最後請列出所有產生的 `.qzv` 檔案。最後輸出 qiime2.sh

