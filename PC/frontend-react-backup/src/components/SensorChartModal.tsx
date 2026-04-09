import React from 'react';
import { Chart, ChartOptions } from 'chart.js';
import { registerables } from 'chart.js';
import { Line } from 'react-chartjs-2';
import { CattleSensorData } from '../types/sensor';
Chart.register(...registerables);

interface Props {
  data: CattleSensorData;
  onClose: () => void;
}

/**
 * 传感器数据图表弹窗组件
 * @param data 传感器数据
 * @param onClose 关闭回调函数
 * @returns 图表弹窗JSX元素
 */
export const SensorChartModal: React.FC<Props> = ({ data, onClose }) => {
  const chartData = {
    labels: data.timestamps.map(timestamp => new Date(timestamp).toLocaleTimeString()),
    datasets: [
      {
        label: '胃温度 (°C)',
        data: data.stomachTemperatures,
        borderColor: '#ff6384',
        yAxisID: 'temperature',
        tension: 0.4,
        fill: false,
      },
      {
        label: '蠕动次数 (次/分钟)',
        data: data.peristalticCounts,
        borderColor: '#36a2eb',
        yAxisID: 'peristaltic',
        tension: 0.4,
        fill: false,
      }
    ]
  };

  const options: ChartOptions<'line'> = {
    responsive: true,
    plugins: {
      title: {
        display: true,
        text: `牛只 ${data.cattleId} 传感器数据`
      }
    },
    scales: {
      temperature: {
        type: 'linear',
        position: 'left',
        title: { display: true, text: '温度 (°C)' }
      },
      peristaltic: {
        type: 'linear',
        position: 'right',
        title: { display: true, text: '蠕动次数' },
        grid: { display: false }
      }
    }
  };

  return (
    <div style={{
      position: 'fixed',
      top: '50%',
      left: '50%',
      transform: 'translate(-50%, -50%)',
      backgroundColor: 'rgba(255, 255, 255, 0.95)',
      padding: '20px',
      borderRadius: '8px',
      boxShadow: '0 2px 10px rgba(0,0,0,0.2)',
      zIndex: 1001,
      minWidth: '600px'
    }}>
      <button 
        onClick={onClose}
        style={{
          position: 'absolute',
          right: '10px',
          top: '10px',
          background: 'none',
          border: 'none',
          cursor: 'pointer'
        }}
      >
        ×
      </button>
      <Line data={chartData} options={options} />
    </div>
  );
};