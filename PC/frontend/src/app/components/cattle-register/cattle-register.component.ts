import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { CattleService } from '../../services/cattle.service';
import { CapsuleService } from '../../services/capsule.service';
import { CattleDTO, CattleQueryParams, PagedResult } from '../../models/cattle';
import { Capsule } from '../../models/capsule';

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
    page: 1,  // 确保从第1页开始
    page_size: 7,
    total_pages: 0
  };
  
  // 查询条件 - 确保page从1开始
  queryParams: CattleQueryParams = {
    page: 1,  // 页码从1开始，而非0开始
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
  
  // 库存胶囊列表
  inventoryCapsules: Capsule[] = [];
  // 选中的胶囊
  selectedCapsule: Capsule | null = null;
  
  constructor(
    private cattleService: CattleService,
    private capsuleService: CapsuleService,
    private cdr: ChangeDetectorRef
  ) {
    console.log('CattleRegisterComponent 已创建');
    console.log('CattleService 注入状态:', !!cattleService);
    console.log('CapsuleService 注入状态:', !!capsuleService);
  }
  
  ngOnInit(): void {
    console.log('CattleRegisterComponent 初始化');
    console.log('初始查询参数:', JSON.stringify(this.queryParams));
    // 确保组件初始化时加载数据
    setTimeout(() => {
      console.log('执行延迟加载，确保服务准备就绪');
      this.loadCattleData();
    }, 500);
  }
  
  // 加载牛群数据
  loadCattleData(): void {
    console.log('开始加载牛群数据，参数:', JSON.stringify(this.queryParams));
    this.isLoading = true;
    this.hasError = false;
    
    this.cattleService.getFilteredCattle(this.queryParams).subscribe({
      next: (result) => {
        console.log('获取数据成功, 总数:', result.total);
        console.log('分页信息: 当前页', result.page, '总页数', result.total_pages);
        console.log('返回数据条数:', result.items?.length || 0);
        console.log('返回数据示例:', result.items?.length > 0 ? JSON.stringify(result.items[0]).substring(0, 100) + '...' : '无数据');
        
        this.pagedResult = result;
        this.cattleList = result.items;
        console.log('列表数据已更新，当前列表长度:', this.cattleList.length);
        
        // 如果列表为空但总数不为0，可能是分页问题，尝试回到第一页
        if (this.cattleList.length === 0 && result.total > 0) {
          console.warn('检测到数据异常：总数大于0但当前页为空，尝试回到第一页');
          this.queryParams.page = 1;
          this.loadCattleData();
          return;
        }
        
        this.isLoading = false;
        
        // 显示数据加载成功的调试信息
        if (this.cattleList.length > 0) {
          console.log('数据加载成功示例 - 第一条:', this.cattleList[0]);
        }
      },
      error: (err) => {
        console.error('加载牛群数据失败', err);
        console.error('错误详情:', err.message);
        
        this.hasError = true;
        this.errorMessage = '加载牛群数据失败，请稍后再试';
        this.isLoading = false;
        
        // 显示错误信息但不弹窗，减少干扰
        console.warn('加载牛群数据失败，请检查网络或服务状态');
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
      created_at: '',
      hasCapsule: '否'
    };
    this.selectedCapsule = null;
    this.loadInventoryCapsules();
    this.showForm = true;
    
    // 强制检测变更
    this.cdr.detectChanges();
  }
  
  // 加载库存胶囊
  loadInventoryCapsules(): void {
    console.log('加载库存胶囊');
    this.capsuleService.getInventoryCapsules().subscribe({
      next: (capsules) => {
        this.inventoryCapsules = capsules;
        console.log(`成功加载${this.inventoryCapsules.length}个库存胶囊`);
      },
      error: (err) => {
        console.error('加载库存胶囊失败', err);
        this.inventoryCapsules = [];
      }
    });
  }
  
  // 选择胶囊
  onCapsuleSelected(capsuleId: string): void {
    console.log('选择胶囊:', capsuleId);
    if (!capsuleId) {
      this.selectedCapsule = null;
      return;
    }
    
    const capsule = this.inventoryCapsules.find(c => c.capsule_id === capsuleId);
    this.selectedCapsule = capsule || null;
    
    if (this.selectedCapsule) {
      this.formData.hasCapsule = '是';
    } else {
      this.formData.hasCapsule = '否';
    }
  }
  
  // 打开编辑表单
  openEditForm(cattle: CattleDTO): void {
    console.log('打开编辑表单，编辑对象:', cattle);
    this.isEditMode = true;
    this.formData = { ...cattle };
    this.showForm = true;
    
    // 加载库存胶囊
    this.loadInventoryCapsules();
    
    // 查询该牛只是否已关联胶囊
    this.checkCattleCapsuleRelation(cattle.cattle_id);
  }
  
  // 查询牛只与胶囊的关联关系
  checkCattleCapsuleRelation(cattleId: number): void {
    console.log('查询牛只与胶囊的关联关系:', cattleId);
    this.selectedCapsule = null;
    
    this.cattleService.getCapsuleInstallation(cattleId).subscribe({
      next: (installation) => {
        if (installation) {
          console.log('找到牛只关联的胶囊安装记录:', installation);
          // 获取关联的胶囊详细信息
          this.capsuleService.getCapsuleById(installation.capsule_id).subscribe({
            next: (capsule) => {
              console.log('获取到关联的胶囊信息:', capsule);
              this.selectedCapsule = capsule;
              this.formData.hasCapsule = '是';
            },
            error: (err) => {
              console.error('获取关联胶囊信息失败', err);
              this.formData.hasCapsule = '否';
            }
          });
        } else {
          console.log('该牛只未关联胶囊');
          this.formData.hasCapsule = '否';
        }
      },
      error: (err) => {
        console.error('查询牛只胶囊关联关系失败', err);
        this.formData.hasCapsule = '否';
      }
    });
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
        
        // 如果选择了胶囊，添加关联关系
        if (this.selectedCapsule) {
          this.saveCapsuleInstallation(result.cattle_id, this.selectedCapsule.capsule_id);
        } else {
          this.showForm = false;
          this.loadCattleData(); // 重新加载数据
          alert('牛只信息登记成功！');
        }
      },
      error: (err) => {
        console.error('牛只信息登记失败', err);
        alert('牛只信息登记失败，请稍后再试');
      }
    });
  }
  
  // 保存胶囊安装记录
  saveCapsuleInstallation(cattleId: number, capsuleId: string): void {
    console.log('保存胶囊安装记录', cattleId, capsuleId);
    
    const installation = {
      cattle_id: cattleId,
      capsule_id: capsuleId,
      install_time: new Date().toISOString(),
      operator: 'admin'
    };
    
    this.cattleService.saveCapsuleInstallation(installation).subscribe({
      next: () => {
        console.log('胶囊安装记录保存成功');
        
        // 更新胶囊状态为已安装
        if (this.selectedCapsule) {
          const updatedCapsule = {...this.selectedCapsule};
          updatedCapsule.status = '已安装';
          
          this.capsuleService.updateCapsule(updatedCapsule).subscribe({
            next: () => {
              console.log('胶囊状态更新成功');
              this.showForm = false;
              this.loadCattleData(); // 重新加载数据
              alert('牛只信息及胶囊关联登记成功！');
            },
            error: (err) => {
              console.error('胶囊状态更新失败', err);
              this.showForm = false;
              this.loadCattleData(); // 重新加载数据
              alert('牛只信息登记成功，但胶囊状态更新失败！');
            }
          });
        } else {
          this.showForm = false;
          this.loadCattleData(); // 重新加载数据
          alert('牛只信息登记成功！');
        }
      },
      error: (err) => {
        console.error('胶囊安装记录保存失败', err);
        this.showForm = false;
        this.loadCattleData(); // 重新加载数据
        alert('牛只信息登记成功，但胶囊关联失败！');
      }
    });
  }
  
  // 更新牛只记录
  updateCattle(): void {
    console.log('更新牛只记录');
    this.cattleService.updateCattle(this.formData).subscribe({
      next: (result) => {
        console.log('牛只信息更新成功', result);
        
        // 处理胶囊关联
        if (this.selectedCapsule) {
          // 检查是否已经关联了该胶囊
          this.cattleService.getCapsuleInstallation(result.cattle_id).subscribe({
            next: (installation) => {
              if (installation && installation.capsule_id === this.selectedCapsule!.capsule_id) {
                console.log('该牛只已关联相同胶囊，无需更新');
                this.showForm = false;
                this.loadCattleData();
                alert('牛只信息更新成功！');
              } else {
                // 添加新的关联关系
                this.saveCapsuleInstallation(result.cattle_id, this.selectedCapsule!.capsule_id);
              }
            },
            error: (err) => {
              console.error('检查胶囊关联失败', err);
              this.showForm = false;
              this.loadCattleData();
              alert('牛只信息更新成功，但检查胶囊关联失败！');
            }
          });
        } else {
          this.showForm = false;
          this.loadCattleData();
          alert('牛只信息更新成功！');
        }
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
