const fs = require('fs');
const path = require('path');

// 读取capsule.json文件
try {
  // 读取capsule数据
  const capsuleFilePath = path.join(__dirname, '../database/capsule.json');
  console.log(`尝试读取文件：${capsuleFilePath}`);
  const capsuleData = JSON.parse(fs.readFileSync(capsuleFilePath, 'utf8'));
  console.log(`成功读取capsule.json文件，共${capsuleData.length}条记录`);

  // 筛选status为"已安装"的capsule
  const installedCapsules = capsuleData.filter(capsule => capsule.status === "已安装");
  console.log(`筛选出${installedCapsules.length}个已安装的胶囊`);

  // 存储所有记录的数组
  const temperatureLogData = [];
  let logId = 1;

  // 为每个已安装的capsule生成180条体温记录
  installedCapsules.forEach(capsule => {
    // 生成基准时间（当前时间减去3天）
    const baseTime = new Date();
    baseTime.setDate(baseTime.getDate() - 3);
    
    for (let i = 0; i < 180; i++) {
      // 计算递增的时间（每条记录间隔60秒）
      const logTime = new Date(baseTime.getTime() + i * 60 * 1000);
      
      // 生成随机体温值，范围在[37.5, 39.5]之间，精确到小数点后1位
      const temperature = (Math.random() * 2 + 37.5).toFixed(1);
      
      // 创建记录对象
      const temperatureLog = {
        log_id: logId++,
        capsule_id: capsule.capsule_id,
        temperature: parseFloat(temperature),
        log_time: logTime.toISOString()
      };
      
      // 添加到记录数组
      temperatureLogData.push(temperatureLog);
    }
  });
  
  console.log(`成功生成${temperatureLogData.length}条体温记录`);
  
  // 将数据写入temperature_log.json文件
  const outputFilePath = path.join(__dirname, '../database/temperature_log.json');
  console.log(`尝试写入文件：${outputFilePath}`);
  fs.writeFileSync(
    outputFilePath, 
    JSON.stringify(temperatureLogData, null, 2),
    'utf8'
  );
  
  console.log(`成功将数据写入temperature_log.json文件`);
  
} catch (error) {
  console.error(`发生错误：${error.message}`);
  console.error(error.stack);
} 