import { apiRequest } from "./client";

export function listBusinesses() {
  return apiRequest("/api/businesses");
}

export function createBusiness(name, slug) {
  return apiRequest("/api/businesses", { method: "POST", body: { name, slug } });
}

export function getBusiness(businessId) {
  return apiRequest(`/api/businesses/${businessId}`);
}

export function listMembers(businessId) {
  return apiRequest(`/api/businesses/${businessId}/members`);
}

export function inviteMember(businessId, email, role) {
  return apiRequest(`/api/businesses/${businessId}/members`, { method: "POST", body: { email, role } });
}

export function listServices(businessId) {
  return apiRequest(`/api/businesses/${businessId}/services`);
}

export function createService(businessId, service) {
  return apiRequest(`/api/businesses/${businessId}/services`, { method: "POST", body: service });
}

export function updateService(businessId, serviceId, service) {
  return apiRequest(`/api/businesses/${businessId}/services/${serviceId}`, { method: "PATCH", body: service });
}

export function deleteService(businessId, serviceId) {
  return apiRequest(`/api/businesses/${businessId}/services/${serviceId}`, { method: "DELETE" });
}

export function getHours(businessId) {
  return apiRequest(`/api/businesses/${businessId}/hours`);
}

export function updateHours(businessId, hours) {
  return apiRequest(`/api/businesses/${businessId}/hours`, { method: "PATCH", body: { hours } });
}

export function listAppointments(businessId) {
  return apiRequest(`/api/businesses/${businessId}/appointments`);
}

export function cancelAppointment(appointmentId) {
  return apiRequest(`/api/appointments/${appointmentId}/cancel`, { method: "POST" });
}
