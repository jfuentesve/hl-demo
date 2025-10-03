import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TranslateModule } from '@ngx-translate/core';

@Component({
  selector: 'app-landing',
  standalone: true,
  templateUrl: './landing.component.html',
  styleUrls: ['./landing.component.scss'],
  imports: [CommonModule, RouterModule, TranslateModule]
})
export class LandingComponent {
  readonly highlights = [
    { value: '$4.2B', labelKey: 'landing.highlights.transactions' },
    { value: '150+', labelKey: 'landing.highlights.institutions' },
    { value: '98%', labelKey: 'landing.highlights.retention' }
  ];

  readonly solutions = [
    {
      titleKey: 'landing.solutions.origin.title',
      copyKey: 'landing.solutions.origin.copy'
    },
    {
      titleKey: 'landing.solutions.portfolio.title',
      copyKey: 'landing.solutions.portfolio.copy'
    },
    {
      titleKey: 'landing.solutions.governance.title',
      copyKey: 'landing.solutions.governance.copy'
    }
  ];

  readonly testimonials = [
    {
      quoteKey: 'landing.testimonials.one.quote',
      authorKey: 'landing.testimonials.one.author',
      roleKey: 'landing.testimonials.one.role'
    },
    {
      quoteKey: 'landing.testimonials.two.quote',
      authorKey: 'landing.testimonials.two.author',
      roleKey: 'landing.testimonials.two.role'
    }
  ];
}
