# 使用官方 n8n 2.1.2 映像
FROM n8nio/n8n:2.1.2

USER root

# 安裝額外的 Node 模組（使用 n8n 內建的 npm）
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