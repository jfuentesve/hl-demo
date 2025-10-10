import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatCardModule } from '@angular/material/card';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatButtonModule } from '@angular/material/button';
import { RouterModule } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { DealsService } from '../../core/services/deals.service';
import { AuthService } from '../../core/services/auth.service';
import { Deal } from '../../core/models/deal.model';

@Component({
  selector: 'app-user-home',
  standalone: true,
  templateUrl: './user-home.component.html',
  styleUrls: ['./user-home.component.scss'],
  imports: [CommonModule, MatCardModule, MatProgressBarModule, MatButtonModule, RouterModule, TranslateModule]
})
export class UserHomeComponent implements OnInit, OnDestroy {
  loading = false;
  error: string | null = null;
  filteredDeals: Deal[] = [];
  totalAmount = 0;

  displayName = 'User';
  clientName: string | null = null;
  readonly isAdmin: boolean;
  adminBannerVisible = false;
  private bannerTimer?: ReturnType<typeof setTimeout>;

  constructor(
    private dealsSvc: DealsService,
    private auth: AuthService,
    private translate: TranslateService
  ) {
    this.displayName = this.auth.firstName ?? this.auth.username ?? 'User';
    this.clientName = this.auth.client;
    this.isAdmin = this.auth.role === 'admin';
  }

  ngOnInit(): void {
    if (this.isAdmin) {
      this.bannerTimer = setTimeout(() => (this.adminBannerVisible = true), 3000);
    }
    this.loadDeals();
  }

  ngOnDestroy(): void {
    if (this.bannerTimer) {
      clearTimeout(this.bannerTimer);
    }
  }

  get totalDeals(): number {
    return this.filteredDeals.length;
  }

  get currentLang(): 'en' | 'es' {
    const lang = (this.translate.currentLang ?? '').toLowerCase();
    return lang === 'es' ? 'es' : 'en';
  }

  private loadDeals(): void {
    this.loading = true;
    this.error = null;

    this.dealsSvc.list().subscribe({
      next: deals => {
        this.filteredDeals = this.filterByClient(deals);
        this.totalAmount = this.filteredDeals.reduce((sum, deal) => sum + Number(deal.amount ?? 0), 0);
        this.loading = false;
      },
      error: err => {
        console.error('Failed to load deals for user home', err);
        this.error = this.translate.instant('userHome.error');
        this.loading = false;
      }
    });
  }

  private filterByClient(deals: Deal[]): Deal[] {
    if (!this.clientName) {
      return deals;
    }

    const clientLower = this.clientName.toLowerCase();
    return deals.filter(deal => deal.client.toLowerCase() === clientLower);
  }
}
