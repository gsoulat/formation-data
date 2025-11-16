# Resources and Links for DP-700

## Introduction

Cette page centralise toutes les ressources officielles et recommandées pour préparer l'examen DP-700. Marquez cette page pour avoir accès rapide à la documentation, formations, et outils essentiels.

## Ressources Officielles Microsoft

### Documentation Fabric

```python
official_docs = {
    'main_portal': {
        'url': 'https://learn.microsoft.com/fabric/',
        'content': 'Documentation complète Microsoft Fabric',
        'essential': True
    },
    'whats_new': {
        'url': 'https://learn.microsoft.com/fabric/release-notes/',
        'content': 'Nouvelles fonctionnalités et mises à jour',
        'check_frequency': 'Mensuel'
    },
    'architecture': {
        'url': 'https://learn.microsoft.com/fabric/get-started/fabric-architecture',
        'content': 'Architecture et composants Fabric',
        'essential': True
    },
    'onelake': {
        'url': 'https://learn.microsoft.com/fabric/onelake/',
        'content': 'Documentation OneLake complète',
        'essential': True
    },
    'data_engineering': {
        'url': 'https://learn.microsoft.com/fabric/data-engineering/',
        'content': 'Lakehouse, Notebooks, Spark',
        'essential': True
    },
    'data_warehouse': {
        'url': 'https://learn.microsoft.com/fabric/data-warehouse/',
        'content': 'Synapse Data Warehouse dans Fabric',
        'essential': True
    },
    'data_factory': {
        'url': 'https://learn.microsoft.com/fabric/data-factory/',
        'content': 'Pipelines et Data Factory',
        'essential': True
    },
    'real_time_analytics': {
        'url': 'https://learn.microsoft.com/fabric/real-time-analytics/',
        'content': 'KQL Database et Eventstreams',
        'essential': True
    },
    'power_bi': {
        'url': 'https://learn.microsoft.com/power-bi/',
        'content': 'Semantic models et reporting',
        'essential': True
    }
}
```

### Page de Certification

```python
certification_resources = {
    'exam_page': {
        'url': 'https://learn.microsoft.com/certifications/exams/dp-700',
        'content': [
            'Skills measured',
            'Study guide officiel',
            'Practice assessment',
            'Inscription à l\'examen'
        ]
    },
    'study_guide': {
        'url': 'https://learn.microsoft.com/certifications/resources/study-guides/dp-700',
        'content': 'Guide d\'étude officiel avec tous les objectifs',
        'essential': True
    },
    'practice_assessment': {
        'url': 'https://learn.microsoft.com/certifications/practice-assessments-for-microsoft-certifications',
        'content': 'Questions de pratique officielles gratuites',
        'essential': True
    },
    'exam_sandbox': {
        'url': 'https://aka.ms/examdemo',
        'content': 'Démo du format d\'examen',
        'recommended': 'Tester avant l\'examen'
    }
}
```

## Learning Paths Microsoft Learn

### Parcours Recommandés

```python
learning_paths = {
    'foundations': {
        'name': 'Get started with Microsoft Fabric',
        'url': 'https://learn.microsoft.com/training/paths/get-started-fabric/',
        'duration': '2-3 heures',
        'modules': [
            'Introduction to Microsoft Fabric',
            'Administer Microsoft Fabric',
            'Work with lakehouses'
        ]
    },
    'data_engineering': {
        'name': 'Implement a lakehouse with Microsoft Fabric',
        'url': 'https://learn.microsoft.com/training/paths/implement-lakehouse-microsoft-fabric/',
        'duration': '4-5 heures',
        'modules': [
            'Use Delta Lake tables',
            'Organize files in OneLake',
            'Create notebooks',
            'Use Apache Spark'
        ]
    },
    'data_warehouse': {
        'name': 'Work with data warehouses in Microsoft Fabric',
        'url': 'https://learn.microsoft.com/training/paths/work-with-data-warehouses-in-microsoft-fabric/',
        'duration': '3-4 heures',
        'modules': [
            'Create warehouse',
            'Load data',
            'Query with T-SQL',
            'Optimize performance'
        ]
    },
    'semantic_models': {
        'name': 'Build reports in Microsoft Fabric',
        'url': 'https://learn.microsoft.com/training/paths/build-reports-microsoft-fabric/',
        'duration': '3-4 heures',
        'modules': [
            'Create Direct Lake models',
            'Write DAX measures',
            'Configure security'
        ]
    },
    'real_time': {
        'name': 'Real-Time Analytics in Microsoft Fabric',
        'url': 'https://learn.microsoft.com/training/paths/explore-real-time-analytics-microsoft-fabric/',
        'duration': '2-3 heures',
        'modules': [
            'Get started with KQL',
            'Configure eventstreams',
            'Query streaming data'
        ]
    }
}
```

## Hands-On Practice

### Environnements de Test

