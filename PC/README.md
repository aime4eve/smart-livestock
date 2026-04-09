# 智慧畜牧系统

智慧畜牧系统是一个用于畜牧场管理的综合系统，包含前端和后端组件。

## 项目结构

项目采用前后端分离的架构：

- `frontend/`: Angular 19 + TypeScript前端应用
- `backend/`: Express + MongoDB后端API服务
- `frontend-react-backup/`: 原React前端代码备份

## 安装与运行

### 安装依赖

```bash
# 安装根目录依赖
npm install

# 安装前端依赖
cd frontend && npm install

# 安装后端依赖
cd backend && npm install
```

### 开发模式

同时启动前端和后端服务：

```bash
npm start
```

只启动前端：

```bash
cd frontend && npm start
```

只启动后端：

```bash
cd backend && npm start
```

### 构建前端

```bash
cd frontend && npm run build
```

## 技术栈

### 前端
- Angular 19
- TypeScript
- Chart.js
- Leaflet (地图功能)

### 后端
- Node.js
- Express
- MongoDB
- JWT 认证

## 主要功能

该系统提供以下主要功能：

1. **地图显示**：在地图上实时显示牛只位置和健康状态
2. **健康监控**：通过颜色和统计图表直观展示牛只健康状况
3. **传感器数据分析**：查看单个牛只的温度和蠕动次数等传感器数据
4. **数据统计**：提供整体牧场的健康状态百分比统计

## 模块说明

### 前端模块

- `cattle-map`: 地图组件，显示牛只位置和健康状态
- `stats-panel`: 统计面板，展示牛群健康状况统计
- `sensor-chart-modal`: 传感器数据图表，显示单个牛只的传感器数据
- `cattle.service`: 服务模块，处理与后端API的通信

### 后端模块

- API服务：提供RESTful API接口
- 数据存储：处理MongoDB数据库操作
- 认证服务：处理用户认证和授权

## 开发文档

详细的开发文档请参考各目录下的README文件：

- [前端文档](./frontend/README.md)
- [后端文档](./backend/README.md)
