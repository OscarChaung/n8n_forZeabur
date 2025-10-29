# 以官方 n8n 為基底
FROM n8nio/n8n:1.117.2

USER root

# 系統工具與 ffmpeg
RUN apk add --no-cache ffmpeg curl ca-certificates

# 安裝 yt-dlp（單檔）
RUN curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
      -o /usr/local/bin/yt-dlp \
 && chmod a+rx /usr/local/bin/yt-dlp

# 安裝要在 Code/Function 節點使用的全域 Node 模組
# 影片：ytdl-core（JS 下載）、fluent-ffmpeg（JS 封裝）
# Notion：@notionhq/client、notion-to-md
RUN npm install -g @notionhq/client notion-to-md ytdl-core fluent-ffmpeg

# 讓 Code/Function 節點找得到全域模組
ENV NODE_PATH=/usr/local/lib/node_modules

# 白名單（可在 Zeabur 覆蓋）
ENV NODE_FUNCTION_ALLOW_EXTERNAL=@notionhq/client,notion-to-md,ytdl-core,fluent-ffmpeg
# 可選：允許所有 Node 內建模組
# ENV NODE_FUNCTION_ALLOW_BUILTIN=*

USER node
