# 以官方 n8n 為基底
FROM n8nio/n8n:1.117.2

# 切到 root 安裝系統工具
USER root

# 安裝 ffmpeg / curl / 憑證
RUN apk add --no-cache ffmpeg curl ca-certificates

# 安裝 yt-dlp（二進位檔）
RUN curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
      -o /usr/local/bin/yt-dlp \
 && chmod a+rx /usr/local/bin/yt-dlp

# 安裝要在 Code/Function 節點使用的全域 Node 模組
RUN npm install -g @notionhq/client notion-to-md notiontomd ytdl-core fluent-ffmpeg

# 讓 n8n 的 Code/Function 節點找得到全域模組
ENV NODE_PATH=/usr/local/lib/node_modules
ENV NODE_FUNCTION_ALLOW_EXTERNAL=@notionhq/client,notion-to-md,notiontomd,ytdl-core,fluent-ffmpeg
# （可選）放行所有 Node 內建模組
# ENV NODE_FUNCTION_ALLOW_BUILTIN=*

# 回到非特權用戶
USER node

