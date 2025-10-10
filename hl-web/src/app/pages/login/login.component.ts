import { Component, OnDestroy, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatDialog, MatDialogModule } from '@angular/material/dialog';

import { AuthService } from '../../core/services/auth.service';
import { PASSWORDS } from '../../core/constants/app.constants';
import { DemoAdminConfirmDialogComponent } from './demo-admin-confirm-dialog.component';

type DemoUser = 'alice' | 'bob' | 'admin';

@Component({
  selector: 'app-login',
  standalone: true,
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss'],
  imports: [FormsModule, MatFormFieldModule, MatInputModule, MatButtonModule, MatDialogModule, TranslateModule]
})
export class LoginComponent implements OnInit, OnDestroy {
  username = '';
  password = ***REDACTED***;
  loading = false;
  error = '';
  bannerVisible = false;
  readonly demoUsers: DemoUser[] = ['alice', 'bob', 'admin'];
  private bannerTimer?: ReturnType<typeof setTimeout>;

  constructor(
    private auth: AuthService,
    private router: Router,
    private translate: TranslateService,
    private dialog: MatDialog
  ) {}

  ngOnInit(): void {
    this.bannerTimer = setTimeout(() => (this.bannerVisible = true), 2000);
  }

  ngOnDestroy(): void {
    if (this.bannerTimer) {
      clearTimeout(this.bannerTimer);
    }
  }

  submit(): void {
    this.loading = true;
    this.error = '';

    this.auth.login(this.username, this.password).subscribe({
      next: () => {
        const lang = (this.translate.currentLang ?? '').toLowerCase() === 'es' ? 'es' : 'en';
        this.router.navigate(['/', lang, 'home']);
      },
      error: (err) => {
        this.error = err?.message ?? 'Login failed';
        this.loading = false;
      }
    });
  }

  loginAs(username: DemoUser): void {
    if (username === 'admin') {
      this.dialog.open(DemoAdminConfirmDialogComponent, {
        width: '420px'
      }).afterClosed().subscribe((confirmed) => {
        if (confirmed) {
          this.loginWithCredentials(username);
        }
      });
      return;
    }

    this.loginWithCredentials(username);
  }

  private loginWithCredentials(username: string): void {
    const password = ***REDACTED***;
    if (!password) {
      return;
    }

    this.username = username;
    this.password = ***REDACTED***;
    this.submit();
  }
}
