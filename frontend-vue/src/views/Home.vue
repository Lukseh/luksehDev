<template>
  <v-container class="pa-8">
    <!-- Hero Section -->
    <v-row justify="center" class="mb-8">
      <v-col cols="12" md="10" lg="8" class="text-center">
        <h1 class="text-h2 font-weight-bold mb-4 gradient-text">
          Developer Portfolio
        </h1>
        <p class="text-h6 mb-6 text-medium-emphasis">
          Welcome to my developer portfolio showcasing GitHub repositories and professional CV
        </p>
        <v-row justify="center" class="mt-8">
          <v-col cols="auto">
            <v-btn
              color="primary"
              size="x-large"
              variant="elevated"
              to="/github"
              prepend-icon="mdi-github"
              class="text-h6 px-8 py-4 ma-2"
            >
              View GitHub Projects
            </v-btn>
          </v-col>
          <v-col cols="auto">
            <v-btn
              color="info"
              size="x-large"
              variant="elevated"
              to="/cv"
              prepend-icon="mdi-file-document"
              class="text-h6 px-8 py-4 ma-2"
            >
              View My CV
            </v-btn>
          </v-col>
        </v-row>
      </v-col>
    </v-row>

    <!-- Quick Overview Cards -->
    <v-row justify="center">
      <v-col cols="12" md="10" lg="8">
        <v-row>
          <v-col cols="12" md="6">
            <v-card elevation="4" class="h-100 text-center pa-6">
              <v-icon icon="mdi-github" size="64" color="primary" class="mb-4"></v-icon>
              <h3 class="text-h5 font-weight-bold mb-3">GitHub Projects</h3>
              <p class="text-body-1 text-medium-emphasis mb-4">
                Explore my open source projects, contributions, and code repositories
              </p>
              <v-btn variant="outlined" color="primary" to="/github">
                Browse Repositories
              </v-btn>
            </v-card>
          </v-col>
          <v-col cols="12" md="6">
            <v-card elevation="4" class="h-100 text-center pa-6">
              <v-icon icon="mdi-file-document" size="64" color="info" class="mb-4"></v-icon>
              <h3 class="text-h5 font-weight-bold mb-3">Curriculum Vitae</h3>
              <p class="text-body-1 text-medium-emphasis mb-4">
                View my professional experience, education, and skills in a traditional CV format
              </p>
              <v-btn variant="outlined" color="info" to="/cv">
                View CV
              </v-btn>
            </v-card>
          </v-col>
        </v-row>
      </v-col>
    </v-row>

    <!-- Technologies Section -->
    <v-row justify="center" class="mt-12">
      <v-col cols="12" md="10" lg="8" class="text-center">
        <h2 class="text-h4 font-weight-bold mb-6">Technologies & Tools</h2>
        <v-row justify="center">
          <v-col cols="auto" v-for="tech in technologies" :key="tech.name">
            <v-chip
              :color="tech.color"
              variant="elevated"
              size="large"
              :prepend-icon="tech.icon"
              class="ma-1"
            >
              {{ tech.name }}
            </v-chip>
          </v-col>
        </v-row>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'Home',
  data() {
    return {
      technologies: [
        { name: 'Vue.js', icon: 'mdi-vuejs', color: 'green' },
        { name: 'TypeScript', icon: 'mdi-language-typescript', color: 'blue' },
        { name: 'JavaScript', icon: 'mdi-language-javascript', color: 'yellow' },
        { name: '.NET', icon: 'mdi-dot-net', color: 'purple' },
        { name: 'Node.js', icon: 'mdi-nodejs', color: 'green' },
        { name: 'Python', icon: 'mdi-language-python', color: 'blue' },
        { name: 'Docker', icon: 'mdi-docker', color: 'cyan' },
        { name: 'Git', icon: 'mdi-git', color: 'orange' }
      ]
    }
  }
}
</script>

<style scoped>
.gradient-text {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
</style>
