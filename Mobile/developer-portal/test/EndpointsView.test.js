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
    expect(wrapper.text()).toContain('Free 免费版');
    expect(wrapper.text()).toContain('Growth 成长版');
    expect(wrapper.text()).toContain('Scale 企业版');
  });

  it('renders endpoint table rows', () => {
    const wrapper = mount(EndpointsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });
    expect(wrapper.text()).toContain('GET');
    expect(wrapper.text()).toContain('POST');
    expect(wrapper.text()).toContain('查询牛只列表');
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
