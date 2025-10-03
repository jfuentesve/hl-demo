import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { TranslateModule, TranslateService } from '@ngx-translate/core';

interface TechItem {
  nameKey: string;
  descriptionKey: string;
  icon: string;
}

@Component({
  selector: 'app-about',
  standalone: true,
  templateUrl: './about.component.html',
  styleUrls: ['./about.component.scss'],
  imports: [CommonModule, RouterModule, TranslateModule]
})
export class AboutComponent {
  constructor(private translate: TranslateService) {}

  get currentLang(): 'en' | 'es' {
    const lang = (this.translate.currentLang ?? '').toLowerCase();
    return lang === 'es' ? 'es' : 'en';
  }
  readonly snapshotItems = [
    'about.hero.snapshot.items.0',
    'about.hero.snapshot.items.1',
    'about.hero.snapshot.items.2',
    'about.hero.snapshot.items.3'
  ];

  readonly architectureChain = [
    {
      icon: 'about/icon-users.svg',
      titleKey: 'about.architecture.chain.clients.title',
      copyKey: 'about.architecture.chain.clients.copy'
    },
    {
      icon: 'about/icon-route53.svg',
      titleKey: 'about.architecture.chain.route53.title',
      copyKey: 'about.architecture.chain.route53.copy'
    },
    {
      icon: 'about/icon-cloudfront.svg',
      titleKey: 'about.architecture.chain.cloudfront.title',
      copyKey: 'about.architecture.chain.cloudfront.copy'
    },
    {
      icon: 'about/icon-s3.svg',
      titleKey: 'about.architecture.chain.s3.title',
      copyKey: 'about.architecture.chain.s3.copy'
    }
  ];

  readonly pipelineStages = [
    {
      icons: [],
      titleKey: 'about.pipeline.steps.build.title',
      copyKey: 'about.pipeline.steps.build.copy'
    },
    {
      icons: ['about/icon-docker.svg', 'about/icon-ecr.svg'],
      titleKey: 'about.pipeline.steps.registry.title',
      copyKey: 'about.pipeline.steps.registry.copy'
    },
    {
      icons: ['about/icon-s3.svg', 'about/icon-cloudfront.svg'],
      titleKey: 'about.pipeline.steps.frontend.title',
      copyKey: 'about.pipeline.steps.frontend.copy'
    },
    {
      icons: ['about/icon-ecs.svg'],
      titleKey: 'about.pipeline.steps.backend.title',
      copyKey: 'about.pipeline.steps.backend.copy'
    }
  ];

  readonly techStack: TechItem[] = [
    {
      nameKey: 'about.tech.route53.name',
      descriptionKey: 'about.tech.route53.description',
      icon: 'about/icon-route53.svg'
    },
    {
      nameKey: 'about.tech.cloudfront.name',
      descriptionKey: 'about.tech.cloudfront.description',
      icon: 'about/icon-cloudfront.svg'
    },
    {
      nameKey: 'about.tech.s3.name',
      descriptionKey: 'about.tech.s3.description',
      icon: 'about/icon-s3.svg'
    },
    {
      nameKey: 'about.tech.alb.name',
      descriptionKey: 'about.tech.alb.description',
      icon: 'about/icon-alb.svg'
    },
    {
      nameKey: 'about.tech.ecs.name',
      descriptionKey: 'about.tech.ecs.description',
      icon: 'about/icon-ecs.svg'
    },
    {
      nameKey: 'about.tech.rds.name',
      descriptionKey: 'about.tech.rds.description',
      icon: 'about/icon-rds.svg'
    },
    {
      nameKey: 'about.tech.dotnet.name',
      descriptionKey: 'about.tech.dotnet.description',
      icon: 'about/icon-dotnet.svg'
    },
    {
      nameKey: 'about.tech.angular.name',
      descriptionKey: 'about.tech.angular.description',
      icon: 'about/icon-angular.svg'
    },
    {
      nameKey: 'about.tech.terraform.name',
      descriptionKey: 'about.tech.terraform.description',
      icon: 'about/icon-terraform.svg'
    },
    {
      nameKey: 'about.tech.ecr.name',
      descriptionKey: 'about.tech.ecr.description',
      icon: 'about/icon-ecr.svg'
    }
  ];

  readonly securityHighlightKeys = [
    'about.security.items.0',
    'about.security.items.1',
    'about.security.items.2',
    'about.security.items.3',
    'about.security.items.4'
  ];
}
