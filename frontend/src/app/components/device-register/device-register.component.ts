import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
import { HttpClientModule } from '@angular/common/http';
import { CapsuleService } from '../../services/capsule.service';
import { Capsule, CapsuleQueryParams } from '../../models/capsule';

@Component({
  selector: 'app-device-register',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, HttpClientModule],
  templateUrl: './device-register.component.html',
  styleUrl: './device-register.component.scss'
})
export class DeviceRegisterComponent implements OnInit {
  // 数据列表
  capsules: Capsule[] = [];
  totalItems: number = 0;
  
  // 加载状态
  isLoading: boolean = false;
  loadError: string | null = null;
  
  // 分页 - 修改每页显示数量为7条
  currentPage: number = 0;
  pageSize: number = 7;
  
  // 查询参数
  queryParams: CapsuleQueryParams = {
    page: this.currentPage,
    pageSize: this.pageSize
  };
  
  // 表单
  searchForm: FormGroup;
  capsuleForm: FormGroup;
  
  // 状态选项
  statusOptions: string[] = ['已安装', '库存', '维修'];
  
  // 编辑模式
  isEditMode: boolean = false;
  currentCapsuleId: string | null = null;
  
  // 是否显示表单
  showForm: boolean = false;
  
  // 添加Math属性以便在模板中使用
  Math = Math;

  constructor(
    private capsuleService: CapsuleService,
    private fb: FormBuilder
  ) {
    // 初始化搜索表单
    this.searchForm = this.fb.group({
      capsule_id: [''],
      production_batch: [''],
      activation_date: [''],
      expiration_date: [''],
      status: [''],
      created_at: ['']
    });
    
    // 初始化新增/编辑表单
    this.capsuleForm = this.fb.group({
      capsule_id: ['', Validators.required],
      production_batch: ['', Validators.required],
      activation_date: ['', Validators.required],
      expiration_date: ['', Validators.required],
      status: ['已安装', Validators.required],
      created_at: ['']
    });
  }

  ngOnInit(): void {
    this.loadCapsules();
  }

  // 加载胶囊设备列表
  loadCapsules(): void {
    this.isLoading = true;
    this.loadError = null;
    
    console.log('开始加载设备数据...');
    
    this.capsuleService.getCapsules(this.queryParams)
      .subscribe({
        next: (response) => {
          this.capsules = response.data;
          this.totalItems = response.total;
          this.isLoading = false;
          console.log(`成功加载设备数据: ${this.capsules.length} 条记录，总计 ${this.totalItems} 条，每页显示 ${this.pageSize} 条`);
        },
        error: (error) => {
          console.error('加载设备数据失败:', error);
          this.loadError = '加载数据失败，请重试';
          this.isLoading = false;
          this.capsules = [];
          this.totalItems = 0;
        }
      });
  }

  // 重新加载数据
  reloadData(): void {
    this.capsuleService.reloadData().subscribe({
      next: (success) => {
        if (success) {
          this.loadCapsules();
        } else {
          this.loadError = '重新加载数据失败，请重试';
        }
      },
      error: (error) => {
        console.error('重新加载数据出错:', error);
        this.loadError = '重新加载数据出错，请重试';
      }
    });
  }

  // 搜索
  search(): void {
    const formValues = this.searchForm.value;
    this.queryParams = {
      ...formValues,
      page: 0, // 搜索时重置到第一页
      pageSize: this.pageSize
    };
    this.currentPage = 0;
    this.loadCapsules();
  }

  // 重置搜索
  resetSearch(): void {
    this.searchForm.reset();
    this.queryParams = {
      page: 0,
      pageSize: this.pageSize
    };
    this.currentPage = 0;
    this.loadCapsules();
  }

  // 页码变化
  onPageChange(page: number): void {
    this.currentPage = page;
    this.queryParams.page = page;
    this.loadCapsules();
  }

  // 打开新增表单
  openAddForm(): void {
    this.isEditMode = false;
    this.currentCapsuleId = null;
    this.capsuleForm.reset({
      status: '库存',
      created_at: new Date().toISOString()
    });
    // 设置状态为库存并禁用修改
    this.capsuleForm.get('status')?.disable();
    this.showForm = true;
  }

  // 打开编辑表单
  openEditForm(capsule: Capsule): void {
    this.isEditMode = true;
    this.currentCapsuleId = capsule.capsule_id;
    this.capsuleForm.setValue({
      capsule_id: capsule.capsule_id,
      production_batch: capsule.production_batch,
      activation_date: capsule.activation_date,
      expiration_date: capsule.expiration_date,
      status: capsule.status,
      created_at: capsule.created_at
    });
    // 编辑模式下允许修改状态
    this.capsuleForm.get('status')?.enable();
    this.showForm = true;
  }

  // 取消表单
  cancelForm(): void {
    this.showForm = false;
    this.capsuleForm.reset();
  }

  // 提交表单
  submitForm(): void {
    if (this.capsuleForm.invalid) {
      return;
    }

    // 获取表单值，包括禁用的控件
    const formValues = this.capsuleForm.getRawValue();
    const capsuleData: Capsule = formValues;
    
    if (!this.isEditMode) {
      // 创建新记录
      this.capsuleService.createCapsule(capsuleData)
        .subscribe({
          next: (response) => {
            this.showForm = false;
            this.loadCapsules();
            alert('设备信息添加成功！');
          },
          error: (error) => {
            console.error('添加设备信息失败:', error);
            alert('添加设备信息失败，请重试！');
          }
        });
    } else {
      // 更新记录
      this.capsuleService.updateCapsule(capsuleData)
        .subscribe({
          next: (response) => {
            this.showForm = false;
            this.loadCapsules();
            alert('设备信息更新成功！');
          },
          error: (error) => {
            console.error('更新设备信息失败:', error);
            alert('更新设备信息失败，请重试！');
          }
        });
    }
  }

  // 生成页码数组用于分页导航
  get pageNumbers(): number[] {
    const pageCount = Math.ceil(this.totalItems / this.pageSize);
    return Array.from({ length: pageCount }, (_, i) => i);
  }
}
