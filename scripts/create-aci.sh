#!/usr/bin/env bash
#
# Crée un Azure Container Instance (ACI) public exposant l'image quickstart
# aci-helloworld sur le port 80. Équivalent CLI de la Partie 3 du TP.
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
LOCATION="francecentral"
ACI_NAME="${ACI_NAME:-api-aci-${PRENOM}}"
ACI_IMAGE="${ACI_IMAGE:-mcr.microsoft.com/azuredocs/aci-helloworld}"
# Étiquette DNS unique dans la région : <label>.<region>.azurecontainer.io
DNS_LABEL="${DNS_LABEL:-api-aci-${PRENOM}}"
ACI_PORT="${ACI_PORT:-80}"
ACI_CPU="${ACI_CPU:-1}"
ACI_MEMORY="${ACI_MEMORY:-1.5}"

echo "==> Vérification de la connexion Azure..."
az account show >/dev/null 2>&1 || { echo "Pas connecté. Lancez 'az login'."; exit 1; }

echo "==> Vérification du groupe de ressources '${RESOURCE_GROUP}'..."
az group show --name "${RESOURCE_GROUP}" >/dev/null 2>&1 \
  || { echo "Groupe de ressources '${RESOURCE_GROUP}' introuvable."; exit 1; }

if az container show --name "${ACI_NAME}" --resource-group "${RESOURCE_GROUP}" >/dev/null 2>&1; then
  echo "==> Container Instance '${ACI_NAME}' déjà présent."
else
  echo "==> Création du Container Instance '${ACI_NAME}'..."
  az container create \
    --resource-group "${RESOURCE_GROUP}" \
    --name "${ACI_NAME}" \
    --image "${ACI_IMAGE}" \
    --location "${LOCATION}" \
    --os-type Linux \
    --cpu "${ACI_CPU}" \
    --memory "${ACI_MEMORY}" \
    --ports "${ACI_PORT}" \
    --ip-address Public \
    --dns-name-label "${DNS_LABEL}"
fi

echo "==> Déploiement terminé."
FQDN=$(az container show --name "${ACI_NAME}" --resource-group "${RESOURCE_GROUP}" \
  --query ipAddress.fqdn -o tsv)
echo "Container Instance créé : http://${FQDN}"
echo
echo "Test  : curl http://${FQDN}"
echo "Logs  : az container logs --name ${ACI_NAME} --resource-group ${RESOURCE_GROUP}"
echo "Shell : az container exec --name ${ACI_NAME} --resource-group ${RESOURCE_GROUP} --exec-command /bin/sh"
