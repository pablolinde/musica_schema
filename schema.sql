/*
CREATE DATABASE IF NOT EXISTS MI_DB;
USE MI_DB;
CREATE SCHEMA IF NOT EXISTS MUSICA;
USE MUSICA;
*/

DROP TABLE USUARIO
    CASCADE CONSTRAINTS PURGE;

DROP TABLE BANDA
    CASCADE CONSTRAINTS PURGE;

DROP TABLE MUSICO
    CASCADE CONSTRAINTS PURGE;
     
DROP TABLE LISTA
    CASCADE CONSTRAINTS PURGE;

DROP TABLE LISTA_CANCION
    CASCADE CONSTRAINTS PURGE;

CREATE TABLE USUARIO(
     id_usuario	CHAR(4) NOT NULL, 
     nombre VARCHAR2(20) NOT NULL,
     email VARCHAR2(40) NULL,
     telefono CHAR(12) NULL,
     tipo VARCHAR2(30) NOT NULL,
     cuota DECIMAL(4,2) NOT NULL,
     invitador CHAR(4) NULL,
     ultimo_acceso DATE NOT NULL,
     CONSTRAINT usuario_key PRIMARY KEY (id_usuario),
     CONSTRAINT usuario_ak UNIQUE (telefono), UNIQUE (email),
     CONSTRAINT usuario_fk_invitador FOREIGN KEY (invitador) REFERENCES USUARIO(id_usuario),
                --ON DELETE NO ACTION ON UPDATE CASCADE
     CONSTRAINT email_xor_telefono_null CHECK ((email IS NOT NULL AND telefono IS NULL) OR (email IS NULL AND telefono IS NOT NULL)),
     CONSTRAINT tipo_valores_posibles CHECK (tipo IN ('PREMIUM INDIVIDUAL', 'GRATUITO', 'PREMIUM DOS', 'PREMIUM FAMILIAR')),
     CONSTRAINT no_auto_invitacion CHECK (invitador <> id_usuario OR invitador IS NULL)
);
     
CREATE TABLE BANDA(
     id_artista CHAR(4) NOT NULL,
     nombre VARCHAR2(20) NOT NULL,
     PAIS_ORIGEN VARCHAR2(30) NULL,
     a_fundacion CHAR(4) NOT NULL,
     lider CHAR (4) NOT NULL,
     CONSTRAINT banda_key PRIMARY KEY (id_artista),
     CONSTRAINT banda_ak UNIQUE (nombre), UNIQUE (lider)
);

CREATE TABLE MUSICO(
     id_musico CHAR(4) NOT NULL, 
     nombre VARCHAR2(20) NOT NULL,
     banda CHAR(4) NOT NULL,
     CONSTRAINT musico_key PRIMARY KEY (id_musico),
     CONSTRAINT musico_fk FOREIGN KEY (banda) REFERENCES BANDA(id_artista)
                --ON DELETE NO ACTION ON UPDATE CASCADE
);

CREATE TABLE LISTA(
     usuario CHAR(4) NOT NULL,
     num_lista NUMBER(2,0) NOT NULL,
     nombre VARCHAR2(20) NOT NULL,
     descripcion VARCHAR2(40) NULL,
     CONSTRAINT lista_key PRIMARY KEY (usuario,num_lista),
     CONSTRAINT lista_fk FOREIGN KEY (usuario) REFERENCES USUARIO(id_usuario),
     CONSTRAINT num_lista_positivo check (num_lista > 0)
                --ON DELETE NO ACTION ON UPDATE CASCADE
);

CREATE TABLE LISTA_CANCION(
     usuario CHAR(4) NOT NULL,
     lista NUMBER(2,0) NOT NULL,
     album CHAR(4) NOT NULL,
     cancion NUMBER(2,0) NOT NULL,
     fecha DATE NOT NULL,
     CONSTRAINT lc_key PRIMARY KEY (usuario,lista,album,cancion),
     CONSTRAINT lc_fk FOREIGN KEY (usuario,lista) REFERENCES LISTA(usuario,num_lista)
                --ON DELETE NO ACTION ON UPDATE CASCADE
);

/*
el alter table de banda se realizara al final de los inserts para
 que no haya problemas de con la clave ajena
*/