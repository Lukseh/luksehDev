<template>
  <v-container class="pa-8">
    <!-- Page Header -->
    <v-row justify="center" class="mb-6">
      <v-col cols="12" class="cv-width">
        <div class="d-flex align-center mb-4">
          <v-btn
            icon="mdi-arrow-left"
            variant="text"
            @click="$router.go(-1)"
            class="mr-3"
          ></v-btn>
          <div>
            <h1 class="text-h3 font-weight-bold gradient-text">
              Curriculum Vitae
            </h1>
            <p class="text-h6 text-medium-emphasis">
              Professional experience and qualifications
            </p>
          </div>
        </div>
      </v-col>
    </v-row>

    <!-- CV Content -->
    <v-row justify="center">
      <v-col cols="12" class="cv-width">
        
        <!-- Personal Information -->
        <v-card elevation="4" class="mb-6">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-account" class="mr-3" size="32" color="primary"></v-icon>
            <span class="text-h5 font-weight-bold">Personal Information</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <v-row>
              <v-col cols="12" md="8">
                <h2 class="text-h4 font-weight-bold mb-2">
                  Adam Komorowski
                </h2>
                <p class="text-h6 text-info mb-3">
                  Junior Backend Developer
                </p>
                <p class="text-body-1 text-medium-emphasis mb-4">
                  Junior Backend Developer specializing in Node.js & Bun runtime environments with Express & Elysia frameworks. Experienced with MongoDB & MySQL databases, passionate about building efficient server-side applications and APIs. Currently expanding expertise in modern backend technologies and cloud solutions.
                </p>
              </v-col>
              <v-col cols="12" md="4">
                <v-list density="compact" class="bg-transparent">
                  <v-list-item prepend-icon="mdi-email">
                    <v-list-item-title>syzyflive@gmail.com</v-list-item-title>
                  </v-list-item>
                  <v-list-item prepend-icon="mdi-map-marker">
                    <v-list-item-title>Częstochowa, Silesia, Poland</v-list-item-title>
                  </v-list-item>
                  <v-list-item prepend-icon="mdi-web">
                    <v-list-item-title>lukseh.dev</v-list-item-title>
                  </v-list-item>
                  <v-list-item prepend-icon="mdi-linkedin">
                    <v-list-item-title>linkedin.com/in/lukseh74</v-list-item-title>
                  </v-list-item>
                </v-list>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <!-- Work Experience -->
        <v-card elevation="4" class="mb-6">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-briefcase" class="mr-3" size="32" color="success"></v-icon>
            <span class="text-h5 font-weight-bold">Work Experience</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <v-timeline side="end" density="compact">
              <v-timeline-item
                v-for="(job, index) in workExperience"
                :key="index"
                :dot-color="job.color"
                size="small"
              >
                <template v-slot:opposite>
                  <span class="text-body-2 text-medium-emphasis">{{ job.period }}</span>
                </template>
                <div>
                  <h4 class="text-h6 font-weight-bold">{{ job.title }}</h4>
                  <p class="text-body-2 text-info mb-2">{{ job.company }}</p>
                  <p class="text-body-2">{{ job.description }}</p>
                  <div class="mt-2">
                    <v-chip
                      v-for="skill in job.technologies"
                      :key="skill"
                      size="small"
                      variant="outlined"
                      class="ma-1"
                    >
                      {{ skill }}
                    </v-chip>
                  </div>
                </div>
              </v-timeline-item>
            </v-timeline>
          </v-card-text>
        </v-card>

        <!-- Education -->
        <v-card elevation="4" class="mb-6">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-school" class="mr-3" size="32" color="info"></v-icon>
            <span class="text-h5 font-weight-bold">Education</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <v-row>
              <v-col 
                cols="12" 
                md="6"
                v-for="(education, index) in educationHistory"
                :key="index"
              >
                <v-card variant="outlined" class="h-100">
                  <v-card-text class="pa-4">
                    <h4 class="text-h6 font-weight-bold mb-2">{{ education.degree }}</h4>
                    <p class="text-body-2 text-info mb-2">{{ education.institution }}</p>
                    <p class="text-body-2 text-medium-emphasis mb-2">{{ education.period }}</p>
                    <p class="text-body-2">{{ education.description }}</p>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <!-- Skills & Technologies -->
        <v-card elevation="4" class="mb-6">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-code-tags" class="mr-3" size="32" color="warning"></v-icon>
            <span class="text-h5 font-weight-bold">Skills & Technologies</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <v-row>
              <v-col cols="12" md="3">
                <h4 class="text-h6 font-weight-bold mb-3">Programming Languages</h4>
                <div class="d-flex flex-wrap">
                  <v-chip 
                    v-for="skill in programmingLanguages" 
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
              <v-col cols="12" md="3">
                <h4 class="text-h6 font-weight-bold mb-3">Frameworks & Libraries</h4>
                <div class="d-flex flex-wrap">
                  <v-chip 
                    v-for="framework in frameworks" 
                    :key="framework.name"
                    :color="framework.color"
                    variant="elevated"
                    class="ma-1"
                    :prepend-icon="framework.icon"
                  >
                    {{ framework.name }}
                  </v-chip>
                </div>
              </v-col>
              <v-col cols="12" md="3">
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
              <v-col cols="12" md="3">
                <h4 class="text-h6 font-weight-bold mb-3">Currently Learning</h4>
                <div class="d-flex flex-wrap">
                  <v-chip 
                    v-for="tech in learningTechnologies" 
                    :key="tech.name"
                    :color="tech.color"
                    variant="outlined"
                    class="ma-1"
                    :prepend-icon="tech.icon"
                  >
                    {{ tech.name }}
                  </v-chip>
                </div>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <!-- Certifications & Achievements -->
        <v-card elevation="4" class="mb-6">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-certificate" class="mr-3" size="32" color="success"></v-icon>
            <span class="text-h5 font-weight-bold">Certifications & Achievements</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <v-row>
              <v-col 
                cols="12" 
                md="6"
                v-for="(cert, index) in certifications"
                :key="index"
              >
                <v-card variant="outlined" class="h-100">
                  <v-card-text class="pa-4 text-center">
                    <v-icon :icon="cert.icon" size="48" :color="cert.color" class="mb-3"></v-icon>
                    <h4 class="text-h6 font-weight-bold mb-2">{{ cert.name }}</h4>
                    <p class="text-body-2 text-info mb-2">{{ cert.issuer }}</p>
                    <p class="text-body-2 text-medium-emphasis">{{ cert.date }}</p>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
          </v-card-text>
        </v-card>

        <!-- Download Actions -->
        <v-card elevation="4">
          <v-card-title class="d-flex align-center pa-6">
            <v-icon icon="mdi-download" class="mr-3" size="32" color="primary"></v-icon>
            <span class="text-h5 font-weight-bold">Download CV</span>
          </v-card-title>
          <v-divider></v-divider>
          <v-card-text class="pa-6">
            <div class="text-center">
              <p class="text-body-1 mb-4">Download a PDF version of my CV or contact me directly</p>
              <v-row justify="center">
                <v-col cols="auto">
                  <v-btn
                    color="primary"
                    variant="elevated"
                    size="large"
                    prepend-icon="mdi-file-pdf-box"
                    @click="downloadPDF"
                  >
                    Download PDF
                  </v-btn>
                </v-col>
                <v-col cols="auto">
                  <v-btn
                    color="success"
                    variant="outlined"
                    size="large"
                    prepend-icon="mdi-email"
                    href="mailto:syzyflive@gmail.com"
                  >
                    Contact Me
                  </v-btn>
                </v-col>
              </v-row>
            </div>
          </v-card-text>
        </v-card>

      </v-col>
    </v-row>
  </v-container>
