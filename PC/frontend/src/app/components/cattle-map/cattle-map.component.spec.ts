import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CattleMapComponent } from './cattle-map.component';

describe('CattleMapComponent', () => {
  let component: CattleMapComponent;
  let fixture: ComponentFixture<CattleMapComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CattleMapComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CattleMapComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
