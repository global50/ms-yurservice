# Руководство по миграции YurService в отдельный репозиторий

Это руководство описывает процесс разделения микрофронтенда `microfrontend-yurservice` в отдельный репозиторий и подключения его как git submodule.

## 📋 Предварительные требования

1. Создан пустой репозиторий на GitHub: `https://github.com/global50/remote-yurservice.git`
2. У вас есть доступ к обоим репозиториям
3. Git установлен и настроен

## 🚀 Автоматическая миграция (рекомендуется)

### Шаг 1: Подготовка

Убедитесь, что все изменения закоммичены:

```bash
git status
git add .
git commit -m "Prepare for yurservice migration"
```

### Шаг 2: Запуск скрипта миграции

```bash
# Сделайте скрипт исполняемым
chmod +x scripts/migrate-yurservice-to-separate-repo.sh

# Запустите миграцию
./scripts/migrate-yurservice-to-separate-repo.sh https://github.com/global50/remote-yurservice.git
```

Скрипт автоматически:
- ✅ Скопирует код микрофронтенда во временную директорию
- ✅ Создаст новый git репозиторий
- ✅ Отправит код в удаленный репозиторий
- ✅ Удалит микрофронтенд из основного репозитория
- ✅ Добавит его как git submodule

### Шаг 3: Закоммитьте изменения

```bash
git status
git add .
git commit -m "Migrate yurservice to separate repository as submodule"
git push
```

## 🔧 Ручная миграция

Если вы предпочитаете выполнить миграцию вручную:

### Шаг 1: Создание отдельного репозитория

```bash
# Создайте временную директорию
mkdir temp-yurservice-repo
cd temp-yurservice-repo

# Скопируйте содержимое микрофронтенда
cp -r ../microfrontend-yurservice/* .
cp -r ../microfrontend-yurservice/.* . 2>/dev/null || true

# Удалите .git если есть
rm -rf .git

# Инициализируйте новый репозиторий
git init
git add .
git commit -m "Initial commit: YurService microfrontend"

# Добавьте remote и отправьте
git remote add origin https://github.com/global50/remote-yurservice.git
git branch -M main
git push -u origin main

cd ..
```

### Шаг 2: Удаление из основного репозитория

```bash
# Вернитесь в основной репозиторий
cd /path/to/ms-yurservice

# Удалите микрофронтенд из git (но оставьте файлы)
git rm -r --cached microfrontend-yurservice

# Удалите директорию
rm -rf microfrontend-yurservice
```

### Шаг 3: Добавление как submodule

```bash
# Добавьте как git submodule
git submodule add https://github.com/global50/remote-yurservice.git microfrontend-yurservice

# Закоммитьте изменения
git add .gitmodules microfrontend-yurservice
git commit -m "Migrate yurservice to separate repository as submodule"
git push
```

## 📦 Работа с submodule

### Клонирование проекта с submodule

```bash
# При клонировании основного репозитория
git clone --recurse-submodules https://github.com/your-org/ms-yurservice.git

# Или после обычного клона
git clone https://github.com/your-org/ms-yurservice.git
cd ms-yurservice
git submodule update --init --recursive
```

### Обновление submodule

```bash
# Обновить до последней версии
cd microfrontend-yurservice
git pull origin main
cd ..

# Или из корня проекта
git submodule update --remote microfrontend-yurservice
```

### Работа с изменениями в submodule

```bash
# Перейти в директорию submodule
cd microfrontend-yurservice

# Создать ветку для изменений
git checkout -b feature/new-feature

# Внести изменения, закоммитить
git add .
git commit -m "Add new feature"
git push origin feature/new-feature

# Вернуться в основной проект
cd ..

# Обновить ссылку на submodule в основном репозитории
git add microfrontend-yurservice
git commit -m "Update yurservice submodule to feature/new-feature"
git push
```

## 🔄 Обновление конфигураций

После миграции убедитесь, что все конфигурации обновлены:

### package.json

Убедитесь, что workspace настроен правильно (если используете npm workspaces):

```json
{
  "workspaces": [
    "microfrontend-yurservice"
  ]
}
```

### vite.config.ts

Алиасы должны продолжать работать, так как submodule сохраняет ту же структуру:

```typescript
resolve: {
  alias: {
    '@yurservice': path.resolve(__dirname, './microfrontend-yurservice/src'),
  },
}
```

### tsconfig.json

Пути TypeScript также должны работать без изменений:

```json
{
  "compilerOptions": {
    "paths": {
      "@yurservice/*": ["./microfrontend-yurservice/src/*"]
    }
  }
}
```

## ✅ Проверка после миграции

1. **Проверьте структуру:**
   ```bash
   ls -la microfrontend-yurservice
   # Должна быть директория с кодом
   ```

2. **Проверьте .gitmodules:**
   ```bash
   cat .gitmodules
   # Должен содержать запись о microfrontend-yurservice
   ```

3. **Запустите проект:**
   ```bash
   npm install
   npm run dev
   # Проверьте, что http://localhost:5173/yurservice работает
   ```

## 🐛 Решение проблем

### Submodule показывает как пустую директорию

```bash
git submodule update --init --recursive
```

### Ошибки при установке зависимостей

```bash
# Удалите node_modules и переустановите
rm -rf node_modules microfrontend-yurservice/node_modules
npm install
```

### Конфликты при обновлении submodule

```bash
cd microfrontend-yurservice
git fetch origin
git reset --hard origin/main
cd ..
```

## 📚 Дополнительные ресурсы

- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Working with Git Submodules](https://www.atlassian.com/git/tutorials/git-submodule)

## 🎯 Преимущества разделения

✅ **Независимое развертывание** - микрофронтенд можно деплоить отдельно  
✅ **Независимая разработка** - команды могут работать параллельно  
✅ **Изолированная история** - чистая git история для каждого проекта  
✅ **Гибкость** - можно использовать разные версии в разных проектах  
✅ **Автоматизация CI/CD** - отдельные пайплайны для каждого репозитория

