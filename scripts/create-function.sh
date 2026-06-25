#!/usr/bin/env bash
#
# Crée une Azure Function App (Python 3.11, plan Consommation/Serverless) et y
# déploie la fonction HTTP "hello".
# Équivalent CLI des étapes du portail Azure (Partie 2 du TP).
#
# Prérequis : Azure CLI installé + connecté (az login), zip installé.
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Chargement des variables depuis .env (situé à côté du script)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/.env"
  set +a
fi

# ---------------------------------------------------------------------------
# Paramètres
# ---------------------------------------------------------------------------
RESOURCE_GROUP="${RESOURCE_GROUP:-mon-groupe-de-ressources}"
FUNC_APP_NAME="${FUNC_APP_NAME:-api-func-melvin}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-stfuncmelvinprf26}"
LOCATION="francecentral"            # France Centre
RUNTIME="python"
RUNTIME_VERSION="3.11"
FUNCTIONS_VERSION="4"
FUNC_SRC="${PROJECT_DIR}/funcapp"   # code source de la fonction
ZIP_PATH="$(mktemp -d)/funcapp.zip"

# ---------------------------------------------------------------------------
# Vérifications
# ---------------------------------------------------------------------------
echo "==> Vérification de la connexion Azure..."
az account show >/dev/null 2>&1 || { echo "Pas connecté. Lancez 'az login'."; exit 1; }

echo "==> Vérification du groupe de ressources '${RESOURCE_GROUP}'..."
az group show --name "${RESOURCE_GROUP}" >/dev/null 2>&1 \
  || { echo "Groupe de ressources '${RESOURCE_GROUP}' introuvable."; exit 1; }

echo "==> Vérification du code source '${FUNC_SRC}'..."
[[ -f "${FUNC_SRC}/host.json" && -f "${FUNC_SRC}/hello/__init__.py" ]] \
  || { echo "Projet function introuvable dans ${FUNC_SRC}."; exit 1; }

# ---------------------------------------------------------------------------
# 1. Compte de stockage (requis par toute Function App)
# ---------------------------------------------------------------------------
if az storage account show --name "${STORAGE_ACCOUNT}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "==> Compte de stockage '${STORAGE_ACCOUNT}' déjà présent."
else
  echo "==> Création du compte de stockage '${STORAGE_ACCOUNT}'..."
  az storage account create \
    --name "${STORAGE_ACCOUNT}" \
    --resource-group "${RESOURCE_GROUP}" \
    --location "${LOCATION}" \
    --sku Standard_LRS
fi

# ---------------------------------------------------------------------------
# 2. Function App (plan Consommation / Serverless, Linux, Python 3.11)
# ---------------------------------------------------------------------------
if az functionapp show --name "${FUNC_APP_NAME}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "==> Function App '${FUNC_APP_NAME}' déjà présente."
else
  echo "==> Création de la Function App '${FUNC_APP_NAME}'..."
  az functionapp create \
    --name "${FUNC_APP_NAME}" \
    --resource-group "${RESOURCE_GROUP}" \
    --storage-account "${STORAGE_ACCOUNT}" \
    --consumption-plan-location "${LOCATION}" \
    --runtime "${RUNTIME}" \
    --runtime-version "${RUNTIME_VERSION}" \
    --functions-version "${FUNCTIONS_VERSION}" \
    --os-type Linux
fi

# Build distant des dépendances Python lors du déploiement zip
echo "==> Activation du build distant (Oryx)..."
az functionapp config appsettings set \
  --name "${FUNC_APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true ENABLE_ORYX_BUILD=true \
  >/dev/null

# ---------------------------------------------------------------------------
# 3. Déploiement du code (zip deploy)
# ---------------------------------------------------------------------------
echo "==> Empaquetage du code..."
( cd "${FUNC_SRC}" && zip -r -q "${ZIP_PATH}" . )

echo "==> Déploiement vers '${FUNC_APP_NAME}'..."
az functionapp deployment source config-zip \
  --name "${FUNC_APP_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --src "${ZIP_PATH}"

# ---------------------------------------------------------------------------
# 4. Résultat
# ---------------------------------------------------------------------------
echo "==> Déploiement terminé."
HOST=$(az functionapp show --name "${FUNC_APP_NAME}" --resource-group "${RESOURCE_GROUP}" --query defaultHostName -o tsv)
echo "Function App : https://${HOST}"
echo "Endpoint API : https://${HOST}/api/hello"
echo
echo "Test : curl https://${HOST}/api/hello"
