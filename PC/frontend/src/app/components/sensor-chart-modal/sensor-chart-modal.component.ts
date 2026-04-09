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
  
  private temperatureChart: Chart | null = null;
  private peristalticChart: Chart | null = null;

  ngOnInit(): void {
    this.initializeCharts();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['data'] && !changes['data'].firstChange) {
      this.updateCharts();
    }
  }

  onClose(): void {
    this.close.emit();
  }

  private initializeCharts(): void {
    // 确保可以获取到DOM元素
    setTimeout(() => {
      this.initializeTemperatureChart();
      this.initializePeristalticChart();
    }, 0);
  }

  private initializeTemperatureChart(): void {
    const ctx = document.getElementById('temperatureChart') as HTMLCanvasElement;
    if (!ctx) return;

    const formattedLabels = this.data.timestamps.map(
      timestamp => new Date(timestamp).toLocaleTimeString()
    );

    // 创建温度图表配置
    const config: ChartConfiguration<'line'> = {
      type: 'line',
      data: {
        labels: formattedLabels,
        datasets: [
          {
            label: '胃温度 (°C)',
            data: this.data.stomachTemperatures,
            borderColor: '#ff6384',
            backgroundColor: 'rgba(255, 99, 132, 0.1)',
            borderWidth: 2,
            pointRadius: 3,
            tension: 0.4,
            fill: true,
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            position: 'top'
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            }
          },
          y: {
            title: {
              display: true,
              text: '温度 (°C)'
            },
            ticks: {
              precision: 1
            }
          }
        }
      }
    };

    this.temperatureChart = new Chart(ctx, config);
  }

  private initializePeristalticChart(): void {
    const ctx = document.getElementById('peristalticChart') as HTMLCanvasElement;
    if (!ctx) return;

    const formattedLabels = this.data.timestamps.map(
      timestamp => new Date(timestamp).toLocaleTimeString()
    );

    // 创建蠕动图表配置
    const config: ChartConfiguration<'line'> = {
      type: 'line',
      data: {
        labels: formattedLabels,
        datasets: [
          {
            label: '蠕动次数 (次/分钟)',
            data: this.data.peristalticCounts,
            borderColor: '#36a2eb',
            backgroundColor: 'rgba(54, 162, 235, 0.1)',
            borderWidth: 2,
            pointRadius: 3,
            tension: 0.4,
            fill: true,
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            position: 'top'
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            }
          },
          y: {
            title: {
              display: true,
              text: '蠕动次数'
            },
            beginAtZero: true,
            ticks: {
              stepSize: 1,
              precision: 0
            }
          }
        }
      }
    };

    this.peristalticChart = new Chart(ctx, config);
  }

  private updateCharts(): void {
    this.updateTemperatureChart();
    this.updatePeristalticChart();
  }

  private updateTemperatureChart(): void {
    if (!this.temperatureChart) {
      this.initializeTemperatureChart();
      return;
    }

    const formattedLabels = this.data.timestamps.map(
      timestamp => new Date(timestamp).toLocaleTimeString()
    );

    this.temperatureChart.data.labels = formattedLabels;
    if (this.temperatureChart.data.datasets && this.temperatureChart.data.datasets.length > 0) {
      this.temperatureChart.data.datasets[0].data = this.data.stomachTemperatures;
    }

    this.temperatureChart.update();
  }

  private updatePeristalticChart(): void {
    if (!this.peristalticChart) {
      this.initializePeristalticChart();
      return;
    }

    const formattedLabels = this.data.timestamps.map(
      timestamp => new Date(timestamp).toLocaleTimeString()
    );

    this.peristalticChart.data.labels = formattedLabels;
    if (this.peristalticChart.data.datasets && this.peristalticChart.data.datasets.length > 0) {
      this.peristalticChart.data.datasets[0].data = this.data.peristalticCounts;
    }

    this.peristalticChart.update();
  }
}
