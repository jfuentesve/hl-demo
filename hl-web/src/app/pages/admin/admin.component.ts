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

  constructor(private dealsSvc: DealsService) {}

  ngOnInit(): void {
    this.refresh();
  }

  refresh(): void {
    this.dealsSvc.list().subscribe((d) => (this.deals = d));
  }

  create(): void {
    this.dealsSvc.create(this.draft).subscribe(() => {
      this.draft = { name: '', client: 'alice', amount: 0 };
      this.refresh();
    });
  }

  remove(id: number): void {
    this.dealsSvc.remove(id).subscribe(() => this.refresh());
  }
}
