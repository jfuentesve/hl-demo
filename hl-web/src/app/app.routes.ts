import { Routes } from '@angular/router';

import { AdminComponent } from './pages/admin/admin.component';
import { DealDetailComponent } from './pages/deal-detail/deal-detail.component';
import { LandingComponent } from './pages/landing/landing.component';
import { LoginComponent } from './pages/login/login.component';
import { UserHomeComponent } from './pages/user-home/user-home.component';
import { AboutComponent } from './pages/about/about.component';
import { languageGuard } from './core/guards/language.guard';

const localizedChildren: Routes = [
  { path: '', component: LandingComponent },
  { path: 'about', component: AboutComponent },
  { path: 'login', component: LoginComponent },
  { path: 'home', component: UserHomeComponent },
  { path: 'deals/:id', component: DealDetailComponent },
  { path: 'admin', component: AdminComponent }
];

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'en' },
  {
    path: ':lang',
    canActivate: [languageGuard],
    children: localizedChildren
  },
  { path: '**', redirectTo: 'en' }
];
