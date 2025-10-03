import { CanActivateFn, Router, RouterStateSnapshot, UrlTree } from '@angular/router';
import { inject } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';

const SUPPORTED_LANGS = ['en', 'es'] as const;
type SupportedLang = (typeof SUPPORTED_LANGS)[number];

function normalizeLang(lang: string | null | undefined): SupportedLang {
  const lower = (lang ?? '').toLowerCase();
  return SUPPORTED_LANGS.includes(lower as SupportedLang) ? (lower as SupportedLang) : 'en';
}

export const languageGuard: CanActivateFn = (route, state: RouterStateSnapshot): boolean | UrlTree => {
  const router = inject(Router);
  const translate = inject(TranslateService);

  const paramLang = route.paramMap.get('lang');
  const lowerParam = (paramLang ?? '').toLowerCase();
  const langToUse = normalizeLang(paramLang);
  const isSupported = SUPPORTED_LANGS.includes(lowerParam as SupportedLang);

  if (translate.currentLang !== langToUse) {
    translate.use(langToUse);
    localStorage.setItem('hl-lang', langToUse);
  }

  if (!isSupported) {
    const currentUrl = state.url.startsWith('/') ? state.url : `/${state.url}`;
    return router.parseUrl(`/${langToUse}${currentUrl}`);
  }

  if (paramLang !== lowerParam) {
    const url = state.url;
    const qIndex = url.indexOf('?');
    const hIndex = url.indexOf('#');
    let cutIndex = -1;
    for (const index of [qIndex, hIndex]) {
      if (index >= 0 && (cutIndex === -1 || index < cutIndex)) {
        cutIndex = index;
      }
    }

    const path = cutIndex >= 0 ? url.slice(0, cutIndex) : url;
    const suffix = cutIndex >= 0 ? url.slice(cutIndex) : '';
    const remainder = path.replace(/^\/[^\/]*/, '');

    return router.parseUrl(`/${langToUse}${remainder}${suffix}`);
  }

  return true;
};
