#!/bin/bash

# Скрипт автоматичного встановлення Docker, Docker Compose, Python 3.11 і Django
# Підтримує Ubuntu/Debian системи
# Версія: 1.0

set -euo pipefail  # Зупинити скрипт при помилці

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Функція оновлення системи
update_system() {
    log "Оновлення списку пакетів..."
    sudo apt update -qq
    log_success "Система оновлена"
}

# Функція встановлення необхідних пакетів
install_prerequisites() {
    local packages=(
        "curl"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "apt-transport-https"
        "software-properties-common"
        "build-essential"
        "libssl-dev"
        "libffi-dev"
        "python3-dev"
    )

    log "Встановлення необхідних пакетів..."
    sudo apt install -y "${packages[@]}" > /dev/null 2>&1
    log_success "Необхідні пакети встановлено"
}

# Функція перевірки встановлення Docker
is_docker_installed() {
    command -v docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1
}

# Функція встановлення Docker
install_docker() {
    if is_docker_installed; then
        log_warning "Docker вже встановлено: $(docker --version)"
        return 0
    fi

    log "Встановлення Docker..."

    # Видалення старих версій Docker
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Видалення старого ключа якщо існує
    sudo rm -f /usr/share/keyrings/docker-archive-keyring.gpg

    # Додавання офіційного GPG ключа Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Додавання репозиторію Docker
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Оновлення списку пакетів і встановлення Docker
    sudo apt update -qq
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

    # Додавання користувача до групи docker
    sudo usermod -aG docker $USER

    # Увімкнення автозапуску Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    if is_docker_installed; then
        log_success "Docker успішно встановлено: $(docker --version)"
        log_warning "Перезайдіть в систему або виконайте 'newgrp docker' для використання Docker без sudo"
    else
        log_error "Помилка встановлення Docker"
        exit 1
    fi
}

# Функція перевірки встановлення Docker Compose
is_docker_compose_installed() {
    # Перевіряємо наявність пакету docker-compose-plugin
    dpkg -l | grep -q "docker-compose-plugin" 2>/dev/null || \
    # Альтернативно перевіряємо команду docker compose (якщо Docker встановлено)
    (command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1)
}

# Функція встановлення Docker Compose
install_docker_compose() {
    if is_docker_compose_installed; then
        log_warning "Docker Compose вже встановлено: $(docker compose version --short)"
        return 0
    fi

    log "Встановлення Docker Compose..."

    # Docker Compose v2 встановлюється як plugin разом з Docker
    # Перевіримо, чи він встановився
    if ! is_docker_compose_installed; then
        # Якщо не встановився автоматично, встановимо вручну
        sudo apt install -y docker-compose-plugin
    fi

    if is_docker_compose_installed; then
        log_success "Docker Compose успішно встановлено: $(docker compose version --short)"
    else
        log_error "Помилка встановлення Docker Compose"
        exit 1
    fi
}

# Функція перевірки встановлення Python
is_python_installed() {
    python3 --version >/dev/null 2>&1 && python3 -c "import sys; exit(0 if sys.version_info >= (3, 11) else 1)" 2>/dev/null
}

# Функція встановлення Python
install_python() {
    local current_version=""

    if command -v python3 >/dev/null 2>&1; then
        current_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    fi

    if is_python_installed; then
        log_warning "Python вже встановлено (версія $current_version >= 3.11)"
        return 0
    fi

    log "Встановлення Python 3.11..."

    # Додавання PPA для останніх версій Python
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update -qq

    # Встановлення Python 3.11
    sudo apt install -y python3.11 python3.11-venv python3.11-dev

    # Встановлення pip для Python 3.11
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

    # Безпечне налаштування alternatives для python3
    if command -v python3.11 >/dev/null 2>&1; then
        # Видалення існуючих alternatives якщо є проблеми
        sudo update-alternatives --remove-all python3 2>/dev/null || true
        # Встановлення нової alternative
        sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 100 --force
        log "Python 3.11 налаштовано як основна версія python3"
    fi

    if is_python_installed; then
        log_success "Python успішно встановлено: $(python3 --version)"
    else
        log_error "Помилка встановлення Python"
        exit 1
    fi
}

# Функція перевірки встановлення pip
is_pip_installed() {
    python3 -m pip --version >/dev/null 2>&1
}

# Функція встановлення pip
install_pip() {
    if is_pip_installed; then
        log_warning "pip вже встановлено: $(python3 -m pip --version)"
        return 0
    fi

    log "Встановлення pip..."

    # Встановлення pip через get-pip.py
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3

    if is_pip_installed; then
        log_success "pip успішно встановлено: $(python3 -m pip --version)"
    else
        log_error "Помилка встановлення pip"
        exit 1
    fi
}

# Функція перевірки встановлення Django
is_django_installed() {
    python3 -c "import django; print(django.get_version())" >/dev/null 2>&1
}

# Функція встановлення Django
install_django() {
    if is_django_installed; then
        local django_version=$(python3 -c "import django; print(django.get_version())" 2>/dev/null)
        log_warning "Django вже встановлено (версія $django_version)"
        return 0
    fi

    log "Встановлення Django..."

    # Оновлення pip до останньої версії (з придушенням попереджень)
    python3 -m pip install --upgrade pip --disable-pip-version-check --quiet

    # Встановлення Django
    python3 -m pip install Django --disable-pip-version-check --quiet

    if is_django_installed; then
        local django_version=$(python3 -c "import django; print(django.get_version())")
        log_success "Django успішно встановлено (версія $django_version)"
    else
        log_error "Помилка встановлення Django"
        exit 1
    fi
}

# Функція виведення підсумкової інформації
show_summary() {
    echo
    log_success "=== ПІДСУМОК ВСТАНОВЛЕННЯ ==="

    if is_docker_installed; then
        echo -e "${GREEN}✓${NC} Docker: $(docker --version)"
    else
        echo -e "${RED}✗${NC} Docker: не встановлено"
    fi

    if is_docker_compose_installed; then
        echo -e "${GREEN}✓${NC} Docker Compose: $(docker compose version --short)"
    else
        echo -e "${RED}✗${NC} Docker Compose: не встановлено"
    fi

    if is_python_installed; then
        echo -e "${GREEN}✓${NC} Python: $(python3 --version)"
    else
        echo -e "${RED}✗${NC} Python: не встановлено або версія < 3.11"
    fi

    if is_pip_installed; then
        echo -e "${GREEN}✓${NC} pip: $(python3 -m pip --version | cut -d' ' -f1-2)"
    else
        echo -e "${RED}✗${NC} pip: не встановлено"
    fi

    if is_django_installed; then
        local django_version=$(python3 -c "import django; print(django.get_version())" 2>/dev/null)
        echo -e "${GREEN}✓${NC} Django: версія $django_version"
    else
        echo -e "${RED}✗${NC} Django: не встановлено"
    fi

    echo
    log_success "Встановлення завершено!"

    if id -nG "$USER" | grep -qw docker; then
        log "Ви можете використовувати Docker без sudo"
    else
        log_warning "Щоб використовувати Docker без sudo, перезайдіть в систему або виконайте: newgrp docker"
    fi
}

# Основна функція
main() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          Скрипт встановлення інструментів розробки           ║${NC}"
    echo -e "${BLUE}║     Docker | Docker Compose | Python 3.11+ | Django          ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo

    check_sudo
    update_system
    install_prerequisites
    install_docker
    install_docker_compose
    install_python
    install_pip
    install_django
    show_summary
}

# Виконання основної функції
main "$@"