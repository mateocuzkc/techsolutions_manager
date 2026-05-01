# techsolutions_manager

# 🚀 TechSolutions Manager

Sistema empresarial desarrollado en **Flutter + Supabase** para la gestión de clientes, con arquitectura moderna, segura y escalable.

---

## 📌 Descripción del Proyecto

TechSolutions Manager es una aplicación full-stack que permite:

* Autenticación de usuarios
* Gestión de clientes (CRUD completo)
* Interfaz moderna y responsiva
* Conexión a base de datos en la nube (Supabase)
* Diferenciación entre aplicación web y móvil

El sistema está diseñado bajo un enfoque empresarial, separando la administración del uso operativo.

---

## 🧱 Tecnologías Utilizadas

### Frontend

* Flutter (Web & Mobile)
* Material Design

### Backend / Base de Datos

* Supabase

  * PostgreSQL
  * Autenticación (JWT)
  * API automática

### Paquetes Flutter

* supabase_flutter
* flutter_dotenv
* go_router
* provider
* intl
* intl_phone_field

---

## ⚙️ Requisitos Previos

* Flutter SDK instalado
* Visual Studio Code
* Cuenta en Supabase
* Navegador Chrome

---

## 🔧 Instalación del Proyecto

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd techsolutions_manager
```

---

### 2. Instalar dependencias

```bash
flutter pub get
```

---

### 3. Crear archivo `.env`

En la raíz del proyecto:

```
.env
```

Contenido:

```env
SUPABASE_URL=https://TU_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=TU_PUBLIC_KEY
```

---

### 4. Configurar `pubspec.yaml`

Asegúrate de tener:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

---

### 5. Ejecutar la aplicación

```bash
flutter run -d chrome
```

---

## 🗄️ Base de Datos (Supabase)

Ejecutar en el **SQL Editor**:

```sql
create table if not exists public.clientes (
  id bigint generated always as identity primary key,
  nombre text not null,
  correo text,
  telefono text,
  empresa text,
  estado text default 'Activo',
  created_at timestamp with time zone default now()
);

alter table public.clientes enable row level security;

create policy "Permitir lectura"
on public.clientes
for select
to authenticated
using (true);

create policy "Permitir inserción"
on public.clientes
for insert
to authenticated
with check (true);

create policy "Permitir actualización"
on public.clientes
for update
to authenticated
using (true);

create policy "Permitir eliminación"
on public.clientes
for delete
to authenticated
using (true);
```

---

## 🔐 Autenticación

El sistema utiliza Supabase Auth:

* Registro de usuarios (solo web)
* Inicio de sesión con correo y contraseña
* Sesión persistente
* Cierre de sesión (logout)

---

## 👥 Gestión de Usuarios y Roles

### 👑 Administrador

* Accede desde la web
* Puede:

  * Crear usuarios
  * Editar usuarios
  * Eliminar usuarios
  * Bloquear cuentas
  * Administrar el sistema

### 👤 Usuario

* Accede desde web y móvil
* Puede:

  * Iniciar sesión
  * Usar el sistema (clientes, proyectos, tareas)
* ❌ No puede administrar usuarios

---

## 🌐📱 Diferenciación Web vs Móvil

### 🌐 Aplicación Web

* Registro de usuarios
* Administración de usuarios
* Acceso completo al sistema

### 📱 Aplicación Móvil

* Inicio de sesión
* Uso del sistema
* ❌ Sin registro
* ❌ Sin administración

---

## 🧠 Implementación Técnica

Se utiliza detección de plataforma:

```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Mostrar registro y administración
} else {
  // Ocultar opciones
}
```

---

## 📂 Estructura del Proyecto

```
lib/
 ├── main.dart
 ├── screens/
 │    ├── auth/
 │    │    └── login_screen.dart
 │    ├── dashboard/
 │    │    └── dashboard_screen.dart
 │    └── clientes/
 │         └── clientes_screen.dart
```

---

## 👤 Módulo de Clientes

### Funcionalidades

* Crear cliente
* Listar clientes
* Editar cliente
* Eliminar cliente
* Estado (Activo / Inactivo)
* Visualización con indicador (verde / rojo)
* Teléfono internacional con banderita 🌎
* Código automático (ID)

---

## 🎯 Flujo del Sistema

1. Usuario inicia sesión
2. Accede al dashboard
3. Ingresa al módulo de clientes
4. Gestiona información en tiempo real

---

## 🔒 Seguridad

* Autenticación con JWT
* Row Level Security (RLS)
* Acceso restringido a usuarios autenticados
* Control de roles

---

## 🌍 Arquitectura

* Flutter → Cliente (Web y Mobile)
* Supabase → Backend serverless
* PostgreSQL → Base de datos en la nube

---

## 🚧 Próximas Funcionalidades

* 📁 Gestión de proyectos
* 📋 Gestión de tareas
* 👑 Roles completos (admin / usuario)
* 🎨 Mejoras UI/UX
* 🌐 Deploy en la nube

---

## 🎯 Estado del Proyecto

🟢 Autenticación completa
🟢 CRUD de clientes completo
🟢 UI funcional
🟡 En desarrollo: módulos avanzados

---

## 👨‍💻 Autor

Proyecto desarrollado con enfoque educativo y empresarial.

---
