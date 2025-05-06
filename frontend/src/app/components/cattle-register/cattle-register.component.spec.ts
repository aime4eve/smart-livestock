import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CattleRegisterComponent } from './cattle-register.component';

describe('CattleRegisterComponent', () => {
  let component: CattleRegisterComponent;
  let fixture: ComponentFixture<CattleRegisterComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CattleRegisterComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CattleRegisterComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
