import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatDialogModule } from '@angular/material/dialog';
import { TranslateModule } from '@ngx-translate/core';

@Component({
  selector: 'app-demo-admin-confirm-dialog',
  standalone: true,
  template: `
    <h2 mat-dialog-title>{{ 'login.demo.dialog.title' | translate }}</h2>
    <mat-dialog-content>
      <p>{{ 'login.demo.adminConfirm' | translate }}</p>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button mat-dialog-close="false">{{ 'login.demo.dialog.cancel' | translate }}</button>
      <button mat-flat-button color="warn" [mat-dialog-close]="true">
        {{ 'login.demo.dialog.confirm' | translate }}
      </button>
    </mat-dialog-actions>
  `,
  imports: [CommonModule, MatDialogModule, MatButtonModule, TranslateModule]
})
export class DemoAdminConfirmDialogComponent {}
