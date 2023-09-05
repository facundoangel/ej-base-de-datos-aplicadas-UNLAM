
--EJ 1
/*
. Cree una base de datos con los valores por defecto de crecimiento, ubicación de
archivos, etc. Llame a la misma con su nombre o el de su grupo (si opta por resolver
el TP en grupo).

*/
create database FACUNDOANGELDB

use FACUNDOANGELDB
go

--EJ 2
/*
Cree un esquema denominado “ddbba” (por bases de datos aplicada). Todos los
objetos que cree a partir de aquí deberán pertenecer a este esquema o a otro según
corresponda. No debe usar el esquema default (dbo).

*/
CREATE SCHEMA ddbba
go


--EJ 3
/*
Cree una tabla llamada “registro” que tenga los siguientes campos: id entero
autoincremental como primary key; fecha y hora con valor default del momento de
inserción, texto con un tamaño máximo de 50 caracteres, modulo con un tamaño
máximo de 10 caracteres. Esta tabla la empleará como bitácora (log) de las
operaciones de los puntos siguientes.
*/
CREATE TABLE [ddbba].[REGISTRO](
	ID INT identity(1, 1),
	FECYHOR DATETIME DEFAULT SYSDATETIME(),
	TEXTO NVARCHAR(50),
	MODULO VARCHAR(10),
	CONSTRAINT PK_REGISTRO PRIMARY KEY (ID),
)

ALTER TABLE ddbba.REGISTRO ALTER COLUMN ID INT identity(1, 1) 

DROP TABLE DDBBA.REGISTRO
go

--EJ 4
/*
Cree un SP llamado “insertarLog” que reciba dos parámetros: modulo y texto. Si el
modulo llega en blanco debe utilizar el texto “N/A”. Este SP insertará registros en la
tabla de bitácora. A partir del siguiente punto, cada inserción, borrado, modificación,
debe crear un registro en la mencionada tabla. En ningún caso debe realizar
INSERTs por fuera del SP insertarLog.
*/
CREATE PROC insertarLog (@moduloEntrada varchar(10),@textoEntrada nvarchar(50))
AS
BEGIN
	DECLARE @TEXTO nvarchar(50);

	IF (@moduloEntrada = '' OR @moduloEntrada IS NULL)
		SET  @TEXTO = 'N/A'
	ELSE
		SET  @TEXTO = @textoEntrada
		

	INSERT INTO [ddbba].[REGISTRO] 
	VALUES (GETDATE(),@TEXTO,@moduloEntrada);
END
GO


drop proc insertarLog
TRUNCATE TABLE ddbba.REGISTRO

exec insertarLog 'h', 'jhj';
exec insertarLog NULL, 'jhj';
exec insertarLog '', 'jhj';




--EJ 5
/*
. Modele la relación entre persona, curso, materia. Una materia tiene varios cursos.
Un curso tiene varias personas. Una persona puede ser alumno o docente en cada
materia (no ambos al mismo tiempo), pero puede ser docente en una y alumno en
otra. Genere tablas para cada uno. Asegúrese de aplicar los siguientes conceptos:
a. Claves primarias en cada tabla
b. Claves foráneas (restricciones) para vincular cada tabla a las demás.
c. Las personas pueden opcionalmente tener un vehículo. Incluya la patente
como campo de carga opcional con las restricciones de verificación
correspondientes.
d. Los cursos (comisiones) tienen un número de comisión de cuatro dígitos.
e. Las personas tienen un DNI y un número de teléfono, también una localidad
de residencia y una fecha de nacimiento. Nombres y apellido se almacenan
por separado.
f. Los aspectos de diseño que no estén detallados se dejan a su criterio.
Documente las decisiones en la forma de comentarios en los scripts.
*/
--CREACION DE TABLAS

CREATE TABLE ddbba.PERSONA(
	ID INT IDENTITY(1,1)
	,DNI INT
	,NOMBRE VARCHAR(30)
	,APELLIDO VARCHAR(30)
	,PATENTE_VEHICULO CHAR(7)
	,LOCALIDAD VARCHAR(30)
	,FECHA_NAC DATE
	,TELEFONO INT
	,CONSTRAINT PK_PERSONA PRIMARY KEY(ID)
	,CONSTRAINT CK_PATENTE_PERSONA CHECK (
		PATENTE_VEHICULO LIKE '[A-Z][A-Z][A-Z][0-9][0-9][0-9]' 
		OR PATENTE_VEHICULO LIKE '[0-9][0-9][0-9][A-Z][A-Z][A-Z]'
		OR PATENTE_VEHICULO LIKE '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]'
	)
);


