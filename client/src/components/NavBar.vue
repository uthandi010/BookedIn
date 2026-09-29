<script setup>
import { useRouter } from "vue-router";
import { LogOut } from "@lucide/vue";
import { useAuthStore } from "../stores/auth";

const auth = useAuthStore();
const router = useRouter();

function handleLogout() {
  auth.logout();
  router.push({ name: "login" });
}
</script>

<template>
  <header class="topnav">
    <RouterLink to="/businesses" class="topnav-brand">
      <span class="dot"></span>
      BookedIn
    </RouterLink>
    <div v-if="auth.user" class="topnav-actions">
      <span class="topnav-user">{{ auth.user.name }}</span>
      <button type="button" class="btn btn-ghost" @click="handleLogout">
        <LogOut :size="16" />
        Log out
      </button>
    </div>
  </header>
</template>
