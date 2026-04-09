# 智慧畜牧系统 - 后端API

智慧畜牧系统的后端API服务，基于Express和MongoDB开发。

## 可用脚本

在后端目录中，您可以运行：

### `npm start`

启动生产环境的服务器。

### `npm run dev`

使用nodemon启动开发环境的服务器，支持热重载。

## API文档

### 认证接口

- `POST /api/auth/register` - 注册新用户
- `POST /api/auth/login` - 用户登录

### 牲畜管理接口

- `GET /api/cattle` - 获取所有牲畜列表
- `GET /api/cattle/:id` - 获取单个牲畜详情
- `POST /api/cattle` - 添加新牲畜
- `PUT /api/cattle/:id` - 更新牲畜信息
- `DELETE /api/cattle/:id` - 删除牲畜

## 技术栈

- Node.js
- Express
- MongoDB
- JWT认证
- bcryptjs (密码加密) 