import oracledb

# Datos de conexión a Oracle
DB_USER = "system"         
DB_PASSWORD = "Loquendo1" 
DB_DSN = "localhost:1521/XEPDB1" 

def probar_conexion():
    try:
        print("Conectando a la base de datos Oracle...")
        # Crear la conexión
        connection = oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
        print("¡Conexión exitosa a VetCare!\n")

        # Ejecutar consulta usando la vista que creaste
        cursor = connection.cursor()
        cursor.execute("SELECT * FROM vw_citas_completas")
        
        # Mostrar resultados
        resultados = cursor.fetchall()
        print("--- Reporte de Citas ---")
        for fila in resultados:
            print(f"Cita: {fila[0]} | Mascota: {fila[1]} | Vet: {fila[2]} | Estado: {fila[5]}")
            
    except oracledb.Error as e:
        print(f"Error en la conexión: {e}")
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'connection' in locals():
            connection.close()
            print("\nConexión cerrada correctamente.")

if __name__ == "__main__":
    probar_conexion()