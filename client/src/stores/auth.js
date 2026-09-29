import { defineStore } from "pinia";
import * as authApi from "../api/auth";
import { getToken, setToken } from "../api/client";

const USER_KEY = "bookedin_user";

function readStoredUser() {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

export const useAuthStore = defineStore("auth", {
  state: () => ({
    user: getToken() ? readStoredUser() : null,
  }),

  getters: {
    isAuthenticated: (state) => state.user !== null,
  },

  actions: {
    applyAuthResponse(auth) {
      setToken(auth.token);
      const user = { userId: auth.userId, name: auth.name, email: auth.email };
      localStorage.setItem(USER_KEY, JSON.stringify(user));
      this.user = user;
    },

    async login(email, password) {
      const auth = await authApi.login(email, password);
      this.applyAuthResponse(auth);
    },

    async register(name, email, password) {
      const auth = await authApi.register(name, email, password);
      this.applyAuthResponse(auth);
    },

    logout() {
      setToken(null);
      localStorage.removeItem(USER_KEY);
      this.user = null;
    },
  },
});
