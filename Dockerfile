# 使用官方 n8n 2.1.2 映像（穩定版，支援 User.role）
FROM n8nio/n8n:2.1.2

USER root

# 安裝系統工具（ffmpeg、yt-dlp）
RUN apk add --no-cache \
    ffmpeg \
    curl \
    python3

# 安裝 yt-dlp（單檔）
RUN curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
      -o /usr/local/bin/yt-dlp \
 && chmod a+rx /usr/local/bin/yt-dlp

# 安裝額外的 Node 模組
RUN npm install -g \
    @notionhq/client \
    notion-to-md \
    ytdl-core \
    fluent-ffmpeg \
    marked

# 讓 Code/Function 節點找得到全域模組
ENV NODE_PATH=/usr/local/lib/node_modules

# 白名單：允許 Code/Function 節點使用這些模組
ENV NODE_FUNCTION_ALLOW_EXTERNAL=@notionhq/client,notion-to-md,ytdl-core,fluent-ffmpeg,marked

USER node