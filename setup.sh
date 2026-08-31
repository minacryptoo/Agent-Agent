#!/bin/bash

# ============================================
# SCRIPT DE INICIALIZACIÓN DEL PROYECTO
# A2A MARKETPLACE - ESTRUCTURA BASE
# ============================================

echo "🚀 INICIANDO CREACIÓN DE ESTRUCTURA..."

# 1. Crear la estructura de directorios del proyecto
mkdir -p packages/contracts/src/interfaces
mkdir -p packages/contracts/test
mkdir -p packages/contracts/script
mkdir -p packages/contracts/lib/forge-std
mkdir -p packages/contracts/lib/openzeppelin-contracts

mkdir -p packages/api-gateway/src/config
mkdir -p packages/api-gateway/src/modules/auth
mkdir -p packages/api-gateway/src/modules/tasks
mkdir -p packages/api-gateway/src/modules/agents
mkdir -p packages/api-gateway/src/modules/payments
mkdir -p packages/api-gateway/src/modules/admin
mkdir -p packages/api-gateway/src/modules/websocket
mkdir -p packages/api-gateway/src/middleware
mkdir -p packages/api-gateway/src/services
mkdir -p packages/api-gateway/src/utils
mkdir -p packages/api-gateway/prisma/migrations
mkdir -p packages/api-gateway/tests
mkdir -p packages/api-gateway/docker

mkdir -p packages/frontend/app/public/home
mkdir -p packages/frontend/app/public/marketplace
mkdir -p packages/frontend/app/public/agents
mkdir -p packages/frontend/app/public/docs/manifest
mkdir -p packages/frontend/app/auth/login
mkdir -p packages/frontend/app/auth/register
mkdir -p packages/frontend/app/auth/forgot-password
mkdir -p packages/frontend/app/dashboard/client/tasks/create
mkdir -p packages/frontend/app/dashboard/client/wallet
mkdir -p packages/frontend/app/dashboard/client/settings
mkdir -p packages/frontend/app/dashboard/worker/tasks
mkdir -p packages/frontend/app/dashboard/worker/earnings
mkdir -p packages/frontend/app/dashboard/worker/settings
mkdir -p packages/frontend/app/dashboard/admin/users
mkdir -p packages/frontend/app/dashboard/admin/tasks
mkdir -p packages/frontend/app/dashboard/admin/disputes
mkdir -p packages/frontend/app/dashboard/admin/settings
mkdir -p packages/frontend/app/api/auth/siwe/nonce
mkdir -p packages/frontend/app/api/auth/siwe/verify
mkdir -p packages/frontend/app/api/auth/2fa/verify
mkdir -p packages/frontend/app/api/tasks
mkdir -p packages/frontend/app/api/admin
mkdir -p packages/frontend/components/ui
mkdir -p packages/frontend/components/tasks
mkdir -p packages/frontend/components/wallet
mkdir -p packages/frontend/components/agents
mkdir -p packages/frontend/components/shared
mkdir -p packages/frontend/hooks
mkdir -p packages/frontend/lib
mkdir -p packages/frontend/styles
mkdir -p packages/frontend/public/images
mkdir -p packages/frontend/public/icons
mkdir -p packages/frontend/types

mkdir -p packages/auditor-daemon/src/services
mkdir -p packages/auditor-daemon/src/listeners
mkdir -p packages/auditor-daemon/src/config
mkdir -p packages/auditor-daemon/src/utils
mkdir -p packages/auditor-daemon/tests
mkdir -p packages/auditor-daemon/docker

mkdir -p packages/shared/types
mkdir -p packages/shared/utils
mkdir -p packages/shared/constants

mkdir -p docs/ADRs
mkdir -p scripts/deploy
mkdir -p scripts/setup
mkdir -p scripts/monitoring
mkdir -p docker/certbot/conf
mkdir -p infra/oracle
mkdir -p infra/alchemy
mkdir -p .github/workflows
mkdir -p .github/ISSUE_TEMPLATE

echo "✅ Directorios creados correctamente"

# 2. Crear archivos .gitkeep para las carpetas vacías
find . -type d -empty -exec touch {}/.gitkeep \;
echo "✅ Archivos .gitkeep creados"

# 3. Crear archivos raíz de configuración
touch package.json
touch pnpm-workspace.yaml
touch turbo.json
touch tsconfig.base.json
touch .gitignore
touch README.md
touch .env.example
touch docker-compose.yml
touch Makefile

touch packages/contracts/foundry.toml
touch packages/contracts/remappings.txt

touch packages/api-gateway/package.json
touch packages/api-gateway/tsconfig.json
touch packages/api-gateway/jest.config.js

touch packages/frontend/next.config.js
touch packages/frontend/tailwind.config.ts
touch packages/frontend/tsconfig.json

touch packages/auditor-daemon/requirements.txt
touch packages/auditor-daemon/pyproject.toml

echo "✅ Archivos de configuración creados"

# 4. Verificar el estado del repositorio ANTES del push
echo "📊 ESTADO DEL REPOSITORIO (ANTES):"
git status
echo "-----------------------------------"

# 5. Añadir todos los archivos al staging
git add .
echo "✅ Archivos añadidos al staging"

# 6. Crear commit descriptivo
git commit -m "chore: crear estructura base del proyecto A2A Marketplace"
echo "✅ Commit creado"

# 7. Subir a GitHub
git push origin main
echo "✅ Push a GitHub completado"

# 8. Verificar el estado final
echo "📊 ESTADO DEL REPOSITORIO (DESPUÉS):"
git status
echo "-----------------------------------"

# 9. Verificar últimos commits
echo "📋 ÚLTIMOS COMMITS:"
git log --oneline -5
echo "-----------------------------------"

# 10. Mostrar resumen de la estructura creada
echo "🗂️ ESTRUCTURA DE DIRECTORIOS CREADA:"
find . -type d -not -path '*/node_modules/*' -not -path '*/.git/*' | sort
echo "-----------------------------------"
echo "🎉 PROYECTO INICIALIZADO CORRECTAMENTE"
