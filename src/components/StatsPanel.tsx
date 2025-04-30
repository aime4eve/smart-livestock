import React from 'react';

interface HealthStats {
  healthy: number;
  warning: number;
  critical: number;
}

interface Props {
  cattleData: any[];
}

/**
 * 健康统计面板组件
 * @param cattleData 牲畜数据数组
 * @returns 统计面板JSX元素
 */
export const StatsPanel: React.FC<Props> = ({ cattleData }) => {
  // 计算健康状态分布
  const calculateStats = (): HealthStats => {
    const total = cattleData.length;
    const counts = cattleData.reduce((acc, curr) => {
      acc[curr.healthStatus] = (acc[curr.healthStatus] || 0) + 1;
      return acc;
    }, { healthy: 0, warning: 0, critical: 0 });

    return {
      healthy: Math.round((counts.healthy / total) * 100),
      warning: Math.round((counts.warning / total) * 100),
      critical: Math.round((counts.critical / total) * 100)
    };
  };

  const stats = calculateStats();

  return (
    <div style={{
      position: 'fixed',
      right: '20px',
      top: '20px',
      backgroundColor: 'rgba(255, 255, 255, 0.9)',
      padding: '20px',
      borderRadius: '8px',
      boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
      zIndex: 1000
    }}>
      <h3 style={{ marginTop: 0 }}>健康状态统计</h3>
      <div>健康：{stats.healthy}%</div>
      <div>警告：{stats.warning}%</div>
      <div>严重：{stats.critical}%</div>
    </div>
  );
};