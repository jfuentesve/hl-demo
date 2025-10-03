import { Component, Inject } from '@angular/core';
import { CommonModule, CurrencyPipe } from '@angular/common';
import { FormsModule, NgForm } from '@angular/forms';
import { MatDialogModule, MatDialogRef, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatButtonModule } from '@angular/material/button';
import { TranslateModule } from '@ngx-translate/core';

import { User } from '../../core/models/user.model';
import { Deal } from '../../core/models/deal.model';

export interface DealFormPayload {
  id?: number;
  name: string;
  client: string;
  amount: number;
}

interface CreateDealDialogData {
  users: User[];
  deal?: Deal;
}

@Component({
  selector: 'app-create-deal-dialog',
  standalone: true,
  templateUrl: './create-deal-dialog.component.html',
  styleUrls: ['./create-deal-dialog.component.scss'],
  providers: [CurrencyPipe],
  imports: [
    CommonModule,
    FormsModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    TranslateModule
  ]
})
export class CreateDealDialogComponent {
  model: DealFormPayload;
  amountDisplay = '$0.00';
  readonly isEdit: boolean;

  constructor(
    private dialogRef: MatDialogRef<CreateDealDialogComponent, DealFormPayload>,
    @Inject(MAT_DIALOG_DATA) public data: CreateDealDialogData,
    private currencyPipe: CurrencyPipe
  ) {
    this.isEdit = !!data.deal;
    this.model = {
      id: data.deal?.id,
      name: data.deal?.name ?? '',
      client: data.deal?.client ?? data.users[0]?.client ?? '',
      amount: data.deal ? Number(data.deal.amount) : 0
    };

    if (this.model.amount > 0) {
      this.amountDisplay =
        this.currencyPipe.transform(this.model.amount, 'USD', 'symbol', '1.2-2') ?? '$0.00';
    }
  }

  submit(form: NgForm): void {
    if (form.invalid) {
      return;
    }

    this.model.name = this.model.name.trim();
    this.dialogRef.close({ ...this.model });
  }

  cancel(): void {
    this.dialogRef.close();
  }

  onAmountKeyDown(event: KeyboardEvent): void {
    const allowedKeys = ['Backspace', 'Delete', 'Tab', 'ArrowLeft', 'ArrowRight'];
    const isNumeric = /^[0-9]$/.test(event.key);
    if (allowedKeys.includes(event.key) || isNumeric) {
      return;
    }
    event.preventDefault();
  }

  onAmountInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    const digits = input.value.replace(/[^0-9]/g, '');
    if (!digits) {
      this.amountDisplay = '$0.00';
      this.model.amount = 0;
      input.value = this.amountDisplay;
      return;
    }

    const normalized = this.toCurrencyDisplay(digits);
    this.amountDisplay = normalized.display;
    this.model.amount = normalized.amount;
    input.value = normalized.display;
  }

  private toCurrencyDisplay(digits: string): { display: string; amount: number } {
    // Ensure at least two digits for cents
    const padded = digits.replace(/^0+/, '').padStart(3, '0');
    const cents = padded.slice(-2);
    const dollars = padded.slice(0, -2);
    const numeric = Number.parseFloat(`${Number(dollars)}.${cents}`);
    const formatted = this.currencyPipe.transform(numeric, 'USD', 'symbol', '1.2-2');

    return {
      amount: Number.isNaN(numeric) ? 0 : numeric,
      display: formatted ?? '$0.00'
    };
  }
}
