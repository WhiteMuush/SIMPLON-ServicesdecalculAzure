# TP Pratique — Module 2 : Services de calcul Azure
**Durée estimée : 50-60 min**  
**Prérequis : accès au portail Azure de la formation — utiliser votre groupe de ressources existant**

> 📖 **Cours complet et détaillé sur le wiki** : <https://github.com/WhiteMuush/simplon-azure-compute-tp/wiki>
>
> Le wiki explique chaque partie deux fois (portail Azure **et** automatisation `az` via les scripts), avec les pièges rencontrés et leurs corrections. Ce README ne contient que l'énoncé du TP.

---

## 🎯 Scénario

Vous êtes développeur DevOps junior chez **AzureTech**. Votre équipe doit évaluer trois plateformes Azure avant de choisir où héberger la future API de l'entreprise. Votre mission : déployer la même API basique `GET /hello` sur **App Service**, **Azure Functions** et **Container Instances**, puis comparer les expériences.

L'API renvoie toujours la même réponse JSON :
```json
{
  "message": "Hello from AzureTech !",
  "service": "[nom du service utilisé]"
}
```

---

## Partie 1 — App Service : déployer l'API en PaaS (20 min)

> **Modèle PaaS** — vous gérez le code, Azure gère l'OS, le runtime et le serveur web.

### 1.1 Créer l'App Service

