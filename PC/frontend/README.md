# 智慧畜牧系统 - 前端

智慧畜牧系统是一个用于监控和管理牲畜的应用，包括地图显示、健康状态监控和传感器数据分析功能。前端使用Angular框架开发，提供直观的用户界面，展示后端提供的牲畜健康和位置数据。

## 技术栈

- **框架**：Angular 19
- **地图**：Leaflet
- **图表**：Chart.js
- **样式**：SCSS
- **HTTP通信**：Angular HttpClient

## 功能特性

- 地图上显示牛只位置和健康状态
- 健康状态统计面板，显示牛群健康百分比
- 传感器数据图表，可查看单个牛只的详细健康数据
- 响应式设计，适配不同设备尺寸

## 项目结构

```
frontend/
├── src/
│   ├── app/
│   │   ├── models/       # 数据模型
│   │   │   ├── cattle.ts
│   │   │   └── sensor.ts
│   │   ├── services/     # 服务
│   │   │   └── cattle.service.ts
│   │   ├── components/   # 组件
│   │   │   ├── loading-spinner/
│   │   │   ├── cattle-map/
│   │   │   ├── stats-panel/
│   │   │   └── sensor-chart-modal/
│   │   ├── app.component.*
│   │   ├── app.config.ts
│   │   └── app.routes.ts
│   ├── environments/   # 环境配置
│   │   └── environment.ts
│   ├── assets/         # 静态资源
│   │   └── images/     # 图片资源
│   └── styles.scss     # 全局样式
├── package.json
├── angular.json
└── tsconfig.json
```

## 开发指南

### 安装依赖

```bash
npm install
```

### 启动开发服务器

```bash
npm start
```

应用将在 `http://localhost:4200` 运行。

### 构建生产版本

```bash
npm run build
```

构建产物将生成在 `dist/` 目录下。

## 与后端通信

前端通过 `CattleService` 服务与后端API通信，获取牛只数据和传感器信息。API地址配置在 `environment.ts` 文件中，可根据部署环境调整。

### API示例：

- `GET /api/cattle`：获取所有牛只数据
- `GET /api/cattle/:id`：获取单个牛只详情
- `GET /api/cattle/:id/sensors`：获取牛只传感器数据

## 组件说明

### CattleMap

地图主组件，使用Leaflet显示牛只位置，并根据健康状态呈现不同颜色的标记。点击标记可查看详细传感器数据。

### StatsPanel

统计面板组件，显示牛群健康状态分布，包括健康、警告和严重状态的百分比。

### SensorChartModal

传感器数据图表模态框，使用Chart.js绘制温度和蠕动次数等传感器数据图表，帮助监控单个牛只的健康状况。

### LoadingSpinner

加载中指示器组件，在数据加载过程中显示，提供良好的用户体验。
