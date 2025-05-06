import axios from 'axios';
import { CattleSensorData } from '../types/sensor';

// 创建axios实例
const apiClient = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:5000/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// 请求拦截器，添加认证token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 定义牛只数据接口
export interface CattleData {
  id: string;
  position: [number, number];
  healthStatus: 'healthy' | 'warning' | 'critical';
  lastUpdate: string;
}

// API方法

/**
 * 获取所有牛只数据
 */
export const getAllCattle = async (): Promise<CattleData[]> => {
  const response = await apiClient.get('/cattle');
  return response.data;
};

/**
 * 获取单个牛只信息
 * @param id 牛只ID
 */
export const getCattleById = async (id: string): Promise<CattleData> => {
  const response = await apiClient.get(`/cattle/${id}`);
  return response.data;
};

/**
 * 获取牛只传感器数据
 * @param id 牛只ID
 * @param period 时间周期(小时)，默认1小时
 */
export const getCattleSensorData = async (id: string, period: number = 1): Promise<CattleSensorData> => {
  const response = await apiClient.get(`/cattle/${id}/sensors`, {
    params: { period }
  });
  return response.data;
};

export default {
  getAllCattle,
  getCattleById,
  getCattleSensorData
}; 