
/********************************************************************
MATERIA: BASES DE DATOS APLICADA
FECHA DE ENTREGA: 11/10/2023
NUMERO DE GRUPO:5
INTEGRANTES:
 -Daniel Corbellini. DNI: 42.875.486
 -Facundo Angel. DNI: 40.640.923
 -Gustavo Rosales. DNI: 43.665.940
 -Kevin Raimo Lugo. DNI: 43.915.535
/********************************************************************/
*/





--CREACION DE TABLAS (REALIZADAS EN LA TERCER ENTREGA)


CREATE TABLE ESPECIALIDAD(
Id_especialidad INT NOT NULL,
Nombre VARCHAR(10),
CONSTRAINT PK_ESPECIALIDAD PRIMARY KEY
(Id_especialidad)
)

CREATE TABLE MEDICO(
Id_medico INT NOT NULL,
Id_espec INT NOT NULL,
Nombre VARCHAR(15),
Apellido VARCHAR(20),
Nro_mat INT,
CONSTRAINT PK_MEDICO PRIMARY KEY
(Id_medico),
CONSTRAINT FK_MED_ESPEC FOREIGN KEY(Id_espec)
REFERENCES Especialidad(Id_especialidad)
)

CREATE TABLE PACIENTE(
ID_Histo_Clinica INT NOT NULL,/*¨No tengo aclaraciones sobre este dato*/
Nombre VARCHAR(20),
Apellido VARCHAR(30),
Apel_materno VARCHAR(30),
Fech_nacimiento DATE,
Tip_Documento VARCHAR(10),
Num_Documento INT,
Sex_Biologico VARCHAR(10),
Genero VARCHAR(10),
Nacionalidad VARCHAR(10),
Fot_perfil VARBINARY(MAX), /*El tipo de dato image no se encuentra disponible para esta versión de SQL*/
/*Varbinary permite almacenar datos en binario con u máximo de 2GB*/
Mail NVARCHAR(35),
Telef_fijo VARCHAR(20),
Tel_alternativo VARCHAR(20),
Tel_laboral VARCHAR(20),
Fech_registro DATE,
Fech_actualiz DATE,
Usuario_act Nvarchar(20),/* Entendemos que se refiera a la actualización de contraseña de usuario. El id de usuario corresponde al DNI del paciente*/
/*Contraints*/
CONSTRAINT PK_PACIENTE PRIMARY KEY(ID_Histo_Clinica)
)

CREATE TABLE PRESTADOR(
	ID IDENTITY(1,1),
	PRESTADOR VARCHAR(40),
	PLAN_PREST VARCHAR(40)
)

CREATE TABLE SEDE(
	ID IDENTITY(1,1)
	,SEDE VARCHAR(40)
	,DIRECCION VARCHAR(40)
	,LOCALIDAD VARCHAR(40)
	,PROVINCIA VARCHAR(40)
)


--============================================================================
--IMPORTACION Y LIMPIEZA DE DATOS DE LA TABLA MEDICOS
--==========================================================================
CREATE TABLE MEDICO_AUX(
	NOMBRE NVARCHAR(40),
	APELLIDO NVARCHAR(40),
	ESPECIALIDAD NVARCHAR(40),
	NUMERO_COLEGIADO INT
);
GO


CREATE TRIGGER LIMPIADOR_INFORMACION_MEDICOS
ON MEDICO_AUX AFTER INSERT 
AS
BEGIN



	DECLARE @CANT INT =(SELECT COUNT(*) FROM inserted);
	DECLARE @I INT = 1;

	WHILE @I <= @CANT
	BEGIN

		DECLARE @NOMBRE_NUEVO NVARCHAR(40);
		DECLARE @ESPECIALIDAD NVARCHAR(40);
		DECLARE @APELLIDO_NUEVO NVARCHAR(40);
		DECLARE @MATRICULA INT;




		WITH REGISTROS_INSERTADOS AS(
			SELECT *
			,ROW_NUMBER() OVER (ORDER BY NUMERO_COLEGIADO) AS NRO
			FROM inserted
		)
		SELECT @NOMBRE_NUEVO=R.APELLIDO
		,@APELLIDO_NUEVO=R.NOMBRE
		,@ESPECIALIDAD=R.ESPECIALIDAD
		,@MATRICULA=R.NUMERO_COLEGIADO
		FROM REGISTROS_INSERTADOS R
		WHERE R.NRO=@I



		--LIMPIEZA APELLIDO
		DECLARE @POS_ESPACIO INT = (CHARINDEX(' ', @APELLIDO_NUEVO));
		IF @POS_ESPACIO <> 0
		BEGIN
			DECLARE @LONG_APELLIDO INT = LEN(@APELLIDO_NUEVO);
			SET @APELLIDO_NUEVO = LOWER(SUBSTRING(@APELLIDO_NUEVO,@POS_ESPACIO,@LONG_APELLIDO));
		END

	
		--LIMPIEZA NOMBRE
		DECLARE @POS_PUNTO INT = CHARINDEX('.',@NOMBRE_NUEVO);
		IF @POS_PUNTO <> 0
			BEGIN
				DECLARE @LONG_NOMBRE INT = LEN(@NOMBRE_NUEVO);
				DECLARE @LONG_MAX INT = @POS_PUNTO-3;
				--PRINT @LONG_MAX;
				SET @NOMBRE_NUEVO = SUBSTRING(@NOMBRE_NUEVO,1,@LONG_MAX);
			END
		SET @NOMBRE_NUEVO=LOWER(@NOMBRE_NUEVO);


		SET @ESPECIALIDAD = LOWER(@ESPECIALIDAD);

	

		UPDATE MEDICO_AUX SET NOMBRE=@NOMBRE_NUEVO, APELLIDO=@APELLIDO_NUEVO, ESPECIALIDAD=@ESPECIALIDAD 
		WHERE NUMERO_COLEGIADO=@MATRICULA

		SET @I=@I+1;
	END
	
