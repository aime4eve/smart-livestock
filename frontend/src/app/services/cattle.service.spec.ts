import { TestBed } from '@angular/core/testing';

import { CattleService } from './cattle.service';

describe('CattleService', () => {
  let service: CattleService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(CattleService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
