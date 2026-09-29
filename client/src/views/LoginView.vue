<script setup>
import { ref } from "vue";
import { useRouter } from "vue-router";
import { useAuthStore } from "../stores/auth";
import { ApiError } from "../api/client";

const auth = useAuthStore();
const router = useRouter();

const email = ref("");
const password = ref("");
const error = ref(null);
const submitting = ref(false);

async function handleSubmit() {
  error.value = null;

  if (!email.value.trim() || !password.value) {
    error.value = "Email and password are required.";
    return;
  }

  submitting.value = true;
  try {
    await auth.login(email.value.trim(), password.value);
    router.push({ name: "businesses" });
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : "Something went wrong. Please try again.";
  } finally {
    submitting.value = false;
  }
}
</script>

<template>
  <div class="auth-page">
    <form class="auth-card" novalidate @submit.prevent="handleSubmit">
      <h1>Log in to BookedIn</h1>
      <p class="auth-subtitle">Manage your business's bookings, services, and hours.</p>

      <div v-if="error" class="form-error" role="alert">{{ error }}</div>

      <label class="field">
        <span>Email</span>
        <input v-model="email" type="email" autocomplete="email" />
      </label>

      <label class="field">
        <span>Password</span>
        <input v-model="password" type="password" autocomplete="current-password" />
      </label>

      <button type="submit" class="btn btn-primary" :disabled="submitting">
        {{ submitting ? "Logging in..." : "Log in" }}
      </button>

      <p class="auth-switch">
        Don't have an account? <RouterLink :to="{ name: 'register' }">Create one</RouterLink>
      </p>
    </form>
  </div>
</template>
