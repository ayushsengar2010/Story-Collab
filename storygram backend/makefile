makeup:
	docker exec -it project3 psql -U root -d project12

migrateup:
	/usr/local/bin/migrate -path db\migration\000001_init_schema.up.sql -database "postgresql://root:Nikhil@123k@project3:5432/project3postgresql1?sslmode=disable" -verbose up


migratedown:
	migrate -path "db/migration/000001_init_schema.down.sql" -database "postgresql://root:Nikhil@123k@project3:5432/project3postgresql1?sslmode=disable" -verbose down

postgres:
	docker run --name project3 -p 5432:5432 \
	-e POSTGRES_USER=root \
	-e POSTGRES_PASSWORD=Nikhil@123k \
	-e POSTGRES_DB=project3postgresql1 \
	-d postgres:17-alpine

createdb:
	psql -U root -d project12 -f db/migration/001_create_authors.sql

.PHONY: makeup migrateup migratedown postgres createdb
