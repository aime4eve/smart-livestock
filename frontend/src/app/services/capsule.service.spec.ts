import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';

import { CapsuleService } from './capsule.service';

describe('CapsuleService', () => {
  let service: CapsuleService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [CapsuleService]
    });
    service = TestBed.inject(CapsuleService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
}); 