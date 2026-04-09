const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { protect, authorize } = require('../middleware/authMiddleware');

// 生成JWT token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'smart_livestock_secret', {
    expiresIn: '30d'
  });
};

// @desc   用户登录
// @route  POST /api/auth/login
// @access Public
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    // 验证输入
    if (!username || !password) {
      return res.status(400).json({ message: '请提供用户名和密码' });
    }

    // 查找用户并获取密码
    const user = await User.findOne({ username }).select('+password');

    if (!user) {
      return res.status(401).json({ message: '用户名或密码不正确' });
    }

    // 密码匹配
    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      return res.status(401).json({ message: '用户名或密码不正确' });
    }

    // 检查账户状态
    if (!user.isActive) {
      return res.status(401).json({ message: '账户已被禁用，请联系管理员' });
    }

    // 更新最后登录时间
    user.lastLogin = Date.now();
    await user.save();

    // 返回token和用户信息
    res.json({
      token: generateToken(user._id),
      user: {
        id: user._id,
        name: user.name,
        username: user.username,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ message: '登录失败', error: error.message });
  }
});

// @desc   注册新用户
// @route  POST /api/auth/register
// @access Admin
router.post('/register', protect, authorize('admin'), async (req, res) => {
  try {
    const { username, password, name, email, role, phone } = req.body;

    // 检查用户是否已存在
    const userExists = await User.findOne({ $or: [{ username }, { email }] });

    if (userExists) {
      return res.status(400).json({ message: '用户名或邮箱已被使用' });
    }

    // 创建用户
    const user = await User.create({
      username,
      password,
      name,
      email,
      role: role || 'viewer',
      phone
    });

    res.status(201).json({
      message: '用户创建成功',
      user: {
        id: user._id,
        name: user.name,
        username: user.username,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    res.status(500).json({ message: '注册失败', error: error.message });
  }
});

// @desc   获取当前用户信息
// @route  GET /api/auth/me
// @access Private
router.get('/me', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);

    res.json({
      id: user._id,
      name: user.name,
      username: user.username,
      email: user.email,
      role: user.role,
      phone: user.phone,
      lastLogin: user.lastLogin
    });
  } catch (error) {
    res.status(500).json({ message: '获取用户信息失败', error: error.message });
  }
});

module.exports = router; 