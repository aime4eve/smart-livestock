import { ComponentFixture, TestBed } from '@angular/core/testing';

import { SensorChartModalComponent } from './sensor-chart-modal.component';

describe('SensorChartModalComponent', () => {
  let component: SensorChartModalComponent;
  let fixture: ComponentFixture<SensorChartModalComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [SensorChartModalComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(SensorChartModalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
