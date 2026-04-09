import { Component, OnInit } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, NavigationEnd, Event } from '@angular/router';
import { CommonModule } from '@angular/common';
import { filter } from 'rxjs/operators';

interface MenuItem {
  label: string;
  route?: string;
  icon?: string;
  children?: MenuItem[];
  expanded?: boolean;
}

@Component({
  selector: 'app-nav-menu',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  templateUrl: './nav-menu.component.html',
  styleUrl: './nav-menu.component.scss'
})
export class NavMenuComponent implements OnInit {
  menuItems: MenuItem[] = [
    {
      label: '牛群监控',
      route: '/map',
      icon: 'monitor'
    },
    {
      label: '系统配置',
      icon: 'settings',
      expanded: false,
      children: [
        {
          label: '牛群信息登记',
          route: '/cattle-register',
          icon: 'edit'
        },
        {
          label: '设备信息登记',
          route: '/device-register',
          icon: 'device'
        }
      ]
    }
  ];

  currentRoute: string = '';

  constructor(private router: Router) {}

  ngOnInit(): void {
    // 监听路由变化，更新当前路由
    this.router.events.subscribe((event: Event) => {
      if (event instanceof NavigationEnd) {
        this.currentRoute = event.url;
      }
    });

    // 初始化当前路由
    this.currentRoute = this.router.url;
  }

  toggleSubmenu(item: MenuItem): void {
    item.expanded = !item.expanded;
  }

  navigateTo(route?: string): void {
    if (route) {
      this.router.navigateByUrl(route);
    }
  }
}
