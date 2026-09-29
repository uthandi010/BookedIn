import { mount, flushPromises } from "@vue/test-utils";
import { createPinia, setActivePinia } from "pinia";
import { createRouter, createMemoryHistory } from "vue-router";
import { beforeEach, describe, expect, it, vi } from "vitest";
import LoginView from "../LoginView.vue";
import { useAuthStore } from "../../stores/auth";
import { ApiError } from "../../api/client";

function createTestRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: "/login", name: "login", component: LoginView },
      { path: "/register", name: "register", component: { template: "<div />" } },
      { path: "/businesses", name: "businesses", component: { template: "<div />" } },
    ],
  });
}

describe("LoginView", () => {
  let router;

  beforeEach(async () => {
    setActivePinia(createPinia());
    router = createTestRouter();
    router.push("/login");
    await router.isReady();
  });

  it("shows a validation error and does not call the store when fields are empty", async () => {
    const authStore = useAuthStore();
    authStore.login = vi.fn();

    const wrapper = mount(LoginView, { global: { plugins: [router] } });

    await wrapper.find("form").trigger("submit.prevent");

    expect(wrapper.text()).toContain("Email and password are required.");
    expect(authStore.login).not.toHaveBeenCalled();
  });

  it("logs in and navigates to /businesses on valid submit", async () => {
    const authStore = useAuthStore();
    authStore.login = vi.fn().mockResolvedValue(undefined);
    router.push = vi.fn();

    const wrapper = mount(LoginView, { global: { plugins: [router] } });

    await wrapper.find('input[type="email"]').setValue("person@example.com");
    await wrapper.find('input[type="password"]').setValue("Password123!");
    await wrapper.find("form").trigger("submit.prevent");
    await flushPromises();

    expect(authStore.login).toHaveBeenCalledWith("person@example.com", "Password123!");
    expect(router.push).toHaveBeenCalledWith({ name: "businesses" });
  });

  it("shows the server's error message when login fails", async () => {
    const authStore = useAuthStore();
    authStore.login = vi.fn().mockRejectedValue(new ApiError(401, "Invalid email or password."));

    const wrapper = mount(LoginView, { global: { plugins: [router] } });

    await wrapper.find('input[type="email"]').setValue("person@example.com");
    await wrapper.find('input[type="password"]').setValue("WrongPassword!");
    await wrapper.find("form").trigger("submit.prevent");
    await flushPromises();

    expect(wrapper.text()).toContain("Invalid email or password.");
  });
});
