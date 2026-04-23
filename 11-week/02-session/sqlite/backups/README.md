# SQLite Backups

Esta carpeta almacena los respaldos de las bases de datos SQLite.

## Estructura

```
backups/
├── backup_YYYYMMDD_HHMMSS.db   # Backups binarios (.db)
├── backup_YYYYMMDD_HHMMSS.sql  # Backups SQL (.sql)
└── README.md                    # Este archivo
```

## Crear Backup

### Backup Binario (.db)
```bash
docker exec serve-sqlite sqlite3 /data/database.db ".backup /backups/backup_$(date +%Y%m%d_%H%M%S).db"
```

### Backup SQL (.sql)
```bash
docker exec serve-sqlite sqlite3 /data/database.db .dump > ./backups/backup_$(date +%Y%m%d_%H%M%S).sql
```

## Restaurar Backup

### Desde .db
```bash
docker exec serve-sqlite cp /backups/backup_20250120.db /data/database.db
```

### Desde .sql
```bash
docker exec -i serve-sqlite sqlite3 /data/database.db < ./backups/backup_20250120.sql
```

## Automatización

Ver el README principal para scripts de backup automatizados.
