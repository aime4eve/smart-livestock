export interface Capsule {
  capsule_id: string;
  production_batch: string;
  activation_date: string;
  expiration_date: string;
  status: string;
  created_at: string;
}

export interface CapsuleQueryParams {
  capsule_id?: string;
  production_batch?: string;
  activation_date?: string;
  expiration_date?: string;
  status?: string;
  created_at?: string;
  page?: number;
  pageSize?: number;
} 