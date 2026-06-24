FROM postgres:16
COPY pg_hba.conf /etc/postgresql/pg_hba.conf
# COPY 保留源文件权限（host 上 600），postgres 进程（非 root）读不了 →
# 启动 FATAL: could not load pg_hba.conf。显式放开读权限
# （pg_hba.conf 仅认证规则，无敏感凭据）。
RUN chmod 644 /etc/postgresql/pg_hba.conf
