#!/bin/bash

# ==========================================
# SCRIPT DE INSTALAÇÃO AUTOMATIZADA ARCH LINUX
# Configuração: UEFI, Hyprland, ZRAM, GRUB
# ==========================================

# Para parar o script caso ocorra algum erro
set -e

# Variáveis de Configuração
DISK="/dev/nvme0n1"
HOSTNAME="ls"
USERNAME="ls"
PASSWORD="1234"
ZRAM_SIZE="6144" # 6GB

echo "========================================"
echo " INICIANDO INSTALAÇÃO EM $DISK"
echo " USUÁRIO: $USERNAME | HOSTNAME: $HOSTNAME"
echo "========================================"

# 1. LIMPEZA E PARTICIONAMENTO
# ------------------------------------------
echo ">>> Limpando e particionando o disco..."
umount -R /mnt 2>/dev/null || true
wipefs -a "$DISK"

# Criar tabela GPT
parted -s "$DISK" mklabel gpt

# Partição 1: EFI (512MB)
parted -s "$DISK" mkpart "EFI" fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on

# Partição 2: ROOT (Restante)
parted -s "$DISK" mkpart "ROOT" ext4 513MiB 100%

# 2. FORMATAÇÃO E MONTAGEM
# ------------------------------------------
echo ">>> Formatando partições..."
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 -F "${DISK}p2"

echo ">>> Montando partições..."
mount "${DISK}p2" /mnt
mkdir -p /mnt/boot/efi
mount "${DISK}p1" /mnt/boot/efi

# 3. INSTALAÇÃO DO SISTEMA BASE
# ------------------------------------------
echo ">>> Instalando pacotes base e Hyprland..."
# Inclui base, kernel, network, editor, bootloader, zram e interface gráfica
pacstrap /mnt base linux linux-firmware base-devel git networkmanager \
    nano vim grub efibootmgr zram-generator \
    hyprland kitty ttf-dejavu

# 4. GERAR FSTAB
# ------------------------------------------
echo ">>> Gerando Fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# 5. CONFIGURAÇÃO INTERNA (CHROOT)
# ------------------------------------------
# Criamos um script temporário dentro do /mnt para rodar as configs internas
echo ">>> Configurando o sistema..."

cat <<EOF > /mnt/setup_system.sh
#!/bin/bash

# Fuso Horário e Relógio
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

# Localização (pt_BR)
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf

# Rede e Hostname
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Configurar Senha de Root
echo "root:$PASSWORD" | chpasswd

# Criar Usuário e Senha
useradd -m -g users -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Habilitar Sudo para o grupo wheel
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Instalar e Configurar GRUB (Bootloader)
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Arch
grub-mkconfig -o /boot/grub/grub.cfg

# Habilitar Serviços
systemctl enable NetworkManager

# Configurar ZRAM (6GB)
echo "[zram0]" > /etc/systemd/zram-generator.conf
echo "zram-size = $ZRAM_SIZE" >> /etc/systemd/zram-generator.conf
echo "compression-algorithm = zstd" >> /etc/systemd/zram-generator.conf

EOF

# 6. EXECUTAR CONFIGURAÇÃO E FINALIZAR
# ------------------------------------------
chmod +x /mnt/setup_system.sh
arch-chroot /mnt ./setup_system.sh

# Limpar script temporário
rm /mnt/setup_system.sh

echo "========================================"
echo " INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
echo " O sistema irá reiniciar automaticamente."
echo "========================================"
sleep 2

umount -R /mnt
reboot
