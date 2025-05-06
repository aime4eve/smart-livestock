import { Component, Input, Output, EventEmitter, OnInit, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Sensor } from '../../models/sensor';
import { Chart, ChartConfiguration, registerables } from 'chart.js';

// Register all Chart.js components
Chart.register(...registerables);

@Component({
  selector: 'app-sensor-chart-modal',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sensor-chart-modal.component.html',
  styleUrl: './sensor-chart-modal.component.scss'
})
export class SensorChartModalComponent implements OnInit, OnChanges {
  @Input() data!: Sensor;
  @Output() close = new EventEmitter<void>();
  
  private chart: Chart | null = null;

  ngOnInit(): void {
    this.initializeChart();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['data'] && !changes['data'].firstChange) {
      this.updateChart();
    }
  }

  onClose(): void {
    this.close.emit();
  }

  private initializeChart(): void {
    // 确保可以获取到DOM元素
    setTimeout(() => {
      const ctx = document.getElementById('sensorChart') as HTMLCanvasElement;
      if (!ctx) return;

      const formattedLabels = this.data.timestamps.map(
        timestamp => new Date(timestamp).toLocaleTimeString()
      );

      // 创建Chart.js配置
      const config: ChartConfiguration<'line'> = {
        type: 'line',
        data: {
          labels: formattedLabels,
          datasets: [
            {
              label: '胃温度 (°C)',
              data: this.data.stomachTemperatures,
              borderColor: '#ff6384',
              yAxisID: 'temperature',
              tension: 0.4,
              fill: false,
            },
            {
              label: '蠕动次数 (次/分钟)',
              data: this.data.peristalticCounts,
              borderColor: '#36a2eb',
              yAxisID: 'peristaltic',
              tension: 0.4,
              fill: false,
            }
          ]
        },
        options: {
          responsive: true,
          plugins: {
            title: {
              display: true,
              text: `牛只 ${this.data.cattleId} 传感器数据`
            }
          },
          scales: {
            temperature: {
              type: 'linear',
              position: 'left',
              title: { display: true, text: '温度 (°C)' }
            },
            peristaltic: {
              type: 'linear',
              position: 'right',
              title: { display: true, text: '蠕动次数' },
              grid: { display: false }
            }
          }
        }
      };

      this.chart = new Chart(ctx, config);
    }, 0);
  }

  private updateChart(): void {
    if (!this.chart) {
      this.initializeChart();
      return;
    }

    const formattedLabels = this.data.timestamps.map(
      timestamp => new Date(timestamp).toLocaleTimeString()
    );

    this.chart.data.labels = formattedLabels;
    if (this.chart.data.datasets && this.chart.data.datasets.length >= 2) {
      this.chart.data.datasets[0].data = this.data.stomachTemperatures;
      this.chart.data.datasets[1].data = this.data.peristalticCounts;
    }

    // 更新标题
    if (this.chart.options && this.chart.options.plugins && this.chart.options.plugins.title) {
      this.chart.options.plugins.title.text = `牛只 ${this.data.cattleId} 传感器数据`;
    }

    this.chart.update();
  }
}
