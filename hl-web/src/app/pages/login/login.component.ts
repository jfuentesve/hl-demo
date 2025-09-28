import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../../core/services/auth.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html'
})
export class LoginComponent {
  username = '';
  password = ***REDACTED***;
  loading = false;
  error = '';

  constructor(private auth: AuthService, private router: Router) {}

  submit() {
    this.loading = true; this.error = '';
    this.auth.login(this.username, this.password).subscribe({
      next: () => this.router.navigate(['/home']),
      error: err => { this.error = err?.message ?? 'Login failed'; this.loading = false; }
    });
  }
}
