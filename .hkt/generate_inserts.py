#!/usr/bin/env python3
# 脚本用于将peristalsis_log.json的数据转换为SQL INSERT语句

import json
import os

# 读取JSON文件
json_file_path = 'database/peristalsis_log.json'
sql_output_path = '.hkt/peristalsis_inserts.sql'

try:
    with open(json_file_path, 'r', encoding='utf-8') as file:
        data = json.load(file)
        
    print(f"成功读取{len(data)}条记录")
    
    # 生成INSERT语句
    with open(sql_output_path, 'w', encoding='utf-8') as sql_file:
        sql_file.write("-- 插入蠕动日志初始数据\n")
        sql_file.write("INSERT INTO peristalsis_log (log_id, capsule_id, peristalsis_count, log_time) VALUES\n")
        
        # 生成所有记录的插入语句
        for i, record in enumerate(data):
            log_id = record['log_id']
            capsule_id = record['capsule_id']
            peristalsis_count = record['peristalsis_count']
            log_time = record['log_time']
            
            # 添加逗号或分号作为结束符
            ending = ',' if i < len(data) - 1 else ';'
            
            # 写入SQL语句
            sql_file.write(f"({log_id}, '{capsule_id}', {peristalsis_count}, '{log_time}'){ending}\n")
            
    print(f"SQL插入语句已生成到 {sql_output_path}")
    
except Exception as e:
    print(f"发生错误: {e}") 