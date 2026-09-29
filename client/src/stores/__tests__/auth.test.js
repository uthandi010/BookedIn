import { setActivePinia, createPinia } from "pinia";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { useAuthStore } from "../auth";
import { getToken } from "../../api/client";

vi.mock("../../api/auth", () => ({
  login: vi.fn(async (email) => ({ token: "test-token", userId: 1, name: "Test User", email })),
  register: vi.fn(async (name, email) => ({ token: "test-token", userId: 2, name, email })),
}));

describe("auth store", () => {
  beforeEach(() => {
    localStorage.clear();
    setActivePinia(createPinia());
  });

  it("starts signed out when there is no stored token", () => {
    const store = useAuthStore();
    expect(store.isAuthenticated).toBe(false);
    expect(store.user).toBeNull();
  });

  it("stores the token and user after a successful login", async () => {
    const store = useAuthStore();
    await store.login("person@example.com", "Password123!");

    expect(store.isAuthenticated).toBe(true);
    expect(store.user.name).toBe("Test User");
    expect(getToken()).toBe("test-token");
  });

  it("stores the token and user after a successful registration", async () => {
    const store = useAuthStore();
    await store.register("New Person", "new@example.com", "Password123!");

    expect(store.isAuthenticated).toBe(true);
    expect(store.user.email).toBe("new@example.com");
  });

  it("clears the token and user on logout", async () => {
    const store = useAuthStore();
    await store.login("person@example.com", "Password123!");

    store.logout();

    expect(store.isAuthenticated).toBe(false);
    expect(store.user).toBeNull();
    expect(getToken()).toBeNull();
  });
});
