# Estructura del proyecto
Esta aplicación consta de dos módulos: `backend` escrito en `PHP` y `Laravel` que se puede encontrar en la carpeta `backend`; y `frontend` escrito con `Angular` y que se puede encontrar en la carpeta `frontend`.

## Repositorios
La carpeta raíz, donde se encuentra este fichero, es un repositorio de Git con dos módulos que se corresponde con las dos partes indicadas: `backend` y `frontend`. Cada una de estas partes es como si de un repositorior aíslado se tratara y así hay que trabajar. No obstante hay que tener presente los siguientes puntos cada vez que se quiera *commitear* cambios en alguna de las dos partes:

1. Se prepara el *commit* en el repositorio concreto.
2. Se hace el *push* en el repositorio concreto.
3. Se prepara el *commit* en el repositorio principal añadiendo como cambio `frontend` o `backend`, según el caso.

## Docker
Este proyecto está *dockerizado*. No tienes más que ver el fichero `docker-compose.yml` para ver los contenedores que hay.

# Backend
Es un proyecto de `Laravel` estándar, así que para poner en marcha este proyecto solo tienes que ejecutar (en el contenedor correspondiente) los pasos que se indican en la documentación oficial.

## Puesta en marcha: resumen
Aquí tienes una simplificación de los pasos a dar tras hacer un `git clone` del proyecto:

1. Genera el fichero .env. Lo más fácil sería copiar el fichero de ejemplo que debería estar en la raíz de tu proyecto:

```shell
$ cp .env.example .env
```

2. Instala las dependencias de PHP (creará la carpeta vendor y lo meterá ahí todo):

```shell
$ composer install
```

3. Instala las dependencias de JavaScript (creará la carpeta node_modules y lo meterá ahí todo):

```shell
$ npm install
```

4. Genera la clave de tu proyecto (APP_KEY):

```shell
$ php artisan key:generate
```

## Trabajando con el backend desde los contenedores
Aquí dejo algunos comandos que se usan recurrentemente en el entorno de desarrollo y que sirven, además, para ilustrar la dinámica de trabajo desde los contenedores:

Si quieres ejecutar las migraciones insertando los datos de prueba en la base de datos, este es el comando a ejecutar:

```shell
docker compose exec bl-app php artisan migrate:fresh --seed
```

Si no quieres llenar la base de datos con datos de prueba y la quieres vacía, no añadas las opción `--seed`.

O para lanzar los tests (**no lances los tests en producción**):

```shell
$ docker compose exec bl-app php artisan test --env=testing
```

Si quieres acceder ala base de datos MariaDB:

```shell
$ docker compose exec bl-mariadb mariadb -ubancolibros -pbancolibros bancolibros
```

También puedes acceder a la base de datos desde el contenedor de `Adminer`.

## Exportar/Importar base de datos
En principio, para exportar/importar la base de datos bastaría con copiar la carpeta `backend/bl-mariadbdata/`. No obstante, cuando lo hago en el entorno de desarrollo:

1. Veo que están todos los datos de la base de datos.
2. Me da el típico error CORS que me impide acceder a la aplicación desde el `frontend`.

La solución que encontré es la siguiente:

1. Copio y pego la carpeta de datos de MariaDB indicada arriba (fija los permisos, en mi caso hacía: `sudo chown -R 999:adm <carpeta de mariadb data>`).
2. Levanto los contenedores.
3. Uso un contenedor de `Adminer` para acceder a la base de datos (servidor: bl-mariadb; usuario: bancolibros; password: bancolibros; base de datos: bancolibros). Dicho contenedor lo añado en el `docker-compose.yml`:

```yaml
adminer:
    image: adminer
    restart: always
    ports:
      - 9090:8080
    networks:
      - bl-network
```

4. Desde `Adminer` borro todos los registros de las tablas: `users`, `migrations`.
5. Exporto a `.sql` la base de datos.
6. Ejecuto el `docker compose exec bl-app php artisan migrate:fresh` para partir de la base de datos vacía.
7. Entro de nuevo al `Adminer`.
8. Importo el back `.sql`.

## Crear migración y ejecutarla

Por ejemplo, imagina que quieres crear una migración para crear dos campos nuevos en la tabla `lendings`. Primero hay que crear el fichero de migración:

```shell
$ docker compose exec bl-app php artisan make:migration add_comments_lendings_table --table=lendings
```

Se añade el código correspondiente en la nueva migración creada en la carpeta `database/migrations`:

```php
public function up(): void
{
    Schema::table('lendings', function (Blueprint $table) {
        $table->text('lending_comment')->nullable();
       $table->text('returned_comment')->nullable();
    });
}

public function down(): void
{
    Schema::table('lendings', function (Blueprint $table) {
        $table->dropColumn('lending_comment');
        $table->dropColumn('returned_comment');
    });
}
```

Una vez creada la migración se puede ejecutar para hacer los cambios en la base de datos:

```shell
$ docker compose exec bl-app php artisan migrate
```

> Todos estos comandos se ejecutan en el contenedor, de ahí que los comandos `php artisan` se hagan desde `docker compose`.

## Ver/Generar logs
Si quieres "escribir" logs en el sistema usa el siguiente `Facade` de Laravel:

```php
use Illuminate\Support\Facades\Log;
```

Y úsalo. Por ejemplo: `Log::error("Esto es un ejemplo");`.

Estos logs se escriben en la carpeta `storage/logs` de Laravel y, por tanto, tendrás que entrar al contenedor `bl-app` y acceder a esa carpeta para ver dichos logs:

```shell
<tu-maquina>$ docker-compose exec bl-app bash
<contenedor>$ cd storage/logs
<contenedor>$ tail -f laravel.log
```

> Suponemos, en el ejemplo de arriba, que el fichero con los logs se llama `laravel.log`. Comprueba primero el nombre del fichero de logs.

# Frontend
Es un proyecto estándar de `Angular` y, por tanto, para ponerlo en marcha para el entorno de desarrollo bastaría con llevar a cabo los pasos de la documentación oficial.

En el entorno de desarrollo bastaría con ejecutar dentro de la carpeta `frontend` el siguiente comando para probarlo:

```shell
$ npm run ng serve
```

Aunque luego se indica en despliegue, cuando se despliega la aplicación, si hay cambios en el `frontend` tienes que ejecutar este comando de `Docker` para reconstruirlo:

```shell
$ docker compose up -d --no-deps --build bl-frontend
```

# Despliegue
## La primera vez: puesta en marcha
TODO: esta parte de la documentación está pendiente

## Cuando se han hecho cambios: nueva versión
En el servidor de producción hay que clonar el código y seguir estos pasos:

1. Para los contenedores: `docker compose stop`
2. Desde el proyecto raíz: `git pull origin main`
3. Desde cada uno de los módulos (`backend` y `frontend`): `git pull origin main`
4. Arranca los contenedores: `docker compose up -d`
4. Asegúrate que en el `frontend`, en el fichero `src/app/constants.ts` se ha puesto el valor `http://172.19.188.251:4200` a la variable `API_URL`.
5. Desde el `frontend`: `docker compose up -d --no-deps --build bl-frontend`

## Backup de la base de datos
Antes de nada para los contenedores: `docker compose stop`.

Simplemente copia/pega la carpeta `backend/bl-mariadbdata/` a algún lugar.

## Restaurar backup de la base de datos
Antes de nada para los contenedores: `docker compose stop`.

Simplemente copia/pega la carpeta a `backend/b-mariadbdata/`.
