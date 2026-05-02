import { describe, it, expect, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import ApiKeysView from '../src/views/ApiKeysView.vue';

let router;

beforeEach(() => {
  setActivePinia(createPinia());
  router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/api-keys', component: ApiKeysView },
      { path: '/login', component: { template: '<div>Login</div>' } },
    ],
  });
});

describe('ApiKeysView', () => {
  it('renders key list', () => {
    const wrapper = mount(ApiKeysView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    expect(wrapper.text()).toContain('API Key 管理');
    expect(wrapper.text()).toContain('活跃');
    expect(wrapper.text()).toContain('sl_apikey_');
  });

  it('shows rotate button', () => {
    const wrapper = mount(ApiKeysView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    const rotateButtons = wrapper.findAll('button');
    const hasRotateBtn = rotateButtons.some((btn) => btn.text() === '轮换 Key');
    expect(hasRotateBtn).toBe(true);
  });

  it('shows confirmation dialog when rotate is clicked', async () => {
    const wrapper = mount(ApiKeysView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    // Before click, no dialog
    expect(wrapper.find('.dialog-overlay').exists()).toBe(false);

    // Click first rotate button
    const rotateBtn = wrapper.find('button:not(.btn-primary)');
    await rotateBtn.trigger('click');

    // Dialog should be visible
    expect(wrapper.find('.dialog-overlay').exists()).toBe(true);
    expect(wrapper.text()).toContain('确认轮换');
  });
});
