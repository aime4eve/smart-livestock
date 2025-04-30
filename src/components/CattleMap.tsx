import React from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import { StatsPanel } from './StatsPanel';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import 'leaflet.fullscreen';

interface CattleData {
  id: string;
  position: [number, number];
  healthStatus: 'healthy' | 'warning' | 'critical';
}

// 全屏控制组件
const FullScreenControl = () => {
  const map = useMap();
  L.control.fullscreen().addTo(map);
  return null;
};

const CattleMap = () => {
  // 模拟牛只数据
const cattleData: CattleData[] = [
  // 新地理范围坐标（纬度28.25-28.26，经度112.895-112.910）
  { id: '1', position: [28.2551, 112.8953], healthStatus: 'healthy' },   // 公园西侧
  { id: '2', position: [28.2518, 112.9106], healthStatus: 'warning' },  // 公园东部
  { id: '3', position: [28.2594, 112.9082], healthStatus: 'critical' }, // 公园中侧
  { id: '4', position: [28.2532, 112.8991], healthStatus: 'healthy' },  // 观鸟台区域
  { id: '5', position: [28.2576, 112.9027], healthStatus: 'healthy' },  // 林荫大道
  { id: '6', position: [28.2543, 112.9075], healthStatus: 'warning' },   // 生态展示区
  { id: '7', position: [28.2569, 112.8964], healthStatus: 'healthy' },  // 西侧缓冲区
  { id: '8', position: [28.2588, 112.9093], healthStatus: 'critical' }, // 科研监测点
  { id: '9', position: [28.2521, 112.9048], healthStatus: 'healthy' },   // 游客中心
  { id: '10', position: [28.2559, 112.9012], healthStatus: 'healthy' }   // 休息区
];

  // 健康状态对应颜色
  const getMarkerIcon = (status: string) => {
    switch (status) {
      case 'healthy': return '/assets/images/健康的牛.png';
      case 'warning': return '/assets/images/有风险的牛.png';
      case 'critical': return '/assets/images/不健康的牛.png';
      default: return '/assets/images/未知状态的牛.png';
    }
  };

  // 创建自定义图标
  const createCustomIcon = (iconUrl: string) => {
    const isCritical = iconUrl.includes('不健康的牛');
    return L.divIcon({
      className: 'custom-marker',
      html: `<div class="marker-container ${isCritical ? 'critical-pulse' : ''}" style="${isCritical ? 'animation: pulse 1.5s ease-in-out infinite; transform-origin: center;' : ''}">
        <img src="${iconUrl}" style="width:32px; height:32px"/>
      </div>`,
      iconSize: [32, 32],
    });
  };

  return (
    <div className="map-container" style={{ position: 'relative', height: '100%' }}>
      <StatsPanel cattleData={cattleData} />
      <MapContainer
      center={[28.2282, 112.9388]}
      zoom={12}
      style={{ height: 'calc(100vh - 64px)', minHeight: '480px', width: '100%' }}
      zoomControl={true}
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution='© OpenStreetMap contributors'
      />
      <FullScreenControl />
      {cattleData.map((cattle) => (
        <Marker
          key={cattle.id}
          position={cattle.position}
          icon={createCustomIcon(getMarkerIcon(cattle.healthStatus))}
        >
          <Popup>
            牛只ID: {cattle.id}<br />
            健康状态: {cattle.healthStatus}
          </Popup>
        </Marker>
        ))}
    </MapContainer>
    </div>
  );
};

export default CattleMap;