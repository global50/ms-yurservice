# Устранение проблем с Git Submodule

## Проверка состояния submodule

### Быстрая проверка

```bash
# Проверьте, что submodule является gitlink (160000)
git ls-tree HEAD microfrontend-yurservice

# Должно показать:
# 160000 commit <hash>	microfrontend-yurservice
```

### Детальная проверка

Используйте скрипт для автоматической проверки:

```bash
./scripts/fix-submodule.sh
```

## Проблема: Файлы отслеживаются как обычные файлы вместо submodule

### Симптомы

- При `git clone --recurse-submodules` submodule не инициализируется
- `git ls-tree HEAD microfrontend-yurservice` показывает `100644` вместо `160000`
- Файлы из `microfrontend-yurservice/` видны в `git ls-files`

### Решение

#### Автоматическое исправление

```bash
./scripts/fix-submodule.sh
```

#### Ручное исправление

1. **Удалите файлы из индекса Git:**

```bash
git rm -r --cached microfrontend-yurservice
```

2. **Удалите директорию (если она существует):**

```bash
rm -rf microfrontend-yurservice
```

3. **Убедитесь, что `.gitmodules` существует и правильный:**

```bash
cat .gitmodules
# Должно содержать:
# [submodule "microfrontend-yurservice"]
# 	path = microfrontend-yurservice
# 	url = https://github.com/global50/remote-yurservice.git
```

4. **Добавьте submodule заново:**

```bash
git submodule add https://github.com/global50/remote-yurservice.git microfrontend-yurservice
```

5. **Или инициализируйте существующий submodule:**

```bash
git submodule update --init --recursive microfrontend-yurservice
```

6. **Проверьте результат:**

```bash
git ls-tree HEAD microfrontend-yurservice
# Должно показать: 160000 commit <hash>
```

7. **Закоммитьте изменения:**

```bash
git add .gitmodules microfrontend-yurservice
git commit -m "Fix: properly configure microfrontend-yurservice as submodule"
```

## Проверка после исправления

### Проверка gitlink

```bash
git ls-tree HEAD microfrontend-yurservice
# Ожидается: 160000 commit <hash>
```

### Проверка отсутствия отслеживаемых файлов

```bash
git ls-files | grep "^microfrontend-yurservice/"
# Должно быть пусто
```

### Проверка статуса submodule

```bash
git submodule status
# Должно показать: <hash> microfrontend-yurservice (heads/main)
```

### Тест клонирования

```bash
cd /tmp
rm -rf test-clone
git clone --recurse-submodules https://github.com/global50/ms-yurservice.git test-clone
cd test-clone
ls -la microfrontend-yurservice/
# Должны быть файлы из submodule
```

## Частые проблемы

### Проблема: "Submodule path 'microfrontend-yurservice' not initialized"

**Решение:**
```bash
git submodule update --init --recursive microfrontend-yurservice
```

### Проблема: "fatal: not a git repository" при работе с submodule

**Решение:**
```bash
git submodule deinit -f microfrontend-yurservice
git submodule update --init --recursive microfrontend-yurservice
```

### Проблема: Конфликт при merge/rebase

**Решение:**
```bash
# Обновите submodule до нужного коммита
cd microfrontend-yurservice
git checkout <commit-hash>
cd ..
git add microfrontend-yurservice
git commit -m "Update submodule to <commit-hash>"
```

## Профилактика

1. **Всегда используйте `--recurse-submodules` при клонировании:**
   ```bash
   git clone --recurse-submodules <repo-url>
   ```

2. **После клонирования без флага:**
   ```bash
   git submodule update --init --recursive
   ```

3. **Проверяйте состояние перед коммитом:**
   ```bash
   git ls-tree HEAD microfrontend-yurservice
   # Должно быть 160000
   ```

4. **Не коммитьте файлы из submodule напрямую в родительский репозиторий**

## Дополнительные ресурсы

- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Working with Git Submodules](https://www.atlassian.com/git/tutorials/git-submodule)

