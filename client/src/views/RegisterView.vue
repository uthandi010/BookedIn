<script setup>
import { ref } from "vue";
import { useRouter } from "vue-router";
import { useAuthStore } from "../stores/auth";
import { ApiError } from "../api/client";

const auth = useAuthStore();
const router = useRouter();

const name = ref("");
const email = ref("");
const password = ref("");
const error = ref(null);
const submitting = ref(false);

async function handleSubmit() {
  error.value = null;

  if (!name.value.trim() || !email.value.trim() || !password.value) {
    error.value = "Name, email, and password are all required.";
    return;
  }
  if (password.value.length < 8) {
    error.value = "Password must be at least 8 characters.";
    return;
  }

  submitting.value = true;
  try {
    await auth.register(name.value.trim(), email.value.trim(), password.value);
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
      <h1>Create your account</h1>
      <p class="auth-subtitle">Set up your business and start taking bookings in minutes.</p>

      <div v-if="error" class="form-error" role="alert">{{ error }}</div>

      <label class="field">
        <span>Name</span>
        <input v-model="name" type="text" autocomplete="name" />
      </label>

      <label class="field">
        <span>Email</span>
        <input v-model="email" type="email" autocomplete="email" />
      </label>

      <label class="field">
        <span>Password</span>
        <input v-model="password" type="password" autocomplete="new-password" />
        <small>At least 8 characters.</small>
      </label>

      <button type="submit" class="btn btn-primary" :disabled="submitting">
        {{ submitting ? "Creating account..." : "Create account" }}
      </button>

      <p class="auth-switch">
        Already have an account? <RouterLink :to="{ name: 'login' }">Log in</RouterLink>
      </p>
    </form>
  </div>
</template>
