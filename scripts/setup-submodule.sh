#!/bin/bash

# Скрипт для настройки submodule после клонирования проекта
# Использование: ./scripts/setup-submodule.sh

set -e

echo "🔧 Настраиваем git submodule для microfrontend-yurservice..."

# Инициализируем и обновляем submodule
git submodule update --init --recursive

echo "✅ Submodule настроен успешно!"
echo ""
echo "💡 Для обновления submodule используйте:"
echo "   git submodule update --remote microfrontend-yurservice"

