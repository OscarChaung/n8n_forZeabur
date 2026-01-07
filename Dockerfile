# 使用官方 n8n 2.1.2 映像
FROM n8nio/n8n:2.1.2

USER root

# 安裝 Notion 相關模組
RUN npm install -g @notionhq/client notion-to-md

# 讓 Code/Function 節點找得到全域模組
ENV NODE_PATH=/usr/local/lib/node_modules

# 白名單：允許 Code/Function 節點使用這些模組
ENV NODE_FUNCTION_ALLOW_EXTERNAL=@notionhq/client,notion-to-md
ENV NODE_FUNCTION_ALLOW_BUILTIN=*

USER node