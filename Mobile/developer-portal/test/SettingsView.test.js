import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import SettingsView from '../src/views/SettingsView.vue';

let router;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/settings', component: SettingsView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('SettingsView', () => {
  it('renders account information section', () => {
    const wrapper = mount(SettingsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    expect(wrapper.text()).toContain('账户设置');
    expect(wrapper.text()).toContain('账户信息');
  });

  it('shows API usage limits', () => {
    const wrapper = mount(SettingsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    expect(wrapper.text()).toContain('每月调用配额');
    expect(wrapper.text()).toContain('速率限制');
    expect(wrapper.text()).toContain('数据保留');
  });

  it('displays default values when not logged in', () => {
    const wrapper = mount(SettingsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    expect(wrapper.text()).toContain('API 开发者');
    expect(wrapper.text()).toContain('Free');
  });
});
