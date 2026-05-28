import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import EndpointsView from '../src/views/EndpointsView.vue';

let router;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/endpoints', component: EndpointsView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('EndpointsView', () => {
  it('renders tier group headings', () => {
    const wrapper = mount(EndpointsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    expect(wrapper.text()).toContain('Free');
    expect(wrapper.text()).toContain('Growth');
    expect(wrapper.text()).toContain('Scale');
  });

  it('renders endpoint paths and methods', () => {
    const wrapper = mount(EndpointsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    expect(wrapper.text()).toContain('GET');
    expect(wrapper.text()).toContain('POST');
    expect(wrapper.text()).toContain('/api/open/v1/twin/fever/list');
  });

  it('displays auth info and rate limit', () => {
    const wrapper = mount(EndpointsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    expect(wrapper.text()).toContain('认证方式');
    expect(wrapper.text()).toContain('频率限制');
    expect(wrapper.text()).toContain('X-API-Key');
  });

  it('displays method badges with correct classes', () => {
    const wrapper = mount(EndpointsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    expect(wrapper.find('.method-badge.method-get').exists()).toBe(true);
    expect(wrapper.find('.method-badge.method-post').exists()).toBe(true);
  });
});
