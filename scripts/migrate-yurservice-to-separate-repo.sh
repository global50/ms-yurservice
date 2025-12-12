#!/bin/bash

# Скрипт для миграции microfrontend-yurservice в отдельный репозиторий
# Использование: ./scripts/migrate-yurservice-to-separate-repo.sh <remote-repo-url>

set -e

REMOTE_REPO_URL="$1"
MICROFRONTEND_DIR="microfrontend-yurservice"
TEMP_DIR=".temp-yurservice-migration"

if [ -z "$REMOTE_REPO_URL" ]; then
    echo "❌ Ошибка: Не указан URL удаленного репозитория"
    echo "Использование: $0 <remote-repo-url>"
    echo "Пример: $0 https://github.com/global50/remote-yurservice.git"
    exit 1
fi

echo "🚀 Начинаем миграцию microfrontend-yurservice в отдельный репозиторий..."
echo "📦 Удаленный репозиторий: $REMOTE_REPO_URL"
echo ""

# Сохраняем корень проекта
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$PROJECT_ROOT"

# Проверяем, что мы в git репозитории
if [ ! -d ".git" ]; then
    echo "❌ Ошибка: Текущая директория не является git репозиторием"
    exit 1
fi

# Проверяем наличие директории микрофронтенда
if [ ! -d "$MICROFRONTEND_DIR" ]; then
    echo "❌ Ошибка: Директория $MICROFRONTEND_DIR не найдена"
    exit 1
fi

# Проверяем, что нет незакоммиченных изменений
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Внимание: Есть незакоммиченные изменения"
    echo "Рекомендуется закоммитить или отменить изменения перед миграцией"
    read -p "Продолжить? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Создаем временную директорию в корне проекта
echo "📁 Создаем временную директорию..."
TEMP_DIR_ABS="$PROJECT_ROOT/$TEMP_DIR"
rm -rf "$TEMP_DIR_ABS"
mkdir -p "$TEMP_DIR_ABS"

# Получаем абсолютный путь к директории микрофронтенда
MICROFRONTEND_DIR_ABS="$PROJECT_ROOT/$MICROFRONTEND_DIR"

# Проверяем, что временная директория не находится внутри микрофронтенда
if [[ "$TEMP_DIR_ABS" == "$MICROFRONTEND_DIR_ABS"* ]]; then
    echo "❌ Ошибка: Временная директория не может находиться внутри микрофронтенда"
    exit 1
fi

# Копируем содержимое микрофронтенда с исключением ненужных директорий
echo "📋 Копируем файлы микрофронтенда (исключая node_modules, .git, dist)..."
if command -v rsync >/dev/null 2>&1; then
    rsync -av --progress \
      --exclude='node_modules' \
      --exclude='.git' \
      --exclude='dist' \
      --exclude='build' \
      --exclude='.temp-yurservice-migration' \
      --exclude='.DS_Store' \
      --exclude='*.log' \
      "$MICROFRONTEND_DIR_ABS/" "$TEMP_DIR_ABS/"
else
    echo "⚠️  rsync не найден, используем tar..."
    cd "$MICROFRONTEND_DIR_ABS"
    tar --exclude='node_modules' \
        --exclude='.git' \
        --exclude='dist' \
        --exclude='build' \
        --exclude='.temp-yurservice-migration' \
        --exclude='.DS_Store' \
        --exclude='*.log' \
        -cf - . 2>/dev/null | (cd "$TEMP_DIR_ABS" && tar -xf -)
    cd "$PROJECT_ROOT"
fi

# Переходим во временную директорию и инициализируем git репозиторий
cd "$TEMP_DIR_ABS"

# Удаляем .git если есть (чтобы не копировать историю из основного репо)
rm -rf .git 2>/dev/null || true

# Инициализируем новый git репозиторий
echo "🔧 Инициализируем новый git репозиторий..."
git init
git add .
git commit -m "Initial commit: YurService microfrontend"

# Добавляем remote и пушим
echo "📤 Отправляем в удаленный репозиторий..."
git remote add origin "$REMOTE_REPO_URL"
git branch -M main
git push -u origin main

# Возвращаемся в корень проекта
cd "$PROJECT_ROOT"

# Удаляем микрофронтенд из основного репозитория
echo "🗑️  Удаляем микрофронтенд из основного репозитория..."
git rm -r --cached "$MICROFRONTEND_DIR" 2>/dev/null || true
rm -rf "$MICROFRONTEND_DIR"

# Добавляем как git submodule
echo "🔗 Добавляем как git submodule..."
git submodule add "$REMOTE_REPO_URL" "$MICROFRONTEND_DIR"

# Обновляем .gitmodules если нужно
if [ -f ".gitmodules" ]; then
    echo "✅ .gitmodules обновлен"
fi

# Очищаем временную директорию
echo "🧹 Очищаем временные файлы..."
rm -rf "$TEMP_DIR_ABS"

echo ""
echo "✅ Миграция завершена успешно!"
echo ""
echo "📝 Следующие шаги:"
echo "1. Проверьте изменения: git status"
echo "2. Закоммитьте изменения: git commit -m 'Migrate yurservice to separate repository as submodule'"
echo "3. Отправьте изменения: git push"
echo ""
echo "💡 Для клонирования проекта с submodule используйте:"
echo "   git clone --recurse-submodules <repo-url>"
echo "   или после клона: git submodule update --init --recursive"

