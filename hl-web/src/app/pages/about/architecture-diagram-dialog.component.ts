import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { MatDialogModule } from '@angular/material/dialog';

@Component({
  selector: 'app-architecture-diagram-dialog',
  standalone: true,
  template: `
    <h2 mat-dialog-title>Architecture diagram</h2>
    <mat-dialog-content>
      <picture class="diagram-wrapper">
        <source srcset="about/architecture-mobile@2x.png 2x" />
        <img src="about/architecture-mobile.png" alt="AWS architecture diagram" />
      </picture>
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