INSERT INTO ddbba.PERSONA 
	VALUES (40640923,'facundo','angel','AB123JB','l. del mirador','19970811',123);

CREATE TABLE ddbba.MATERIA(
	ID INT IDENTITY(1,1),
	NOMBRE VARCHAR(30),
	CONSTRAINT PK_MATERIA PRIMARY KEY(ID)
);

INSERT INTO ddbba.MATERIA
	VALUES ('ALGEBRA');

CREATE TABLE ddbba.CURSO(
	NRO_COM INT
	,NOMBRE VARCHAR(30)
	,ID_MAT INT NOT NULL
	,CONSTRAINT PK_CURSO PRIMARY KEY(NRO_COM)
	,CONSTRAINT FORMAT_NRO_COM CHECK (NRO_COM >= 1000 AND NRO_COM <= 9999)
	,CONSTRAINT FK_MATERIA_CURSO FOREIGN KEY(ID_MAT) 
		REFERENCES ddbba.MATERIA(ID)
);

INSERT INTO DDBBA.CURSO
	VALUES(1236,'DETERMINANTES',3);

CREATE TABLE ddbba.ESTUDIA_EN(
	ID_PERSONA INT
	,ID_MAT INT
	,CONSTRAINT PK_ESTUDIA_EN PRIMARY KEY(ID_PERSONA, ID_MAT)
	,CONSTRAINT FK_ID__PERSONA__ESTUDIA_EN FOREIGN KEY (ID_PERSONA)
		REFERENCES ddbba.PERSONA(ID)
	,CONSTRAINT FK__ID_MAT__ESTUDIA_EN FOREIGN KEY (ID_MAT)
		REFERENCES ddbba.MATERIA(ID)
)
INSERT INTO DDBBA.ESTUDIA_EN
	VALUES (1,1)

DELETE FROM DDBBA.ESTUDIA_EN

CREATE TABLE ddbba.DA_CLASE(
	ID_PERSONA INT
	,ID_MAT INT
	,CONSTRAINT PK_DA_CLASE PRIMARY KEY(ID_PERSONA, ID_MAT)
	,CONSTRAINT FK__ID_PERSONA__DA_CLASE FOREIGN KEY (ID_PERSONA)
		REFERENCES ddbba.PERSONA(ID)
	,CONSTRAINT FK__ID_MAT__DA_CLASE FOREIGN KEY (ID_MAT)
		REFERENCES ddbba.MATERIA(ID)
)
GO

INSERT INTO DDBBA.DA_CLASE
	VALUES (1,1)
GO

--CREACION DE TRIGGERS


CREATE TRIGGER ddbba.VALIDACION__ESTUDIA_EN
ON ddbba.ESTUDIA_EN
AFTER INSERT
AS
BEGIN
	/*
		TRIGGER QUE VALIDA QUE UNA PERSONA NO ESTUDIE EN LA MISMA
		MATERIA DONDE DA CLASES
	*/

	DECLARE @PERSONA INT = (select i.ID_PERSONA from inserted i);
	DECLARE @MATERIA INT  = (select i.ID_MAT from inserted i);

	DECLARE @DA_CLASE INT = (SELECT 1 FROM ddbba.DA_CLASE DC 
		WHERE DC.ID_PERSONA = @PERSONA AND DC.ID_MAT=@MATERIA)

	IF @DA_CLASE IS NOT NULL
	BEGIN
		DELETE FROM ddbba.ESTUDIA_EN 
			WHERE ddbba.ESTUDIA_EN.ID_MAT = @MATERIA AND
			ddbba.ESTUDIA_EN.ID_PERSONA = @PERSONA;
		PRINT('ERROR: ESTA PERSONA ESTA DANDO CLASE EN EL MISMO CURSO EN DONDE QUERES QUE ESTUDIE, BOLUDO');
	END
		
END
GO

