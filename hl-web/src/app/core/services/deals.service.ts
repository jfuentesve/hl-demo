import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map } from 'rxjs';

import { environment } from '../../../environments/environment';
import { Deal } from '../models/deal.model';

@Injectable({ providedIn: 'root' })
export class DealsService {
  private readonly baseUrl = `${environment.apiUrl}/deals`;

  private static toDeal(dto: DealDto): Deal {
    return {
      id: dto.id,
      name: dto.title,
      client: dto.client,
      amount: Number(dto.amount),
      createdAt: dto.createdAt
    };
  }

  constructor(private http: HttpClient) {}

  list(): Observable<Deal[]> {
    return this.http
      .get<DealDto[]>(this.baseUrl)
      .pipe(map((items) => items.map(DealsService.toDeal)));
  }

  create(payload: DealInput): Observable<Deal> {
    const body = this.toApiPayload(payload);

    return this.http
      .post<DealDto>(this.baseUrl, body)
      .pipe(map(DealsService.toDeal));
  }

  remove(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }

  update(id: number, payload: DealInput): Observable<void> {
    const body = this.toApiPayload(payload);
    return this.http.put<void>(`${this.baseUrl}/${id}`, body);
  }

  private toApiPayload(payload: DealInput): DealCreatePayload {
    return {
      title: payload.name,
      client: payload.client,
      amount: payload.amount
    };
  }
}

interface DealDto {
  id: number;
  title: string;
  client: string;
  amount: number;
  createdAt: string;
}

interface DealCreatePayload {
  title: string;
  client: string;
  amount: number;
}

export interface DealInput {
  name: string;
  client: string;
  amount: number;
}
