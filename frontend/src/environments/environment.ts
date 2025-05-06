// 新增环境变量类型接口
export interface Environment {
  production: boolean;
  apiUrl: string;
}

// 使用类型断言明确类型
export const environment: Environment = {
  production: false,
  apiUrl: 'http://localhost:3000/api'
};
