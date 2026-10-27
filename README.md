# Autéllo Barskiy - Защищенный контур лидогенерации

Изолированная серверная инфраструктура для приёма, валидации и хранения заявок («тёплых клиентов») с локальной БД, веб-интерфейсом pgAdmin, шлюзом Nginx, Docker Registry и автообновлением через Watchtower.

## Архитектура контура

- **Nginx Gateway (Порты 80, 443):** Единая публичная точка входа. Раздает статический фронтенд, проксирует вызовы `/api/` в защищенный бэкенд и интерфейс `/pgadmin/`.
- **PostgreSQL 16:** Серверная база данных. Расположена в строго изолированной внутренней сети `backend_net` (`internal: true`). Внешний доступ к портам СУБД из интернета физически невозможен.
- **pgAdmin 4:** Веб-панель для администрирования БД PostgreSQL (доступ через Nginx по адресу `/pgadmin/`).
- **Docker Registry v2:** Приватный локальный реестр Docker-образов для бэкенда с авторизацией через `htpasswd` (`docker login`).
- **Watchtower:** Демон автоматического обновления контейнеров при пуше свежих образов в локальный Registry (по метке `com.centurylinklabs.watchtower.enable=true`).
- **Backend (API):** Сервис обработки заявок (шаблон подготовлен и закомментирован в `docker-compose.yml`).

## Быстрый старт

1. Склонируйте репозиторий:
```bash
git clone https://github.com/MaxGarAI/Aut-llo_Barskiy.git
cd Aut-llo_Barskiy
```

2. Скопируйте и настройте переменные окружения:
```bash
cp .env.example .env
```

3. Сгенерируйте учетные данные для локального Docker Registry:
```bash
chmod +x scripts/create-registry-user.sh
./scripts/create-registry-user.sh developer DevSecurePass2026!
```

4. Запустите инфраструктуру:
```bash
docker compose up -d
```

## Работа с локальным реестром Docker

1. Авторизация:
```bash
docker login <IP_СЕРВЕРА>:5000 -u developer -p DevSecurePass2026!
```

2. Пуш образов бэкенда:
```bash
docker tag backend:latest <IP_СЕРВЕРА>:5000/autello/backend:latest
docker push <IP_СЕРВЕРА>:5000/autello/backend:latest
```

## Доступ к pgAdmin
- Адрес: `http://<IP_СЕРВЕРА>/pgadmin/`
- Настройки подключения к базе:
  - Host: `postgres`
  - Port: `5432`
  - Database: `leads_db`
  - User: `leads_user`
