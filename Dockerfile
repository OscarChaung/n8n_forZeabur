# 以官方 n8n 為基底
FROM n8nio/n8n:1.117.2

# 切到 root 安裝系統相依與 CLI 工具
USER root

# 安裝 ffmpeg 與基礎套件
RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# 安裝 yt-dlp (官方建議抓最新 release 二進位檔)
RUN curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
     -o /usr/local/bin/yt-dlp \
 && chmod a+rx /usr/local/bin/yt-dlp

# 安裝需要用到的 Node 模組（全域）
# - notion 套件：@notionhq/client、notion-to-md（順手裝 notiontomd 以防你使用那個名字）
# - 影片相關：ytdl-core（JS 下載器）、fluent-ffmpeg（JS 封裝器）
RUN npm install -g @notionhq/client notion-to-md notiontomd ytdl-core fluent-ffmpeg

# 讓 Node 可以解析到全域模組（Code/Function 節點 require 時會用到）
ENV NODE_PATH=/usr/local/lib/node_modules

# 預設放行 Code/Function 節點可 require 的外部模組（必要時可在 Zeabur 環境變數覆蓋）
ENV NODE_FUNCTION_ALLOW_EXTERNAL=@notionhq/client,notion-to-md,notiontomd,ytdl-core,fluent-ffmpeg
# 若也要放行所有內建模組（可選）
# ENV NODE_FUNCTION_ALLOW_BUILTIN=*

# 切回非特權使用者
USER node

# 不需另外指定 CMD，沿用 n8n 官方映像的啟動設定