CREATE TRIGGER ddbba.VALIDACION__DA_CLASES
ON ddbba.DA_CLASE
AFTER INSERT
AS
BEGIN
	/*
		TRIGGER QUE VALIDA QUE UNA PERSONA DE CLASES EN LA MISMA
		MATERIA DONDE ESTUDIA
	*/

	DECLARE @PERSONA INT = (select i.ID_PERSONA from inserted i);
	DECLARE @MATERIA INT  = (select i.ID_MAT from inserted i);

	DECLARE @ESTUDIA_EN INT = (SELECT 1 FROM ddbba.ESTUDIA_EN EN 
		WHERE EN.ID_PERSONA = @PERSONA AND EN.ID_MAT=@MATERIA);

	IF @ESTUDIA_EN IS NOT NULL
	BEGIN
		DELETE FROM ddbba.DA_CLASE
			WHERE ddbba.DA_CLASE.ID_MAT = @MATERIA AND
			ddbba.DA_CLASE.ID_PERSONA = @PERSONA;
		PRINT('ERROR: ESTA PERSONA ESTA ESTUDIANDO EN EL MISMO CURSO EN DONDE QUERES QUE DE CLASES, BOLUDO');
	END;
END
GO

--EJ 6
/*
Compruebe que las restricciones creadas funcionen correctamente generando
juegos de prueba que no se admitan. Documente con un comentario el error de
validación en cada caso. Asegúrese de probar con valores no admitidos siquiera una
vez cada restricción.
*/
INSERT INTO ddbba.PERSONA 
	VALUES (40640923,'facundo','angel','ABC1234','l. del mirador','19970811',123);
INSERT INTO ddbba.PERSONA 
	VALUES (40640923,'facundo','angel','3455BVC','l. del mirador','19970811',123);
GO

--EJ 7
/*
Cree un stored procedure para generar registros aleatorios en la tabla de alumnos.
Para ello genere una tabla de nombres que tenga valores de nombres y apellidos
que podrá combinar de forma aleatoria. Al generarse cada registro de alumno tome
al azar dos valores de nombre y uno de apellido. El resto de los valores (localidad,
fecha de nacimiento, DNI, etc.) genérelos en forma aleatoria también. El SP debe
admitir un parámetro para indicar la cantidad de registros a generar.
*/

CREATE PROC SP_REGISTRO_RANDOM (@CANTREG INT)
AS
BEGIN
	DECLARE @CONT INT = 0;
	WHILE (@CONT < @CANTREG)
	BEGIN
		DECLARE @NUEVO_DNI INT = RAND() * 99999999 +1;
		DECLARE @NUEVO_NOMBRE VARCHAR(30);
		DECLARE @NUEVO_APELLIDO VARCHAR(30);
		DECLARE @PATENTE VARCHAR(7)='';
		DECLARE @NUEVA_LOCALIDAD VARCHAR(30);
		DECLARE @NUEVA_FECHA DATE;
		DECLARE @NUEVO_TELEFONO INT = 40000000 + RAND() * (999999) + 1


		SET @NUEVO_NOMBRE = (CASE CAST((RAND()*4+1) AS INT)
			WHEN 1 THEN 'FACUNDO'
			WHEN 2 THEN 'BRIAN'
			WHEN 3 THEN 'TOBIAS'
			WHEN 4 THEN 'ALEXIS'
			ELSE 'MARTIN'
			END);

		SET @NUEVO_APELLIDO = (CASE CAST((RAND()*3+1) AS INT)
			WHEN 1 THEN 'GONZALEZ'
			WHEN 2 THEN 'MARTINEZ'
			WHEN 3 THEN 'ALTAMONTE'
			WHEN 4 THEN 'PEREYRA'
			ELSE 'GUTIERREZ'
			END);

		--GENERO ALEATORIAMENTE LA PATENTE
		DECLARE @I INT=0;
		WHILE(@I < 7)
		BEGIN
			IF(@I<3)
				SET @PATENTE = @PATENTE +  (CASE CAST((RAND()*3+1) AS INT)
					WHEN 1 THEN 'A'
					WHEN 2 THEN 'B'
					WHEN 3 THEN 'C'
					WHEN 4 THEN 'D'
					ELSE 'E'
					END);

			IF(@I>=4)
				SET @PATENTE = @PATENTE +  (CASE CAST((RAND()*3+1) AS INT)
					WHEN 1 THEN '1'
					WHEN 2 THEN '2'
					WHEN 3 THEN '3'
					WHEN 4 THEN '4'
					ELSE '5'
					END);


			SET @I = @I + 1;
		END


		SET @NUEVA_LOCALIDAD = (CASE CAST((RAND()*3+1) AS INT)
			WHEN 1 THEN 'GONZALEZ CATAN'
			WHEN 2 THEN 'MORON'
			WHEN 3 THEN 'L. DEL MIRADOR'
			WHEN 4 THEN 'RAMOS MEJIA'
			ELSE 'LANUS'
			END);

		DECLARE @FECHA_INICIO DATE='19950101';
		DECLARE @FECHA_FIN DATE ='20001231';
		DECLARE @DIF_DIAS INT = DATEDIFF(DAY,@FECHA_INICIO,@FECHA_FIN);

		SET @NUEVA_FECHA= DATEADD(DAY,RAND(CHECKSUM(NEWID()))*@DIF_DIAS,@FECHA_INICIO) 
	

		INSERT INTO DDBBA.PERSONA
			VALUES(@NUEVO_DNI,@NUEVO_NOMBRE,@NUEVO_APELLIDO,@PATENTE,@NUEVA_LOCALIDAD,@NUEVA_FECHA,@NUEVO_TELEFONO);

		SET @CONT = @CONT + 1;
	END