```python
practice_environments = {
    'fabric_trial': {
        'url': 'https://app.fabric.microsoft.com',
        'type': 'Free trial',
        'duration': '60 days',
        'includes': [
            'All Fabric workloads',
            'Trial capacity',
            'Sample datasets'
        ],
        'setup': 'Microsoft 365 account required'
    },
    'azure_free_account': {
        'url': 'https://azure.microsoft.com/free/',
        'credit': '$200 for 30 days',
        'includes': 'Azure services integration',
        'setup': 'Credit card required (not charged)'
    },
    'm365_developer': {
        'url': 'https://developer.microsoft.com/microsoft-365/dev-program',
        'type': 'Developer tenant',
        'includes': 'Full M365 environment',
        'renewal': 'Auto-renew if active'
    }
}
```

### Sample Datasets

```python
sample_data_sources = {
    'fabric_samples': {
        'location': 'Fabric portal > Sample datasets',
        'datasets': [
            'AdventureWorks DW',
            'Contoso Sales',
            'Wide World Importers'
        ]
    },
    'public_datasets': {
        'nyc_taxi': {
            'url': 'https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page',
            'use': 'Large scale data processing'
        },
        'kaggle': {
            'url': 'https://www.kaggle.com/datasets',
            'use': 'Various business scenarios'
        }
    },
    'microsoft_samples': {
        'github': 'https://github.com/microsoft/fabric-samples',
        'content': 'Official Fabric sample code and notebooks'
    }
}
```

## Community Resources

### Blogs et Forums

```python
community_resources = {
    'official_blog': {
        'url': 'https://blog.fabric.microsoft.com/',
        'content': 'Updates, features, best practices',
        'frequency': 'Weekly posts'
    },
    'tech_community': {
        'url': 'https://techcommunity.microsoft.com/t5/microsoft-fabric/ct-p/MicrosoftFabric',
        'content': 'Q&A, discussions, announcements',
        'activity': 'Very active community'
    },
    'reddit': {
        'url': 'https://www.reddit.com/r/MicrosoftFabric/',
        'content': 'Community discussions',
        'tone': 'Informal but helpful'
    },
    'stack_overflow': {
        'tag': '[microsoft-fabric]',
        'url': 'https://stackoverflow.com/questions/tagged/microsoft-fabric',
        'content': 'Technical Q&A'
    },
    'linkedin_groups': {
        'search': 'Microsoft Fabric',
        'content': 'Professional networking and discussions'
    }
}
```

### YouTube Channels

```python
youtube_resources = {
    'microsoft_official': {
        'channel': 'Microsoft Power BI',
        'url': 'https://www.youtube.com/@MicrosoftPowerBI',
        'content': 'Official tutorials and updates'
    },
    'guy_in_a_cube': {
        'channel': 'Guy in a Cube',
        'url': 'https://www.youtube.com/@GuyInACube',
        'content': 'Power BI and Fabric tutorials',
        'style': 'Beginner to intermediate'
    },
    'curbal': {
        'channel': 'Curbal',
        'url': 'https://www.youtube.com/@CurbalEN',
        'content': 'DAX and Power BI deep dives',
        'style': 'Advanced techniques'
    },
    'sqlbi': {
        'channel': 'SQLBI',
        'url': 'https://www.youtube.com/@SQLBI',
        'content': 'DAX patterns and modeling',
        'style': 'Expert level'
    }
}
```

## Books and Publications

### Recommended Reading

```python
books = {
    'data_modeling': {
        'title': 'The Data Warehouse Toolkit',
        'author': 'Ralph Kimball',
        'relevance': 'Dimensional modeling fundamentals',
        'essential_chapters': [
            'Dimensional Modeling Primer',
            'Retail Sales',
            'Slowly Changing Dimensions'
        ]
    },
    'dax': {
        'title': 'The Definitive Guide to DAX',
        'author': 'Marco Russo, Alberto Ferrari',
        'relevance': 'DAX mastery',
        'url': 'https://www.sqlbi.com/books/the-definitive-guide-to-dax/'
    },
    'spark': {
        'title': 'Learning Spark',
        'author': 'Jules Damji et al.',
        'relevance': 'PySpark fundamentals',
        'focus': 'Chapters on DataFrames and SQL'
    }
}
```

### Online Articles

```python
essential_articles = {
    'medallion_architecture': {
        'url': 'https://www.databricks.com/glossary/medallion-architecture',
        'content': 'Medallion pattern explained'
    },
    'delta_lake_deep_dive': {
        'url': 'https://delta.io/learn',
        'content': 'Delta Lake features and internals'
    },
    'direct_lake_mode': {
        'url': 'https://learn.microsoft.com/fabric/get-started/direct-lake-overview',
        'content': 'Direct Lake mode explained'
    },
    'fabric_vs_synapse': {
        'url': 'https://techcommunity.microsoft.com/...',
        'content': 'Comparison and migration paths'
    }
}
```

