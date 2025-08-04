<template>
  <v-container fluid class="pa-8">
    <!-- Page Header -->
    <v-row justify="center" class="mb-6">
      <v-col cols="12">
        <div class="d-flex align-center mb-4">
          <v-btn
            icon="mdi-arrow-left"
            variant="text"
            @click="$router.go(-1)"
            class="mr-4"
          ></v-btn>
          <div>
            <h1 class="text-h3 font-weight-bold gradient-text">
              GitHub Repositories
            </h1>
            <p class="text-h6 text-medium-emphasis">
              My open source projects and contributions
            </p>
          </div>
        </div>
      </v-col>
    </v-row>

    <!-- Filters and Controls -->
    <v-row justify="center" class="mb-6">
      <v-col cols="12">
        <v-card elevation="2" class="pa-4">
          <v-row align="center">
            <v-col cols="12" md="4">
              <v-text-field
                v-model="searchQuery"
                label="Search repositories"
                prepend-inner-icon="mdi-magnify"
                variant="outlined"
                density="compact"
                clearable
                hide-details
              ></v-text-field>
            </v-col>
            <v-col cols="12" md="3">
              <v-select
                v-model="selectedLanguage"
                :items="languageOptions"
                label="Filter by language"
                variant="outlined"
                density="compact"
                clearable
                hide-details
              ></v-select>
            </v-col>
            <v-col cols="12" md="3">
              <v-select
                v-model="sortBy"
                :items="sortOptions"
                label="Sort by"
                variant="outlined"
                density="compact"
                hide-details
              ></v-select>
            </v-col>
            <v-col cols="12" md="2">
              <v-switch
                v-model="hideArchived"
                label="Hide archived"
                color="primary"
                hide-details
                inset
              ></v-switch>
            </v-col>
          </v-row>
          
          <!-- Quick Stats -->
          <v-row class="mt-4">
            <v-col cols="auto">
              <v-chip color="primary" variant="elevated">
                {{ filteredRepos.length }} repositories
              </v-chip>
            </v-col>
            <v-col cols="auto">
              <v-chip color="success" variant="elevated">
                {{ totalStars }} total stars
              </v-chip>
            </v-col>
            <v-col cols="auto">
              <v-chip color="info" variant="elevated">
                {{ uniqueLanguages.length }} languages
              </v-chip>
            </v-col>
          </v-row>
        </v-card>
      </v-col>
    </v-row>

    <!-- Error Alert -->
    <v-row justify="center" v-if="error" class="mb-4">
      <v-col cols="12">
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
          color="primary"
          size="48"
        ></v-progress-circular>
        <p class="text-body-1 mt-4 text-medium-emphasis">Loading GitHub repositories...</p>
      </v-col>
    </v-row>

    <!-- Language Groups -->
    <div v-else-if="groupedRepos && Object.keys(groupedRepos).length > 0">
      <v-row justify="center" v-for="(repos, language) in groupedRepos" :key="language" class="mb-8">
        <v-col cols="12">
          <!-- Language Header -->
          <div class="d-flex align-center mb-4">
            <div 
              class="language-dot mr-3"
              :style="{ backgroundColor: getLanguageColor(language) }"
            ></div>
            <h2 class="text-h4 font-weight-bold">{{ language || 'Other' }}</h2>
            <v-chip class="ml-4" variant="outlined">{{ repos.length }} repos</v-chip>
          </div>

          <!-- Repository Cards -->
          <v-row>
            <v-col 
              cols="12" 
              sm="6" 
              md="4" 
              lg="3" 
              xl="2"
              v-for="repo in repos" 
              :key="repo.id"
            >
              <!-- GitHub Repository Embed -->
              <v-card 
                elevation="2" 
                class="h-100 repo-embed-card"
                :class="{ 'archived-repo': repo.archived }"
                variant="outlined"
              >
                <!-- Repository Header -->
                <v-card-title class="pa-3 pb-2">
                  <div class="d-flex align-start justify-space-between w-100">
                    <div class="flex-grow-1">
                      <div class="d-flex align-center mb-1">
                        <v-icon 
                          icon="mdi-source-repository" 
                          size="20" 
                          class="mr-2 text-medium-emphasis"
                        ></v-icon>
                        <h3 class="text-subtitle-1 font-weight-bold github-repo-name">
                          <a 
                            :href="repo.html_url" 
                            target="_blank"
                            class="text-decoration-none"
                            @click.stop
                          >
                            lukseh/{{ repo.name }}
                          </a>
                        </h3>
                      </div>
                      
                      <!-- Repository badges -->
                      <div class="d-flex align-center flex-wrap">
                        <v-chip 
                          v-if="repo.archived" 
                          size="x-small" 
                          color="warning" 
                          variant="outlined"
                          class="mr-2 mb-1"
                        >
                          <v-icon icon="mdi-archive" size="12" class="mr-1"></v-icon>
                          Archived
                        </v-chip>
                        <v-chip 
                          v-if="repo.fork" 
                          size="x-small" 
                          color="info" 
                          variant="outlined"
                          class="mr-2 mb-1"
                        >
                          <v-icon icon="mdi-source-fork" size="12" class="mr-1"></v-icon>
                          Fork
                        </v-chip>
                        <v-chip 
                          v-if="repo.language" 
                          size="x-small" 
                          variant="outlined"
                          class="mb-1"
                          :style="{ 
                            borderColor: getLanguageColor(repo.language),
                            color: getLanguageColor(repo.language)
                          }"
                        >
                          <div 
                            class="language-dot-tiny mr-1"
                            :style="{ backgroundColor: getLanguageColor(repo.language) }"
                          ></div>
                          {{ repo.language }}
                        </v-chip>
                      </div>
                    </div>
                  </div>
                </v-card-title>

                <!-- Repository Description -->
                <v-card-text class="pa-3 pt-1">
                  <p 
                    class="text-body-2 text-medium-emphasis github-description" 
                    style="min-height: 48px; line-height: 1.4;"
                  >
                    {{ repo.description || 'No description available' }}
                  </p>
                </v-card-text>

                <!-- Repository Stats Footer -->
                <v-card-actions class="pa-3 pt-0">
                  <div class="d-flex align-center justify-space-between w-100">
                    <div class="d-flex align-center">
                      <!-- Stars -->
                      <div class="d-flex align-center mr-4">
                        <v-icon 
                          icon="mdi-star-outline" 
                          size="16" 
                          class="mr-1 text-medium-emphasis"
                        ></v-icon>
                        <span class="text-caption font-weight-medium">{{ repo.stargazers_count }}</span>
                      </div>
                      
                      <!-- Language (if different from chip) -->
                      <div v-if="repo.language" class="d-flex align-center mr-4">
                        <div 
                          class="language-dot-small mr-1"
                          :style="{ backgroundColor: getLanguageColor(repo.language) }"
                        ></div>
                        <span class="text-caption">{{ getLanguagePercentage(repo.language) }}%</span>
                      </div>
                    </div>
                    
                    <!-- Updated time -->
                    <div class="d-flex align-center">
                      <span class="text-caption text-medium-emphasis">
                        Updated {{ getRelativeTime(repo.updated_at) }}
                      </span>
                    </div>
                  </div>
                </v-card-actions>

                <!-- GitHub Actions -->
                <v-divider></v-divider>
                <v-card-actions class="pa-2">
                  <v-btn
                    variant="text"
                    size="small"
                    prepend-icon="mdi-github"
                    :href="repo.html_url"
                    target="_blank"
                    class="text-caption"
                  >
                    View on GitHub
                  </v-btn>
                  <v-spacer></v-spacer>
                  <v-btn
                    icon="mdi-star-outline"
                    variant="text"
                    size="small"
                    @click="starRepository(repo)"
                    class="text-medium-emphasis"
                  ></v-btn>
                  <v-btn
                    icon="mdi-eye-outline"
                    variant="text"
                    size="small"
                    @click="watchRepository(repo)"
                    class="text-medium-emphasis"
                  ></v-btn>
                </v-card-actions>
              </v-card>
            </v-col>
          </v-row>
        </v-col>
      </v-row>
    </div>

    <!-- Empty State -->
    <v-row justify="center" v-else-if="!loading">
      <v-col cols="12" md="6" class="text-center">
        <v-icon icon="mdi-github" size="64" color="grey" class="mb-4"></v-icon>
        <h3 class="text-h5 mb-3">No repositories found</h3>
        <p class="text-body-1 text-medium-emphasis mb-4">
          Try adjusting your filters or check back later.
        </p>
        <v-btn 
          color="primary" 
          variant="elevated" 
          @click="loadGitHubData"
          prepend-icon="mdi-refresh"
        >
          Refresh
        </v-btn>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
