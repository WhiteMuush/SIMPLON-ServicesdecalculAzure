#!/usr/bin/env bash
#
# Crée une App Service Web (PHP 8.2, Linux) dans un groupe de ressources existant.
# Équivalent CLI des étapes du portail Azure (App Service > Créer > Application web).
#
# Prérequis : Azure CLI installé + connecté (az login).
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Chargement des variables depuis .env (situé à côté du script)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
  set +a
fi

# ---------------------------------------------------------------------------
# Paramètres (valeurs du .env, surchargées par 1er argument pour le prénom)
# ---------------------------------------------------------------------------
PRENOM="${1:-${PRENOM:-melvin}}"            # prénom (1er argument prioritaire sur .env)
RESOURCE_GROUP="${RESOURCE_GROUP:-mon-groupe-de-ressources}"  # groupe existant
APP_SERVICE_PLAN="${APP_SERVICE_PLAN:-plan-formation}"        # plan formation (nom ou resource ID)
LOCATION="francecentral"                    # France Centre
RUNTIME="PHP:8.2"                           # pile d'exécution
APP_NAME="api-appservice-${PRENOM}"         # nom de l'app (doit être unique)

# ---------------------------------------------------------------------------
# Vérifications
# ---------------------------------------------------------------------------
echo "==> Vérification de la connexion Azure..."
az account show >/dev/null 2>&1 || { echo "Pas connecté. Lancez 'az login'."; exit 1; }

echo "==> Vérification du groupe de ressources '${RESOURCE_GROUP}'..."
az group show --name "${RESOURCE_GROUP}" >/dev/null 2>&1 \
  || { echo "Groupe de ressources '${RESOURCE_GROUP}' introuvable."; exit 1; }

echo "==> Vérification du plan App Service '${APP_SERVICE_PLAN}'..."
# Le plan peut être dans un autre groupe de ressources : on accepte un nom OU un resource ID.
if [[ "${APP_SERVICE_PLAN}" == /subscriptions/* ]]; then
  az appservice plan show --ids "${APP_SERVICE_PLAN}" >/dev/null 2>&1 \
    || { echo "Plan introuvable (resource ID): ${APP_SERVICE_PLAN}"; exit 1; }
else
  az appservice plan show --name "${APP_SERVICE_PLAN}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1 \
    || { echo "Plan '${APP_SERVICE_PLAN}' introuvable dans '${RESOURCE_GROUP}'."; exit 1; }
fi

# ---------------------------------------------------------------------------
# Création de l'App Service (= "Vérifier + créer" > "Créer")
# ---------------------------------------------------------------------------
echo "==> Création de l'App Service '${APP_NAME}'..."
az webapp create \
  --resource-group "${RESOURCE_GROUP}" \
  --plan "${APP_SERVICE_PLAN}" \
  --name "${APP_NAME}" \
  --runtime "${RUNTIME}"

# ---------------------------------------------------------------------------
# "Accéder à la ressource" : afficher l'URL et les infos
# ---------------------------------------------------------------------------
echo "==> Déploiement terminé."
URL=$(az webapp show --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --query defaultHostName -o tsv)
echo "App Service créée : https://${URL}"
