import { Routes } from '@angular/router';

import { AdminComponent } from './pages/admin/admin.component';
import { DealDetailComponent } from './pages/deal-detail/deal-detail.component';
import { LandingComponent } from './pages/landing/landing.component';
import { LoginComponent } from './pages/login/login.component';
import { UserHomeComponent } from './pages/user-home/user-home.component';
import { AboutComponent } from './pages/about/about.component';

export const routes: Routes = [
  { path: '', component: LandingComponent },
  { path: 'about', component: AboutComponent },
  { path: 'login', component: LoginComponent },
  { path: 'home', component: UserHomeComponent },
  { path: 'deals/:id', component: DealDetailComponent },
  { path: 'admin', component: AdminComponent },
  { path: '**', redirectTo: '' }
];
