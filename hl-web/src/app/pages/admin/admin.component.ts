import { Component, OnInit } from '@angular/core';
import { DealsService } from '../../core/services/deals.service';
import { Deal } from '../../core/models/deal.model';
import { USERS } from '../../core/constants/app.constants';

@Component({
  selector: 'app-admin',
  templateUrl: './admin.component.html'
})
export class AdminComponent implements OnInit {
  deals: Deal[] = [];
  users = USERS.filter(u => u.role !== 'viewer');
  draft: Partial<Deal> = { name: '', client: 'alice', amount: 0 };

  constructor(private dealsSvc: DealsService) {}
  ngOnInit(): void { this.refresh(); }

  refresh() { this.dealsSvc.list().subscribe(d => this.deals = d); }
  create() { this.dealsSvc.create(this.draft).subscribe(_ => { this.draft = { name:'', client:'alice', amount:0 }; this.refresh(); }); }
  remove(id: number) { this.dealsSvc.remove(id).subscribe(_ => this.refresh()); }
}
