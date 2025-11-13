// Configuration Astro Starlight pour Formation Data Engineer
// À copier dans docs/astro.config.mjs après l'installation

import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
  // Site de base (à modifier pour le déploiement)
  // IMPORTANT: Commenter 'base' en développement local, décommenter pour GitHub Pages
  site: 'https://votre-username.github.io',
  // base: '/formation-data-engineer',  // Décommenter pour le déploiement GitHub Pages

  integrations: [
    starlight({
      // Titre du site
      title: 'Formation Data Engineer',

      // Description
      description: 'Formation complète DevOps, Cloud & Data Engineering - Simplon',

      // Localisation en français
      defaultLocale: 'root',
      locales: {
        root: {
          label: 'Français',
          lang: 'fr',
        },
      },

      // Logo (décommenter si vous ajoutez un logo)
      // logo: {
      //   src: './src/assets/logo.svg',
      //   alt: 'Formation Data Engineer Logo',
      // },

      // Liens sociaux (syntaxe v0.33+ - TABLEAU requis)
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/votre-username/formation-data-engineer',
        },
      ],

      // Navigation latérale (sidebar)
      sidebar: [
        // Page d'accueil
        {
          label: '🏠 Accueil',
          link: '/',
        },

        // Fondamentaux
        {
          label: '📚 Fondamentaux',
          collapsed: false,
          items: [
            {
              label: 'Vue d\'ensemble',
              link: '/fondamentaux/',
            },
            {
              label: 'Bash & Shell',
              autogenerate: { directory: 'fondamentaux/bash' },
            },
            {
              label: 'Git',
              autogenerate: { directory: 'fondamentaux/git' },
            },
            {
              label: 'SQL',
              autogenerate: { directory: 'fondamentaux/sql' },
            },
          ],
        },

        // Containerisation
        {
          label: '🐳 Containerisation',
          collapsed: true,
          items: [
            {
              label: 'Docker',
              autogenerate: { directory: 'containerisation/docker' },
            },
            {
              label: 'Kubernetes',
              autogenerate: { directory: 'containerisation/kubernetes' },
            },
          ],
        },

        // Infrastructure as Code
        {
          label: '🏗️ Infrastructure as Code',
          collapsed: true,
          items: [
            {
              label: 'Terraform',
              items: [
                {
                  label: 'Introduction',
                  link: '/infrastructure/terraform/',
                },
                {
                  label: 'Cours',
                  autogenerate: { directory: 'infrastructure/terraform/cours' },
                },
                {
                  label: 'Exercices',
                  autogenerate: { directory: 'infrastructure/terraform/exercices' },
                },
              ],
            },
            {
              label: 'Ansible',
              items: [
                {
                  label: 'Introduction',
                  link: '/infrastructure/ansible/',
                },
                {
                  label: 'Modules',
                  autogenerate: { directory: 'infrastructure/ansible' },
                },
              ],
            },
          ],
        },

        // Cloud Platforms
        {
          label: '☁️ Cloud Platforms',
          collapsed: true,
          items: [
            {
              label: 'Azure',
              autogenerate: { directory: 'cloud/azure' },
            },
            {
              label: 'AWS',
              autogenerate: { directory: 'cloud/aws' },
            },
            {
              label: 'GCP',
              autogenerate: { directory: 'cloud/gcp' },
            },
          ],
        },

        // Databases
        {
          label: '💾 Databases',
          collapsed: true,
          items: [
            {
              label: 'SQL',
              autogenerate: { directory: 'databases/sql' },
            },
            {
              label: 'NoSQL',
              autogenerate: { directory: 'databases/nosql' },
            },
            {
              label: 'Snowflake',
              autogenerate: { directory: 'databases/snowflake' },
            },
            {
              label: 'MongoDB',
              autogenerate: { directory: 'databases/mongodb' },
            },
          ],
        },

        // Data Engineering
        {
          label: '📊 Data Engineering',
          collapsed: true,
          items: [
            {
              label: 'Introduction',
              link: '/data-engineering/',
            },
            {
              label: 'dbt',
              autogenerate: { directory: 'data-engineering/dbt' },
            },
            {
              label: 'Apache Airflow',
              autogenerate: { directory: 'data-engineering/airflow' },
            },
            {
              label: 'Spark',
              autogenerate: { directory: 'data-engineering/spark' },
            },
            {
              label: 'DltHub',
              autogenerate: { directory: 'data-engineering/dlthub' },
            },
          ],
        },

        // DevOps
        {
          label: '🔧 DevOps',
          collapsed: true,
          items: [
            {
              label: 'CI/CD',
              autogenerate: { directory: 'devops/cicd' },
            },
            {
              label: 'GitHub Actions',
              autogenerate: { directory: 'devops/github-actions' },
            },
            {
              label: 'Monitoring',
              autogenerate: { directory: 'devops/monitoring' },
            },
          ],
        },

        // Briefs et Projets
        {
          label: '🎯 Briefs & Projets',
          collapsed: true,
          items: [
            {
              label: 'Vue d\'ensemble',
              link: '/briefs/',
            },
            {
              label: 'NYC Taxi Pipeline',
              link: '/briefs/nyc-taxi-pipeline',
            },
            {
              label: 'Qualité Eau France',
              link: '/briefs/qualite-eau-france',
            },
            {
              label: 'ECO2 Mix RTE',
              link: '/briefs/eco2-mix-rte',
            },
            // Ajoutez vos autres briefs ici
          ],
        },

        // Ressources
        {
          label: '📖 Ressources',
          items: [
            {
              label: 'Documentation officielle',
              link: '/ressources/documentation',
            },
            {
              label: 'Outils recommandés',
              link: '/ressources/outils',
            },
            {
              label: 'Liens utiles',
              link: '/ressources/liens',
            },
          ],
        },
      ],

      // CSS personnalisé
      customCss: [
        // Styles personnalisés
        './src/styles/custom.css',
      ],

      // Edition sur GitHub
      editLink: {
        baseUrl: 'https://github.com/votre-username/formation-data-engineer/edit/main/docs/',
      },

      // Date de dernière mise à jour
      lastUpdated: true,

      // Table des matières
      tableOfContents: {
        minHeadingLevel: 2,
        maxHeadingLevel: 4,
      },

      // Pagination
      pagination: true,
    }),
  ],

  // Configuration Markdown
  markdown: {
    // Coloration syntaxique
    shikiConfig: {
      theme: 'github-dark',
      wrap: true,
    },
  },
});