1. Dans le portail **[https://portal.azure.com](https://portal.azure.com)**, cherchez **App Service** → **+ Créer** → **Application web**.
2. Renseignez :

   | Champ | Valeur |
   |---|---|
   | Groupe de ressources | *(votre groupe de ressources existant)* |
   | Nom | `api-appservice-[votre_prenom]` |
   | Publier | Code |
   | Pile d'exécution | **PHP 8.2** |
   | Système d'exploitation | Linux |
   | Région | France Centre |

3. Dans **Plan App Service** → sélectionnez le **plan partagé de la formation**.
4. Cliquez **Vérifier + créer** → **Créer** → attendez le déploiement → **Accéder à la ressource**.

### 1.2 Déployer le code de l'API

1. Sur la page de votre App Service, dans le menu de gauche, cherchez **Outils de développement** → **App Service Editor (Aperçu)** → **Go →**.
2. L'éditeur de code s'ouvre dans un nouvel onglet (interface similaire à VS Code dans le navigateur).
3. Faites un clic droit sur le dossier racine (`/home/site/wwwroot`) → **New File** → nommez-le `index.php`.
4. Collez ce code dans l'éditeur :

```php
<?php
header('Content-Type: application/json');
echo json_encode([
    "message" => "Hello from AzureTech !",
    "service" => "Azure App Service (PaaS)",
    "runtime" => "PHP 8.2",
    "host"    => gethostname()
]);
```

5. Sauvegardez avec **Ctrl+S**.
6. Revenez à l'onglet de votre App Service → cliquez sur l'**URL** de votre application.
7. Vous devriez voir la réponse JSON s'afficher ✅

   > **Question :** Avez-vous installé PHP ? Apache ? Un serveur ? Qu'est-ce que cela illustre sur le modèle PaaS ?

### 1.3 Tester la scalabilité

1. Dans le menu de gauche → **Scale out (App Service)** → observez l'option de mise à l'échelle manuelle et automatique.
2. Notez l'URL de votre API : `https://api-appservice-[votre_prenom].azurewebsites.net` → **vous en aurez besoin pour la comparaison finale**.

---

## Partie 2 — Azure Functions : déployer l'API en Serverless (18 min)

> **Modèle Serverless** — vous écrivez uniquement la logique. Azure gère tout le reste et vous facture à l'exécution.

### 2.1 Créer la Function App

1. Dans la barre de recherche, tapez **Function App** → **+ Créer**.
2. Renseignez :

   | Champ | Valeur |
   |---|---|
   | Groupe de ressources | *(votre groupe de ressources existant)* |
   | Nom | `api-func-[votre_prenom]` |
   | Région | France Centre |
   | Pile d'exécution | **Python** |
   | Version | 3.11 |

3. Onglet **Hébergement** :
   - Plan d'hébergement : **Consommation (Serverless)** ← gratuit, facturation à l'exécution
4. Cliquez **Vérifier + créer** → **Créer** → attendez (1-2 min) → **Accéder à la ressource**.

### 2.2 Créer la fonction HTTP

1. Dans le menu de gauche → **Fonctions** → **+ Créer**.
2. Choisissez :
   - Environnement de développement : **Développer dans le portail**
   - Modèle : **HTTP trigger**
   - Nom : `hello`
   - Niveau d'autorisation : **Anonymous**
3. Cliquez **Créer** → attendez quelques secondes.

### 2.3 Modifier le code de l'API

1. Sur la page de votre fonction, cliquez sur **Code + Test** dans le menu de gauche.
2. Remplacez tout le contenu du fichier `__init__.py` par ce code :

```python
import azure.functions as func
import json

def main(req: func.HttpRequest) -> func.HttpResponse:
    response = {
        "message": "Hello from AzureTech !",
        "service": "Azure Functions (Serverless)",
        "runtime": "Python 3.11",
        "trigger": "HTTP"
    }
    return func.HttpResponse(
        json.dumps(response),
        mimetype="application/json",
        status_code=200
    )
```

3. Cliquez sur **Enregistrer**.
4. Cliquez sur **Tester/Exécuter** → **Exécuter** → observez la réponse dans le panneau Output ✅
5. Cliquez sur **Obtenir l'URL de la fonction** → copiez l'URL et ouvrez-la dans un nouvel onglet.

   > **Question :** Combien de serveurs avez-vous provisionné ? Que se passe-t-il si 10 000 utilisateurs appellent cette fonction simultanément ?

6. Dans le menu de gauche → **Monitor** → observez le tableau des invocations (vos appels de test apparaissent).

---

## Partie 3 — Container Instances : déployer l'API via un conteneur (10 min)

> **Modèle Conteneur** — vous fournissez une image Docker prête à l'emploi. Azure la démarre en quelques secondes.

### 3.1 Déployer le conteneur

1. Dans la barre de recherche, tapez **Container Instances** → **+ Créer**.
2. Renseignez :

   | Champ | Valeur |
   |---|---|
   | Groupe de ressources | *(votre groupe de ressources existant)* |
   | Nom du conteneur | `api-aci-[votre_prenom]` |
   | Région | France Centre |
   | Source d'image | **Démarrage rapide** |
   | Image | `mcr.microsoft.com/azuredocs/aci-helloworld` (pré-sélectionnée) |
   | Type de système d'exploitation | Linux |
   | Taille | 1 vCPU, 1.5 Gio (défaut) |

3. Onglet **Réseau** :
   - Type de réseau : **Public**
   - Étiquette du nom DNS : `api-aci-[votre_prenom]`
   - Ports : `80` (TCP) — déjà renseigné
4. Cliquez **Vérifier + créer** → **Créer** → attendez le déploiement (1-2 min) → **Accéder à la ressource**.

### 3.2 Tester l'API conteneur

1. Sur la page du Container Instance, repérez le **Nom de domaine complet (FQDN)** dans Vue d'ensemble.
2. Ouvrez `http://[votre-FQDN]` dans un nouvel onglet → vous voyez la page de l'application conteneurisée ✅
3. Dans le menu de gauche, cliquez sur **Conteneurs** → **Journaux** → observez les logs de démarrage du conteneur.
4. Cliquez sur **Se connecter** → observez qu'on peut ouvrir un shell directement dans le conteneur.

   > **Question :** En quoi ACI est-il différent d'une Function App ? Quand préférieriez-vous ACI à une Function ?

---

## Partie 4 — Comparaison finale (5 min)

Vous avez maintenant 3 URL actives. Ouvrez-les côte à côte dans votre navigateur et comparez :

| Critère | App Service | Azure Functions | Container Instances |
|---|---|---|---|
| **URL de votre API** | `azurewebsites.net` | `azurewebsites.net/api/hello` | `[région].azurecontainer.io` |
| **Temps de déploiement** | ~2 min | ~2 min | ~1 min |
| **Code déployé** | Oui (PHP) | Oui (Python) | Non (image Docker) |
| **Facturation** | Plan mensuel | À l'exécution | À la seconde |
| **Scale automatique** | Oui (plan Standard+) | Oui (natif) | Non (manuel) |
| **Gestion OS** | ❌ Azure | ❌ Azure | ❌ Azure |
| **Gestion runtime** | ❌ Azure | ❌ Azure | ✅ Vous (dans l'image) |

> **Question finale :** Pour une startup qui lance une nouvelle API avec un trafic imprévisible et un budget limité, quel service choisiriez-vous et pourquoi ?

---

## 🧹 Nettoyage (3 min)

> ⚠️ Supprimez vos ressources dans cet ordre pour éviter les erreurs de dépendance.

1. **Container Instance** → cherchez **Container Instances** → sélectionnez `api-aci-[votre_prenom]` → **Supprimer** → confirmez.
2. **Function App** → cherchez **Function App** → sélectionnez `api-func-[votre_prenom]` → **Supprimer** → confirmez.
3. **App Service** → cherchez **App Services** → sélectionnez `api-appservice-[votre_prenom]` → **Supprimer** → confirmez.

---

## ✅ Ce que vous avez appris

- **App Service (PaaS)** : déployez du code directement — Azure gère l'OS, le runtime et le serveur. Idéal pour les applications web et les API en production.
- **Azure Functions (Serverless)** : écrivez une fonction, Azure l'exécute à la demande. Facturation à l'exécution, scaling natif. Idéal pour les traitements événementiels et les APIs légères.
- **Container Instances** : déployez une image Docker en quelques secondes sans gérer de cluster. Idéal pour les tâches isolées et les démos rapides.
- Le même résultat (une API HTTP) peut être obtenu de trois façons très différentes — le choix dépend du contrôle souhaité, du coût et de la charge de gestion.