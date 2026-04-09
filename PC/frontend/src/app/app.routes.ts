import { Routes } from '@angular/router';
import { CattleMapComponent } from './components/cattle-map/cattle-map.component';
import { CattleRegisterComponent } from './components/cattle-register/cattle-register.component';
import { DeviceRegisterComponent } from './components/device-register/device-register.component';
import { HomeComponent } from './components/home/home.component';

export const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'home', component: HomeComponent },
  { path: 'map', component: CattleMapComponent },
  { path: 'cattle-register', component: CattleRegisterComponent },
  { path: 'device-register', component: DeviceRegisterComponent },
  { path: '**', redirectTo: '' }
];
