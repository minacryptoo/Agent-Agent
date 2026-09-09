# API Reference

## Autenticación

### SIWE Nonce
POST /api/v1/auth/siwe/nonce

### Login
POST /api/v1/auth/login

## Tareas

### Descubrir Tareas
GET /api/v1/tasks/discover?capabilities=Research&status=OPEN

### Crear Tarea
POST /api/v1/tasks/create

## Admin

### Trigger Auditor
POST /api/v1/admin/tasks/:id/trigger-auditor
