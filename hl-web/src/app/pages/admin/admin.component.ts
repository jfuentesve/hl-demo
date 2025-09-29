import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatDividerModule } from '@angular/material/divider';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatTableModule } from '@angular/material/table';

import { USERS } from '../../core/constants/app.constants';
import { Deal } from '../../core/models/deal.model';
import { DealsService } from '../../core/services/deals.service';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-admin',
  standalone: true,
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss'],
  imports: [
    CommonModule,
    FormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatDividerModule,
    MatTableModule
  ]
})
export class AdminComponent implements OnInit {
  deals: Deal[] = [];
  users = USERS.filter(u => u.role !== 'viewer');
  draft: Partial<Deal> = { name: '', client: 'alice', amount: 0 };
  loading = false;
  error: string | null = null;

  constructor(
    private dealsSvc: DealsService,
    private auth: AuthService
  ) {}

  get isAuth(): boolean {
    return this.auth.isAuthenticated();
  }

  ngOnInit(): void {
    if (this.isAuth) {
      this.refresh();
    }
  }

  refresh(): void {
    if (!this.isAuth) {
      this.deals = [];
      return;
    }

    this.loading = true;
    this.error = null;

    this.dealsSvc.list().subscribe({
      next: (d) => {
        this.deals = d;
        this.loading = false;
      },
      error: (err) => {
        console.error('Failed to load deals', err);
        this.error = 'Unable to load deals. Please try again.';
        this.loading = false;
      }
    });
  }

  create(): void {
    this.dealsSvc.create(this.draft).subscribe({
      next: () => {
        this.draft = { name: '', client: 'alice', amount: 0 };
        this.refresh();
      },
      error: (err) => {
        console.error('Failed to create deal', err);
        this.error = 'Unable to create deal.';
      }
    });
  }

  remove(id: number): void {
    this.dealsSvc.remove(id).subscribe({
      next: () => this.refresh(),
      error: (err) => {
        console.error('Failed to delete deal', err);
        this.error = 'Unable to delete deal.';
      }
    });
  }
}
