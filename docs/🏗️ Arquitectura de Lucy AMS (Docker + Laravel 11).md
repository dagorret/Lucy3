# 🏗️ Arquitectura de Lucy AMS (Docker + Laravel 11)

## 1. El Concepto: Separación de Poderes

A diferencia de un entorno simple (como XAMPP), aquí cada servicio vive en su propia celda (contenedor). Esto garantiza que si actualizamos PHP, la base de datos no se entere, y viceversa.

### Los 4 Pilares:

1. **`lucy-web` (Nginx):** El "Portero". Recibe las peticiones HTTP (puerto 8084) y decide qué es una imagen (la sirve él) y qué es código PHP (se lo pasa al siguiente).

2. **`lucy-app` (PHP 8.4-FPM):** El "Cerebro". Aquí vive Laravel. Procesa la lógica y se comunica con la DB.

3. **`lucy-db` (MariaDB 10.11):** El "Archivo". Guarda los datos de alumnos, legajos y notas.

4. **`lucy-redis` (Redis):** La "Memoria de corto plazo". Guarda sesiones y caché para que Lucy vuele.

---

## 2. Diferencias: Desarrollo vs. Producción

Esta es la clave de por qué usamos archivos `.yml` y `.override.yml`.

| Característica   | En Desarrollo (Tu Inspiron)                                                                 | En Producción (Servidor Real)                                                                 |
| ---------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| **Volúmenes**    | **Mapeo en vivo:** Cambias un archivo en VS Code y se refleja al instante en el contenedor. | **Inyección de código:** El código se "copia" dentro de la imagen. Es inmutable y más rápido. |
| **Nginx**        | Expone el puerto **8084** para no chocar con otros proyectos.                               | Expone el puerto **80** (o 443 con SSL).                                                      |
| **Permisos**     | Sincronizados con tu **User ID 1000** para que puedas editar archivos.                      | El dueño suele ser el usuario `www-data` de forma estricta.                                   |
| **Herramientas** | Mailpit y phpMyAdmin activos para diagnosticar.                                             | Estas herramientas se apagan por seguridad.                                                   |

Exportar a Hojas de cálculo

---

## 3. Guía de Uso Diario (Workflows)

### A. Para empezar a trabajar:

Bash

```
docker compose up -d
```

*Si algo cambió en el Dockerfile:* `docker compose up -d --build`

### B. Para instalar paquetes (Composer/NPM):

No uses el Composer de tu máquina, usa el del contenedor para que la versión de PHP coincida:

Bash

```
docker exec -it lucy-app composer install
docker exec -it lucy-app npm install && npm run dev
```

### C. Para limpiar la "casa" (Cuando algo raro pasa):

Bash

```
# Limpia el caché de Laravel que a veces miente
docker exec -it lucy-app php artisan optimize:clear
```

---

## 4. El "Machete" de Permisos (Vital)

En Linux, los archivos tienen tres niveles de permisos: **Dueño (rwx) - Grupo (rwx) - Otros (rwx)**.

- **Tu configuración:** Usamos el `USER_ID=1000`. Esto hace que el usuario `laravel` dentro del contenedor sea "hermano gemelo" de tu usuario `carlos` en la Inspiron.

- **Si algo falla (403 Forbidden o 500):**
  
  1. Ver permisos: `ls -la`
  
  2. Resetear dueño: `docker exec -it --user root lucy-app chown -R 1000:1000 /var/www`
  
  3. Dar permisos a storage: `docker exec -it --user root lucy-app chmod -R 775 storage`

---

## 5. El Flujo de Despliegue (Roadmap)

1. **Commit:** Guardas tus cambios en Git.

2. **CI/CD:** El servidor descarga el código.

3. **Build:** Se crea una imagen Docker de Lucy que ya trae el código adentro.

4. **Migrate:** Se ejecutan las migraciones de base de datos automáticamente.

5. **Live:** El tráfico se swapea a la nueva versión sin caída de servicio.
