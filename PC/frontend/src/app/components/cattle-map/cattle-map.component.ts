import { Component, AfterViewInit, OnDestroy, ChangeDetectorRef, PLATFORM_ID, Inject } from '@angular/core';
import { CommonModule, isPlatformBrowser } from '@angular/common';
import { CattleService } from '../../services/cattle.service';
import { Cattle } from '../../models/cattle';
import { Sensor } from '../../models/sensor';
import { LoadingSpinnerComponent } from '../loading-spinner/loading-spinner.component';
import { StatsPanelComponent } from '../stats-panel/stats-panel.component';
import { SensorChartModalComponent } from '../sensor-chart-modal/sensor-chart-modal.component';
// import * as L from 'leaflet';  

interface SelectedCattleData extends Cattle {
  sensorData: Sensor;
}

@Component({
  selector: 'app-cattle-map',
  standalone: true,
  imports: [
    CommonModule,
    LoadingSpinnerComponent,
    StatsPanelComponent,
    SensorChartModalComponent
  ],
  templateUrl: './cattle-map.component.html',
  styleUrl: './cattle-map.component.scss'
})
export class CattleMapComponent implements AfterViewInit, OnDestroy {
  cattleData: Cattle[] = [];
  selectedCattle: SelectedCattleData | null = null;
  loading = true;
  loadingSensorData = false;
  error: string | null = null;
  private map: any;
  private L: any;

  constructor(
    @Inject(PLATFORM_ID) private platformId: Object,
    private cattleService: CattleService,
    private cdr: ChangeDetectorRef
  ) {}

  ngAfterViewInit(): void {
    // 只在浏览器环境中初始化地图
    if (isPlatformBrowser(this.platformId)) {
      // 动态导入
      import('leaflet').then(leaflet => {
        this.L = leaflet;
        this.cattleService.getAllCattle().subscribe({
          next: (data) => {
            this.cattleData = data;
            this.initMap();
            this.loading = false;
            this.cdr.detectChanges();
          },
          error: (err) => {
            this.error = '无法加载牛只数据，请稍后再试';
            this.loading = false;
            this.cdr.detectChanges();
          }
        });
      });
    }
  }

  ngOnDestroy(): void {
    if (this.map) {
      this.map.remove();
    }
    
    // 移除窗口大小变化的监听
    if (isPlatformBrowser(this.platformId)) {
      window.removeEventListener('resize', () => {
        if (this.map) {
          this.map.invalidateSize();
        }
      });
    }
  }

  // 初始化地图
  private initMap(): void {
    // 创建地图实例
    this.map = this.L.map('map', {
      center: [28.2458, 112.8519],// 初始中心坐标 华宽通
      zoom: 17,
      zoomControl: true
    });

    // 添加OpenStreetMap图层
    this.L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors'
    }).addTo(this.map);

    // 添加牛只标记
    this.addCattleMarkers();

    // 确保地图尺寸正确渲染
    setTimeout(() => {
      this.map.invalidateSize();
    }, 200);

    // 添加窗口大小变化的监听
    if (isPlatformBrowser(this.platformId)) {
      window.addEventListener('resize', () => {
        if (this.map) {
          this.map.invalidateSize();
        }
      });
    }
  }

  // 添加牛只标记
  private addCattleMarkers(): void {
    this.cattleData.forEach(cattle => {
      const icon = this.createCustomIcon(cattle.healthStatus);
      const marker = this.L.marker(cattle.position as L.LatLngExpression, { icon })
        .addTo(this.map);
      
      // 添加点击事件
      marker.on('click', () => {
        this.handleSelectCattle(cattle);
      });
    });
  }

  // 健康状态对应颜色
  private getMarkerColor(status: string): string {
    switch (status) {
      case 'healthy': return '#4caf50'; // 绿色
      case 'warning': return '#ff9800'; // 橙色
      case 'critical': return '#f44336'; // 红色
      default: return '#9e9e9e'; // 灰色
    }
  }

  // 创建自定义图标
  private createCustomIcon(status: string): any {
    const color = this.getMarkerColor(status);
    const isCritical = status === 'critical';
    return this.L.divIcon({
      className: 'custom-marker',
      html: `<div class="marker-container ${isCritical ? 'critical-pulse' : ''}" style="
        width: 20px; 
        height: 20px; 
        background-color: ${color}; 
        border-radius: 50%; 
        border: 2px solid white;
        box-shadow: 0 0 4px rgba(0,0,0,0.3);
        ${isCritical ? 'animation: pulse 1.5s ease-in-out infinite; transform-origin: center;' : ''}
      "></div>`,
      iconSize: [24, 24] as L.PointExpression,
      iconAnchor: [12, 12] as L.PointExpression
    });
  }

  // 选择牛只时获取传感器数据
  handleSelectCattle(cattle: Cattle): void {
    this.loadingSensorData = true;
    this.cdr.detectChanges();
    
    this.cattleService.getCattleSensorData(cattle.id).subscribe({
      next: (sensorData) => {
        this.selectedCattle = {
          ...cattle,
          sensorData
        };
        this.loadingSensorData = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.error = '无法加载传感器数据，请稍后再试';
        this.loadingSensorData = false;
        this.cdr.detectChanges();
      }
    });
  }

  // 关闭传感器数据弹窗
  closeModal(): void {
    this.selectedCattle = null;
  }
}
