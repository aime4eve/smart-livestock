import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import AuthorizationsView from '../src/views/AuthorizationsView.vue';

let router;

// Mock API client so store fetchAuthorizations does not hit network
vi.mock('../src/api/client.js', () => ({
  apiGet: vi.fn().mockResolvedValue({ data: { items: [], page: 1, pageSize: 20, total: 0 } }),
  apiPost: vi.fn().mockResolvedValue({ data: { id: 'auth_999', status: 'pending' } }),
}));

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/authorizations', component: AuthorizationsView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('AuthorizationsView', () => {
  it('renders data authorization heading', async () => {
    const wrapper = mount(AuthorizationsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    await flushPromises();
    expect(wrapper.text()).toContain('数据授权');
  });

  it('shows new application button', async () => {
    const wrapper = mount(AuthorizationsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    await flushPromises();
    const buttons = wrapper.findAll('button');
    const hasNewAppBtn = buttons.some((b) => b.text().includes('新建申请'));
    expect(hasNewAppBtn).toBe(true);
  });

  it('toggles application form visibility', async () => {
    const wrapper = mount(AuthorizationsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    await flushPromises();
    expect(wrapper.find('.form-group').exists()).toBe(false);
    const toggleBtn = wrapper.findAll('button').find((b) => b.text().includes('新建申请'));
    await toggleBtn.trigger('click');
    expect(wrapper.find('.form-group').exists()).toBe(true);
    expect(wrapper.text()).toContain('新建数据访问申请');
  });

  it('shows empty state when no authorizations', async () => {
    const wrapper = mount(AuthorizationsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    await flushPromises();
    expect(wrapper.text()).toContain('暂无数据授权记录');
  });
});
