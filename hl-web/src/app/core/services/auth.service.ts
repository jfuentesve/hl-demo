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

  constructor(private http: HttpClient) {}

  login(username: string, password: string): Observable<void> {
    // Optional quick client-side validation (for UX + demo):
    const expected = PASSWORDS[username];
    if (!expected || expected !== password) {
      // We still call backend; if backend denies, user sees proper error.
      // return throwError(() => new Error('Invalid credentials'));
    }

    return this.http.post<LoginResponse>(
      `${environment.apiBaseUrl}/api/auth/login`,
      { username, password }
    ).pipe(
      map(res => {
        const role = USERS.find(u => u.username === username)?.role ?? 'viewer';
        localStorage.setItem(this.tokenKey, res.token);
        localStorage.setItem(this.roleKey, role);
        localStorage.setItem(this.userKey, username);
      })
    );
  }

  logout(): void {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.roleKey);
    localStorage.removeItem(this.userKey);
  }

  get token(): string | null { return localStorage.getItem(this.tokenKey); }
  get role(): Role { return (localStorage.getItem(this.roleKey) as Role) ?? 'viewer'; }
  get username(): string | null { return localStorage.getItem(this.userKey); }

  isAuthenticated(): boolean { return !!this.token; }
  hasRole(required: Role | Role[]): boolean {
    const r = this.role;
    return Array.isArray(required) ? required.includes(r) : r === required;
  }
}
