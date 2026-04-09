import json

# 读取JSON数据
with open('database/temperature_log.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# 生成SQL插入语句
with open('.hkt/temperature_log_inserts.sql', 'w', encoding='utf-8') as f:
    f.write('INSERT INTO temperature_log (log_id, capsule_id, temperature, log_time) VALUES\n')
    for idx, d in enumerate(data):
        line = f"({d['log_id']}, '{d['capsule_id']}', {d['temperature']}, '{d['log_time']}')"
        if idx < len(data) - 1:
            f.write(line + ',\n')
        else:
            f.write(line + ';\n')

print('SQL插入语句已生成到 .hkt/temperature_log_inserts.sql') 