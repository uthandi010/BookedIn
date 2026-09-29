import { apiRequest } from "./client";

export function getPublicBusiness(slug) {
  return apiRequest(`/api/public/businesses/${slug}`, { auth: false });
}

export function getAvailability(slug, serviceId, date) {
  const params = new URLSearchParams({ serviceId, date });
  return apiRequest(`/api/public/businesses/${slug}/availability?${params}`, { auth: false });
}

export function bookAppointment(slug, payload) {
  return apiRequest(`/api/public/businesses/${slug}/appointments`, {
    method: "POST",
    body: payload,
    auth: false,
  });
}
