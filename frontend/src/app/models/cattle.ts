// 牛只数据接口定义

// 原始Cattle接口，供应用内部组件使用
export type HealthStatus = 'healthy' | 'warning' | 'critical';

export interface Cattle {
  id: string;
  position: [number, number]; // 经纬度坐标
  healthStatus: HealthStatus;
  lastUpdate: string; // ISO日期字符串
}

// 牛只数据传输对象，匹配cattle.json数据结构
export interface CattleDTO {
  cattle_id: number;
  breed: string;
  birth_date: string;
  weight: number;
  gender: string;
  created_at: string;
}

// 查询条件接口
export interface CattleQueryParams {
  breed?: string;
  gender?: string;
  weight_min?: number;
  weight_max?: number; 
  birth_date_start?: string;
  birth_date_end?: string;
  created_at_start?: string;
  created_at_end?: string;
  page?: number;
  page_size?: number;
}

// 分页结果接口
export interface PagedResult<T> {
  items: T[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}
