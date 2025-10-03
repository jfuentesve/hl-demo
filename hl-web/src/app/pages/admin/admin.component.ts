import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressBarModule } from '@angular/material/progress-bar';
import { MatTableModule } from '@angular/material/table';
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
    MatProgressBarModule,
    MatTableModule,
    MatTooltipModule,
    TranslateModule
  ]
})
export class AdminComponent implements OnInit {
  deals: Deal[] = [];
  users: User[] = USERS.filter(u => u.role !== 'viewer');
  loading = false;
  error: string | null = null;
  displayedColumns: string[] = ['id', 'name', 'client', 'amount', 'actions'];

  constructor(
    private dealsSvc: DealsService,
    private auth: AuthService,
    private dialog: MatDialog,
    private translate: TranslateService
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
}
