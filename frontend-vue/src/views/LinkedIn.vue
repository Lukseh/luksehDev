<template>
  <v-container class="pa-8">
    <!-- Page Header -->
    <v-row justify="center" class="mb-6">
      <v-col cols="12" md="10" lg="8">
        <div class="d-flex align-center mb-4">
          <v-btn
            icon="mdi-arrow-left"
            variant="text"
            @click="$router.go(-1)"
            class="mr-4"
          ></v-btn>
          <div>
            <h1 class="text-h3 font-weight-bold gradient-text">
              LinkedIn Profile
            </h1>
            <p class="text-h6 text-medium-emphasis">
              Professional experience and career highlights
            </p>
          </div>
        </div>
      </v-col>
    </v-row>

    <!-- Error Alert -->
    <v-row justify="center" v-if="error" class="mb-4">
      <v-col cols="12" md="10" lg="8">
        <v-alert
          type="error"
          :text="error"
          variant="outlined"
          closable
          @click:close="error = null"
        ></v-alert>
      </v-col>
    </v-row>

    <!-- Loading State -->
    <v-row justify="center" v-if="loading">
      <v-col cols="12" class="text-center py-8">
        <v-progress-circular
          indeterminate
          color="info"
          size="48"
        ></v-progress-circular>
        <p class="text-body-1 mt-4 text-medium-emphasis">Loading LinkedIn profile...</p>
      </v-col>
    </v-row>

    <!-- Profile Content -->
    <v-row justify="center" v-else>
      <v-col cols="12" md="10" lg="8">
        <!-- Profile Header Card -->
        <v-card elevation="4" class="mb-6">
          <v-card-text class="pa-6">
            <div class="d-flex align-start">
              <v-avatar
                size="120"
                color="info"
                class="mr-6"
              >
                <v-icon icon="mdi-account" size="64"></v-icon>
              </v-avatar>
              
              <div class="flex-grow-1">
                <h2 class="text-h4 font-weight-bold mb-2">
                  {{ profile?.name || 'Lukseh Developer' }}
                </h2>
                <p class="text-h6 text-info mb-3">
                  {{ profile?.headline || 'Full Stack Developer' }}
                </p>
                <p class="text-body-1 text-medium-emphasis mb-4">
                  {{ profile?.summary || 'Passionate developer with expertise in modern web technologies, cloud platforms, and software architecture. Committed to creating efficient, scalable, and user-friendly applications.' }}
                </p>
                
                <div class="d-flex flex-wrap">
                  <v-btn
                    color="info"
                    variant="elevated"
                    href="https://linkedin.com/in/lukseh74"
                    target="_blank"
                    prepend-icon="mdi-linkedin"
                    class="mr-3 mb-2"
                  >
                    View LinkedIn Profile
                  </v-btn>
                  <v-btn
                    color="primary"
                    variant="outlined"
                    href="mailto:contact@lukseh.dev"
                    prepend-icon="mdi-email"
                    class="mb-2"
                  >
                    Contact Me
                  </v-btn>
                </div>
              </div>
            </div>
          </v-card-text>
        </v-card>

        <!-- Skills & Technologies -->
        <v-card elevation="4" class="mb-6">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-code-tags" class="mr-3" size="32" color="primary"></v-icon>
            <span class="text-h5 font-weight-bold">Skills & Technologies</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <v-row>
              <v-col cols="12" md="6">
                <h4 class="text-h6 font-weight-bold mb-3">Frontend Development</h4>
                <div class="d-flex flex-wrap">
                  <v-chip 
                    v-for="skill in frontendSkills" 
                    :key="skill.name"
                    :color="skill.color"
                    variant="elevated"
                    class="ma-1"
                    :prepend-icon="skill.icon"
                  >
                    {{ skill.name }}
                  </v-chip>
                </div>
              </v-col>
              <v-col cols="12" md="6">
                <h4 class="text-h6 font-weight-bold mb-3">Backend Development</h4>
                <div class="d-flex flex-wrap">
                  <v-chip 
                    v-for="skill in backendSkills" 
                    :key="skill.name"
                    :color="skill.color"
                    variant="elevated"
                    class="ma-1"
                    :prepend-icon="skill.icon"
                  >
                    {{ skill.name }}
                  </v-chip>
                </div>
              </v-col>
            </v-row>
            <v-row class="mt-4">
              <v-col cols="12">
                <h4 class="text-h6 font-weight-bold mb-3">Tools & Platforms</h4>
                <div class="d-flex flex-wrap">
                  <v-chip 
                    v-for="tool in tools" 
                    :key="tool.name"
                    :color="tool.color"
                    variant="elevated"
                    class="ma-1"
                    :prepend-icon="tool.icon"
                  >
                    {{ tool.name }}
                  </v-chip>
                </div>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <!-- Experience Highlights -->
        <v-card elevation="4" class="mb-6">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-briefcase" class="mr-3" size="32" color="success"></v-icon>
            <span class="text-h5 font-weight-bold">Experience Highlights</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <v-timeline side="end" density="compact">
              <v-timeline-item
                v-for="(experience, index) in experiences"
                :key="index"
                :dot-color="experience.color"
                size="small"
              >
                <template v-slot:opposite>
                  <span class="text-body-2 text-medium-emphasis">{{ experience.period }}</span>
                </template>
                <div>
                  <h4 class="text-h6 font-weight-bold">{{ experience.title }}</h4>
                  <p class="text-body-2 text-info mb-2">{{ experience.company }}</p>
                  <p class="text-body-2">{{ experience.description }}</p>
                </div>
              </v-timeline-item>
            </v-timeline>
          </v-card-text>
        </v-card>

        <!-- Contact Information -->
        <v-card elevation="4">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-contact-mail" class="mr-3" size="32" color="warning"></v-icon>
            <span class="text-h5 font-weight-bold">Get In Touch</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <v-row>
              <v-col cols="12" md="4">
                <div class="text-center">
                  <v-icon icon="mdi-email" size="48" color="primary" class="mb-3"></v-icon>
                  <h4 class="text-h6 font-weight-bold mb-2">Email</h4>
                  <p class="text-body-2">contact@lukseh.dev</p>
                </div>
              </v-col>
              <v-col cols="12" md="4">
                <div class="text-center">
                  <v-icon icon="mdi-linkedin" size="48" color="info" class="mb-3"></v-icon>
                  <h4 class="text-h6 font-weight-bold mb-2">LinkedIn</h4>
                  <p class="text-body-2">linkedin.com/in/lukseh74</p>
                </div>
              </v-col>
              <v-col cols="12" md="4">
                <div class="text-center">
                  <v-icon icon="mdi-github" size="48" color="grey-darken-1" class="mb-3"></v-icon>
                  <h4 class="text-h6 font-weight-bold mb-2">GitHub</h4>
                  <p class="text-body-2">github.com/lukseh</p>
                </div>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import { ref, onMounted } from 'vue'
