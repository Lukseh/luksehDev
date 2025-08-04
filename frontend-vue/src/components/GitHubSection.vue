<template>
  <v-card elevation="4" class="h-100">
    <v-card-title class="d-flex align-center pa-6">
      <v-icon icon="mdi-github" class="mr-3" size="32"></v-icon>
      <span class="text-h5 font-weight-bold">GitHub Repositories</span>
    </v-card-title>

    <v-divider></v-divider>

    <v-card-text class="pa-6">
      <!-- Error State -->
      <v-alert
        v-if="error"
        type="error"
        variant="tonal"
        class="mb-4"
        :text="error"
        closable
      ></v-alert>

      <!-- Loading State -->
      <div v-else-if="loading" class="text-center py-8">
        <v-progress-circular
          indeterminate
          color="primary"
          size="48"
        ></v-progress-circular>
        <p class="text-body-1 mt-4 text-medium-emphasis">Loading GitHub repositories...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="!repos || repos.length === 0" class="text-center py-8">
        <v-icon icon="mdi-github" size="64" class="text-medium-emphasis mb-4"></v-icon>
        <p class="text-body-1 text-medium-emphasis">
          Click "Load Portfolio Data" to see GitHub repositories
        </p>
      </div>

      <!-- Repository List -->
      <div v-else>
        <v-card
          v-for="repo in repos"
          :key="repo.id"
          variant="outlined"
          class="mb-4 repo-card"
          :href="repo.html_url"
          target="_blank"
          hover
        >
          <v-card-text class="pa-4">
            <div class="d-flex justify-space-between align-start mb-2">
              <h4 class="text-h6 font-weight-bold text-primary">
                {{ repo.name }}
              </h4>
              <v-chip
                v-if="repo.language"
                :color="getLanguageColor(repo.language)"
                size="small"
                variant="flat"
              >
                {{ repo.language }}
              </v-chip>
            </div>

            <p class="text-body-2 text-medium-emphasis mb-3" style="min-height: 40px;">
              {{ repo.description || 'No description available' }}
            </p>

            <div class="d-flex justify-space-between align-center">
              <div class="d-flex align-center">
                <v-icon icon="mdi-star" size="16" class="mr-1"></v-icon>
                <span class="text-body-2">{{ repo.stargazers_count }}</span>
              </div>
              
              <div class="d-flex align-center">
                <v-icon icon="mdi-update" size="16" class="mr-1"></v-icon>
                <span class="text-body-2">{{ formatDate(repo.updated_at) }}</span>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </div>
    </v-card-text>
  </v-card>
</template>

<script>
export default {
  name: 'GitHubSection',
  props: {
    repos: {
      type: Array,
      default: () => []
    },
    loading: {
      type: Boolean,
      default: false
    },
    error: {
      type: String,
      default: null
    }
  },
  methods: {
    getLanguageColor(language) {
      const colors = {
        'JavaScript': '#f7df1e',
        'TypeScript': '#007acc',
        'Python': '#3776ab',
        'Java': '#f89820',
        'C#': '#239120',
        'C++': '#00599c',
        'HTML': '#e34f26',
        'CSS': '#1572b6',
        'Vue': '#4fc08d',
        'React': '#61dafb',
        'Node.js': '#339933'
      }
      return colors[language] || 'grey'
    },
    formatDate(dateString) {
      const date = new Date(dateString)
      const now = new Date()
      const diffTime = Math.abs(now - date)
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
      
      if (diffDays === 1) return '1 day ago'
      if (diffDays < 7) return `${diffDays} days ago`
      if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`
      if (diffDays < 365) return `${Math.floor(diffDays / 30)} months ago`
      return `${Math.floor(diffDays / 365)} years ago`
    }
  }
}
</script>

<style scoped>
.repo-card {
  transition: all 0.2s ease;
}

.repo-card:hover {
  transform: translateY(-2px);
}
</style>
