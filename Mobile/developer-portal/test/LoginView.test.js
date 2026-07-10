import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import LoginView from '../src/views/LoginView.vue';

let router;
let wrapper;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/login', component: LoginView },
      { path: '/dashboard', component: { template: '<div>Dashboard</div>' } },
    ],
  });
});

describe('LoginView', () => {
  it('renders login form', () => {
    wrapper = mount(LoginView, {
      global: {
        plugins: [createPinia(), router],
      },
    });

    expect(wrapper.text()).toContain('智慧畜牧 API 平台');
    expect(wrapper.find('input').exists()).toBe(true);
    expect(wrapper.find('button').text()).toBe('登录');
  });

  it('has default token value', () => {
    wrapper = mount(LoginView, {
      global: {
        plugins: [createPinia(), router],
      },
    });

    const input = wrapper.find('input');
    expect(input.element.value).toBe('mock-token-api-consumer');
  });
});