END

GO


BULK INSERT MEDICO_AUX
FROM 'C:\Users\facun\OneDrive\Escritorio\cuarta entrega bbdd\Medicos.csv'
WITH(
	FIELDTERMINATOR=';',
	ROWTERMINATOR='\n',
	KEEPIDENTITY,
	FIRSTROW = 2,
	FIRE_TRIGGERS,
	CODEPAGE = '65001'
)
GO

--======================================================================

--IMPORTACION Y LIMPIEZA DE DATOS DE LA TABLA PACIENTES

--======================================================================


CREATE TABLE PACIENTE_AUX(
	NOMBRE NVARCHAR(40),
	APELLIDO NVARCHAR(40),
	FECHA_NAC DATE,
	TIPO_DNI CHAR(3),
	NRO_DOC INT PRIMARY KEY,
	SEXO CHAR(9),
	GENERO VARCHAR(6),
	TELEFONO CHAR(14),
	NACIONALIDAD VARCHAR(40),
	MAIL VARCHAR(40),
	DIRECCION VARCHAR(60),
	LOCALIDAD VARCHAR(60),
	PROVINCIA VARCHAR(60)
);
GO


CREATE TRIGGER LIMPIADOR_INFORMACION_PACIENTES
ON PACIENTE_AUX AFTER INSERT 
AS
BEGIN



	DECLARE @CANT INT =(SELECT COUNT(*) FROM inserted);
	DECLARE @I INT = 1;

	WHILE @I <= @CANT
	BEGIN

			DECLARE	@FECHA_NAC DATE,
			@SEXO CHAR(9),
			@DIRECCION VARCHAR(40),
			@LOCALIDAD VARCHAR(40),
			@PROVINCIA VARCHAR(40),
			@NRO_DOC INT;


		WITH REGISTROS_INSERTADOS AS(
			SELECT *
			,ROW_NUMBER() OVER (ORDER BY NRO_DOC) AS NRO_REG
			FROM inserted
		)
		SELECT @FECHA_NAC=convert(datetime,R.FECHA_NAC, 103),
		@SEXO=LOWER(R.SEXO),
		@DIRECCION=LOWER(R.DIRECCION),
		@LOCALIDAD=LOWER(R.LOCALIDAD),
		@PROVINCIA=LOWER(R.PROVINCIA),
		@NRO_DOC=R.NRO_DOC
		FROM REGISTROS_INSERTADOS R
		WHERE R.NRO_REG=@I


		UPDATE PACIENTE_AUX SET FECHA_NAC=@FECHA_NAC,
		SEXO = @SEXO,
		DIRECCION = @DIRECCION,
		LOCALIDAD = @LOCALIDAD,
		PROVINCIA = @PROVINCIA
		WHERE NRO_DOC=@NRO_DOC
		
		SET @I=@I+1;
	END
	
END

GO


BULK INSERT PACIENTE_AUX
FROM 'C:\Users\facun\OneDrive\Escritorio\cuarta entrega bbdd\Pacientes.csv'
WITH(
	FIELDTERMINATOR=';',
	ROWTERMINATOR='\n',
	KEEPIDENTITY,
	FIRSTROW = 2,
	FIRE_TRIGGERS,
	CODEPAGE = '65001'
)
GO

--======================================================================

--IMPORTACION Y LIMPIEZA DE DATOS DE LA TABLA PRESTADOR

--======================================================================



CREATE TABLE PRESTADOR_AUX(
	PRESTADOR VARCHAR(40),
	PLAN_PREST VARCHAR(40)
)
GO


CREATE TRIGGER IMPORTADO_PRESTADOR
ON PRESTADOR_AUX AFTER INSERT 
AS
BEGIN



	DECLARE @CANT INT =(SELECT COUNT(*) FROM inserted);
	DECLARE @I INT = 1;

	WHILE @I <= @CANT
	BEGIN

			DECLARE @PRESTADOR VARCHAR(40),
			@PLAN_PREST VARCHAR(40);


		WITH REGISTROS_INSERTADOS AS(
			SELECT *
			,ROW_NUMBER() OVER (ORDER BY PRESTADOR) AS NRO_REG
			FROM inserted
		)
		SELECT @PRESTADOR=R.PRESTADOR,
		@PLAN_PREST=REPLACE(R.PLAN_PREST,';','')
		FROM REGISTROS_INSERTADOS R
		WHERE R.NRO_REG=@I


		--INSERT INTO PRESTADOR VALUES (@PRESTADOR,@PLAN_PREST);
		
		SET @I=@I+1;
	END
	
