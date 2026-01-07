# 使用 Node.js 20 LTS Alpine 作為基底（保留 apk 套件管理器）
# 注意：Node.js 22 與 n8n 的 whatwg-url 有相容性問題
FROM node:20-alpine

USER root

# 安裝系統工具（n8n 依賴 + ffmpeg + yt-dlp）
RUN apk add --no-cache \
    git \
    openssh \
    openssl \
    graphicsmagick \
    tini \
    tzdata \
    ca-certificates \
    libc6-compat \
    ffmpeg \
    curl \
    python3

# 安裝 yt-dlp（單檔）
RUN curl -L "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp" \
      -o /usr/local/bin/yt-dlp \
 && chmod a+rx /usr/local/bin/yt-dlp

# 安裝 n8n 和其他全域模組
# full-icu: 國際化支援
# 影片：ytdl-core、fluent-ffmpeg
# Notion：@notionhq/client、notion-to-md
# Markdown：marked
RUN npm install -g \
    n8n \
    full-icu@1.5.0 \
    @notionhq/client \
    notion-to-md \
    ytdl-core \
    fluent-ffmpeg \
    marked

# 設定環境變數
ENV NODE_ENV=production
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu
ENV NODE_PATH=/usr/local/lib/node_modules
ENV SHELL=/bin/sh

# 白名單：允許 Code/Function 節點使用這些模組
ENV NODE_FUNCTION_ALLOW_EXTERNAL=@notionhq/client,notion-to-md,ytdl-core,fluent-ffmpeg,marked

# 建立工作目錄
WORKDIR /home/node
RUN mkdir -p /home/node/.n8n && chown -R node:node /home/node

# 清理暫存檔
RUN rm -rf /tmp/* /root/.npm /root/.cache

EXPOSE 5678/tcp
USER node

ENTRYPOINT ["tini", "--"]
CMD ["n8n"]