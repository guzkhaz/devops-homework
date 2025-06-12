# В качестве базового образа используем стабильный образ Debian
FROM debian:bullseye

# Указываем автора
MAINTAINER Khazratova Guzel <guzkhaz04@gmail.com>

# Устанавливаем nginx, postgresql и доп. утилиты
RUN apt-get update && \
    apt-get install -y nginx postgresql && \
    apt-get clean

# Устанавливаем переменные окружения
ENV POSTGRES_USER=admin \
    POSTGRES_PASSWORD=secret

# Создаём рабочую директорию
WORKDIR /var/www/html

# Копируем конфиг. файл nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Добавляем html-файл
ADD index.html /var/www/html/index.html

# Добавляем volume для хранения данных PostgreSQL вне контейнера
VOLUME ["/var/lib/postgresql/data"]

# Создаём нового пользователя с правами root
RUN useradd -u 0 -o -ms /bin/bash webuser
USER webuser

# Открываем порты для nginx и postgres
EXPOSE 80 5432

# Запускаем оба сервиса
CMD service postgresql start && nginx -g 'daemon off;'