END

GO

BULK INSERT PRESTADOR_AUX
FROM 'C:\Users\facun\OneDrive\Escritorio\cuarta entrega bbdd\Prestador.csv'
WITH(
	FIELDTERMINATOR=';',
	FIRE_TRIGGERS,
	ROWTERMINATOR='\n',
	FIRSTROW = 2,
	CODEPAGE = '65001'
)
GO

--======================================================================

--IMPORTACION Y LIMPIEZA DE DATOS DE LA TABLA SEDES

--======================================================================
CREATE TABLE SEDE_AUX(
	SEDE VARCHAR(40)
	,DIRECCION VARCHAR(40)
	,LOCALIDAD VARCHAR(40)
	,PROVINCIA VARCHAR(40)
)
GO

CREATE TRIGGER IMPORTADO_SEDES
ON SEDE AFTER INSERT 
AS
BEGIN



	DECLARE @CANT INT =(SELECT COUNT(*) FROM inserted);
	DECLARE @I INT = 1;

	WHILE @I <= @CANT
	BEGIN

			DECLARE @SEDE VARCHAR(40)
			,@DIRECCION VARCHAR(40)
			,@LOCALIDAD VARCHAR(40)
			,@PROVINCIA VARCHAR(40);
			/*

		WITH REGISTROS_INSERTADOS AS(
			SELECT *
			,ROW_NUMBER() OVER (ORDER BY PRESTADOR) AS NRO_REG
			FROM inserted
		)
		SELECT @PRESTADOR=R.PRESTADOR,
		@PLAN_PREST=REPLACE(R.PLAN_PREST,';','')
		FROM REGISTROS_INSERTADOS R
		WHERE R.NRO_REG=@I


		INSERT INTO PRESTADOR VALUES (@PRESTADOR,@PLAN_PREST);*/
		
		SET @I=@I+1;
	END
	
END

GO

BULK INSERT SEDE
FROM 'C:\Users\facun\OneDrive\Escritorio\cuarta entrega bbdd\Sedes.csv'
WITH(
	FIELDTERMINATOR=';',
	FIRE_TRIGGERS,
	ROWTERMINATOR='\n',
	FIRSTROW = 2,
	CODEPAGE = '65001'
)
GO

/* Adicionalmente se requiere que el sistema sea capaz de generar un archivo XML detallando los
	* turnos atendidos para informar a la Obra Social. El mismo debe constar de los datos del paciente
	* (Apellido, nombre, DNI), nombre y matrícula del profesional que lo atendió, fecha, hora,
	* especialidad. Los parámetros de entrada son el nombrede la obra social y un intervalo de fechas.
	*/
 CREATE OR ALTER PROCEDURE EXPORTAR_TURNOS_A_XML @FechaInicio date, @FechaFin date, @NombrePrestador VARCHAR(20) AS
	EXEC master.dbo.sp_configure 'show advanced options', 1
	RECONFIGURE
	EXEC master.dbo.sp_configure 'xp_cmdshell', 1
	RECONFIGURE;

	DROP TABLE IF EXISTS ##DatosTurno;

	SELECT 
		PC.Nombre AS Nombre_Paciente, 
		PC.Apellido AS Apellido_Paciente, 
		PC.Num_Documento AS DNI_Paciente,
		MD.Nombre AS Nombre_Medico, 
		MD.Apellido AS Apellido_Medico, 
		MD.Nro_mat AS Matricula, 
		ES.Nombre AS Especialidad,
		RT.Fecha,
		RT.Hora
	INTO ##DatosTurno
	FROM 
		Reserva_turno RT 
		JOIN paciente PC ON RT.Id_hist_clinica = PC.ID_Histo_Clinica 
		JOIN cobertura CB ON RT.Id_hist_clinica = CB.Id_hist_clin 
		JOIN Prestador PR ON CB.Id_cobertura = PR.Id_cober 
		JOIN Estado_turno ET ON RT.id_est_turno = ET.id_estado 
		JOIN Dias_x_sede DS ON RT.Id_diasSede = DS.Id_sede 
		JOIN Medico MD ON MD.Id_medico = DS.Id_medico 
		JOIN Especialidad ES ON MD.Id_espec = ES.id_especialidad 
	WHERE 
		ET.nombre = 'Atendido'
		AND RT.Fecha BETWEEN @FechaInicio AND @FechaFin
		AND PR.nombre = @NombrePrestador
	
	EXEC xp_cmdshell 'BCP "SELECT * FROM ##DatosTurno FOR XML PATH(''Turno'')" QUERYOUT "C:\export_turnos.xml" -e "C:/error_export.txt" -T -c -t,';
GO

EXEC EXPORTAR_TURNOS_A_XML
	 @FechaInicio = '2020-02-20',
	 @FechaFin = '2024-02-20',
	 @NombrePrestador  = 'Prestador A';