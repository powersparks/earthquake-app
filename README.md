docker pull postgres:16-alpine

docker run -d \
  --name earthquake-postgres \
  -e POSTGRES_DB=earthquake_db \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgres:16-alpine

  brew install kind