## Tools and Utilities

### Development Tools

```python
development_tools = {
    'power_bi_desktop': {
        'url': 'https://powerbi.microsoft.com/desktop/',
        'use': 'Local development of reports and models',
        'version': 'Always use latest'
    },
    'azure_data_studio': {
        'url': 'https://docs.microsoft.com/sql/azure-data-studio/',
        'use': 'SQL development and querying',
        'extensions': ['SQL Server Schema Compare', 'Notebooks']
    },
    'vs_code': {
        'url': 'https://code.visualstudio.com/',
        'extensions': [
            'Python',
            'Jupyter',
            'Azure Account',
            'Power Platform Tools'
        ]
    },
    'tabular_editor': {
        'url': 'https://tabulareditor.com/',
        'use': 'Advanced semantic model development',
        'version': 'TE2 (free) or TE3 (paid)'
    },
    'dax_studio': {
        'url': 'https://daxstudio.org/',
        'use': 'DAX query testing and optimization',
        'essential': True
    }
}
```

### Browser Extensions

```python
browser_tools = {
    'json_formatter': {
        'name': 'JSON Formatter',
        'use': 'Format API responses'
    },
    'color_picker': {
        'name': 'ColorZilla',
        'use': 'Extract colors for reports'
    },
    'screen_recorder': {
        'name': 'Loom/OBS',
        'use': 'Record practice sessions'
    }
}
```

## Quick Reference Links

### Must-Have Bookmarks

```markdown
## Quick Access Links (Bookmark These)

### Daily Use
- [Fabric Portal](https://app.fabric.microsoft.com)
- [Fabric Docs](https://learn.microsoft.com/fabric/)
- [DP-700 Exam Page](https://learn.microsoft.com/certifications/exams/dp-700)

### Documentation
- [OneLake Overview](https://learn.microsoft.com/fabric/onelake/)
- [Delta Lake Docs](https://docs.delta.io/)
- [DAX Reference](https://dax.guide/)
- [KQL Reference](https://learn.microsoft.com/kusto/query/)
- [T-SQL Reference](https://learn.microsoft.com/sql/t-sql/)

### Learning
- [Microsoft Learn Paths](https://learn.microsoft.com/training/browse/?products=fabric)
- [Practice Assessment](https://learn.microsoft.com/certifications/practice-assessments)
- [GitHub Samples](https://github.com/microsoft/fabric-samples)

### Community
- [Tech Community Blog](https://blog.fabric.microsoft.com/)
- [Power BI YouTube](https://www.youtube.com/@MicrosoftPowerBI)
- [SQLBI](https://www.sqlbi.com/)

### Tools
- [Power BI Desktop](https://powerbi.microsoft.com/desktop/)
- [DAX Studio](https://daxstudio.org/)
- [Tabular Editor](https://tabulareditor.com/)
```

## Certification Tracking

### Progress Tracker Template

```markdown
## My DP-700 Preparation Progress

### Week 1-2: Foundations
- [ ] Fabric Trial setup
- [ ] OneLake documentation read
- [ ] First Learning Path completed
- [ ] Sample Lakehouse created

### Week 3-4: Data Engineering
- [ ] Medallion architecture implemented
- [ ] Spark notebooks written
- [ ] Delta Lake features tested
- [ ] Pipelines configured

### Week 5-6: Data Warehouse
- [ ] Warehouse created
- [ ] SCD Type 2 implemented
- [ ] Query optimization practiced
- [ ] T-SQL specifics understood

### Week 7-8: Semantic Models
- [ ] Direct Lake model created
- [ ] DAX measures written
- [ ] RLS configured and tested
- [ ] Performance tuning done

### Week 9-10: Advanced Topics
- [ ] KQL queries practiced
- [ ] Eventstreams configured
- [ ] Git integration setup
- [ ] Deployment pipelines tested

### Week 11-12: Final Review
- [ ] All practice questions done
- [ ] Weak areas identified and studied
- [ ] Full mock exam completed
- [ ] Exam scheduled

### Exam Day
- [ ] Materials prepared
- [ ] Good night's sleep
- [ ] Arrived early / Setup complete
- [ ] PASSED! Score: ____/1000
```

## Points Clés

- Utilisez les ressources officielles Microsoft comme source principale
- Pratiquez dans un environnement Fabric réel (trial gratuit)
- Suivez les Learning Paths structurés de Microsoft Learn
- Rejoignez la communauté pour support et discussions
- Gardez vos bookmarks organisés pour accès rapide
- Mettez à jour vos connaissances avec les release notes
- Utilisez les bons outils pour chaque tâche
- Trackez votre progression pour rester motivé

Bonne préparation et bonne chance pour votre certification DP-700!

---

**Navigation** : [Précédent : Exam Day Tips](./07-exam-day-tips.md) | [Index](../README.md) | [Retour au Module 12](../12-Administration-Monitoring/01-capacity-management.md)
