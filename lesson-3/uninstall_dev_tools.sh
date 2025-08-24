#!/bin/bash

# Скрипт видалення Docker, Docker Compose, Python 3.11 і Django
# Підтримує Ubuntu/Debian системи
# Версія: 1.0

set -euo pipefail  # Зупинити скрипт при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функція логування
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Функція перевірки прав sudo
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Не запускайте цей скрипт від root користувача!"
        log_error "Використовуйте звичайного користувача з правами sudo"
        exit 1
    fi

    if ! sudo -n true 2>/dev/null; then
        log "Для виконання скрипта потрібні права sudo"
        sudo -v || {
            log_error "Не вдалося отримати права sudo"
            exit 1
        }
    fi
}

# Функція підтвердження дії
confirm_action() {
    local message="$1"
    local default="${2:-n}"

    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$(echo -e "${YELLOW}[CONFIRM]${NC} $message [Y/n]: ")" choice
            choice=${choice:-y}
        else
            read -p "$(echo -e "${YELLOW}[CONFIRM]${NC} $message [y/N]: ")" choice
            choice=${choice:-n}
        fi

        case "$choice" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Будь ласка, введіть y або n" ;;
        esac
    done
}

# Функція перевірки встановлення Django
is_django_installed() {
    python3 -c "import django; print(django.get_version())" >/dev/null 2>&1
}

# Функція видалення Django
uninstall_django() {
    if ! is_django_installed; then
        log_info "Django не встановлено"
        return 0
    fi

    local django_version=$(python3 -c "import django; print(django.get_version())" 2>/dev/null)
    log "Видалення Django (версія $django_version)..."

    if confirm_action "Видалити Django?"; then
        # Видалення Django через pip
        python3 -m pip uninstall -y Django --disable-pip-version-check --quiet 2>/dev/null || true

        if ! is_django_installed; then
            log_success "Django успішно видалено"
        else
            log_warning "Django все ще присутній в системі"
        fi
    else
        log_info "Видалення Django скасовано"
    fi
}

# Функція перевірки встановлення Python 3.11
is_python311_installed() {
    command -v python3.11 >/dev/null 2>&1
}

# Функція безпечного видалення Python 3.11
uninstall_python311() {
    if ! is_python311_installed; then
        log_info "Python 3.11 не встановлено"
        return 0
    fi

    log "Підготовка до видалення Python 3.11..."

    # Перевірка системного Python
    local system_python=""
    if [[ -f /usr/bin/python3.8 ]]; then
        system_python="python3.8"
    elif [[ -f /usr/bin/python3.9 ]]; then
        system_python="python3.9"
    elif [[ -f /usr/bin/python3.10 ]]; then
        system_python="python3.10"
    fi

    if [[ -z "$system_python" ]]; then
        log_error "Не знайдено системної версії Python! Видалення Python 3.11 може зламати систему."
        log_error "Скасування операції для безпеки."
        return 1
    fi

    log_info "Знайдено системний Python: $system_python"

    if confirm_action "Видалити Python 3.11? (системний $system_python буде збережено)"; then
        # Відновлення системного Python як default
        if update-alternatives --list python3 >/dev/null 2>&1; then
            log "Відновлення системного Python як default..."
            sudo update-alternatives --remove-all python3 2>/dev/null || true
            sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/$system_python 100 --force
        fi

        # Видалення пакетів Python 3.11
        log "Видалення пакетів Python 3.11..."
        sudo apt remove -y \
            python3.11 \
            python3.11-dev \
            python3.11-venv \
            python3.11-distutils \
            python3.11-lib2to3 \
            python3.11-minimal \
            libpython3.11 \
            libpython3.11-dev \
            libpython3.11-minimal \
            libpython3.11-stdlib 2>/dev/null || true

        # Очищення залишків
        sudo apt autoremove -y >/dev/null 2>&1 || true

        # Видалення PPA (опціонально)
        if confirm_action "Видалити PPA deadsnakes (джерело Python 3.11)?"; then
            sudo add-apt-repository --remove -y ppa:deadsnakes/ppa 2>/dev/null || true
            sudo apt update -qq 2>/dev/null || true
        fi

        if ! is_python311_installed; then
            log_success "Python 3.11 успішно видалено"
            log_info "Активний Python: $(python3 --version)"
        else
            log_warning "Python 3.11 все ще присутній в системі"
        fi
    else
        log_info "Видалення Python 3.11 скасовано"
    fi
}

