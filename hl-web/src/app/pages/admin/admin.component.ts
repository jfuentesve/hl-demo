import { Component, OnInit, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatSort, MatSortModule } from '@angular/material/sort';
import { MatTableDataSource, MatTableModule } from '@angular/material/table';
import { MatTooltipModule } from '@angular/material/tooltip';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

import { USERS } from '../../core/constants/app.constants';
import { Deal } from '../../core/models/deal.model';
import { DealInput, DealsService } from '../../core/services/deals.service';
import { AuthService } from '../../core/services/auth.service';
import { User } from '../../core/models/user.model';
import { CreateDealDialogComponent, DealFormPayload } from './create-deal-dialog.component';
import { ConfirmDeleteDialogComponent } from './confirm-delete-dialog.component';

@Component({
  selector: 'app-admin',
  standalone: true,
  templateUrl: './admin.component.html',
  styleUrls: ['./admin.component.scss'],
  imports: [
    CommonModule,
    MatButtonModule,
    MatCardModule,
    MatDialogModule,
    MatIconModule,
    MatFormFieldModule,
    MatInputModule,
    MatProgressBarModule,
    MatSortModule,
    MatTableModule,
    MatTooltipModule,
    TranslateModule
  ]
})
export class AdminComponent implements OnInit {
  private _sort?: MatSort;

  @ViewChild(MatSort)
  set sort(sort: MatSort | undefined) {
    this._sort = sort;
    if (sort) {
      this.dataSource.sort = sort;
    }
  }

  get sort(): MatSort | undefined {
    return this._sort;
  }

  deals: Deal[] = [];
  users: User[] = USERS.filter(u => u.role !== 'viewer');
  loading = false;
  error: string | null = null;
  displayedColumns: string[] = ['id', 'name', 'client', 'amount', 'actions'];
  dataSource = new MatTableDataSource<Deal>([]);

  filters: Record<'id' | 'name' | 'client' | 'amount', string> = {
    id: '',
    name: '',
    client: '',
    amount: ''
  };

  constructor(
    private dealsSvc: DealsService,
    private auth: AuthService,
    private dialog: MatDialog,
    private translate: TranslateService
  ) {
    this.dataSource.filterPredicate = (data, rawFilter) => {
      if (!rawFilter) {
        return true;
      }

      let filters: typeof this.filters;
      try {
        filters = JSON.parse(rawFilter) as typeof this.filters;
      } catch {
        return true;
      }

      const idFilter = filters.id?.toLowerCase() ?? '';
      const nameFilter = filters.name?.toLowerCase() ?? '';
      const clientFilter = filters.client?.toLowerCase() ?? '';
      const amountFilter = filters.amount?.toLowerCase() ?? '';

      const matchesId = !idFilter || data.id.toString().toLowerCase().includes(idFilter);
      const matchesName = !nameFilter || data.name.toLowerCase().includes(nameFilter);
      const matchesClient = !clientFilter || data.client.toLowerCase().includes(clientFilter);
      const matchesAmount =
        !amountFilter ||
        data.amount
          .toString()
          .toLowerCase()
          .includes(amountFilter);

      return matchesId && matchesName && matchesClient && matchesAmount;
    };
  }

  get isAuth(): boolean {
    return this.auth.isAuthenticated();
  }

  get hasActiveFilters(): boolean {
    return Object.values(this.filters).some(Boolean);
  }

  ngOnInit(): void {
    if (this.isAuth) {
      this.refresh();
    }
  }

  refresh(): void {
    if (!this.isAuth) {
      this.deals = [];
      this.dataSource.data = [];
      return;
    }

    this.loading = true;
    this.error = null;

    this.dealsSvc.list().subscribe({
      next: (d) => {
        this.deals = d;
        this.dataSource.data = d;
        if (this.sort) {
          this.dataSource.sort = this.sort;
        }
        this.loading = false;
        this.applyFilters();
      },
      error: (err) => {
        console.error('Failed to load deals', err);
        this.error = this.translate.instant('admin.errorLoad');
        this.loading = false;
      }
    });
  }

  remove(deal: Deal): void {
    const dialogRef = this.dialog.open(ConfirmDeleteDialogComponent, {
      width: '420px',
      data: { deal }
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (!confirmed) {
        return;
      }

      this.dealsSvc.remove(deal.id).subscribe({
        next: () => this.refresh(),
        error: (err) => {
          console.error('Failed to delete deal', err);
          this.error = this.translate.instant('admin.errorDelete');
        }
      });
    });
  }

  openCreateDialog(): void {
    const dialogRef = this.dialog.open(CreateDealDialogComponent, {
      width: '420px',
      data: { users: this.users }
    });

    dialogRef.afterClosed().subscribe((result?: DealFormPayload) => {
      if (!result) {
        return;
      }
      if (result.id != null) {
        this.updateDeal(result);
      } else {
        this.createDeal(result);
      }
    });
  }

  openEditDialog(deal: Deal): void {
    const dialogRef = this.dialog.open(CreateDealDialogComponent, {
      width: '420px',
      data: { users: this.users, deal }
    });

    dialogRef.afterClosed().subscribe((result?: DealFormPayload) => {
      if (!result) {
        return;
      }
      if (result.id != null) {
        this.updateDeal(result);
      }
    });
  }

  private createDeal(payload: DealFormPayload): void {
    this.loading = true;
    this.error = null;

    this.dealsSvc.create(this.toDealInput(payload)).subscribe({
      next: () => this.refresh(),
      error: (err) => {
        console.error('Failed to create deal', err);
        this.error = this.translate.instant('createDeal.errorCreate');
        this.loading = false;
      }
    });
  }

  private updateDeal(payload: DealFormPayload): void {
    if (payload.id == null) {
      return;
    }

    this.loading = true;
    this.error = null;

    this.dealsSvc.update(payload.id, this.toDealInput(payload)).subscribe({
      next: () => this.refresh(),
      error: (err) => {
        console.error('Failed to update deal', err);
        this.error = this.translate.instant('createDeal.errorUpdate');
        this.loading = false;
      }
    });
  }

  private toDealInput(payload: DealFormPayload): DealInput {
    return {
      name: payload.name,
      client: payload.client,
      amount: payload.amount
    };
  }

  applyColumnFilter(column: keyof typeof this.filters, value: string): void {
    this.filters[column] = value.trim();
    this.applyFilters();
  }

  clearFilter(column: keyof typeof this.filters): void {
    if (!this.filters[column]) {
      return;
    }
    this.filters[column] = '';
    this.applyFilters();
  }

  clearAllFilters(): void {
    this.filters = { id: '', name: '', client: '', amount: '' };
    this.applyFilters();
  }

  private applyFilters(): void {
    const nextFilter = JSON.stringify(this.filters);
    this.dataSource.filter = Object.values(this.filters).every(val => !val)
      ? ''
      : nextFilter;
  }
}
