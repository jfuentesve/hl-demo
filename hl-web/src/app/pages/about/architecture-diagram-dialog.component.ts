import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { MatDialogModule } from '@angular/material/dialog';

@Component({
  selector: 'app-architecture-diagram-dialog',
  standalone: true,
  template: `
    <h2 mat-dialog-title>Architecture diagram</h2>
    <mat-dialog-content>
      <div class="diagram-wrapper">
        <img src="about/architecture-mobile.png" alt="AWS architecture diagram" />
      </div>
    </mat-dialog-content>
  `,
  styles: [
    `
      .diagram-wrapper {
        max-width: min(90vw, 800px);
        overflow: auto;
      }

      img {
        width: 100%;
        display: block;
        border-radius: 12px;
        box-shadow: 0 16px 32px rgba(15, 23, 42, 0.18);
      }
    `
  ],
  imports: [CommonModule, MatDialogModule]
})
export class ArchitectureDiagramDialogComponent {}
