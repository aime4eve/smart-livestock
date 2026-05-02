import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import DashboardView from '../src/views/DashboardView.vue';

let router;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/dashboard', component: DashboardView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('DashboardView', () => {
  it('renders metric cards', () => {
    const wrapper = mount(DashboardView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('本月 API 调用量');
    expect(wrapper.text()).toContain('剩余配额');
    expect(wrapper.text()).toContain('使用率');
    expect(wrapper.text()).toContain('API Key 状态');
  });

  it('shows usage stats table', () => {
    const wrapper = mount(DashboardView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('最近 API 调用记录');
    expect(wrapper.find('table.data-table').exists()).toBe(true);
  });
});
