import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';

import { AuthService } from '../services/auth.service';

const SUPPORTED_LANGS = ['en', 'es'] as const;

function inferLangFromUrl(url: string): string {
  const match = /^\/(en|es)(\/|$)/i.exec(url);
  if (match && SUPPORTED_LANGS.includes(match[1].toLowerCase() as typeof SUPPORTED_LANGS[number])) {
    return match[1].toLowerCase();
  }
  return 'en';
}

export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);

  if (auth.isAuthenticated()) {
    return true;
  }

  const router = inject(Router);
  const lang =
    route.paramMap.get('lang') ??
    route.parent?.paramMap.get('lang') ??
    inferLangFromUrl(state.url);

  const normalizedLang = inferLangFromUrl(`/${(lang ?? 'en').toLowerCase()}`);

  return router.createUrlTree(['/', normalizedLang, 'login'], {
    queryParams: { returnUrl: state.url }
  });
};
