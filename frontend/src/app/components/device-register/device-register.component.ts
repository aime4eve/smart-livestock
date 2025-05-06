import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-device-register',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './device-register.component.html',
  styleUrl: './device-register.component.scss'
})
export class DeviceRegisterComponent {
  deviceName: string = '';
  deviceId: string = '';
  deviceType: string = '';
  installDate: string = '';
  status: string = '正常';
  description: string = '';
  
  statusOptions: string[] = ['正常', '故障', '维修中', '已停用'];
  
  registerDevice(): void {
    console.log('设备信息登记', {
      deviceName: this.deviceName,
      deviceId: this.deviceId,
      deviceType: this.deviceType,
      installDate: this.installDate,
      status: this.status,
      description: this.description
    });
    
    // 重置表单
    this.deviceName = '';
    this.deviceId = '';
    this.deviceType = '';
    this.installDate = '';
    this.status = '正常';
    this.description = '';
    
    // 这里将来可以添加与后端API的交互
    alert('设备信息登记成功！');
  }
}
