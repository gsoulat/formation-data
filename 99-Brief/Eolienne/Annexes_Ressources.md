# Annexes et Ressources

---

## 📖 Annexe A : Glossaire des termes

**Architecture Medallion** : Pattern d'organisation des données en trois couches (Bronze/Silver/Gold).

**Bronze Layer** : Couche de données brutes, non transformées.

**Silver Layer** : Couche de données nettoyées et enrichies.

**Gold Layer** : Couche de données hautement raffinées avec modèle dimensionnel.

**Delta Lake** : Format de stockage transactionnel pour data lakes.

**Lakehouse** : Architecture combinant data lakes et data warehouses.

**Semantic Model** : Couche sémantique pour Power BI.

**Star Schema** : Modèle dimensionnel avec une table de faits centrale.

**DAX** : Data Analysis Expressions, langage pour Power BI.

---

## 📚 Annexe B : Ressources d'apprentissage

### Documentation officielle
- [Microsoft Fabric](https://learn.microsoft.com/fabric/)
- [Delta Lake](https://docs.delta.io/)
- [PySpark](https://spark.apache.org/docs/latest/api/python/)
- [Power BI](https://learn.microsoft.com/power-bi/)

### Formations
- [Microsoft Learn](https://learn.microsoft.com/training/)
- [Databricks Academy](https://www.databricks.com/learn/)

### Communautés
- [Fabric Community](https://community.fabric.microsoft.com/)
- [Power BI Community](https://community.powerbi.com/)

---

## 🔧 Annexe C : Commandes Git essentielles

```bash
# Initialisation
git init
git remote add origin URL

# Workflow
git status
git add .
git commit -m "message"
git push

# Historique
git log --oneline

# Tags
git tag -a v1.0 -m "Version 1.0"
git push origin v1.0
```

---

## 💡 Annexe D : Conventions de nommage

| Ressource | Préfixe | Exemple |
|-----------|---------|---------|
| Lakehouse | LH_ | LH_Wind_Power_Bronze |
| Notebook | NB_ | NB_Get_Daily_Data_Python |
| Pipeline | PL_ | PL_Orchestration |
| Semantic Model | SM_ | SM_Wind_Turbine_Power |
| Report | RPT_ | RPT_Analysis |
| Dimension | dim_ | dim_date |
| Fact | fact_ | fact_wind_power |

---

*Annexes complètes pour le projet Wind Power Analytics*
