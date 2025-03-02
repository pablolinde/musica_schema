-- Selecciona los usuarios que han invitado al menos a 2 personas y muestra su ID, nombre y cuota
SELECT id_usuario, nombre, cuota
FROM USUARIO
WHERE id_usuario IN (
    SELECT invitador
    FROM USUARIO
    GROUP BY invitador
    HAVING COUNT(id_usuario) >= 2
)
ORDER BY nombre;

-- Reduce en un 5% la cuota de los usuarios que han invitado al menos a 2 personas
UPDATE USUARIO
SET cuota = cuota * 0.95
WHERE id_usuario IN (
    SELECT invitador
    FROM USUARIO
    GROUP BY invitador
    HAVING COUNT(id_usuario) >= 2
);
ROLLBACK; -- Revierte la actualización de las cuotas

-- Deshabilita la restricción de clave foránea en LISTA_CANCION antes de actualizar
ALTER TABLE LISTA_CANCION
    DISABLE CONSTRAINT lc_fk;

-- Modifica el usuario en LISTA_CANCION de 'U001' a 'U901'
UPDATE LISTA_CANCION
    SET USUARIO = 'U901'
    WHERE USUARIO = 'U001';

-- Deshabilita la restricción de clave foránea en LISTA antes de actualizar
ALTER TABLE LISTA
    DISABLE CONSTRAINT lista_fk;

-- Modifica el usuario en LISTA de 'U001' a 'U901'
UPDATE LISTA
    SET USUARIO = 'U901'
    WHERE USUARIO = 'U001';

-- Deshabilita la restricción de clave foránea en USUARIO antes de actualizar
ALTER TABLE USUARIO
    DISABLE CONSTRAINT usuario_fk_invitador;

-- Modifica el id_usuario de 'U001' a 'U901'
UPDATE USUARIO
    SET id_usuario = 'U901'
    WHERE id_usuario = 'U001';

-- Modifica el campo invitador de 'U001' a 'U901'
UPDATE USUARIO
    SET invitador = 'U901'
    WHERE invitador = 'U001';

-- Reactiva las restricciones de claves foráneas en USUARIO, LISTA y LISTA_CANCION
ALTER TABLE USUARIO
    ENABLE CONSTRAINT usuario_fk_invitador;

ALTER TABLE LISTA
    ENABLE CONSTRAINT lista_fk;
    
ALTER TABLE LISTA_CANCION 
    ENABLE CONSTRAINT lc_key;

-- Borra los usuarios gratuitos que no han invitado a nadie, cuyo último acceso fue antes del 19/11/2019 y que no tienen listas de canciones asociadas
DELETE FROM USUARIO 
WHERE id_usuario IN (
    SELECT invitador.id_usuario
    FROM USUARIO invitador
    WHERE tipo = 'GRATUITO'
        AND NOT EXISTS (
            SELECT id_usuario
            FROM USUARIO invitado
            WHERE invitado.invitador = invitador.id_usuario
        )
        AND ultimo_acceso < TO_DATE('19/11/2019', 'dd/mm/yyyy')
        AND id_usuario NOT IN (SELECT usuario FROM LISTA_CANCION)
);

COMMIT; -- Confirma los cambios

-- Borra las listas y listas de canciones del usuario 'U236', luego borra al usuario
DELETE FROM LISTA_CANCION WHERE usuario = 'U236';
DELETE FROM LISTA WHERE usuario = 'U236';
DELETE FROM USUARIO WHERE id_usuario = 'U236';

COMMIT; -- Confirma los cambios

-- Elimina las columnas pais_origen y a_fundacion de la tabla BANDA
ALTER TABLE BANDA
    DROP (pais_origen, a_fundacion);

-- Crea una vista con datos de usuarios no gratuitos, incluyendo la cantidad de listas creadas y los días desde su último acceso
CREATE VIEW DATOS_USUARIO(usuario, tipo, cuota, listas, desconexion) 
AS SELECT id_usuario usuario, tipo, cuota, COUNT(usuario) listas,
    (TO_DATE('29/12/2023', 'dd/mm/yyyy') - ultimo_acceso) desconexion
FROM USUARIO
LEFT JOIN LISTA ON id_usuario = usuario
WHERE tipo <> 'GRATUITO'
GROUP BY id_usuario, tipo, cuota, ultimo_acceso;

-- Muestra el contenido de la vista ordenado por usuario
SELECT * FROM DATOS_USUARIO ORDER BY usuario;

-- Modifica la vista para incluir el 21% de aumento en la cuota
CREATE OR REPLACE VIEW DATOS_USUARIO(usuario, cuota, listas, desconexion) 
AS SELECT id_usuario usuario, cuota * 1.21, COUNT(usuario) listas,
    (TO_DATE('29/12/2023', 'dd/mm/yyyy') - ultimo_acceso) desconexion
FROM USUARIO
LEFT JOIN LISTA ON id_usuario = usuario
WHERE cuota > 0
GROUP BY id_usuario, tipo, cuota, ultimo_acceso;

-- Inserta un nuevo usuario premium en la base de datos
INSERT INTO USUARIO (id_usuario, nombre, email, telefono, tipo, cuota, invitador, ultimo_acceso)
VALUES ('UUUU', 'FEDERICO', 'federico@gmail.com', NULL, 'PREMIUM DOS', 14, NULL, TO_DATE('25/02/2019', 'dd/mm/yyyy'));

-- Vuelve a mostrar el contenido de la vista para verificar los cambios
SELECT * FROM DATOS_USUARIO ORDER BY usuario;

COMMIT; -- Confirma los cambios

-- Restricciones de integridad.
/*
CREATE ASSERTION lider_banda
CHECK(NOT EXISTS(SELECT lider FROM BANDA JOIN MUSICO ON lider = id_musico WHERE banda <> id_artista));

Esto se podria usar para comprobar que el codigo anterior esta bien

update banda
set lider = 'M019'
where nombre = 'QUEEN'

update banda
set lider = 'M003'
where nombre = 'QUEEN'
*/

-- Encuentra todas las listas creadas por usuarios gratuitos con más de 6 canciones en sus colecciones
SELECT l.nombre, u.nombre, u.tipo 
FROM usuario u JOIN lista l ON u.id_usuario = l.usuario 
WHERE u.id_usuario IN (
    SELECT usuario 
    FROM lista_cancion 
    GROUP BY usuario 
    HAVING COUNT(*) > 6
) 
AND u.tipo = 'GRATUITO';

-- Crea un índice en la columna 'tipo' de la tabla USUARIO para mejorar el rendimiento de la consulta anterior
CREATE INDEX idx_usuario_tipo ON USUARIO(tipo);

-- Muestra el plan de ejecución de la consulta para verificar si usa el índice
EXPLAIN PLAN FOR
SELECT l.nombre, u.nombre, u.tipo
FROM usuario u JOIN lista l ON u.id_usuario = l.usuario
WHERE u.id_usuario IN (
    SELECT usuario
    FROM lista_cancion
    GROUP BY usuario
    HAVING COUNT(*) > 6
)
AND u.tipo = 'GRATUITO';

-- Muestra el plan de ejecución generado
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);