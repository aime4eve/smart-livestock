const express = require('express');
const router = express.Router();
const Cattle = require('../models/Cattle');
const { protect } = require('../middleware/authMiddleware');

// @desc   获取所有牛只基础信息
// @route  GET /api/cattle
// @access Private
router.get('/', protect, async (req, res) => {
  try {
    const cattle = await Cattle.find().select('cattleId position healthStatus lastUpdate');
    
    const formattedData = cattle.map(cow => ({
      id: cow.cattleId,
      position: cow.position,
      healthStatus: cow.healthStatus,
      lastUpdate: cow.lastUpdate
    }));
    
    res.json(formattedData);
  } catch (error) {
    res.status(500).json({ message: '获取牛只数据失败', error: error.message });
  }
});

// @desc   获取单个牛只详细信息
// @route  GET /api/cattle/:id
// @access Private
router.get('/:id', protect, async (req, res) => {
  try {
    const cattle = await Cattle.findOne({ cattleId: req.params.id });
    
    if (!cattle) {
      return res.status(404).json({ message: '找不到该牛只信息' });
    }
    
    res.json({
      id: cattle.cattleId,
      position: cattle.position,
      healthStatus: cattle.healthStatus,
      lastUpdate: cattle.lastUpdate,
      metadata: cattle.metadata
    });
  } catch (error) {
    res.status(500).json({ message: '获取牛只详情失败', error: error.message });
  }
});

// @desc   获取牛只传感器数据
// @route  GET /api/cattle/:id/sensors
// @access Private
router.get('/:id/sensors', protect, async (req, res) => {
  try {
    const period = parseInt(req.query.period) || 1; // 默认获取1小时数据
    const cattle = await Cattle.findOne({ cattleId: req.params.id });
    
    if (!cattle) {
      return res.status(404).json({ message: '找不到该牛只信息' });
    }
    
    // 获取指定时间段的传感器数据
    const sensorData = cattle.getSensorDataForPeriod(period);
    
    // 格式化为前端需要的格式
    const formattedData = {
      cattleId: cattle.cattleId,
      timestamps: sensorData.map(d => d.timestamp.toISOString()),
      stomachTemperatures: sensorData.map(d => d.stomachTemperature),
      peristalticCounts: sensorData.map(d => d.peristalticCount)
    };
    
    res.json(formattedData);
  } catch (error) {
    res.status(500).json({ message: '获取传感器数据失败', error: error.message });
  }
});

// @desc   添加传感器数据 (通常由设备自动上传)
// @route  POST /api/cattle/:id/sensors
// @access Private
router.post('/:id/sensors', protect, async (req, res) => {
  try {
    const { stomachTemperature, peristalticCount } = req.body;
    
    if (!stomachTemperature || !peristalticCount) {
      return res.status(400).json({ message: '传感器数据不完整' });
    }
    
    let cattle = await Cattle.findOne({ cattleId: req.params.id });
    
    if (!cattle) {
      return res.status(404).json({ message: '找不到该牛只信息' });
    }
    
    // 添加新的传感器数据点
    cattle.sensorData.push({
      timestamp: new Date(),
      stomachTemperature,
      peristalticCount
    });
    
    // 更新健康状态
    await cattle.updateHealthStatus();
    
    res.status(201).json({ 
      message: '传感器数据添加成功',
      healthStatus: cattle.healthStatus
    });
  } catch (error) {
    res.status(500).json({ message: '添加传感器数据失败', error: error.message });
  }
});

module.exports = router; 