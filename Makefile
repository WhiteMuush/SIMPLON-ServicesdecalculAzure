.PHONY: function-app
function-app: 
		./scripts/create-function.sh

.PHONY: aci
aci:
	./scripts/create-aci.sh

.PHONY: service-app
service-app:
	./scripts/create-appservice.sh

.PHONY: cleanup-rg
cleanup-rg:
	./scripts/cleanup-rg.sh

.PHONY: help
help:
	@echo ""
	@echo "Cibles disponibles :"
	@echo ""
	@echo "  make function-app   Crée la Function App"
	@echo "  make aci            Crée le Container Instance"
	@echo "  make service-app    Crée l'App Service"
	@echo "  make cleanup-rg     Supprime toutes les ressources du RG"
	@echo "  make help           Affiche cette aide"
