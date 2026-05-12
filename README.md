# TechSolutions Manager

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Firebase Hosting](https://img.shields.io/badge/Firebase-Hosting-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Available-222222?logo=github&logoColor=white)](https://pages.github.com/)

Sistema de gestion de clientes, proyectos y tareas desarrollado con **Flutter** y **Supabase**, con enfoque empresarial, control de roles y una experiencia responsive para **web** y **movil**.

## Enlaces Rapidos

- Demo Web: https://techsolutions-manager-ma-92b26.web.app
- Repositorio: https://github.com/mateocuzkc/techsolutions_manager

## Descripcion

**TechSolutions Manager** es una aplicacion orientada a la gestion operativa de equipos y relaciones con clientes. Permite administrar informacion clave del negocio en un solo entorno: clientes, proyectos, tareas, responsables, avances y reportes.

El sistema fue construido para ofrecer:

- una experiencia moderna y clara en Flutter
- autenticacion real con Supabase Auth
- gestion por roles con diferentes niveles de acceso
- sincronizacion de datos en tiempo real con backend serverless
- soporte para uso responsivo en navegador y dispositivos moviles

## Tecnologias

| Tecnologia | Uso principal |
| --- | --- |
| Flutter | Desarrollo del frontend web y movil |
| Dart | Lenguaje principal del proyecto |
| Supabase | Backend, base de datos, autenticacion y API |
| Firebase Hosting | Publicacion de la version web |
| GitHub Pages | Presencia y documentacion del proyecto |

## Arquitectura

```text
Frontend  -> Flutter
Backend   -> Supabase
Hosting   -> Firebase Hosting
```

### Frontend

- Flutter para interfaz web y movil
- UI moderna, responsive y orientada a productividad

### Backend

- Supabase como plataforma backend
- PostgreSQL como base de datos
- Supabase Auth para login y sesiones

### Hosting

- Firebase Hosting para la demo web publica

## Funcionalidades

- Gestion de clientes
- Gestion de proyectos
- Gestion de tareas
- Roles y permisos por tipo de usuario
- Login real con Supabase Auth
- Reasignacion de responsables
- Reportes PDF
- Dashboard dinamico
- Buscadores en tiempo real
- Responsive Web/Movil
- Avance automatico de tareas
- Finalizacion automatica de proyectos

## Roles del Sistema

### Admin

- Gestion completa del sistema
- Administracion de clientes, proyectos y tareas
- Acceso a reportes globales
- Reasignacion de responsables

### Usuario

- Gestion de registros asignados
- Acceso a clientes, proyectos y tareas segun permisos
- Uso de reportes filtrados por responsable

### Cliente

- Visualizacion controlada de informacion relacionada a su cuenta
- Acceso a proyectos y tareas de su cliente

## Instalacion

### 1. Clonar el repositorio

```bash
git clone https://github.com/mateocuzkc/techsolutions_manager.git
cd techsolutions_manager
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar variables de entorno

Crea un archivo `.env` en la raiz del proyecto:

```env
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_SUPABASE_ANON_KEY
```

### 4. Verificar carga de assets en `pubspec.yaml`

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

### 5. Ejecutar la aplicacion

```bash
flutter run -d chrome
```

Si deseas ejecutar en movil:

```bash
flutter run
```

## Demo Web

La version desplegada del sistema esta disponible en:

**https://techsolutions-manager-ma-92b26.web.app**

## Capturas

Puedes reemplazar estos placeholders por imagenes reales del proyecto cuando lo desees:

```md
![Login](docs/screenshots/login.png)
![Dashboard](docs/screenshots/dashboard.png)
![Clientes](docs/screenshots/clientes.png)
![Proyectos](docs/screenshots/proyectos.png)
![Tareas](docs/screenshots/tareas.png)
```

Sugerencia de secciones visuales para GitHub:

- Pantalla de login
- Dashboard principal
- Modulo de clientes
- Modulo de proyectos
- Modulo de tareas
- Reportes PDF

## Autor

**Mateo Augusto Cuz Kuckling Catalan**

- GitHub: https://github.com/mateocuzkc
- Repositorio del proyecto: https://github.com/mateocuzkc/techsolutions_manager

---

TechSolutions Manager fue desarrollado como una solucion de gestion moderna, escalable y profesional, enfocada en organizar clientes, proyectos y tareas dentro de un solo ecosistema.
