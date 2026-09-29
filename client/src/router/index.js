import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "../stores/auth";

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: "/login", name: "login", component: () => import("../views/LoginView.vue") },
    { path: "/register", name: "register", component: () => import("../views/RegisterView.vue") },
    {
      path: "/businesses",
      name: "businesses",
      component: () => import("../views/BusinessesView.vue"),
      meta: { requiresAuth: true },
    },
    {
      path: "/businesses/:id",
      name: "business",
      component: () => import("../views/BusinessView.vue"),
      meta: { requiresAuth: true },
      props: true,
    },
    {
      path: "/book/:slug",
      name: "public-booking",
      component: () => import("../views/PublicBookingView.vue"),
      props: true,
    },
    { path: "/", redirect: "/businesses" },
    { path: "/:pathMatch(.*)*", redirect: "/businesses" },
  ],
});

router.beforeEach((to) => {
  const auth = useAuthStore();
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { name: "login" };
  }
  return true;
});

export default router;
