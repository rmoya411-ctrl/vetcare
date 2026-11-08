
-- PROYECTO: VETCARE - CLÍNICA HUELLITAS
-- AVANCE 2: 50% DEL CÓDIGO PL/SQL
-- PARTE 1: CREACIÓN DE LAS TABLAS (Estructura)

-- Tabla de Dueños
CREATE TABLE Dueno (
    IdDueno NUMBER PRIMARY KEY,
    Nombre VARCHAR2(100),
    Apellido VARCHAR2(100),
    Telefono VARCHAR2(20),
    Correo VARCHAR2(100),
    Direccion VARCHAR2(200)
);

-- Tabla de Mascotas (Relacionada con Dueño)
CREATE TABLE Mascota (
    IdMascota NUMBER PRIMARY KEY,
    IdDueno NUMBER,
    Nombre VARCHAR2(100),
    Especie VARCHAR2(50),
    Raza VARCHAR2(50),
    FechaNacimiento DATE,
    Peso NUMBER(5,2),
    CONSTRAINT fk_mascota_dueno FOREIGN KEY (IdDueno) REFERENCES Dueno(IdDueno)
);

-- Tabla de Veterinarios
CREATE TABLE Veterinario (
    IdVeterinario NUMBER PRIMARY KEY,
    Nombre VARCHAR2(100),
    Apellido VARCHAR2(100),
    Especialidad VARCHAR2(100),
    Telefono VARCHAR2(20),
    Correo VARCHAR2(100)
);

-- Tabla de Citas (Relacionada con Mascota y Veterinario)
CREATE TABLE Cita (
    IdCita NUMBER PRIMARY KEY,
    IdMascota NUMBER,
    IdVeterinario NUMBER,
    FechaHora TIMESTAMP,
    Motivo VARCHAR2(200),
    Estado VARCHAR2(50),
    CONSTRAINT fk_cita_mascota FOREIGN KEY (IdMascota) REFERENCES Mascota(IdMascota),
    CONSTRAINT fk_cita_veterinario FOREIGN KEY (IdVeterinario) REFERENCES Veterinario(IdVeterinario)
);

-- Tabla de Tratamientos (Relacionada con Cita)
CREATE TABLE Tratamiento (
    IdTratamiento NUMBER PRIMARY KEY,
    IdCita NUMBER,
    Descripcion VARCHAR2(200),
    FechaInicio DATE,
    FechaFin DATE,
    Observaciones VARCHAR2(300),
    CONSTRAINT fk_tratamiento_cita FOREIGN KEY (IdCita) REFERENCES Cita(IdCita)
);

-- Tabla de Medicamentos
CREATE TABLE Medicamento (
    IdMedicamento NUMBER PRIMARY KEY,
    Nombre VARCHAR2(100),
    Descripcion VARCHAR2(200),
    Stock NUMBER,
    Precio NUMBER(10,2),
    FechaVencimiento DATE
);

-- Tabla Intermedia (Tratamiento - Medicamento)
CREATE TABLE TratamientoMedicamento (
    IdTratamiento NUMBER,
    IdMedicamento NUMBER,
    Dosis VARCHAR2(50),
    Frecuencia VARCHAR2(50),
    CONSTRAINT pk_trat_med PRIMARY KEY (IdTratamiento, IdMedicamento),
    CONSTRAINT fk_tm_tratamiento FOREIGN KEY (IdTratamiento) REFERENCES Tratamiento(IdTratamiento),
    CONSTRAINT fk_tm_medicamento FOREIGN KEY (IdMedicamento) REFERENCES Medicamento(IdMedicamento)
);

-- PARTE 2: INSERTAR DATOS DE PRUEBA
INSERT INTO Dueno VALUES (1, 'Juan', 'Perez', '8888-1111', 'juan@email.com', 'San Jose');
INSERT INTO Dueno VALUES (2, 'Maria', 'Lopez', '8888-2222', 'maria@email.com', 'Alajuela');

INSERT INTO Mascota VALUES (1, 1, 'Firulais', 'Perro', 'Labrador', TO_DATE('2018-05-10', 'YYYY-MM-DD'), 25.5);
INSERT INTO Mascota VALUES (2, 2, 'Michi', 'Gato', 'Siames', TO_DATE('2020-08-15', 'YYYY-MM-DD'), 4.2);

