import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-cattle-register',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './cattle-register.component.html',
  styleUrl: './cattle-register.component.scss'
})
export class CattleRegisterComponent {
  cattleName: string = '';
  cattleId: string = '';
  breed: string = '';
  birthDate: string = '';
  weight: number | null = null;
  
  registerCattle(): void {
    console.log('牛群信息登记', {
      cattleName: this.cattleName,
      cattleId: this.cattleId,
      breed: this.breed,
      birthDate: this.birthDate,
      weight: this.weight
    });
    
    // 重置表单
    this.cattleName = '';
    this.cattleId = '';
    this.breed = '';
    this.birthDate = '';
    this.weight = null;
    
    // 这里将来可以添加与后端API的交互
    alert('牛群信息登记成功！');
  }
}
