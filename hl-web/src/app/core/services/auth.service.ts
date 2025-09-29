import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment';
import { USERS, PASSWORDS } from '../constants/app.constants';
import { Role } from '../models/role.type';
import { Observable, map, of, throwError } from 'rxjs';

interface LoginResponse { token: string; }

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly tokenKey = 'jwt';
  private readonly roleKey  = 'role';
  private readonly userKey  = 'username';
  private readonly clientKey = 'client';
  private readonly firstNameKey = 'firstName';
  private readonly lastNameKey = 'lastName';

  constructor(private http: HttpClient) {}

  login(username: string, password: string): Observable<void> {
    // Optional quick client-side validation (for UX + demo):
    const expected = PASSWORDS[username];
    if (!expected || expected !== password) {
      // We still call backend; if backend denies, user sees proper error.
      // return throwError(() => new Error('Invalid credentials'));
    }

    return this.http.post<LoginResponse>(
      `${environment.apiUrl}/auth/login`,
      { username, password }
    ).pipe(
      map(res => {
        console.log('Login response', res);
        const userMeta = USERS.find(u => u.username === username);
        const role = userMeta?.role ?? 'viewer';
        localStorage.setItem(this.tokenKey, res.token);
        localStorage.setItem(this.roleKey, role);
        localStorage.setItem(this.userKey, username);
        if (userMeta?.client) {
          localStorage.setItem(this.clientKey, userMeta.client);
        } else {
          localStorage.removeItem(this.clientKey);
        }
        if (userMeta?.firstName) {
          localStorage.setItem(this.firstNameKey, userMeta.firstName);
        } else {
          localStorage.removeItem(this.firstNameKey);
        }
        if (userMeta?.lastName) {
          localStorage.setItem(this.lastNameKey, userMeta.lastName);
        } else {
          localStorage.removeItem(this.lastNameKey);
        }
      })
    );
  }

  logout(): void {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.roleKey);
    localStorage.removeItem(this.userKey);
    localStorage.removeItem(this.clientKey);
    localStorage.removeItem(this.firstNameKey);
    localStorage.removeItem(this.lastNameKey);
  }

  get token(): string | null { return localStorage.getItem(this.tokenKey); }
  get role(): Role { return (localStorage.getItem(this.roleKey) as Role) ?? 'viewer'; }
  get username(): string | null { return localStorage.getItem(this.userKey); }
  get client(): string | null { return localStorage.getItem(this.clientKey); }
  get firstName(): string | null { return localStorage.getItem(this.firstNameKey); }
  get lastName(): string | null { return localStorage.getItem(this.lastNameKey); }
  get fullName(): string | null {
    const parts = [this.firstName, this.lastName].filter((p): p is string => !!p && p.trim().length > 0);
    if (parts.length > 0) {
      return parts.join(' ');
    }
    return this.username;
  }

  isAuthenticated(): boolean { return !!this.token; }
  hasRole(required: Role | Role[]): boolean {
    const r = this.role;
    return Array.isArray(required) ? required.includes(r) : r === required;
  }
}