END
GO

--EJ 8
--Utilizando el SP creado en el punto anterior, genere 1000 registros de alumnos.

SET NOCOUNT ON
EXEC SP_REGISTRO_RANDOM 1000
GO

--EJ 9
--Elimine los registros duplicados utilizando common table expressions.
-- SE ASUME LOS QUE TIENEN EL MISMO NOMBRE Y APELLIDO COMO MISMAS PERSONAS
WITH CONTREPETIDOS AS
(
SELECT 
ID, DNI, NOMBRE, APELLIDO, ROW_NUMBER() OVER (PARTITION BY NOMBRE, APELLIDO ORDER BY NOMBRE) AS CANT_REG
FROM ddbba.PERSONA
)

DELETE FROM ddbba.PERSONA
WHERE ID IN (
	SELECT ID
	FROM CONTREPETIDOS
	WHERE CANT_REG <> 1
)
GO


--EJ 10
/*
Cree otro SP para generar registros aleatorios de comisiones por materia. Cada
materia debe tener entre 1 y 5 comisiones, entre los distintos turnos.
*/
INSERT INTO ddbba.MATERIA VALUES 
('FISICA')
, ('LENGUA')
,('MATEMATICA')
,('PROGRAMACION')
,('DIBUJO TECNICO')
,('BASE DE DATOS')
,('BASE DE DATOS APLICADA')
,('FUNDAMENTOS DE TICS')
GO


CREATE PROC sp_generarComisionesAleat 
AS
BEGIN
	DECLARE @CANT_FILAS INT =	(SELECT COUNT(*) FROM ddbba.MATERIA);
	
	DECLARE @I INT = 0;


	WHILE @I<@CANT_FILAS
	BEGIN

		DECLARE @CANT_COMISIONES INT = RAND()*5+1
		,@J INT=0;

		WHILE @J<@CANT_COMISIONES
		BEGIN
			DECLARE @TURNO VARCHAR(2) = CASE CAST(RAND()*2+1 AS INT)
			WHEN 1 THEN 'TM'
			WHEN 2 THEN 'TT'
			ELSE 'TN'
			END;

			--NUMERO ENTRE 1000 Y 9999
			DECLARE @NRO INT = (RAND()*8999+1) + 1000;


			INSERT INTO ddbba.CURSO VALUES 
				(@NRO,@TURNO + '_' + CAST(@NRO AS VARCHAR) + '_' + CAST(@I AS VARCHAR),@I+1);

			SET @J = @J+1;
		END

	
	SET @I = @I + 1;
	END
END

EXEC sp_generarComisionesAleat
GO

