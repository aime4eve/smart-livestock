import { describe, it, expect, beforeEach, vi } from 'vitest';
import { mount, flushPromises } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import { createRouter, createWebHistory } from 'vue-router';
import ApiKeysView from '../src/views/ApiKeysView.vue';

// Mock API client to return fixture data
vi.mock('../src/api/client.js', () => ({
  apiGet: vi.fn().mockResolvedValue({
    data: [
      {
        keyId: 'key_001',
        keyPrefix: 'sl_apikey_',
        keySuffix: 'A1B2',
        status: 'active',
        createdAt: '2026-04-15',
        rotatedAt: '2026-05-02 09:23:15',
      },
      {
        keyId: 'key_002',
        keyPrefix: 'sl_apikey_',
        keySuffix: 'C3D4',
        status: 'active',
        createdAt: '2026-03-01',
        rotatedAt: '2026-04-28 14:10:00',
      },
    ],
  }),
  apiPost: vi.fn().mockResolvedValue({ data: {} }),
}));

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
  it('renders key list', async () => {
    const wrapper = mount(ApiKeysView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    await flushPromises();

    expect(wrapper.text()).toContain('API Key 管理');
    expect(wrapper.text()).toContain('活跃');
    expect(wrapper.text()).toContain('sl_apikey_');
  });

  it('shows rotate button', async () => {
    const wrapper = mount(ApiKeysView, {
      global: {
        plugins: [createPinia(), router],
        stubs: { AppLayout: { template: '<div><slot /></div>' } },
      },
    });

    await flushPromises();

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

    await flushPromises();

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
