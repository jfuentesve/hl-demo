import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterModule } from '@angular/router';
import { MatButtonModule } from '@angular/material/button';
import { MatToolbarModule } from '@angular/material/toolbar';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { MatDividerModule } from '@angular/material/divider';

import { AuthService } from '../../core/services/auth.service';
import { Role } from '../../core/models/role.type';

@Component({
  selector: 'app-navbar',
  standalone: true,
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.scss'],
  imports: [CommonModule, RouterModule, MatToolbarModule, MatButtonModule, MatIconModule, MatMenuModule, MatDividerModule]
})
export class NavbarComponent {

    constructor(private auth: AuthService, private router: Router) {}

  get isAuthenticated(): boolean {
    return this.auth.isAuthenticated();
  }

  //use of a function to check for roles
  hasRole(role: Role): boolean {
    return this.auth.hasRole(role);
  }

  // use of a getter to retrieve the current role
  get role(): Role {
    return this.auth.role;
  }

  get isUserOrAdmin(): boolean {
    return this.auth.hasRole(['user', 'admin']);
  }

  get displayName(): string {
    return this.auth.fullName ?? this.auth.username ?? '';
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/']);
  }
}
