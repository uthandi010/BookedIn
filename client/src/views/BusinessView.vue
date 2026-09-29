<script setup>
import { ref, onMounted, computed } from "vue";
import { Plus, Trash2, Ban, Copy } from "@lucide/vue";
import NavBar from "../components/NavBar.vue";
import * as businessesApi from "../api/businesses";
import { useAuthStore } from "../stores/auth";
import { ApiError } from "../api/client";

const props = defineProps({ id: { type: [String, Number], required: true } });
const businessId = computed(() => Number(props.id));
const auth = useAuthStore();

const DAYS = [
  { value: 0, label: "Sunday" },
  { value: 1, label: "Monday" },
  { value: 2, label: "Tuesday" },
  { value: 3, label: "Wednesday" },
  { value: 4, label: "Thursday" },
  { value: 5, label: "Friday" },
  { value: 6, label: "Saturday" },
];

const activeTab = ref("services");
const error = ref(null);
const business = ref(null);
const services = ref(null);
const appointments = ref(null);
const members = ref(null);
const hoursForm = ref(DAYS.map((d) => ({ day: d.value, label: d.label, enabled: false, start: "09:00", end: "17:00" })));

const myRole = computed(() => members.value?.find((m) => m.userId === auth.user?.userId)?.role ?? null);
const isOwner = computed(() => myRole.value === "Owner");
const bookingLink = computed(() => (business.value ? `${window.location.origin}/book/${business.value.slug}` : ""));

async function loadAll() {
  try {
    const [b, s, a, m] = await Promise.all([
      businessesApi.getBusiness(businessId.value),
      businessesApi.listServices(businessId.value),
      businessesApi.listAppointments(businessId.value),
      businessesApi.listMembers(businessId.value),
    ]);
    business.value = b;
    services.value = s;
    appointments.value = a;
    members.value = m;

    const existingHours = await businessesApi.getHours(businessId.value);
    hoursForm.value = DAYS.map((d) => {
      const match = existingHours.find((h) => h.dayOfWeek === d.value);
      return match
        ? { day: d.value, label: d.label, enabled: true, start: match.startLabel, end: match.endLabel }
        : { day: d.value, label: d.label, enabled: false, start: "09:00", end: "17:00" };
    });
  } catch (err) {
    error.value = err instanceof ApiError ? err.message : "Failed to load this business.";
  }
}

onMounted(loadAll);

function copyBookingLink() {
  navigator.clipboard?.writeText(bookingLink.value);
}

// ----- Services -----
const newService = ref({ name: "", durationMinutes: 30, price: "", description: "" });
const serviceError = ref(null);

async function handleCreateService() {
  serviceError.value = null;
  if (!newService.value.name.trim() || !newService.value.durationMinutes) {
    serviceError.value = "Name and duration are required.";
    return;
  }
  try {
    const created = await businessesApi.createService(businessId.value, {
      name: newService.value.name.trim(),
      durationMinutes: Number(newService.value.durationMinutes),
      priceCents: newService.value.price ? Math.round(Number(newService.value.price) * 100) : null,
      description: newService.value.description.trim() || null,
    });
    services.value = [...services.value, created];
    newService.value = { name: "", durationMinutes: 30, price: "", description: "" };
  } catch (err) {
    serviceError.value = err instanceof ApiError ? err.message : "Could not create that service.";
  }
}

async function handleDeleteService(serviceId) {
  serviceError.value = null;
  try {
    await businessesApi.deleteService(businessId.value, serviceId);
    services.value = services.value.filter((s) => s.id !== serviceId);
  } catch (err) {
    serviceError.value = err instanceof ApiError ? err.message : "Could not delete that service.";
  }
}

async function handleToggleActive(service) {
  serviceError.value = null;
  try {
    const updated = await businessesApi.updateService(businessId.value, service.id, { active: !service.active });
    services.value = services.value.map((s) => (s.id === service.id ? updated : s));
  } catch (err) {
    serviceError.value = err instanceof ApiError ? err.message : "Could not update that service.";
  }
}

// ----- Hours -----
const hoursError = ref(null);
const hoursSaved = ref(false);

async function handleSaveHours() {
  hoursError.value = null;
  hoursSaved.value = false;
  const payload = hoursForm.value
    .filter((row) => row.enabled)
    .map((row) => ({ dayOfWeek: row.day, startLabel: row.start, endLabel: row.end }));

  try {
    await businessesApi.updateHours(businessId.value, payload);
    hoursSaved.value = true;
  } catch (err) {
    hoursError.value = err instanceof ApiError ? err.message : "Could not save your hours.";
  }
}

// ----- Appointments -----
const appointmentError = ref(null);

async function handleCancelAppointment(appointmentId) {
  appointmentError.value = null;
  try {
    await businessesApi.cancelAppointment(appointmentId);
    appointments.value = appointments.value.map((a) =>
      a.id === appointmentId ? { ...a, status: "Cancelled" } : a
    );
  } catch (err) {
    appointmentError.value = err instanceof ApiError ? err.message : "Could not cancel that appointment.";
  }
}

// ----- Members -----
const inviteEmail = ref("");
const inviteRole = ref("Staff");
const inviteError = ref(null);

async function handleInvite() {
  inviteError.value = null;
  if (!inviteEmail.value.trim()) return;
  try {
    const member = await businessesApi.inviteMember(businessId.value, inviteEmail.value.trim(), inviteRole.value);
    members.value = [...members.value, member];
    inviteEmail.value = "";
  } catch (err) {
    inviteError.value = err instanceof ApiError ? err.message : "Could not invite that person.";
  }
}
</script>