</template>

<script>
export default {
  name: 'CV',
  data() {
    return {
      workExperience: [
        {
          title: 'Backend Developer',
          company: 'Personal Projects & Learning',
          period: '2023 - Present',
          description: 'Developing backend applications and APIs using modern technologies like Node.js, Bun runtime, and various frameworks. Building projects with Express.js and Elysia, working with different databases including MongoDB, PostgreSQL, and Redis.',
          technologies: ['Node.js', 'Bun', 'Express.js', 'Elysia', 'MongoDB', 'PostgreSQL'],
          color: 'primary'
        },
        {
          title: 'Self-Taught Developer',
          company: 'Continuous Learning',
          period: '2022 - Present',
          description: 'Completed FreeCodeCamp certifications in Backend Development and APIs, and Foundational C# with Microsoft. Focus on learning modern backend technologies, database management, and API development patterns.',
          technologies: ['JavaScript', 'TypeScript', 'C#', '.NET'],
          color: 'success'
        }
      ],
      
      educationHistory: [
        {
          degree: 'Back End Development and APIs Certification',
          institution: 'FreeCodeCamp',
          period: '2025',
          description: 'Comprehensive certification covering Node.js, Express.js, MongoDB, and API development. Completed hands-on projects building RESTful APIs, working with databases, and implementing authentication.'
        },
        {
          degree: 'Foundational C# with Microsoft Certification',
          institution: 'FreeCodeCamp & Microsoft',
          period: '2025',
          description: 'Foundational certification in C# programming language covering object-oriented programming principles, .NET framework basics, and Microsoft development tools.'
        }
      ],
      
      programmingLanguages: [
        { name: 'JavaScript', icon: 'mdi-language-javascript', color: 'yellow' },
        { name: 'TypeScript', icon: 'mdi-language-typescript', color: 'blue' },
        { name: 'C#', icon: 'mdi-language-csharp', color: 'purple' },
        { name: 'C++', icon: 'mdi-language-cpp', color: 'blue' },
        { name: 'HTML5', icon: 'mdi-language-html5', color: 'orange' },
        { name: 'CSS3', icon: 'mdi-language-css3', color: 'blue' }
      ],
      
      frameworks: [
        { name: 'Node.js', icon: 'mdi-nodejs', color: 'green' },
        { name: 'Bun', icon: 'mdi-flash', color: 'orange' },
        { name: 'Express.js', icon: 'mdi-nodejs', color: 'grey' },
        { name: 'Elysia', icon: 'mdi-lightning-bolt', color: 'purple' },
        { name: '.NET', icon: 'mdi-dot-net', color: 'purple' }
      ],

      learningTechnologies: [
        { name: 'Rust', icon: 'mdi-cog', color: 'orange' },
        { name: 'Tailwind CSS', icon: 'mdi-palette', color: 'cyan' },
        { name: 'HAProxy', icon: 'mdi-network', color: 'red' }
      ],
      
      tools: [
        { name: 'MongoDB', icon: 'mdi-leaf', color: 'green' },
        { name: 'MariaDB', icon: 'mdi-database', color: 'blue' },
        { name: 'PostgreSQL', icon: 'mdi-elephant', color: 'blue' },
        { name: 'Redis', icon: 'mdi-memory', color: 'red' },
        { name: 'Git', icon: 'mdi-git', color: 'orange' },
        { name: 'VS Code', icon: 'mdi-microsoft-visual-studio-code', color: 'blue' },
        { name: 'GitHub', icon: 'mdi-github', color: 'grey-darken-1' },
        { name: 'Docker', icon: 'mdi-docker', color: 'blue' },
        { name: 'Postman', icon: 'mdi-api', color: 'orange' },
        { name: 'Swagger', icon: 'mdi-api', color: 'green' },
        { name: 'Nginx', icon: 'mdi-server', color: 'green' },
        { name: 'Caddy', icon: 'mdi-server-network', color: 'blue' },
        { name: 'Apache', icon: 'mdi-server', color: 'red' }
      ],
      
      certifications: [
        {
          name: 'Back End Development and APIs',
          issuer: 'FreeCodeCamp',
          date: '2025',
          icon: 'mdi-certificate',
          color: 'success'
        },
        {
          name: 'Foundational C# with Microsoft',
          issuer: 'FreeCodeCamp & Microsoft',
          date: '2025',
          icon: 'mdi-microsoft',
          color: 'info'
        }
      ]
    }
  },
  
  methods: {
    downloadPDF() {
      // Implement PDF download functionality
      // You can either:
      // 1. Link to a static PDF file
      // 2. Generate PDF dynamically using libraries like jsPDF
      // 3. Use a server-side PDF generation service
      
      alert('PDF download feature - Replace this with actual PDF generation or link to your CV PDF file')
    }
  }
}
</script>

<style scoped>
.gradient-text {
  background: linear-gradient(135deg, #6a1b9a 0%, #2c1810 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.v-timeline-item {
  margin-bottom: 2rem;
}

.v-card {
  background: linear-gradient(135deg, rgba(106, 27, 154, 0.05) 0%, rgba(44, 24, 16, 0.05) 100%) !important;
  border: 1px solid rgba(106, 27, 154, 0.1) !important;
}

.v-card-title {
  background: linear-gradient(135deg, rgba(106, 27, 154, 0.1) 0%, rgba(44, 24, 16, 0.1) 100%) !important;
}

@media (max-width: 960px) {
  .v-timeline {
    padding-left: 0;
  }
}

/* Custom dark purple accent colors */
.text-info {
  color: #9c27b0 !important;
}

.v-chip--elevated {
  box-shadow: 0 2px 8px rgba(106, 27, 154, 0.3) !important;
}

.cv-width {
  width: 80% !important;
  max-width: 80% !important;
  flex: 0 0 80% !important;
}
</style>
