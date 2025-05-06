import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { Capsule, CapsuleQueryParams } from '../models/capsule';
import { environment } from '../../environments/environment';

@Injectable({
  providedIn: 'root'
})
export class CapsuleService {
  // 使用更安全的方式定义apiUrl
  private apiUrl = environment.apiUrl ? `${environment.apiUrl}/capsules` : '/api/capsules';
  
  // 临时使用的模拟数据
  private mockCapsules: Capsule[] = [
    {
      "capsule_id": "a1b2c3d4-e5f6-47g8-h9i0-j1k2l3m4n5o6",
      "production_batch": "PB20241125-001",
      "activation_date": "2024-12-15",
      "expiration_date": "2026-12-15",
      "status": "已安装",
      "created_at": "2025-01-12T10:30:22"
    },
    {
      "capsule_id": "b2c3d4e5-f6g7-48h9-i0j1-k2l3m4n5o6p7",
      "production_batch": "PB20241220-001",
      "activation_date": "2025-01-10",
      "expiration_date": "2027-01-10",
      "status": "已安装",
      "created_at": "2025-02-07T09:45:18"
    }
  ];

  constructor(private http: HttpClient) { }

  // 获取胶囊列表，支持分页和查询条件
  getCapsules(queryParams: CapsuleQueryParams = {}): Observable<{data: Capsule[], total: number}> {
    // 注意：这里使用模拟数据，实际项目中应该连接到真实API
    // 真实API代码示例:
    /*
    let params = new HttpParams();
    
    if (queryParams.capsule_id) {
      params = params.set('capsule_id', queryParams.capsule_id);
    }
    if (queryParams.production_batch) {
      params = params.set('production_batch', queryParams.production_batch);
    }
    if (queryParams.activation_date) {
      params = params.set('activation_date', queryParams.activation_date);
    }
    if (queryParams.expiration_date) {
      params = params.set('expiration_date', queryParams.expiration_date);
    }
    if (queryParams.status) {
      params = params.set('status', queryParams.status);
    }
    if (queryParams.created_at) {
      params = params.set('created_at', queryParams.created_at);
    }
    
    const page = queryParams.page || 0;
    const pageSize = queryParams.pageSize || 20;
    
    params = params.set('page', page.toString());
    params = params.set('size', pageSize.toString());
    
    return this.http.get<{data: Capsule[], total: number}>(this.apiUrl, { params })
      .pipe(
        catchError(this.handleError<{data: Capsule[], total: number}>('getCapsules', {data: [], total: 0}))
      );
    */
    
    // 模拟实现：过滤和分页
    let filteredCapsules = [...this.mockCapsules];
    
    if (queryParams.capsule_id) {
      filteredCapsules = filteredCapsules.filter(c => 
        c.capsule_id.includes(queryParams.capsule_id || ''));
    }
    if (queryParams.production_batch) {
      filteredCapsules = filteredCapsules.filter(c => 
        c.production_batch.includes(queryParams.production_batch || ''));
    }
    if (queryParams.activation_date) {
      filteredCapsules = filteredCapsules.filter(c => 
        c.activation_date.includes(queryParams.activation_date || ''));
    }
    if (queryParams.expiration_date) {
      filteredCapsules = filteredCapsules.filter(c => 
        c.expiration_date.includes(queryParams.expiration_date || ''));
    }
    if (queryParams.status) {
      filteredCapsules = filteredCapsules.filter(c => 
        c.status === queryParams.status);
    }
    if (queryParams.created_at) {
      filteredCapsules = filteredCapsules.filter(c => 
        c.created_at.includes(queryParams.created_at || ''));
    }
    
    const total = filteredCapsules.length;
    const page = queryParams.page || 0;
    const pageSize = queryParams.pageSize || 20;
    
    // 分页
    const startIndex = page * pageSize;
    const endIndex = startIndex + pageSize;
    const paginatedCapsules = filteredCapsules.slice(startIndex, endIndex);
    
    return of({
      data: paginatedCapsules,
      total: total
    });
  }

  // 获取单个胶囊信息
  getCapsule(id: string): Observable<Capsule | null> {
    // 实际环境: return this.http.get<Capsule>(`${this.apiUrl}/${id}`);
    
    // 模拟实现
    const capsule = this.mockCapsules.find(c => c.capsule_id === id);
    return of(capsule || null);
  }

  // 创建新胶囊
  createCapsule(capsule: Capsule): Observable<Capsule> {
    // 实际环境: return this.http.post<Capsule>(this.apiUrl, capsule);
    
    // 模拟实现
    this.mockCapsules.push(capsule);
    return of(capsule);
  }

  // 更新胶囊信息
  updateCapsule(capsule: Capsule): Observable<Capsule> {
    // 实际环境: return this.http.put<Capsule>(`${this.apiUrl}/${capsule.capsule_id}`, capsule);
    
    // 模拟实现
    const index = this.mockCapsules.findIndex(c => c.capsule_id === capsule.capsule_id);
    if (index !== -1) {
      this.mockCapsules[index] = capsule;
    }
    return of(capsule);
  }

  // 删除胶囊
  deleteCapsule(id: string): Observable<void> {
    // 实际环境: return this.http.delete<void>(`${this.apiUrl}/${id}`);
    
    // 模拟实现
    const index = this.mockCapsules.findIndex(c => c.capsule_id === id);
    if (index !== -1) {
      this.mockCapsules.splice(index, 1);
    }
    return of(void 0);
  }

  // 错误处理
  private handleError<T>(operation = 'operation', result?: T) {
    return (error: any): Observable<T> => {
      console.error(`${operation} failed: ${error.message}`);
      return of(result as T);
    };
  }
} 