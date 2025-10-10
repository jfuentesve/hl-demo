import { APP_INITIALIZER, EnvironmentProviders, importProvidersFrom, makeEnvironmentProviders } from '@angular/core';
import { TranslateModule, TranslateService, provideTranslateService } from '@ngx-translate/core';
import { provideTranslateHttpLoader } from '@ngx-translate/http-loader';

import packageJson from '../../../../package.json' assert { type: 'json' };

const TRANSLATION_VERSION = typeof packageJson.version === 'string' ? packageJson.version : 'dev';

export function provideTranslation(): EnvironmentProviders {
  return makeEnvironmentProviders([
    importProvidersFrom(TranslateModule),
    provideTranslateService(),
    ...provideTranslateHttpLoader({
      prefix: 'assets/i18n/',
      suffix: `.json?v=${TRANSLATION_VERSION}`
    }),
    {
      provide: APP_INITIALIZER,
      multi: true,
      deps: [TranslateService],
      useFactory: (translate: TranslateService) => () => {
        const browserLang = translate.getBrowserLang();
        const savedLang = localStorage.getItem('hl-lang');
        const langToUse = savedLang || (browserLang ? browserLang.split('-')[0] : 'es');

        translate.addLangs(['es', 'en']);
        translate.setDefaultLang('en');
        translate.use(langToUse === 'es' ? 'es' : 'en');
      }
    }
  ]);
}
