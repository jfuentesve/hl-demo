import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-landing',
  standalone: true,
  templateUrl: './landing.component.html',
  styleUrls: ['./landing.component.scss'],
  imports: [CommonModule, RouterModule]
})
export class LandingComponent {
  readonly highlights = [
    { value: '$4.2B', label: 'en transacciones habilitadas' },
    { value: '150+', label: 'instituciones asociadas' },
    { value: '98%', label: 'tasa de retención de clientes' }
  ];

  readonly solutions = [
    {
      title: 'Originación inteligente',
      copy:
        'Motor de originación impulsado por analítica predictiva para identificar oportunidades antes que el mercado.'
    },
    {
      title: 'Gestión de portafolio 360°',
      copy:
        'Supervisa flujo de caja, covenants y performance en tiempo real con dashboards adaptados a tu mesa de inversión.'
    },
    {
      title: 'Gobierno y cumplimiento',
      copy:
        'Automatiza auditorías, políticas KYC/AML y flujos de aprobación con trazabilidad completa.'
    }
  ];

  readonly testimonials = [
    {
      quote:
        'HL Deals nos dio la agilidad para cerrar estructuras complejas en días, no semanas. La visibilidad en riesgo cambió la conversación con nuestros inversionistas.',
      author: 'María Torres',
      role: 'Directora de Inversiones, Capital Nova'
    },
    {
      quote:
        'La plataforma nos permitió consolidar originación y seguimiento en un solo lugar. El equipo de HL entiende verdaderamente el negocio financiero.',
      author: 'Sebastián Ríos',
      role: 'CEO, Horizonte Partners'
    }
  ];
}