<template>
  <div>
    <NavBar />
    <main class="page-content">
      <div v-if="error" class="form-error" role="alert">{{ error }}</div>

      <template v-if="business">
        <div class="page-header">
          <h1>{{ business.name }}</h1>
          <p>
            Public booking page:
            <a :href="bookingLink" target="_blank">{{ bookingLink }}</a>
            <button type="button" class="btn btn-ghost" @click="copyBookingLink"><Copy :size="14" /> Copy</button>
          </p>
        </div>

        <div class="tabs">
          <button
            v-for="tab in ['services', 'hours', 'appointments', 'staff']"
            :key="tab"
            type="button"
            :class="['tab-button', { active: activeTab === tab }]"
            @click="activeTab = tab"
          >
            {{ tab.charAt(0).toUpperCase() + tab.slice(1) }}
          </button>
        </div>

        <!-- Services -->
        <section v-if="activeTab === 'services'">
          <form v-if="isOwner" class="inline-form" @submit.prevent="handleCreateService">
            <input v-model="newService.name" type="text" placeholder="Service name" />
            <input v-model="newService.durationMinutes" type="number" min="1" placeholder="Minutes" />
            <input v-model="newService.price" type="number" min="0" step="0.01" placeholder="Price ($, optional)" />
            <button type="submit" class="btn btn-primary"><Plus :size="16" /> Add service</button>
          </form>
          <div v-if="serviceError" class="form-error" role="alert">{{ serviceError }}</div>

          <p v-if="services === null" class="muted">Loading services...</p>
          <p v-else-if="services.length === 0" class="muted">No services yet.</p>
          <table v-else class="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Duration</th>
                <th>Price</th>
                <th>Active</th>
                <th v-if="isOwner"></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="service in services" :key="service.id">
                <td>{{ service.name }}</td>
                <td>{{ service.durationMinutes }} min</td>
                <td>{{ service.priceCents != null ? `$${(service.priceCents / 100).toFixed(2)}` : "—" }}</td>
                <td>
                  <button
                    v-if="isOwner"
                    type="button"
                    class="btn btn-ghost"
                    @click="handleToggleActive(service)"
                  >
                    {{ service.active ? "Active" : "Inactive" }}
                  </button>
                  <span v-else>{{ service.active ? "Active" : "Inactive" }}</span>
                </td>
                <td v-if="isOwner">
                  <button type="button" class="btn btn-danger" @click="handleDeleteService(service.id)">
                    <Trash2 :size="14" />
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </section>

        <!-- Hours -->
        <section v-if="activeTab === 'hours'">
          <div v-if="hoursError" class="form-error" role="alert">{{ hoursError }}</div>
          <div v-if="hoursSaved" class="form-success">Hours saved.</div>

          <div class="hours-grid">
            <div v-for="row in hoursForm" :key="row.day" class="hours-row">
              <label class="day-toggle">
                <input v-model="row.enabled" type="checkbox" :disabled="!isOwner" />
                {{ row.label }}
              </label>
              <template v-if="row.enabled">
                <input v-model="row.start" type="time" :disabled="!isOwner" />
                <span class="muted">to</span>
                <input v-model="row.end" type="time" :disabled="!isOwner" />
              </template>
              <span v-else class="muted">Closed</span>
            </div>
          </div>

          <button v-if="isOwner" type="button" class="btn btn-primary" @click="handleSaveHours">Save hours</button>
        </section>

        <!-- Appointments -->
        <section v-if="activeTab === 'appointments'">
          <div v-if="appointmentError" class="form-error" role="alert">{{ appointmentError }}</div>

          <p v-if="appointments === null" class="muted">Loading appointments...</p>
          <p v-else-if="appointments.length === 0" class="muted">No appointments booked yet.</p>
          <table v-else class="data-table">
            <thead>
              <tr>
                <th>When</th>
                <th>Service</th>
                <th>Customer</th>
                <th>Status</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="appointment in appointments" :key="appointment.id">
                <td>{{ new Date(appointment.startsAt).toLocaleString() }}</td>
                <td>{{ appointment.serviceName }}</td>
                <td>{{ appointment.customerName }} &lt;{{ appointment.customerEmail }}&gt;</td>
                <td>
                  <span :class="['status-pill', `status-${appointment.status.toLowerCase()}`]">
                    {{ appointment.status }}
                  </span>
                </td>
                <td>
                  <button
                    v-if="appointment.status === 'Confirmed'"
                    type="button"
                    class="btn btn-danger"
                    @click="handleCancelAppointment(appointment.id)"
                  >
                    <Ban :size="14" /> Cancel
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </section>

        <!-- Staff -->
        <section v-if="activeTab === 'staff'">
          <form v-if="isOwner" class="inline-form" @submit.prevent="handleInvite">
            <input v-model="inviteEmail" type="email" placeholder="teammate@example.com" />
            <select v-model="inviteRole">
              <option value="Staff">Staff</option>
            </select>
            <button type="submit" class="btn btn-primary"><Plus :size="16" /> Invite</button>
          </form>
          <p v-if="isOwner" class="muted">They need to already have a BookedIn account with this email.</p>
          <div v-if="inviteError" class="form-error" role="alert">{{ inviteError }}</div>

          <table v-if="members" class="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Email</th>
                <th>Role</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="member in members" :key="member.userId">
                <td>{{ member.name }}</td>
                <td>{{ member.email }}</td>
                <td><span :class="['role-badge', `role-${member.role.toLowerCase()}`]">{{ member.role }}</span></td>
              </tr>
            </tbody>
          </table>
        </section>
      </template>
    </main>
  </div>
</template>
