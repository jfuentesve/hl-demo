import { inject } from '@angular/core';
import { HttpInterceptorFn } from '@angular/common/http';

import { AuthService } from '../services/auth.service';
import { environment } from '../../../environments/environment';

const apiBase = environment.apiUrl;

export const authTokenInterceptor: HttpInterceptorFn = (req, next) => {
  const auth = inject(AuthService);
  const token = auth.token;

  // Only attach the header for calls directed at our API
  const isApiCall = req.url.startsWith(apiBase);
  if (!token || !isApiCall) {
    return next(req);
  }

  const authorized = req.clone({
    setHeaders: { Authorization: `Bearer ${token}` }
  });

  return next(authorized);
};
