import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { Deal } from '../models/deal.model';

@Injectable({ providedIn: 'root' })
export class DealsService {
  private readonly baseUrl = `${environment.apiUrl}/deals`;

  constructor(private http: HttpClient) {}

  list(): Observable<Deal[]> {
    return this.http.get<Deal[]>(this.baseUrl);
  }

  create(payload: Partial<Deal>): Observable<Deal> {
    return this.http.post<Deal>(this.baseUrl, payload);
  }

  remove(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
