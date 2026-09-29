<script setup>
import { ref, watch } from "vue";
import * as publicApi from "../api/public";
import { ApiError } from "../api/client";

const props = defineProps({ slug: { type: String, required: true } });

const business = ref(null);
const error = ref(null);
const selectedService = ref(null);
const selectedDate = ref(new Date().toISOString().slice(0, 10));
const slots = ref(null);
const selectedSlot = ref(null);
const customerName = ref("");
const customerEmail = ref("");
const booking = ref(false);
const bookingError = ref(null);
const confirmation = ref(null);

async function loadBusiness() {
  try {
    business.value = await publicApi.getPublicBusiness(props.slug);
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : "This business could not be found.";
  }
}
loadBusiness();

async function loadAvailability() {
  if (!selectedService.value) return;
  slots.value = null;
  selectedSlot.value = null;
  try {
    const result = await publicApi.getAvailability(props.slug, selectedService.value.id, selectedDate.value);
    slots.value = result.slots;
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : "Could not load availability.";
  }
}

function selectService(service) {
  selectedService.value = service;
  loadAvailability();
}

watch(selectedDate, () => {
  if (selectedService.value) loadAvailability();
});

function formatSlot(iso) {
  return new Date(iso).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

async function handleBook() {
  bookingError.value = null;
  if (!customerName.value.trim() || !customerEmail.value.trim() || !selectedSlot.value) {
    bookingError.value = "Please fill in your name, email, and pick a time.";
    return;
  }

  booking.value = true;
  try {
    confirmation.value = await publicApi.bookAppointment(props.slug, {
      serviceId: selectedService.value.id,
      customerName: customerName.value.trim(),
      customerEmail: customerEmail.value.trim(),
      startsAt: selectedSlot.value,
    });
  } catch (err) {
    bookingError.value = err instanceof ApiError ? err.message : "Could not book that appointment.";
    // The slot may have just been taken by someone else - refresh the list.
    loadAvailability();
  } finally {
    booking.value = false;
  }
}
</script>

<template>
  <div class="booking-page">
    <div v-if="error" class="form-error" role="alert">{{ error }}</div>

    <template v-else-if="business">
      <div class="booking-header">
        <h1>{{ business.name }}</h1>
        <p class="muted">Choose a service and pick a time that works for you.</p>
      </div>

      <div v-if="confirmation" class="confirmation-card">
        <h2>You're booked!</h2>
        <p>{{ confirmation.serviceName }} on {{ new Date(confirmation.startsAt).toLocaleString() }}</p>
        <p class="muted">A confirmation was sent to {{ customerEmail }}.</p>
      </div>

      <template v-else>
        <div class="service-list">
          <button
            v-for="service in business.services"
            :key="service.id"
            type="button"
            :class="['service-option', { selected: selectedService?.id === service.id }]"
            @click="selectService(service)"
          >
            <span>
              <strong>{{ service.name }}</strong>
              <span class="muted">{{ service.durationMinutes }} min</span>
            </span>
            <span v-if="service.priceCents != null">${{ (service.priceCents / 100).toFixed(2) }}</span>
          </button>
          <p v-if="business.services.length === 0" class="muted">This business hasn't listed any services yet.</p>
        </div>

        <template v-if="selectedService">
          <label class="field">
            <span>Date</span>
            <input v-model="selectedDate" type="date" />
          </label>

          <p v-if="slots === null" class="muted">Loading available times...</p>
          <p v-else-if="slots.length === 0" class="muted">No open times on this date. Try another day.</p>
          <div v-else class="slot-grid">
            <button
              v-for="slot in slots"
              :key="slot"
              type="button"
              :class="['slot-button', { selected: selectedSlot === slot }]"
              @click="selectedSlot = slot"
            >
              {{ formatSlot(slot) }}
            </button>
          </div>

          <template v-if="selectedSlot">
            <div v-if="bookingError" class="form-error" role="alert">{{ bookingError }}</div>
            <label class="field">
              <span>Your name</span>
              <input v-model="customerName" type="text" />
            </label>
            <label class="field">
              <span>Your email</span>
              <input v-model="customerEmail" type="email" />
            </label>
            <button type="button" class="btn btn-primary" :disabled="booking" @click="handleBook">
              {{ booking ? "Booking..." : "Confirm booking" }}
            </button>
          </template>
        </template>
      </template>
    </template>
  </div>
</template>
