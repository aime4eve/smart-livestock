const mongoose = require('mongoose');

// 传感器数据子文档结构
const sensorDataSchema = new mongoose.Schema({
  timestamp: {
    type: Date,
    required: true,
    default: Date.now
  },
  stomachTemperature: {
    type: Number,
    required: true
  },
  peristalticCount: {
    type: Number,
    required: true
  }
});

// 牛只模型
const cattleSchema = new mongoose.Schema({
  cattleId: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  position: {
    type: [Number], // [纬度, 经度]
    required: true,
    validate: {
      validator: function(v) {
        return v.length === 2 &&
               v[0] >= -90 && v[0] <= 90 &&
               v[1] >= -180 && v[1] <= 180;
      },
      message: '位置格式无效，应为 [纬度, 经度]'
    }
  },
  healthStatus: {
    type: String,
    enum: ['healthy', 'warning', 'critical'],
    default: 'healthy'
  },
  deviceId: {
    type: String,
    required: true,
    trim: true
  },
  sensorData: [sensorDataSchema], // 按时间顺序存储的传感器数据
  lastUpdate: {
    type: Date,
    default: Date.now
  },
  metadata: {
    age: Number,
    weight: Number,
    breed: String,
    notes: String
  }
}, { timestamps: true });

// 索引
cattleSchema.index({ cattleId: 1 });
cattleSchema.index({ 'sensorData.timestamp': -1 });
cattleSchema.index({ healthStatus: 1 });

// 方法：获取指定时间段的传感器数据
cattleSchema.methods.getSensorDataForPeriod = function(hours = 1) {
  const cutoffTime = new Date();
  cutoffTime.setHours(cutoffTime.getHours() - hours);
  
  return this.sensorData
    .filter(data => data.timestamp >= cutoffTime)
    .sort((a, b) => a.timestamp - b.timestamp);
};

// 更新健康状态的方法
cattleSchema.methods.updateHealthStatus = function() {
  const recentData = this.getSensorDataForPeriod(2);
  
  if (recentData.length === 0) return;
  
  // 计算平均温度和蠕动次数
  const avgTemp = recentData.reduce((sum, data) => sum + data.stomachTemperature, 0) / recentData.length;
  const avgPeristaltic = recentData.reduce((sum, data) => sum + data.peristalticCount, 0) / recentData.length;
  
  // 健康状态判断逻辑
  if (avgTemp > 39.5 || avgPeristaltic < 2) {
    this.healthStatus = 'critical';
  } else if (avgTemp > 39.0 || avgPeristaltic < 3) {
    this.healthStatus = 'warning';
  } else {
    this.healthStatus = 'healthy';
  }
  
  this.lastUpdate = new Date();
  return this.save();
};

module.exports = mongoose.model('Cattle', cattleSchema); 