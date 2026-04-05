-- ============================================================
-- Base de Datos II · Unidad 2 · Semana 7 · Sesión 2
-- Taller: Triggers aplicados en PostgreSQL
-- CORHUILA · Ingeniería de Sistemas
-- ============================================================

-- ============================================================
-- PARTE 1: TABLAS BASE
-- ============================================================

CREATE TABLE IF NOT EXISTS estudiante (
  id         BIGSERIAL PRIMARY KEY,
  nombre     TEXT NOT NULL,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS matricula (
  id            BIGSERIAL PRIMARY KEY,
  estudiante_id BIGINT NOT NULL REFERENCES estudiante(id),
  semestre      TEXT NOT NULL,
  nota_final    NUMERIC NULL,
  updated_at    TIMESTAMP NULL
);

CREATE TABLE IF NOT EXISTS matricula_audit (
  id           BIGSERIAL PRIMARY KEY,
  operacion    TEXT NOT NULL,
  matricula_id BIGINT,
  fecha        TIMESTAMP NOT NULL DEFAULT NOW(),
  detalle      TEXT
);

-- ============================================================
-- PARTE 2: TRIGGER BEFORE — estudiante
-- Qué hace: normaliza el nombre (TRIM + INITCAP) y asigna
-- created_at en INSERT y updated_at en INSERT/UPDATE.
-- Por qué: garantiza datos limpios sin depender de la app.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_estudiante_before()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Normalizar nombre: quita espacios y pone mayúscula inicial
  NEW.nombre := INITCAP(TRIM(NEW.nombre));

  IF TG_OP = 'INSERT' THEN
    IF NEW.created_at IS NULL THEN
      NEW.created_at := NOW();
    END IF;
    NEW.updated_at := NOW();

  ELSIF TG_OP = 'UPDATE' THEN
    NEW.updated_at := NOW();
  END IF;

  RETURN NEW;  -- Obligatorio en BEFORE: devuelve la fila modificada
END;
$$;

DROP TRIGGER IF EXISTS trg_estudiante_before ON estudiante;

CREATE TRIGGER trg_estudiante_before
BEFORE INSERT OR UPDATE ON estudiante
FOR EACH ROW
EXECUTE FUNCTION fn_estudiante_before();

-- ============================================================
-- PARTE 3: TRIGGER BEFORE — matricula (validación de nota)
-- Qué hace: rechaza notas fuera del rango 0–5 y asigna updated_at.
-- Por qué: una nota inválida nunca debe llegar a la tabla.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_matricula_validar_nota()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- Validar rango de nota_final
  IF NEW.nota_final IS NOT NULL
     AND (NEW.nota_final < 0 OR NEW.nota_final > 5) THEN
    RAISE EXCEPTION 'Nota fuera de rango (0 a 5). Valor=%', NEW.nota_final;
  END IF;

  NEW.updated_at := NOW();
  RETURN NEW;  -- Obligatorio en BEFORE
END;
$$;

DROP TRIGGER IF EXISTS trg_matricula_before ON matricula;

CREATE TRIGGER trg_matricula_before
BEFORE INSERT OR UPDATE ON matricula
FOR EACH ROW
EXECUTE FUNCTION fn_matricula_validar_nota();

-- ============================================================
-- PARTE 4: TRIGGER AFTER — auditoría de matrícula
-- Qué hace: registra toda operación (INSERT/UPDATE/DELETE)
-- en matricula_audit con fecha, tipo y id afectado.
-- Por qué: trazabilidad completa sin modificar la lógica principal.
-- ============================================================

CREATE OR REPLACE FUNCTION fn_matricula_audit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO matricula_audit(operacion, matricula_id, detalle)
    VALUES ('INSERT', NEW.id, 'Nueva matrícula registrada');
    RETURN NEW;

  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO matricula_audit(operacion, matricula_id, detalle)
    VALUES ('UPDATE', NEW.id, 'Matrícula actualizada');
    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    -- En DELETE no existe NEW, solo OLD
    INSERT INTO matricula_audit(operacion, matricula_id, detalle)
    VALUES ('DELETE', OLD.id, 'Matrícula eliminada');
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_matricula_audit ON matricula;

CREATE TRIGGER trg_matricula_audit
AFTER INSERT OR UPDATE OR DELETE ON matricula
FOR EACH ROW
EXECUTE FUNCTION fn_matricula_audit();

-- ============================================================
-- PARTE 5: PRUEBAS Y EVIDENCIAS
-- ============================================================

-- ------------------------------------------------------------
-- PRUEBA 1: INSERT en estudiante — verifica normalización y timestamps
-- Evidencia esperada: nombre = 'Maria Lopez', created_at y updated_at
-- ------------------------------------------------------------
INSERT INTO estudiante(nombre) VALUES ('   maria lopez   ');
SELECT id, nombre, created_at, updated_at
FROM estudiante
ORDER BY id DESC LIMIT 1;

-- ------------------------------------------------------------
-- PRUEBA 2: INSERT en matricula válida — verifica auditoría INSERT
-- ------------------------------------------------------------
INSERT INTO matricula(estudiante_id, semestre, nota_final)
VALUES (1, '2026-1', 4.2);

SELECT id, estudiante_id, semestre, nota_final, updated_at
FROM matricula
ORDER BY id DESC LIMIT 1;

SELECT id, operacion, matricula_id, fecha, detalle
FROM matricula_audit
ORDER BY id DESC LIMIT 5;

-- ------------------------------------------------------------
-- PRUEBA 3: UPDATE en matrícula — verifica auditoría UPDATE
-- ------------------------------------------------------------
UPDATE matricula SET nota_final = 3.5 WHERE id = 1;

SELECT id, operacion, matricula_id, fecha, detalle
FROM matricula_audit
ORDER BY id DESC LIMIT 5;

-- ------------------------------------------------------------
-- PRUEBA 4 (OPCIONAL): DELETE — verifica auditoría DELETE
-- ------------------------------------------------------------
-- DELETE FROM matricula WHERE id = 1;
-- SELECT * FROM matricula_audit ORDER BY id DESC LIMIT 5;

-- ------------------------------------------------------------
-- PRUEBA 5: Operación fallida — nota fuera de rango (DEBE FALLAR)
-- Evidencia esperada: ERROR con mensaje 'Nota fuera de rango...'
-- ------------------------------------------------------------
UPDATE matricula SET nota_final = 7 WHERE id = 1;

-- ============================================================
-- FIN DEL SCRIPT
-- ============================================================
