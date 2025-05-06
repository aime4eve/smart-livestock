import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { CattleService } from '../../services/cattle.service';
import { CattleDTO, CattleQueryParams, PagedResult } from '../../models/cattle';

@Component({
  selector: 'app-cattle-register',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './cattle-register.component.html',
  styleUrl: './cattle-register.component.scss'
})
export class CattleRegisterComponent implements OnInit {
  // 牛群列表和分页数据
  cattleList: CattleDTO[] = [];
  pagedResult: PagedResult<CattleDTO> = {
    items: [],
    total: 0,
    page: 1,
    page_size: 7,
    total_pages: 0
  };
  
  // 查询条件
  queryParams: CattleQueryParams = {
    page: 1,
    page_size: 7
  };
  
  // 表单数据
  formData: CattleDTO = {
    cattle_id: 0,
    breed: '',
    birth_date: '',
    weight: 0,
    gender: '',
    created_at: ''
  };
  
  // 编辑模式
  isEditMode = false;
  showForm = false;
  
  // 调试标志
  isLoading = false;
  hasError = false;
  errorMessage = '';
  
  constructor(private cattleService: CattleService) {
    console.log('CattleRegisterComponent 已创建');
    console.log('CattleService 注入状态:', !!cattleService);
  }
  
  ngOnInit(): void {
    console.log('CattleRegisterComponent 初始化');
    this.loadCattleData();
  }
  
  // 加载牛群数据
  loadCattleData(): void {
    console.log('开始加载牛群数据，参数:', this.queryParams);
    this.isLoading = true;
    this.hasError = false;
    
    this.cattleService.getFilteredCattle(this.queryParams).subscribe({
      next: (result) => {
        console.log('获取数据成功:', result);
        this.pagedResult = result;
        this.cattleList = result.items;
        console.log('列表数据已更新，当前列表长度:', this.cattleList.length);
        this.isLoading = false;
      },
      error: (err) => {
        console.error('加载牛群数据失败', err);
        this.hasError = true;
        this.errorMessage = '加载牛群数据失败，请稍后再试';
        this.isLoading = false;
        alert('加载牛群数据失败，请稍后再试');
      }
    });
  }
  
  // 查询牛群数据
  searchCattle(): void {
    console.log('执行查询，条件:', this.queryParams);
    // 重置到第一页
    this.queryParams.page = 1;
    this.loadCattleData();
  }
  
  // 重置查询条件
  resetQuery(): void {
    console.log('重置查询条件');
    this.queryParams = {
      page: 1,
      page_size: 7
    };
    this.loadCattleData();
  }
  
  // 切换页码
  changePage(page: number): void {
    console.log('切换页码:', page);
    if (page < 1 || page > this.pagedResult.total_pages) {
      console.log('页码超出范围，不执行操作');
      return;
    }
    this.queryParams.page = page;
    this.loadCattleData();
  }
  
  // 打开添加表单
  openAddForm(): void {
    console.log('打开添加表单');
    this.isEditMode = false;
    this.formData = {
      cattle_id: 0,
      breed: '',
      birth_date: '',
      weight: 0,
      gender: '',
      created_at: ''
    };
    this.showForm = true;
  }
  
  // 打开编辑表单
  openEditForm(cattle: CattleDTO): void {
    console.log('打开编辑表单，编辑对象:', cattle);
    this.isEditMode = true;
    this.formData = { ...cattle };
    this.showForm = true;
  }
  
  // 关闭表单
  closeForm(): void {
    console.log('关闭表单');
    this.showForm = false;
  }
  
  // 保存牛只数据（添加或更新）
  saveCattle(): void {
    console.log('保存牛只数据');
    if (this.validateForm()) {
      if (this.isEditMode) {
        this.updateCattle();
      } else {
        this.addCattle();
      }
    }
  }
  
  // 添加牛只记录
  addCattle(): void {
    console.log('添加牛只记录');
    // 设置创建时间
    this.formData.created_at = new Date().toISOString();
    
    this.cattleService.addCattle(this.formData).subscribe({
      next: (result) => {
        console.log('牛只信息登记成功', result);
        this.showForm = false;
        this.loadCattleData(); // 重新加载数据
        alert('牛只信息登记成功！');
      },
      error: (err) => {
        console.error('牛只信息登记失败', err);
        alert('牛只信息登记失败，请稍后再试');
      }
    });
  }
  
  // 更新牛只记录
  updateCattle(): void {
    console.log('更新牛只记录');
    this.cattleService.updateCattle(this.formData).subscribe({
      next: (result) => {
        console.log('牛只信息更新成功', result);
        this.showForm = false;
        this.loadCattleData(); // 重新加载数据
        alert('牛只信息更新成功！');
      },
      error: (err) => {
        console.error('牛只信息更新失败', err);
        alert('牛只信息更新失败，请稍后再试');
      }
    });
  }
  
  // 表单验证
  validateForm(): boolean {
    console.log('验证表单');
    if (!this.formData.breed || this.formData.breed.trim() === '') {
      alert('请输入牛的品种');
      return false;
    }
    
    if (!this.formData.birth_date) {
      alert('请选择出生日期');
      return false;
    }
    
    if (!this.formData.gender || this.formData.gender.trim() === '') {
      alert('请选择性别');
      return false;
    }
    
    if (!this.formData.weight || this.formData.weight <= 0) {
      alert('请输入有效的体重');
      return false;
    }
    
    return true;
  }
}
