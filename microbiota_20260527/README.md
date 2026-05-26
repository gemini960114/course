# Microbiota 20260527 - QIIME 2 微生物群分析流程專案

本專案為基於 **QIIME 2** 與 **Singularity 容器技術**的 16S rRNA 微生物菌群多樣性分析流程。專案設計專為 HPC 高效能計算叢集（採用 Slurm 排程器）優化，實現自動化、可重入（步驟斷點自動跳過）的微生物群分析。

---

## 📂 目錄結構與檔案說明

本專案根目錄 `microbiota_20260527` 的檔案配置如下：

```text
microbiota_20260527/
├── run_qiime2_moving_pictures.sh      # 核心分析流程 Shell 腳本 (QIIME 2 Workflow)
├── run_qiime2_moving_pictures.slurm   # Slurm 工作提交腳本 (呼叫 Singularity 執行核心分析)
├── demo_qiime2.sh                      # 診斷測試 Shell 腳本 (僅輸出 qiime info)
├── demo_qiime2.slurm                  # 診斷測試 Slurm 工作提交腳本
├── demo_job.slurm                      # 基礎 Slurm 工作範本
├── f1_microbiota.pptx                  # 專案分析成果與簡報投影片
├── proxy.sh                            # 網路代理環境設定腳本
├── GEMINI.md                           # AI 助理開發規範及環境限制說明
├── PROMPT.md                           # 專案初始需求與規格說明
├── README.md                           # 本專案說明文件 (本檔案)
├── .agents/                            # AI 助理自訂技能與工作流設定目錄
├── logs/                               # Slurm 工作執行記錄與錯誤輸出日誌目錄
└── moving-pictures-run/                # QIIME 2 分析工作主目錄 (輸入資料與分析產出)
    ├── emp-single-end-sequences/       # 原始定序數據 (包含 sequences.fastq.gz 與 barcodes.fastq.gz)
    ├── sample-metadata.tsv             # 樣本元數據 (樣品分組、時間點及條碼序列等資訊)
    ├── reference-sequences.qza         # 分類法比對參考序列檔案
    └── reference-taxonomy.qza          # 分類法比對參考分類階層檔案
```

---

## 🧬 QIIME 2 分析流程步驟

核心指令腳本 `run_qiime2_moving_pictures.sh` 實作了完整的 QIIME 2 分析流程，每個步驟均具備 **「若產出已存在則自動跳過（Skip）」** 的防錯機制，方便斷點續跑：

1. **Step 1 - 檢查樣本元數據**：確認 `sample-metadata.tsv` 是否就位。
2. **Step 2 - 元數據可視化**：產生 `sample-metadata-viz.qzv`。
3. **Step 3-4 - 匯入 EMP 單端定序數據**：將 FastQ 原始資料匯入為 QIIME 2 專用的物件格式 `emp-single-end-sequences.qza`。
4. **Step 5-6 - 樣本解交錯 (Demultiplexing)**：利用 barcodes 進行分樣，並產生品質評估圖表 `demux.qzv`。
5. **Step 7-8 - DADA2 去噪與序列篩選**：執行 DADA2 演算法（支援多執行緒處理），進行去噪、去嵌合體與濾除低品質 reads，產生 Feature Table (`table.qza`)、代表性序列 (`rep-seqs.qza`) 與去噪統計可視化 (`denoising-stats.qzv`)。
6. **Step 9 - 特徵表與序列彙整**：產生特徵表統計資料 `table.qzv` 與代表性序列統計資料 `rep-seqs.qzv`。
7. **Step 10 - 系統發育樹建構**：使用 MAFFT 進行序列比對，並以 FastTree 建構帶根發育樹 `rooted-tree.qza`。
8. **Step 11-13 - 核心多樣性分析 (Core Diversity Metrics)**：
   * 根據設定的抽樣深度進行群落均一化。
   * 計算並輸出 Alpha 多樣性指標（Faith's Phylogenetic Diversity、Evenness 等）及群組顯著性分析 (`faith-pd-group-significance.qzv`、`evenness-group-significance.qzv`)。
   * 計算 Beta 多樣性指標（Unweighted/Weighted UniFrac、Jaccard、Bray-Curtis PCoA），並輸出三維交互式 PCoA 散佈圖。
9. **Step 14 - 物種分類器比對 (Taxonomy Classification)**：
   * 使用預訓練的分類器比對 `reference-sequences.qza` 與 `reference-taxonomy.qza`，指派特徵序列的物種分類階層 (`taxonomy.qza`, `taxonomy.qzv`)。
10. **Step 15 - 物種豐度條形圖 (Taxa Barplot)**：
    * 產生直觀的交互式物種組成豐度條形圖 `taxa-bar-plots.qzv`。

---

## 🚀 執行與使用方式

本專案執行需依賴 Singularity 容器鏡像檔案 `/work1/${USER}/docker/qiime2-2026-4.sif`。請確保該鏡像存在後，使用以下方式運行。

### 1. 透過 Slurm 排程器提交後台任務 (推薦)
在專案目錄下直接提交 Slurm 腳本，任務將在計算節點後台獨立執行，不受終端機斷線影響：
```bash
sbatch run_qiime2_moving_pictures.slurm
```
* **日誌查詢**：Slurm 執行的標準輸出與錯誤日誌會存放在 `logs/` 目錄中，檔案格式為 `job-<Job_ID>.out` 與 `job-<Job_ID>.err`。
* **資源分配**：預設使用 `ct112` 分割區、1 個節點、8 個 CPU 執行緒，限時 2 小時。

### 2. 手動在 Singularity 容器中執行 (互動/偵錯)
若您處於互動式計算節點或想要逐步測試，可以使用以下指令進入容器執行：
```bash
singularity exec \
  -B "$PWD:$PWD" \
  -B "$HOME:$HOME" \
  /work1/$(whoami)/docker/qiime2-2026-4.sif \
  bash run_qiime2_moving_pictures.sh
```

---

## 📊 產出結果檢視

所有以 `.qzv` 結尾的 QIIME 2 可視化結果檔案均存放在 `moving-pictures-run/` 目錄下。您可以使用以下方式檢視這些結果：
1. 下載 `.qzv` 檔案至個人電腦，並拖曳至網頁版 [QIIME 2 View (view.qiime2.org)](https://view.qiime2.org/) 進行交互式圖表瀏覽。
2. 使用 `qiime tools view <filename>.qzv` 指令在本機瀏覽。

---

*本說明文件由 Antigravity 助理協助自動生成與整理維護。*