import { ref, computed, onMounted } from 'vue'
import axios from 'axios'

export default {
  name: 'GitHub',
  setup() {
    const loading = ref(false)
    const error = ref(null)
    const repos = ref([])
    const searchQuery = ref('')
    const selectedLanguage = ref(null)
    const sortBy = ref('updated')
    const hideArchived = ref(true)

    const sortOptions = [
      { title: 'Recently updated', value: 'updated' },
      { title: 'Most stars', value: 'stars' },
      { title: 'Name (A-Z)', value: 'name' },
      { title: 'Created date', value: 'created' }
    ]

    const loadGitHubData = async () => {
      try {
        loading.value = true
        error.value = null
        
        const response = await axios.get('http://localhost:3000/api/social/lukseh')
        
        if (response.data?.success && response.data?.data?.gitHub?.repos) {
          repos.value = response.data.data.gitHub.repos
          
          // Debug logging
          console.log('Total repos loaded:', repos.value.length)
          console.log('Archived repos:', repos.value.filter(r => r.archived).map(r => r.name))
          console.log('TypeScript repos:', repos.value.filter(r => r.language === 'TypeScript').map(r => r.name))
          console.log('JavaScript repos:', repos.value.filter(r => r.language === 'JavaScript').map(r => r.name))
          
        } else {
          throw new Error(response.data?.error || 'Invalid response format')
        }
      } catch (err) {
        console.error('Failed to load GitHub data:', err)
        error.value = err.response?.data?.error || 'Failed to load GitHub repositories. Please try again later.'
      } finally {
        loading.value = false
      }
    }

    const filteredRepos = computed(() => {
      let filtered = repos.value

      // Filter by archived status
      if (hideArchived.value) {
        filtered = filtered.filter(repo => !repo.archived)
      }

      // Filter by search query
      if (searchQuery.value) {
        const query = searchQuery.value.toLowerCase()
        filtered = filtered.filter(repo => 
          repo.name.toLowerCase().includes(query) ||
          (repo.description && repo.description.toLowerCase().includes(query))
        )
      }

      // Filter by language
      if (selectedLanguage.value) {
        filtered = filtered.filter(repo => repo.language === selectedLanguage.value)
      }

      // Sort repositories
      filtered.sort((a, b) => {
        switch (sortBy.value) {
          case 'stars':
            return b.stargazers_count - a.stargazers_count
          case 'name':
            return a.name.localeCompare(b.name)
          case 'created':
            return new Date(b.created_at) - new Date(a.created_at)
          case 'updated':
          default:
            return new Date(b.updated_at) - new Date(a.updated_at)
        }
      })

      return filtered
    })

    const uniqueLanguages = computed(() => {
      const languages = new Set(repos.value.map(repo => repo.language).filter(Boolean))
      return Array.from(languages).sort()
    })

    const languageOptions = computed(() => {
      return uniqueLanguages.value.map(lang => ({
        title: lang,
        value: lang
      }))
    })

    const groupedRepos = computed(() => {
      const groups = {}
      filteredRepos.value.forEach(repo => {
        const language = repo.language || 'Other'
        if (!groups[language]) {
          groups[language] = []
        }
        groups[language].push(repo)
      })

      // Sort languages by repository count
      const sortedGroups = {}
      Object.keys(groups)
        .sort((a, b) => groups[b].length - groups[a].length)
        .forEach(key => {
          sortedGroups[key] = groups[key]
        })

      return sortedGroups
    })

    const totalStars = computed(() => {
      return filteredRepos.value.reduce((sum, repo) => sum + repo.stargazers_count, 0)
    })

    const getLanguageColor = (language) => {
      const colors = {
        'JavaScript': '#f7df1e',
        'TypeScript': '#007acc',
        'Python': '#3776ab',
        'Java': '#f89820',
        'C#': '#239120',
        'C++': '#f34b7d',
        'C': '#555555',
        'HTML': '#e34c26',
        'CSS': '#1572b6',
        'Vue': '#4fc08d',
        'React': '#61dafb',
        'PHP': '#777bb4',
        'Ruby': '#701516',
        'Go': '#00add8',
        'Rust': '#dea584',
        'Swift': '#fa7343',
        'Kotlin': '#7f52ff',
        'Dart': '#0175c2',
        'Shell': '#89e051'
      }
      return colors[language] || '#6c757d'
    }

    const formatDate = (dateString) => {
      const date = new Date(dateString)
      return date.toLocaleDateString('en-US', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric' 
      })
    }

    const openRepository = (url) => {
      window.open(url, '_blank')
    }

    const getRelativeTime = (dateString) => {
      const date = new Date(dateString)
      const now = new Date()
      const diffTime = Math.abs(now - date)
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24))
      
      if (diffDays === 0) return 'today'
      if (diffDays === 1) return 'yesterday'
      if (diffDays < 7) return `${diffDays} days ago`
      if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`
      if (diffDays < 365) return `${Math.floor(diffDays / 30)} months ago`
      return `${Math.floor(diffDays / 365)} years ago`
    }

    const getLanguagePercentage = (language) => {
      // Simulate language percentage (in a real app, this would come from GitHub's languages API)
      const percentages = {
        'JavaScript': 85,
        'TypeScript': 92,
        'Python': 88,
        'Java': 76,
        'C#': 89,
        'C++': 74,
        'C': 71,
        'HTML': 45,
        'CSS': 23,
        'Vue': 91,
        'React': 87,
        'PHP': 83,
        'Ruby': 79,
        'Go': 86,
        'Rust': 94,
        'Swift': 82,
        'Kotlin': 84,
        'Dart': 90,
        'Shell': 67
      }
      return percentages[language] || 75
    }

    const starRepository = (repo) => {
      // Open GitHub star page
      window.open(`${repo.html_url}/stargazers`, '_blank')
    }

    const watchRepository = (repo) => {
      // Open GitHub watchers page
      window.open(`${repo.html_url}/watchers`, '_blank')
    }

    onMounted(() => {
      loadGitHubData()
    })

    return {
      loading,
      error,
      searchQuery,
      selectedLanguage,
      sortBy,
      hideArchived,
      sortOptions,
      filteredRepos,
      groupedRepos,
      languageOptions,
      uniqueLanguages,
      totalStars,
      loadGitHubData,
      getLanguageColor,
      formatDate,
      openRepository,
      getRelativeTime,
      getLanguagePercentage,
      starRepository,
      watchRepository
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

.language-dot {
  width: 16px;
  height: 16px;
  border-radius: 50%;
  display: inline-block;
}

.language-dot-small {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  display: inline-block;
}

.language-dot-tiny {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

.repo-card {
  transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
}

.repo-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.15) !important;
}

.repo-embed-card {
  border: 1px solid rgba(255,255,255,0.12);
  transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out, border-color 0.2s ease-in-out;
}

.repo-embed-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15) !important;
  border-color: rgba(103, 126, 234, 0.5);
}

.github-repo-name a {
  color: #667eea;
  transition: color 0.2s ease-in-out;
}

.github-repo-name a:hover {
  color: #764ba2;
  text-decoration: underline !important;
}

.github-description {
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
  text-overflow: ellipsis;
}

.archived-repo {
  opacity: 0.7;
}

.archived-repo .repo-embed-card {
  border-color: rgba(255, 193, 7, 0.3);
}

.archived-repo .github-repo-name a {
  color: rgba(103, 126, 234, 0.7);
}

.archived-repo:hover {
  opacity: 1;
}
</style>
