import React, { useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import { StatsPanel } from './StatsPanel';
import { SensorChartModal } from './SensorChartModal';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import 'leaflet.fullscreen';
import { CattleSensorData, generateSensorData } from '../types/sensor';

interface CattleData {
  id: string;
  position: [number, number];
  healthStatus: 'healthy' | 'warning' | 'critical';
  sensorData: CattleSensorData;
}

// 全屏控制组件
const FullScreenControl = () => {
  const map = useMap();
  L.control.fullscreen().addTo(map);
  return null;
};

const CattleMap = () => {
  // 模拟牛数据
  const cattleData: CattleData[] = Array.from({ length: 50 }, (_, i) => ({
    id: (i + 1).toString(),
    position: [28.25 + Math.random() * 0.01, 112.895 + Math.random() * 0.015],
    healthStatus: Math.random() < 0.8 ? 'healthy' : (Math.random() < 0.5 ? 'warning' : 'critical'),
    sensorData: generateSensorData()
  }));

  const [selectedCattle, setSelectedCattle] = useState<CattleData | null>(null);

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
            eventHandlers={{ click: () => setSelectedCattle(cattle) }}
          />
        ))}
      </MapContainer>
      {selectedCattle && <SensorChartModal data={selectedCattle.sensorData} onClose={() => setSelectedCattle(null)} />}
    </div>
  );
};

export default CattleMap;