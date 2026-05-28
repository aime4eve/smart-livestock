import { ComponentFixture, TestBed } from '@angular/core/testing';

import { DeviceRegisterComponent } from './device-register.component';

describe('DeviceRegisterComponent', () => {
  let component: DeviceRegisterComponent;
  let fixture: ComponentFixture<DeviceRegisterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DeviceRegisterComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(DeviceRegisterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
