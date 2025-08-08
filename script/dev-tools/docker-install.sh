#!/bin/bash
# needs-sudo

# ==============================================================================
# Skrip Instalasi Docker Otomatis untuk Distribusi Linux Populer
# ==============================================================================

# Periksa apakah skrip dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Harap jalankan skrip ini sebagai root atau menggunakan sudo."
  exit 1
fi

# Fungsi untuk menginstal Docker di distribusi berbasis Debian (Ubuntu, Debian)
install_docker_debian() {
    echo "--- Mendeteksi sistem berbasis Debian/Ubuntu ---"
    apt-get update
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "--- Instalasi Docker di $(. /etc/os-release && echo "$PRETTY_NAME") selesai ---"
}

# Fungsi untuk menginstal Docker di distribusi berbasis RHEL (CentOS, Fedora)
install_docker_rhel() {
    echo "--- Mendeteksi sistem berbasis CentOS/Fedora ---"
    dnf -y install dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    # Untuk Fedora, gunakan repo CentOS
    if [ -f /etc/fedora-release ]; then
        dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    fi
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl start docker
    systemctl enable docker
    echo "--- Instalasi Docker di $(. /etc/os-release && echo "$PRETTY_NAME") selesai ---"
}

# --- Logika Utama Skrip ---

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Tidak dapat mendeteksi distribusi Linux."
    exit 1
fi

case "$OS" in
    ubuntu|debian)
        install_docker_debian
        ;;
    centos|rhel|fedora)
        install_docker_rhel
        ;;
    *)
        echo "Distribusi Linux '$OS' tidak didukung oleh skrip ini."
        echo "Silakan lihat dokumentasi resmi Docker untuk instruksi instalasi manual."
        exit 1
        ;;
esac

# Opsional: Menambahkan user non-root ke grup docker agar bisa menjalankan docker tanpa sudo
# Hati-hati: Ini memiliki implikasi keamanan.
read -p "Apakah Anda ingin menambahkan user Anda ke grup Docker agar tidak perlu 'sudo'? (y/n): " add_user_to_group
if [[ "$add_user_to_group" == "y" || "$add_user_to_group" == "Y" ]]; then
    # Deteksi user yang menjalankan sudo
    if [ -n "$SUDO_USER" ]; then
        USER_TO_ADD="$SUDO_USER"
    else
        # Fallback jika SUDO_USER tidak ada
        USER_TO_ADD=$(logname)
    fi

    if [ -z "$USER_TO_ADD" ]; then
        echo "Tidak dapat mendeteksi nama user Anda. Proses penambahan ke grup docker dilewati."
    else
        usermod -aG docker "$USER_TO_ADD"
        echo "User '$USER_TO_ADD' telah ditambahkan ke grup docker."
        echo "Agar perubahan ini efektif, Anda perlu logout dan login kembali,"
        echo "atau jalankan perintah berikut di terminal Anda: newgrp docker"
    fi
fi

echo ""
echo "✅ Instalasi Docker berhasil!"
echo "Verifikasi instalasi dengan menjalankan: docker run hello-world"
