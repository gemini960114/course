# RULE

1. 請一律使用繁體中文回答。技術術語保留 English，不強制翻譯。

2. 所有生成或輸出的檔案，預設存放於目前專案根目錄（Current Workspace / Working Directory）下。
   不得預設存放至：`~/`、使用者家目錄、暫存目錄或其他非專案路徑。
   若無法判定 Current Workspace / Working Directory，需先詢問我目標路徑。

3. 回答結尾不需要制式摘要；除非任務較長、涉及多個檔案，或我要求整理結論。

4. 使用 singularity 來操作 QIIME 2 套件，例如：

```bash
singularity exec -B /work1 /work1/$(whoami)/docker/qiime2-2026-4.sif qiime --help
```

執行 QIIME 2 相關指令時，預設使用上述 singularity image 與 `-B /work1` bind mount。
除非我另外指定，不要假設本機已安裝 qiime、conda 環境或 docker。