# Функція перевірки встановлення Docker
is_docker_installed() {
    command -v docker >/dev/null 2>&1
}

# Функція видалення Docker
uninstall_docker() {
    if ! is_docker_installed; then
        log_info "Docker не встановлено"
        return 0
    fi

    local docker_version=$(docker --version 2>/dev/null || echo "невідома версія")
    log "Підготовка до видалення Docker ($docker_version)..."

    if confirm_action "Видалити Docker та всі його дані (контейнери, образи, томи)?"; then
        # Зупинка Docker сервісів
        log "Зупинка Docker сервісів..."
        sudo systemctl stop docker 2>/dev/null || true
        sudo systemctl stop containerd 2>/dev/null || true
        sudo systemctl disable docker 2>/dev/null || true
        sudo systemctl disable containerd 2>/dev/null || true

        # Видалення користувача з групи docker
        if groups $USER | grep -q docker; then
            log "Видалення користувача $USER з групи docker..."
            sudo gpasswd -d $USER docker 2>/dev/null || true
        fi

        # Видалення всіх контейнерів, образів та томів
        if confirm_action "Видалити всі Docker контейнери, образи та томи?"; then
            log "Очищення Docker даних..."
            # Зупинка всіх контейнерів
            docker stop $(docker ps -aq) 2>/dev/null || true
            # Видалення всіх контейнерів
            docker rm $(docker ps -aq) 2>/dev/null || true
            # Видалення всіх образів
            docker rmi $(docker images -q) 2>/dev/null || true
            # Видалення всіх томів
            docker volume rm $(docker volume ls -q) 2>/dev/null || true
            # Очищення мереж
            docker network prune -f 2>/dev/null || true
            # Системне очищення
            docker system prune -a -f 2>/dev/null || true
        fi

        # Видалення пакетів Docker
        log "Видалення пакетів Docker..."
        sudo apt remove -y \
            docker-ce \
            docker-ce-cli \
            docker-buildx-plugin \
            docker-compose-plugin \
            docker-ce-rootless-extras \
            containerd.io 2>/dev/null || true

        # Видалення залишкових пакетів
        sudo apt purge -y \
            docker-ce \
            docker-ce-cli \
            docker-buildx-plugin \
            docker-compose-plugin \
            docker-ce-rootless-extras \
            containerd.io 2>/dev/null || true

        # Видалення репозиторію Docker
        if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
            log "Видалення репозиторію Docker..."
            sudo rm -f /etc/apt/sources.list.d/docker.list
        fi

        # Видалення GPG ключа
        if [[ -f /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
            sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg
        fi

        # Видалення даних Docker
        if [[ -d /var/lib/docker ]] && confirm_action "Видалити дані Docker (/var/lib/docker)?"; then
            sudo rm -rf /var/lib/docker
        fi

        if [[ -d /var/lib/containerd ]] && confirm_action "Видалити дані containerd (/var/lib/containerd)?"; then
            sudo rm -rf /var/lib/containerd
        fi

        # Видалення конфігураційних файлів
        sudo rm -rf /etc/docker 2>/dev/null || true
        sudo rm -rf /etc/containerd 2>/dev/null || true

        # Видалення systemd файлів
        sudo rm -f /etc/systemd/system/docker.service 2>/dev/null || true
        sudo rm -f /etc/systemd/system/containerd.service 2>/dev/null || true
        sudo systemctl daemon-reload 2>/dev/null || true

        # Очищення залишків та автоматично встановлених пакетів
        log "Очищення автоматично встановлених пакетів..."
        sudo apt autoremove -y 2>/dev/null || true
        sudo apt update -qq 2>/dev/null || true

        # Очищення кешу команд bash
        hash -r 2>/dev/null || true

        if ! is_docker_installed; then
            log_success "Docker успішно видалено"
        else
            log_warning "Docker все ще присутній в системі"
            log_info "Спробуйте перезайти в систему або виконати: hash -r"
        fi
    else
        log_info "Видалення Docker скасовано"
    fi
}

# Функція очищення pip кешу та конфігурацій
cleanup_pip() {
    if command -v python3 >/dev/null 2>&1; then
        if confirm_action "Очистити pip кеш та користувацькі пакети?"; then
            log "Очищення pip кешу..."
            python3 -m pip cache purge 2>/dev/null || true

            if [[ -d "$HOME/.local/lib/python3.11" ]] && confirm_action "Видалити користувацькі пакети Python 3.11?"; then
                rm -rf "$HOME/.local/lib/python3.11" 2>/dev/null || true
                rm -rf "$HOME/.local/bin/django-admin" 2>/dev/null || true
            fi

            log_success "Pip кеш очищено"
        fi
    fi
}

# Функція виведення статусу компонентів
show_status() {
    echo
    log_success "=== СТАТУС КОМПОНЕНТІВ ПІСЛЯ ВИДАЛЕННЯ ==="

    if is_docker_installed; then
        echo -e "${RED}✗${NC} Docker: $(docker --version 2>/dev/null || echo 'помилка версії')"
    else
        echo -e "${GREEN}✓${NC} Docker: видалено"
    fi

    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        echo -e "${RED}✗${NC} Docker Compose: $(docker compose version --short 2>/dev/null || echo 'помилка версії')"
    else
        echo -e "${GREEN}✓${NC} Docker Compose: видалено"
    fi

    if is_python311_installed; then
        echo -e "${RED}✗${NC} Python 3.11: $(python3.11 --version 2>/dev/null || echo 'помилка версії')"
    else
        echo -e "${GREEN}✓${NC} Python 3.11: видалено"
    fi

    if command -v python3 >/dev/null 2>&1; then
        echo -e "${CYAN}ℹ${NC} Активний Python: $(python3 --version)"

        if command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; then
            echo -e "${CYAN}ℹ${NC} pip: $(python3 -m pip --version | cut -d' ' -f1-2)"
        else
            echo -e "${GREEN}✓${NC} pip: недоступний"
        fi
    else
        echo -e "${RED}!${NC} Python: не знайдено (можлива проблема!)"
    fi

    if is_django_installed; then
        local django_version=$(python3 -c "import django; print(django.get_version())" 2>/dev/null || echo "помилка версії")
        echo -e "${RED}✗${NC} Django: версія $django_version"
    else
        echo -e "${GREEN}✓${NC} Django: видалено"
    fi

    echo
}

# Основна функція
main() {
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║               Скрипт видалення інструментів розробки         ║${NC}"
    echo -e "${RED}║        Docker | Docker Compose | Python 3.11 | Django        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo

    log_warning "УВАГА: Цей скрипт видалить компоненти, встановлені install_dev_tools.sh"
    log_warning "Переконайтеся, що у вас є резервні копії важливих даних!"
    echo

    if ! confirm_action "Продовжити видалення компонентів?"; then
        log_info "Операція скасована користувачем"
        exit 0
    fi

    check_sudo

    echo
    log "Починаємо процес видалення..."
    echo

    # Видалення в зворотному порядку встановлення
    uninstall_django
    echo

    cleanup_pip
    echo

    uninstall_python311
    echo

    uninstall_docker
    echo

    show_status

    log_success "Процес видалення завершено!"

}

# Виконання основної функції
main "$@"