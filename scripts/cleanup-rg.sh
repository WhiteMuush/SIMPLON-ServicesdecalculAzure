#!/usr/bin/env bash
#
# Supprime TOUTES les ressources contenues dans un groupe de ressources Azure,
# sans jamais supprimer le groupe de ressources lui-même.
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

RESOURCE_GROUP="${1:-${RESOURCE_GROUP:-mon-groupe-de-ressources}}"  # 1er argument prioritaire sur .env
FORCE="${FORCE:-}"                                                  # FORCE=1 pour sauter la confirmation

echo "==> Vérification de la connexion Azure..."
az account show >/dev/null 2>&1 || { echo "Pas connecté. Lancez 'az login'."; exit 1; }

echo "==> Vérification du groupe de ressources '${RESOURCE_GROUP}'..."
az group show --name "${RESOURCE_GROUP}" >/dev/null 2>&1 \
  || { echo "Groupe de ressources '${RESOURCE_GROUP}' introuvable."; exit 1; }

echo "==> Liste des ressources présentes dans '${RESOURCE_GROUP}'..."
mapfile -t IDS < <(az resource list --resource-group "${RESOURCE_GROUP}" --query "[].id" -o tsv)

if [[ "${#IDS[@]}" -eq 0 ]]; then
  echo "Aucune ressource à supprimer. Le groupe '${RESOURCE_GROUP}' est déjà vide."
  exit 0
fi

az resource list --resource-group "${RESOURCE_GROUP}" \
  --query "[].{Nom:name, Type:type}" -o table

echo
echo "ATTENTION : ${#IDS[@]} ressource(s) ci-dessus vont être SUPPRIMÉES définitivement."
echo "Le groupe de ressources '${RESOURCE_GROUP}' sera CONSERVÉ."
if [[ "${FORCE}" != "1" ]]; then
  read -r -p "Confirmer la suppression ? Tapez le nom du groupe pour continuer : " CONFIRM
  if [[ "${CONFIRM}" != "${RESOURCE_GROUP}" ]]; then
    echo "Annulé. Aucune ressource supprimée."
    exit 1
  fi
fi

# Suppression en bloc : az gère l'ordre des dépendances et réessaie tant qu'il
# reste des ressources (utile quand une suppression en libère une autre).
echo "==> Suppression des ressources..."
az resource delete --ids "${IDS[@]}" --verbose || true

# Boucle de vérification : certaines ressources ont des dépendances implicites
# qui empêchent leur suppression au premier passage.
for attempt in 1 2 3; do
  mapfile -t REMAINING < <(az resource list --resource-group "${RESOURCE_GROUP}" --query "[].id" -o tsv)
  [[ "${#REMAINING[@]}" -eq 0 ]] && break
  echo "==> ${#REMAINING[@]} ressource(s) restante(s), nouvelle tentative (${attempt}/3)..."
  az resource delete --ids "${REMAINING[@]}" --verbose || true
done

mapfile -t REMAINING < <(az resource list --resource-group "${RESOURCE_GROUP}" --query "[].id" -o tsv)
if [[ "${#REMAINING[@]}" -eq 0 ]]; then
  echo "==> Terminé. Le groupe '${RESOURCE_GROUP}' est vide et toujours présent."
else
  echo "==> Attention : ${#REMAINING[@]} ressource(s) n'ont pas pu être supprimées :"
  az resource list --resource-group "${RESOURCE_GROUP}" --query "[].{Nom:name, Type:type}" -o table
  exit 1
fi
