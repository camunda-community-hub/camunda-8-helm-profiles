
.PHONY: docker-compose-up
docker-compose-up:
	docker-compose -f $(dockerComposeFile) up -d

.PHONY: docker-compose-down
docker-compose-down:
	docker-compose -f $(dockerComposeFile) down -v