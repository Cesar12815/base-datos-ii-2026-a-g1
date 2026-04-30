
# Manual de Configuración y Creación de Base de Datos en Cassandra

## 1. Configuración del Contenedor de Cassandra

### Dockerfile:

```Dockerfile
FROM cassandra:latest

# Copia tu archivo personalizado de configuración de Cassandra
COPY cassandra.yaml /etc/cassandra/cassandra.yaml

# Exponer el puerto 9042 (para consultas CQL) y 7000 (para Gossip)
EXPOSE 9042 7000

CMD ["cassandra", "-f"]
```

### `docker-compose.yml`:

```yaml
version: '3.8'

services:
  cassandra:
    image: cassandra:latest
    container_name: serve-cassandra
    restart: always
    environment:
      CASSANDRA_CLUSTER_NAME: "Test Cluster"
      CASSANDRA_NUM_TOKENS: 256
      CASSANDRA_DC: DC1
      CASSANDRA_RACK: Rack1
      CASSANDRA_ENDPOINT_SNITCH: GossipingPropertyFileSnitch
      CASSANDRA_LISTEN_ADDRESS: <Coloca_IP_Aqui>  # Usa la IP del contenedor
      CASSANDRA_BROADCAST_ADDRESS: <Coloca_IP_Aqui>  # Usa la misma IP del contenedor
      CASSANDRA_SEEDS: <Coloca_IP_Aqui>  # También usa esta IP como semilla
      CASSANDRA_AUTHENTICATOR: PasswordAuthenticator
      CASSANDRA_USERNAME: admin
      CASSANDRA_PASSWORD: abcd1234
    ports:
      - "9042:9042"  # Puerto para consultas CQL
      - "7000:7000"  # Puerto Gossip para la comunicación entre nodos
    volumes:
      - cassandra_data:/var/lib/cassandra
    networks:
      - network_local_server
    healthcheck:
      test: ["CMD-SHELL", "cqlsh -u admin -p abcd1234 -e 'describe cluster'"]
      interval: 30s
      timeout: 10s
      retries: 5
    labels:
      - com.corhuila.group=databases

volumes:
  cassandra_data:
    driver: local

networks:
  network_local_server:
    external: true
```

### `cassandra.yaml`:

```yaml
cluster_name: 'Test Cluster'

num_tokens: 256
initial_token:
# Se recomienda no definir el initial_token cuando se utiliza num_tokens

listen_address: 0.0.0.0  # Escucha en todas las interfaces

broadcast_address: cassandra  # Usar el nombre del servicio o la IP del contenedor

rpc_address: 0.0.0.0  # Permite que Cassandra escuche en todas las interfaces para solicitudes RPC

seed_provider:
  - class_name: org.apache.cassandra.locator.SimpleSeedProvider
    parameters:
         - seeds: "cassandra"  # Puedes usar el nombre del servicio como semilla para el clúster

# Autenticación habilitada
authenticator: PasswordAuthenticator

endpoint_snitch: GossipingPropertyFileSnitch
```

## 2. Creación de la Red de Docker y Obtención de la IP

Para conectar el contenedor a una red de Docker y obtener la dirección IP, sigue estos pasos:

1. Crea la red de Docker si no existe con el siguiente comando:

   ```bash
    docker network rm network_local_server
    docker network create network_local_server
   ```

2. Montar contenedor 
  
  ```bash
    docker-compose down
    docker-compose up -d --build
  ``` 

3. Verifica la red y obtén la dirección IP interna del contenedor:

   ```bash
   docker network inspect network_local_server
   ```

   Busca el contenedor de Cassandra (`serve-cassandra`) y obtén la dirección IP.

4. Usa la IP obtenida en las variables `CASSANDRA_LISTEN_ADDRESS`, `CASSANDRA_BROADCAST_ADDRESS`, y `CASSANDRA_SEEDS` en el archivo `docker-compose.yml`.

5. Reestablecer el contenedor.
  
  ```bash
    docker restart serve-cassandra
  ```

6. Acceder al contenedor `docker exec -it serve-cassandra cqlsh -u admin -p abcd1234`

## 3. Creación de una Base de Datos de Prueba

Una vez que Cassandra está corriendo correctamente, sigue estos pasos para crear un keyspace (equivalente a una base de datos) y una tabla.

### 1. Crear un Keyspace de prueba:

```sql
CREATE KEYSPACE test_keyspace
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
```

### 2. Usar el Keyspace:

```sql
USE test_keyspace;
```

### 3. Crear una tabla:

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY,
  name TEXT,
  email TEXT
);
```

### 4. Insertar datos de prueba:

```sql
INSERT INTO users (id, name, email) VALUES (uuid(), 'John Doe', 'john.doe@example.com');
INSERT INTO users (id, name, email) VALUES (uuid(), 'Jane Smith', 'jane.smith@example.com');
```

### 5. Consultar los datos insertados:

```sql
SELECT * FROM users;
```

## 4. Conclusión

Este manual te guía a través del proceso completo de configuración de Cassandra en Docker, incluyendo la configuración de la red, obtención de la IP, y la creación de un keyspace y tablas de prueba. Asegúrate de ajustar la IP y las variables de entorno según sea necesario para adaptarse a tu entorno de red.