INSERT INTO Veterinario VALUES (1, 'Carlos', 'Mora', 'Cirugia', '8888-3333', 'carlos@vet.com');
INSERT INTO Veterinario VALUES (2, 'Ana', 'Rojas', 'Dermatologia', '8888-4444', 'ana@vet.com');

INSERT INTO Medicamento VALUES (1, 'Amoxicilina', 'Antibiotico', 50, 5000, TO_DATE('2027-12-31', 'YYYY-MM-DD'));
INSERT INTO Medicamento VALUES (2, 'Antipulgas', 'Tratamiento externo', 5, 8000, TO_DATE('2026-10-31', 'YYYY-MM-DD'));

INSERT INTO Cita VALUES (1, 1, 1, SYSTIMESTAMP, 'Revision general', 'Completada');
INSERT INTO Cita VALUES (2, 2, 2, SYSTIMESTAMP, 'Problema de piel', 'Programada');

COMMIT;


-- PARTE 3: PROGRAMACIÓN PL/SQL

-- 1. FUNCIÓN: Calcula la edad de la mascota
CREATE OR REPLACE FUNCTION fn_edad_mascota (p_id_mascota NUMBER) 
RETURN NUMBER IS
    v_edad NUMBER;
BEGIN
    SELECT TRUNC(MONTHS_BETWEEN(SYSDATE, FechaNacimiento) / 12) 
    INTO v_edad
    FROM Mascota WHERE IdMascota = p_id_mascota;
    RETURN v_edad;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN NULL;
END;
/

-- 2. PROCEDIMIENTO: Inserta un nuevo dueño
CREATE OR REPLACE PROCEDURE sp_insertar_dueno (
    p_id NUMBER, p_nombre VARCHAR2, p_apellido VARCHAR2, p_tel VARCHAR2, p_correo VARCHAR2, p_dir VARCHAR2
) IS
BEGIN
    INSERT INTO Dueno VALUES (p_id, p_nombre, p_apellido, p_tel, p_correo, p_dir);
    COMMIT;
END;
/

-- 3. VISTA: Muestra las citas con datos de mascota y veterinario
CREATE OR REPLACE VIEW vw_citas_completas AS
SELECT c.IdCita, m.Nombre AS Mascota, v.Nombre AS Veterinario, c.FechaHora, c.Motivo, c.Estado
FROM Cita c
JOIN Mascota m ON c.IdMascota = m.IdMascota
JOIN Veterinario v ON c.IdVeterinario = v.IdVeterinario;
/

-- 4. TRIGGER: Descuenta stock al asignar un medicamento
CREATE OR REPLACE TRIGGER trg_descontar_stock
AFTER INSERT ON TratamientoMedicamento
FOR EACH ROW
BEGIN
    UPDATE Medicamento
    SET Stock = Stock - 1
    WHERE IdMedicamento = :NEW.IdMedicamento;
END;
/

-- 5. PAQUETE (Cabecera y Cuerpo)
CREATE OR REPLACE PACKAGE pkg_veterinaria AS
    PROCEDURE registrar_cita (p_id NUMBER, p_mascota NUMBER, p_vet NUMBER, p_fecha TIMESTAMP, p_motivo VARCHAR2);
END pkg_veterinaria;
/

CREATE OR REPLACE PACKAGE BODY pkg_veterinaria AS
    PROCEDURE registrar_cita (p_id NUMBER, p_mascota NUMBER, p_vet NUMBER, p_fecha TIMESTAMP, p_motivo VARCHAR2) IS
    BEGIN
        INSERT INTO Cita VALUES (p_id, p_mascota, p_vet, p_fecha, p_motivo, 'Programada');
        COMMIT;
    END;
END pkg_veterinaria;
/

-- 6. CURSOR: Recorre las mascotas y muestra su edad calculada
SET SERVEROUTPUT ON;
DECLARE
    CURSOR c_mascotas IS 
        SELECT Nombre, FechaNacimiento FROM Mascota;
    v_nombre Mascota.Nombre%TYPE;
    v_fecha Mascota.FechaNacimiento%TYPE;
    v_edad NUMBER;
BEGIN
    OPEN c_mascotas;
    LOOP
        FETCH c_mascotas INTO v_nombre, v_fecha;
        EXIT WHEN c_mascotas%NOTFOUND;
        
        v_edad := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha) / 12);
        DBMS_OUTPUT.PUT_LINE('Mascota: ' || v_nombre || ' - Edad: ' || v_edad || ' años');
    END LOOP;
    CLOSE c_mascotas;
END;
/