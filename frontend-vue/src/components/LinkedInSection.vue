<template>
  <v-card elevation="4" class="h-100">
    <v-card-title class="d-flex align-center pa-6">
      <v-icon icon="mdi-linkedin" class="mr-3" size="32"></v-icon>
      <span class="text-h5 font-weight-bold">LinkedIn Profile</span>
    </v-card-title>

    <v-divider></v-divider>

    <v-card-text class="pa-6">
      <!-- Error State -->
      <v-alert
        v-if="error"
        type="warning"
        variant="tonal"
        class="mb-4"
        closable
      >
        <div class="text-body-2">
          <strong>{{ error }}</strong>
        </div>
        <div class="mt-2 text-body-2">
          To enable LinkedIn integration, configure your API credentials:
        </div>
        <v-list class="mt-2 bg-transparent" density="compact">
          <v-list-item class="pa-0">
            <template v-slot:prepend>
              <v-icon icon="mdi-key" size="16" class="mr-2"></v-icon>
            </template>
            <span class="text-body-2">LinkedInAccessToken</span>
          </v-list-item>
          <v-list-item class="pa-0">
            <template v-slot:prepend>
              <v-icon icon="mdi-account" size="16" class="mr-2"></v-icon>
            </template>
            <span class="text-body-2">LinkedInProfileId</span>
          </v-list-item>
        </v-list>
      </v-alert>

      <!-- Loading State -->
      <div v-else-if="loading" class="text-center py-8">
        <v-progress-circular
          indeterminate
          color="info"
          size="48"
        ></v-progress-circular>
        <p class="text-body-1 mt-4 text-medium-emphasis">Loading LinkedIn profile...</p>
      </div>

      <!-- Empty State -->
      <div v-else-if="!profile" class="text-center py-8">
        <v-icon icon="mdi-linkedin" size="64" class="text-medium-emphasis mb-4"></v-icon>
        <p class="text-body-1 text-medium-emphasis mb-4">
          Click "Load Portfolio Data" to see LinkedIn profile
        </p>
        <v-card variant="outlined" class="pa-4">
          <h4 class="text-h6 mb-2">LinkedIn Integration Available</h4>
          <p class="text-body-2 text-medium-emphasis mb-3">
            Configure your LinkedIn API credentials to display professional profile information.
          </p>
          <v-btn
            variant="outlined"
            color="info"
            href="https://developer.linkedin.com/"
            target="_blank"
            prepend-icon="mdi-open-in-new"
            size="small"
          >
            LinkedIn Developer Portal
          </v-btn>
        </v-card>
      </div>

      <!-- Profile Display -->
      <div v-else>
        <v-card variant="outlined" class="linkedin-profile-card">
          <v-card-text class="pa-4">
            <div class="d-flex align-center mb-3">
              <v-avatar
                color="info"
                size="64"
                class="mr-4"
              >
                <v-icon icon="mdi-account" size="32"></v-icon>
              </v-avatar>
              <div>
                <h3 class="text-h6 font-weight-bold">
                  {{ getFullName() }}
                </h3>
                <p class="text-body-2 text-medium-emphasis mb-0">
                  {{ profile.headline || 'Professional Developer' }}
                </p>
              </div>
            </div>

            <v-divider class="my-4"></v-divider>

            <div class="d-flex justify-space-between align-center">
              <v-chip
                color="info"
                variant="flat"
                prepend-icon="mdi-briefcase"
              >
                Professional
              </v-chip>
              
              <v-btn
                variant="outlined"
                color="info"
                href="https://linkedin.com/in/lukseh74"
                target="_blank"
                prepend-icon="mdi-linkedin"
                size="small"
              >
                View Profile
              </v-btn>
            </div>
          </v-card-text>
        </v-card>

        <!-- Professional Timeline (Placeholder) -->
        <v-card variant="outlined" class="mt-4">
          <v-card-title class="text-h6 pa-4">
            <v-icon icon="mdi-timeline" class="mr-2"></v-icon>
            Professional Timeline
          </v-card-title>
          <v-card-text class="pa-4">
            <p class="text-body-2 text-medium-emphasis">
              Posts and updates will appear here when LinkedIn API is fully configured.
            </p>
          </v-card-text>
        </v-card>
      </div>
    </v-card-text>
  </v-card>
</template>

<script>
export default {
  name: 'LinkedInSection',
  props: {
    profile: {
      type: Object,
      default: null
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
    getFullName() {
      if (!this.profile) return 'Professional Developer'
      
      const firstName = this.profile.firstName || ''
      const lastName = this.profile.lastName || ''
      
      if (firstName && lastName) {
        return `${firstName} ${lastName}`
      }
      
      return firstName || lastName || 'Professional Developer'
    }
  }
}
</script>

<style scoped>
.linkedin-profile-card {
  background: linear-gradient(135deg, rgba(0, 119, 181, 0.1) 0%, rgba(0, 119, 181, 0.05) 100%);
}
</style>
