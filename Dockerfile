# 1) 以官方 n8n 為基底
FROM n8nio/n8n:1.64.0

# 2) 切到 root 安裝你要的外部套件（可多個）
USER root
RUN npm install -g @notionhq/client pg

# 3) 回到非特權使用者
USER node

# 4) 不需要再指定 CMD，沿用官方 n8n 預設啟動指令
#    平台會依據容器輸出與暴露的 5678 port 對外提供服務
