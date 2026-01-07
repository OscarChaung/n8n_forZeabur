# 使用官方 n8n 2.1.2 映像（不做任何修改）
FROM n8nio/n8n:2.1.2

# 白名單：允許 Code/Function 節點使用內建模組
ENV NODE_FUNCTION_ALLOW_BUILTIN=*