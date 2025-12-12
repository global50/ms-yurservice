#!/bin/bash

# Скрипт для исправления состояния git submodule
# Убеждается, что microfrontend-yurservice правильно настроен как submodule

set -e

SUBMODULE_PATH="microfrontend-yurservice"
PROJECT_ROOT=$(git rev-parse --show-toplevel)

cd "$PROJECT_ROOT"

echo "🔍 Проверяем состояние submodule..."

# Проверяем, что .gitmodules существует
if [ ! -f ".gitmodules" ]; then
    echo "❌ Ошибка: .gitmodules не найден"
    exit 1
fi

# Проверяем, что submodule объявлен в .gitmodules
if ! grep -q "\[submodule \"$SUBMODULE_PATH\"\]" .gitmodules; then
    echo "❌ Ошибка: $SUBMODULE_PATH не найден в .gitmodules"
    exit 1
fi

# Проверяем, что в HEAD submodule является gitlink (160000)
TREE_LINE=$(git ls-tree HEAD "$SUBMODULE_PATH" 2>/dev/null || echo "")
if [ -z "$TREE_LINE" ]; then
    echo "❌ Ошибка: $SUBMODULE_PATH не найден в HEAD"
    exit 1
fi

TREE_MODE=$(echo "$TREE_LINE" | awk '{print $1}')
if [ "$TREE_MODE" != "160000" ]; then
    echo "❌ Ошибка: $SUBMODULE_PATH не является gitlink в HEAD (режим: $TREE_MODE, ожидается: 160000)"
    echo "   Это означает, что файлы все еще отслеживаются как обычные файлы"
    exit 1
else
    echo "✅ Submodule правильно настроен как gitlink (160000)"
fi

# Проверяем, нет ли отслеживаемых файлов в индексе
TRACKED_FILES=$(git ls-files --stage | grep "^$SUBMODULE_PATH/" || true)
if [ -n "$TRACKED_FILES" ]; then
    echo "❌ Обнаружены отслеживаемые файлы в индексе:"
    echo "$TRACKED_FILES"
    echo ""
    echo "🔧 Удаляем файлы из индекса..."
    git rm -r --cached "$SUBMODULE_PATH" 2>/dev/null || true
    echo "✅ Файлы удалены из индекса"
fi

# Удаляем директорию если она существует и не является submodule
if [ -d "$SUBMODULE_PATH" ]; then
    if [ ! -f "$SUBMODULE_PATH/.git" ] && [ ! -d "$SUBMODULE_PATH/.git" ]; then
        echo "⚠️  Директория существует, но не является submodule"
        echo "🔧 Удаляем директорию..."
        rm -rf "$SUBMODULE_PATH"
    fi
fi

# Деинициализируем и переинициализируем submodule
echo "🔧 Переинициализируем submodule..."
git submodule deinit -f "$SUBMODULE_PATH" 2>/dev/null || true
git submodule update --init --recursive "$SUBMODULE_PATH"

# Финальная проверка
echo ""
echo "✅ Финальная проверка:"
echo "---"

# Проверяем gitlink
TREE_LINE=$(git ls-tree HEAD "$SUBMODULE_PATH" 2>/dev/null || echo "")
if [ -n "$TREE_LINE" ]; then
    TREE_MODE=$(echo "$TREE_LINE" | awk '{print $1}')
    TREE_TYPE=$(echo "$TREE_LINE" | awk '{print $2}')
    TREE_HASH=$(echo "$TREE_LINE" | awk '{print $3}')
    echo "Режим в HEAD: $TREE_MODE (ожидается: 160000 для gitlink)"
    echo "Тип объекта: $TREE_TYPE"
    echo "Хеш коммита: $TREE_HASH"
    if [ "$TREE_MODE" = "160000" ]; then
        echo "✅ Submodule правильно настроен как gitlink!"
    else
        echo "❌ Submodule НЕ настроен как gitlink!"
    fi
else
    echo "❌ Submodule не найден в HEAD"
fi

# Проверяем статус submodule
echo ""
echo "Статус submodule:"
git submodule status "$SUBMODULE_PATH"

# Проверяем .git файл
if [ -f "$SUBMODULE_PATH/.git" ]; then
    echo ""
    echo "Содержимое .git файла:"
    cat "$SUBMODULE_PATH/.git"
fi

# Проверяем, что нет отслеживаемых файлов
TRACKED_FILES=$(git ls-files | grep "^$SUBMODULE_PATH/" || true)
if [ -z "$TRACKED_FILES" ]; then
    echo ""
    echo "✅ Нет отслеживаемых файлов в индексе - все правильно!"
else
    echo ""
    echo "⚠️  Все еще есть отслеживаемые файлы:"
    echo "$TRACKED_FILES"
fi

echo ""
echo "✅ Проверка завершена!"

