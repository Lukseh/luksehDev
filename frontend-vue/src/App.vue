<template>
  <v-app>
    <v-app-bar
      color="primary"
      elevation="2"
      height="80"
    >
      <template v-slot:prepend>
        <v-icon icon="mdi-rocket-launch" size="40" class="ml-4"></v-icon>
      </template>
      
      <v-app-bar-title class="text-h4 font-weight-bold">
        <router-link to="/" class="text-decoration-none text-white">
          lukseh.dev
        </router-link>
      </v-app-bar-title>

      <v-spacer></v-spacer>
      
      <!-- Navigation Links -->
      <v-btn
        variant="text"
        to="/"
        exact
        class="text-h6 mx-2"
      >
        Home
      </v-btn>
      <v-btn
        variant="text"
        to="/github"
        prepend-icon="mdi-github"
        class="text-h6 mx-2"
      >
        GitHub
      </v-btn>
      <v-btn
        variant="text"
        to="/linkedin"
        prepend-icon="mdi-linkedin"
        class="text-h6 mx-2"
      >
        LinkedIn
      </v-btn>

      <template v-slot:append>
        <v-btn
          icon="mdi-github"
          variant="text"
          href="https://github.com/lukseh"
          target="_blank"
        ></v-btn>
        <v-btn
          icon="mdi-linkedin"
          variant="text"
          href="https://linkedin.com/in/lukseh74"
          target="_blank"
        ></v-btn>
      </template>
    </v-app-bar>

    <v-main>
      <router-view />
    </v-main>

    <!-- Footer -->
    <v-footer color="surface-variant" class="text-center pa-4">
      <v-row justify="center">
        <v-col cols="12">
          <span class="text-body-2">
            Built with ❤️ using Vue.js, Vuetify & .NET
          </span>
        </v-col>
      </v-row>
    </v-footer>
  </v-app>
</template>

<script>
export default {
  name: 'App'
}
</script>

<style scoped>
.v-container {
  max-width: 1200px;
  margin: 0 auto;
}

/* Better responsive spacing */
@media (max-width: 960px) {
  .v-container {
    padding-left: 16px;
    padding-right: 16px;
  }
}

/* Navigation active state */
.v-btn--active {
  background-color: rgba(255, 255, 255, 0.1) !important;
}

/* Router link styling */
.router-link-active {
  background-color: rgba(255, 255, 255, 0.1);
  border-radius: 4px;
}
</style>
