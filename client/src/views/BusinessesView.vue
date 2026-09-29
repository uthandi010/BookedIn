<script setup>
import { ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import { Plus, Users, Briefcase } from "@lucide/vue";
import NavBar from "../components/NavBar.vue";
import * as businessesApi from "../api/businesses";
import { ApiError } from "../api/client";

const router = useRouter();

const businesses = ref(null);
const newName = ref("");
const newSlug = ref("");
const creating = ref(false);
const error = ref(null);

function slugify(value) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function handleNameInput() {
  if (!newSlug.value || newSlug.value === slugify(newName.value.slice(0, -1))) {
    newSlug.value = slugify(newName.value);
  }
}

async function loadBusinesses() {
  try {
    businesses.value = await businessesApi.listBusinesses();
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : "Failed to load your businesses.";
  }
}

async function handleCreate() {
  if (!newName.value.trim() || !newSlug.value.trim()) return;

  creating.value = true;
  error.value = null;
  try {
    const business = await businessesApi.createBusiness(newName.value.trim(), newSlug.value.trim());
    businesses.value = [...(businesses.value ?? []), business];
    newName.value = "";
    newSlug.value = "";
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : "Could not create that business.";
  } finally {
    creating.value = false;
  }
}

onMounted(loadBusinesses);
</script>

<template>
  <div>
    <NavBar />
    <main class="page-content">
      <div class="page-header">
        <h1>Your businesses</h1>
        <p>Each business gets its own services, hours, staff, and public booking page.</p>
      </div>

      <form class="inline-form" @submit.prevent="handleCreate">
        <input v-model="newName" type="text" placeholder="Business name" @input="handleNameInput" />
        <input v-model="newSlug" type="text" placeholder="url-slug" />
        <button type="submit" class="btn btn-primary" :disabled="creating">
          <Plus :size="16" />
          Create business
        </button>
      </form>

      <div v-if="error" class="form-error" role="alert">{{ error }}</div>

      <p v-if="businesses === null" class="muted">Loading your businesses...</p>
      <p v-else-if="businesses.length === 0" class="muted">
        You're not part of any business yet. Create one above to get started.
      </p>
      <div v-else class="card-grid">
        <button
          v-for="business in businesses"
          :key="business.id"
          type="button"
          class="business-card"
          @click="router.push({ name: 'business', params: { id: business.id } })"
        >
          <span :class="['role-badge', `role-${business.myRole.toLowerCase()}`]">{{ business.myRole }}</span>
          <h2>{{ business.name }}</h2>
          <div class="business-card-stats">
            <span><Briefcase :size="14" /> {{ business.serviceCount }} service(s)</span>
            <span><Users :size="14" /> {{ business.memberCount }} member(s)</span>
          </div>
        </button>
      </div>
    </main>
  </div>
</template>