--EJ 11
--Genere un SP para crear inscripciones a materias asignando alumnos a comisiones
CREATE PROC SP_INSCRIPCION_ALUMNOS
AS
BEGIN
	
	DECLARE @CANT_PERSONAS INT = (SELECT COUNT(*) FROM DDBBA.PERSONA);
	DECLARE @I INT = 1;

	-- PARA CADA PERSONA INICIO EL PROCESO DE INSCRIPCIÓN
	WHILE @I<=@CANT_PERSONAS
	BEGIN
		DECLARE @PERSONA_ID INT;

		WITH CTE_PERSONAS AS (
		SELECT *
		,ROW_NUMBER() OVER (ORDER BY ID) AS NUM
		FROM ddbba.PERSONA
		) SELECT @PERSONA_ID = ID FROM CTE_PERSONAS WHERE NUM = @I

		

		DECLARE @CANT_MAT_INSCRIPTO INT = RAND()*5+1;
		DECLARE @J INT = 0;


		--CALCULO UNA CANTIDAD RANDOM DE MATERIAS QUE SE VA A ANOTAR Y HAGO LA INSCRIPCION
		--PARA CADA MATERIA
		WHILE @J < @CANT_MAT_INSCRIPTO
		BEGIN
			DECLARE @MATERIA_ID INT = (SELECT TOP 1 ID FROM DDBBA.MATERIA ORDER BY NEWID());

			BEGIN TRY
				INSERT INTO DDBBA.ESTUDIA_EN VALUES (@PERSONA_ID,@MATERIA_ID);
			END TRY
			BEGIN CATCH
				--SI EN LA MATERIA YA ESTA INSCRIPTO DECREMENTO LA VARIABLE @J Y HAGO QUE REPITA
				--EL PROCESO HASTA ENCONTRAR UNA MATERIA EN LA QUE NO ESTE INSCRIPTO
				IF ERROR_NUMBER() = 2627
				BEGIN
					SET @J = @J - 1;
				END
			END CATCH

			SET @J = @J + 1;
		END

		SET @I = @I + 1;
	END

	
END
GO

--EJ 12
/*
 Cree una vista para visualizar las comisiones (nro de comisión, código de materia,
nombre de materia, apellido y nombre de los alumnos). El apellido y nombre debe
mostrarse con el formato “Apellido, Nombres” (observe la coma intermedia).
*/


WITH CTE_PER_MAT AS (
	SELECT 
	M.NOMBRE AS NOM_MAT
	, (P.APELLIDO + ', ' + P.NOMBRE) AS AYN
	,M.ID AS ID_MAT
	FROM DDBBA.PERSONA P 
	INNER JOIN DDBBA.ESTUDIA_EN EN 
		ON P.ID=EN.ID_PERSONA 
	INNER JOIN DDBBA.MATERIA M
		ON M.ID=EN.ID_MAT
) SELECT 
C.NRO_COM
,C.ID_MAT
,CPM.NOM_MAT
,CPM.AYN
FROM CTE_PER_MAT CPM, ddbba.CURSO C
	WHERE CPM.ID_MAT=C.ID_MAT


--EJ 13
/*
Agregue a la tabla de comisión soporte para día y turno de cursada. (Modifique la
tabla). Los números de comisión son únicos para cada cuatrimestre
*/

ALTER TABLE DDBBA.CURSO ADD DIA VARCHAR(16);
ALTER TABLE DDBBA.CURSO ADD TURNO CHAR(2);


--EJ 14
/*
Complete los datos de día y curso con valores aleatorios.
*/

DECLARE @CANT_INSCRIP INT = (SELECT COUNT(*) FROM DDBBA.ESTUDIA_EN)
DECLARE @I INT = 1;

WHILE @I<=@CANT_INSCRIP
BEGIN

	DECLARE @ID_COM INT;
	DECLARE @NOMBRE VARCHAR(30);
	DECLARE @DIA VARCHAR(16);
	DECLARE @TURNO CHAR(2);
	
	WITH CTE_INSCRIP AS(
		SELECT *
		,ROW_NUMBER() OVER ( ORDER BY C.NRO_COM) AS NUM
		FROM DDBBA.CURSO C
	)SELECT @ID_COM = CTE_I.NRO_COM
	,@NOMBRE = CTE_I.NOMBRE
	FROM CTE_INSCRIP CTE_I
	WHERE CTE_I.NUM = @I



	SET @DIA = CASE CAST(RAND()*4+1 AS INT)
	WHEN 1 THEN 'LUNES'
	WHEN 2 THEN 'MARTES'
	WHEN 3 THEN 'MIERCOLES'
	WHEN 4 THEN 'JUEVES'
	ELSE 'VIERNES'
	END;

	SET @TURNO = SUBSTRING(@NOMBRE,1,2);

	UPDATE DDBBA.CURSO
	SET DIA = @DIA, TURNO=@TURNO
	WHERE NRO_COM=@ID_COM


	SET @I = @I + 1;
