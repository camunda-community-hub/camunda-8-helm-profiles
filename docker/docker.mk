
.PHONY: docker-compose-up
docker-compose-up:
	docker-compose -f $(dockerComposeFile) up -d

.PHONY: docker-compose-ps
docker-compose-ps:
	docker-compose ps
#	docker inspect gateway-with-3-brokers-broker-1-1 | jq ".[].State.Health.Status"

.PHONY: docker-compose-down
docker-compose-down:
	docker-compose -f $(dockerComposeFile) down -v