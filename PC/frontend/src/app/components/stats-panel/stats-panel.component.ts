import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Cattle } from '../../models/cattle';

interface HealthStats {
  healthy: number;
  warning: number;
  critical: number;
}

@Component({
  selector: 'app-stats-panel',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './stats-panel.component.html',
  styleUrl: './stats-panel.component.scss'
})
export class StatsPanelComponent {
  @Input() cattleData: Cattle[] = [];
  
  // 计算健康状态分布百分比
  calculateStats(): HealthStats {
    const total = this.cattleData.length;
    if (total === 0) {
      return { healthy: 0, warning: 0, critical: 0 };
    }
    
    const counts = this.cattleData.reduce((acc, curr) => {
      const status = curr.healthStatus as keyof HealthStats;
      acc[status] = (acc[status] || 0) + 1;
      return acc;
    }, { healthy: 0, warning: 0, critical: 0 } as HealthStats);

    return {
      healthy: Math.round((counts.healthy / total) * 100),
      warning: Math.round((counts.warning / total) * 100),
      critical: Math.round((counts.critical / total) * 100)
    };
  }
}