END
GO



--EJ 15
/*
Genere una función validaCursada que devuelva la cantidad de materias
superpuestas a las que está inscripto un alumno, recibiendo el DNI por parámetro.
*/


CREATE FUNCTION DDBBA.validaCursada 
(@DNI INT)
RETURNS INT
AS
BEGIN

		DECLARE @RESULTADO INT;

	
		WITH CTE_PERS AS(
			SELECT P.*
			,C.TURNO
			,C.NRO_COM
			,C.DIA
			FROM DDBBA.PERSONA P, DDBBA.ESTUDIA_EN EN, DDBBA.CURSO C
			WHERE P.ID=EN.ID_PERSONA AND EN.ID_MAT=C.ID_MAT
			AND P.DNI=@DNI
		)SELECT @RESULTADO = COUNT(*) 
		FROM (
			SELECT C.*
			,ROW_NUMBER() OVER(PARTITION BY C.DIA,C.TURNO ORDER BY C.TURNO) AS NUM
			FROM CTE_PERS C
		) SUBCONS
		WHERE SUBCONS.NUM <> 1
		

		RETURN @RESULTADO
END


DECLARE @RESULT INT;

EXEC @RESULT = DDBBA.validaCursada @DNI=65544709; 

PRINT @RESULT;
GO

--EJ 16

/*
Cree una vista que utilice la función del punto anterior y muestre los alumnos con
superposición de inscripciones.
*/


CREATE VIEW DDBBA.alumnosCInterposicion 
AS
	SELECT DISTINCT
	A.ID
	,A.DNI
	,A.NOMBRE
	,A.APELLIDO
	,A.PATENTE_VEHICULO
	,A.LOCALIDAD
	,A.FECHA_NAC
	,A.TELEFONO
	FROM (
		SELECT P.*
				--,C.TURNO
				--,C.NRO_COM
				--,C.DIA
				,ROW_NUMBER() OVER (PARTITION BY C.DIA, C.TURNO,P.ID ORDER BY C.NRO_COM) AS NUM
				FROM DDBBA.PERSONA P, DDBBA.ESTUDIA_EN EN, DDBBA.CURSO C
				WHERE P.ID=EN.ID_PERSONA AND EN.ID_MAT=C.ID_MAT
	) A
	WHERE A.NUM <> 1

GO


SELECT *
FROM DDBBA.alumnosCInterposicion
GO

--EJ 17

/*
Cree un SP que elimine las inscripciones superpuestas o duplicadas.
*/
CREATE PROC DDBBA.ELIMINAR_INSCRP_INTERPUESTAS
AS
BEGIN 
	DECLARE @ID_ALUMNO INT=1;
	DECLARE @ID_MAT INT;


	WHILE @ID_ALUMNO <> 0
	BEGIN

		
		SELECT TOP 1 @ID_ALUMNO=A.ID,@ID_MAT=A.ID_MAT FROM(
		
			SELECT P.*
				,C.TURNO
				,C.NRO_COM
				,C.DIA
				,EN.ID_MAT
				,ROW_NUMBER() OVER (PARTITION BY C.DIA, C.TURNO,P.ID ORDER BY C.NRO_COM) AS NUM
			FROM DDBBA.PERSONA P, DDBBA.ESTUDIA_EN EN, DDBBA.CURSO C
			WHERE P.ID=EN.ID_PERSONA AND EN.ID_MAT=C.ID_MAT

		) A
		WHERE A.NUM <> 1


		DELETE FROM DDBBA.ESTUDIA_EN
		WHERE ID_PERSONA=@ID_ALUMNO AND ID_MAT=@ID_MAT

		SET @ID_ALUMNO = ISNULL(@ID_ALUMNO,0)

	END




END

