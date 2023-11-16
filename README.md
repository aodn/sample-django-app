# Recipe App API DevOps Starting Point

Source code for my Udemy course Build a [Backend REST API with Python & Django - Advanced](http://udemy.com/django-python-advanced/).

The course teaches how to build a fully functioning REST API using:

 - Python
 - Django / Django-REST-Framework
 - Docker / Docker-Compose
 - Test Driven Development

## Getting started

To start project, run:

```
docker-compose up
```

The API will then be available at http://127.0.0.1:8000

## Creating the Database
To initialise the database on a new host (e.g. RDS), connect to the database instance with superuser (e.g postgres or whatever user you have granted superuser privileges to) and run the following commands:
```sql
CREATE DATABASE api;
CREATE USER api WITH PASSWORD 'mypassword';
ALTER DATABASE api OWNER TO api;
-- the next two commands are needed on PostgreSQL 15 and later
\connect api;
GRANT CREATE ON SCHEMA public TO api;
```
