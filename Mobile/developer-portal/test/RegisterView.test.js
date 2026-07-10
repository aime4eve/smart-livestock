import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createRouter, createWebHistory } from 'vue-router';
import RegisterView from '../src/views/RegisterView.vue';

let router;

beforeEach(() => {
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/register', component: RegisterView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('RegisterView', () => {
  it('renders placeholder message', () => {
    const wrapper = mount(RegisterView, {
      global: { plugins: [router] },
    });
    expect(wrapper.text()).toContain('请联系平台管理员申请 API 访问权限');
  });

  it('shows contact information', () => {
    const wrapper = mount(RegisterView, {
      global: { plugins: [router] },
    });
    expect(wrapper.text()).toContain('api@smart-livestock.com');
    expect(wrapper.text()).toContain('400-888-9999');
  });

  it('has link back to login', () => {
    const wrapper = mount(RegisterView, {
      global: { plugins: [router] },
    });
    const links = wrapper.findAllComponents({ name: 'RouterLink' });
    const hasLoginLink = links.some((l) => l.props().to === '/login');
    expect(hasLoginLink).toBe(true);
  });
});
