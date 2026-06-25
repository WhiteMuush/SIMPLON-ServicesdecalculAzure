#!/usr/bin/env bash
#
# Crée une App Service Web (PHP 8.2, Linux). Équivalent CLI de la Partie 1 du TP.
# Prérequis : az CLI connecté (az login).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
  set +a
fi

PRENOM="${1:-${PRENOM:-melvin}}"            # 1er argument prioritaire sur .env
RESOURCE_GROUP="${RESOURCE_GROUP:-mon-groupe-de-ressources}"
APP_SERVICE_PLAN="${APP_SERVICE_PLAN:-plan-formation}"
LOCATION="francecentral"
RUNTIME="PHP:8.2"
APP_NAME="api-appservice-${PRENOM}"

echo "==> Vérification de la connexion Azure..."
az account show >/dev/null 2>&1 || { echo "Pas connecté. Lancez 'az login'."; exit 1; }

echo "==> Vérification du groupe de ressources '${RESOURCE_GROUP}'..."
az group show --name "${RESOURCE_GROUP}" >/dev/null 2>&1 \
  || { echo "Groupe de ressources '${RESOURCE_GROUP}' introuvable."; exit 1; }

echo "==> Vérification du plan App Service '${APP_SERVICE_PLAN}'..."
# Plan partagé dans un autre groupe : accepte un resource ID (--ids) ou un nom local.
if [[ "${APP_SERVICE_PLAN}" == /subscriptions/* ]]; then
  az appservice plan show --ids "${APP_SERVICE_PLAN}" >/dev/null 2>&1 \
    || { echo "Plan introuvable (resource ID): ${APP_SERVICE_PLAN}"; exit 1; }
else
  az appservice plan show --name "${APP_SERVICE_PLAN}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1 \
    || { echo "Plan '${APP_SERVICE_PLAN}' introuvable dans '${RESOURCE_GROUP}'."; exit 1; }
fi

echo "==> Création de l'App Service '${APP_NAME}'..."
az webapp create \
  --resource-group "${RESOURCE_GROUP}" \
  --plan "${APP_SERVICE_PLAN}" \
  --name "${APP_NAME}" \
  --runtime "${RUNTIME}"

echo "==> Déploiement terminé."
URL=$(az webapp show --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --query defaultHostName -o tsv)
echo "App Service créée : https://${URL}"