import axios from 'axios'

export default {
  name: 'LinkedIn',
  setup() {
    const loading = ref(false)
    const error = ref(null)
    const profile = ref(null)

    const frontendSkills = [
      { name: 'Vue.js', icon: 'mdi-vuejs', color: 'green' },
      { name: 'React', icon: 'mdi-react', color: 'cyan' },
      { name: 'TypeScript', icon: 'mdi-language-typescript', color: 'blue' },
      { name: 'JavaScript', icon: 'mdi-language-javascript', color: 'yellow' },
      { name: 'HTML5', icon: 'mdi-language-html5', color: 'orange' },
      { name: 'CSS3', icon: 'mdi-language-css3', color: 'blue' },
      { name: 'Vuetify', icon: 'mdi-vuetify', color: 'blue' }
    ]

    const backendSkills = [
      { name: '.NET', icon: 'mdi-dot-net', color: 'purple' },
      { name: 'Node.js', icon: 'mdi-nodejs', color: 'green' },
      { name: 'Python', icon: 'mdi-language-python', color: 'blue' },
      { name: 'C#', icon: 'mdi-language-csharp', color: 'purple' },
      { name: 'Express.js', icon: 'mdi-nodejs', color: 'grey' },
      { name: 'REST APIs', icon: 'mdi-api', color: 'teal' }
    ]

    const tools = [
      { name: 'Git', icon: 'mdi-git', color: 'orange' },
      { name: 'Docker', icon: 'mdi-docker', color: 'cyan' },
      { name: 'VS Code', icon: 'mdi-microsoft-visual-studio-code', color: 'blue' },
      { name: 'Azure', icon: 'mdi-microsoft-azure', color: 'blue' },
      { name: 'GitHub', icon: 'mdi-github', color: 'grey-darken-1' },
      { name: 'Vite', icon: 'mdi-lightning-bolt', color: 'yellow' },
      { name: 'npm', icon: 'mdi-npm', color: 'red' }
    ]

    const experiences = [
      {
        title: 'Full Stack Developer',
        company: 'Self-Employed / Open Source',
        period: '2023 - Present',
        description: 'Developing modern web applications using Vue.js, .NET, and cloud technologies. Focus on creating scalable, maintainable solutions.',
        color: 'primary'
      },
      {
        title: 'Software Developer',
        company: 'Various Projects',
        period: '2022 - 2023',
        description: 'Worked on diverse projects including web applications, desktop tools, and API development using modern frameworks.',
        color: 'success'
      },
      {
        title: 'Learning & Development',
        company: 'Continuous Education',
        period: '2021 - 2022',
        description: 'Intensive learning period focusing on modern web development, cloud platforms, and software architecture patterns.',
        color: 'info'
      }
    ]

    const loadLinkedInData = async () => {
      try {
        loading.value = true
        error.value = null
        
        const response = await axios.get('http://localhost:3000/api/social/lukseh')
        
        if (response.data?.success && response.data?.data?.linkedIn) {
          profile.value = response.data.data.linkedIn.profile
        }
        // Note: LinkedIn API might not be configured, so we'll use fallback data
      } catch (err) {
        console.error('Failed to load LinkedIn data:', err)
        // Don't show error for LinkedIn since it might not be configured
        // error.value = err.response?.data?.error || 'Failed to load LinkedIn profile.'
      } finally {
        loading.value = false
      }
    }

    onMounted(() => {
      loadLinkedInData()
    })

    return {
      loading,
      error,
      profile,
      frontendSkills,
      backendSkills,
      tools,
      experiences
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
