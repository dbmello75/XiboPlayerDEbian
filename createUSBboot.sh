#!/usr/bin/env bash
set -euo pipefail

EFI_MOUNT="/mnt/efi"
DATA_MOUNT="/mnt/debian"
ISO_MOUNT="/mnt/iso"
ESP_SIZE_MIB=100
BIOS_GRUB_SIZE_MIB=2

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Faltando comando: $1"; exit 1; }; }
for c in parted mkfs.vfat grub-install lsblk awk sed cp mount umount; do require_cmd "$c"; done

echo "=== Dispositivos removíveis detectados ==="
mapfile -t DEVICES < <(lsblk -dpno NAME,MODEL,SIZE,TRAN | grep -E "usb|removable")
if (( ${#DEVICES[@]} == 0 )); then
  echo "Nenhum pendrive detectado."
  exit 1
fi

for i in "${!DEVICES[@]}"; do
  printf "  %d) %s\n" "$((i+1))" "${DEVICES[$i]}"
done

choice_dev=""
while :; do
  read -rp "Escolha o dispositivo para formatar [1-${#DEVICES[@]}]: " choice_dev
  [[ "$choice_dev" =~ ^[0-9]+$ ]] && (( choice_dev>=1 && choice_dev<=${#DEVICES[@]} )) && break
  echo "Opção inválida."
done
DISK=$(echo "${DEVICES[$((choice_dev-1))]}" | awk '{print $1}')
echo ">> Dispositivo selecionado: $DISK"

echo "ATENÇÃO: Todos os dados em $DISK serão APAGADOS."
read -rp "Confirme digitando o nome do dispositivo ($DISK): " CONF
[[ "${CONF}" == "${DISK}" ]] || { echo "Abortado."; exit 1; }

# Seleção da ISO
shopt -s nullglob
mapfile -t ISOS < <(ls -1 *.iso 2>/dev/null || true)
if (( ${#ISOS[@]} == 0 )); then
  echo "Nenhum arquivo .iso encontrado no diretório atual."
  exit 1
fi

echo "=== ISOs disponíveis ==="
for i in "${!ISOS[@]}"; do
  printf "  %d) %s\n" "$((i+1))" "${ISOS[$i]}"
done

choice_iso=""
while :; do
  read -rp "Escolha a ISO [1-${#ISOS[@]}]: " choice_iso
  [[ "$choice_iso" =~ ^[0-9]+$ ]] && (( choice_iso>=1 && choice_iso<=${#ISOS[@]} )) && break
  echo "Opção inválida."
done
ISO_FILE="${ISOS[$((choice_iso-1))]}"
echo ">> ISO selecionada: ${ISO_FILE}"

# Desmontar montagens existentes
echo "Desmontando quaisquer partições montadas de $DISK..."
for p in $(lsblk -nrpo NAME,MOUNTPOINT "$DISK" | awk '$2!=""{print $1}'); do sudo umount -f "$p" || true; done

# Criar partições GPT (BIOS+UEFI)
sudo parted -s "$DISK" mklabel gpt
sudo parted -s "$DISK" mkpart primary 1MiB "$((1+BIOS_GRUB_SIZE_MIB))MiB"
sudo parted -s "$DISK" set 1 bios_grub on
START_ESP_MIB=$((1+BIOS_GRUB_SIZE_MIB))
END_ESP_MIB=$((START_ESP_MIB+ESP_SIZE_MIB))
sudo parted -s "$DISK" mkpart primary fat32 "${START_ESP_MIB}MiB" "${END_ESP_MIB}MiB"
sudo parted -s "$DISK" set 2 esp on
sudo parted -s "$DISK" mkpart primary fat32 "${END_ESP_MIB}MiB" 100%

ESP_PART="${DISK}2"
DATA_PART="${DISK}3"

# Formatar
sudo mkfs.vfat -F32 -n EFI "$ESP_PART"
sudo mkfs.vfat -F32 -n DEBIAN "$DATA_PART"

# Montar partições
sudo mkdir -p "$EFI_MOUNT" "$DATA_MOUNT" "$ISO_MOUNT"
sudo mount "$ESP_PART" "$EFI_MOUNT"
sudo mount "$DATA_PART" "$DATA_MOUNT"

# Copiar conteúdo da ISO
sudo mount -o loop "$ISO_FILE" "$ISO_MOUNT"
sudo cp -rT "$ISO_MOUNT" "$DATA_MOUNT"

# Instalar GRUB UEFI
sudo grub-install \
  --target=x86_64-efi \
  --efi-directory="$EFI_MOUNT" \
  --boot-directory="$DATA_MOUNT/boot" \
  --removable

# Instalar GRUB BIOS
sudo grub-install \
  --target=i386-pc \
  --boot-directory="$DATA_MOUNT/boot" \
  "$DISK"

# Criar grub.cfg
sudo mkdir -p "$DATA_MOUNT/boot/grub"
sudo tee "$DATA_MOUNT/boot/grub/grub.cfg" >/dev/null <<'EOF'
set timeout=5
set default=0

menuentry "Debian Live" {
    linux /live/vmlinuz boot=live
    initrd /live/initrd.img
}
EOF

# Desmontar ISO e EFI automaticamente
sudo umount "$ISO_MOUNT" || true
sudo umount "$EFI_MOUNT" || true

# Perguntar sobre desmontar /mnt/debian
read -rp "Deseja desmontar ${DATA_MOUNT}? [s/N]: " UM
case "${UM:-N}" in
  s|S|sim|SIM|y|Y|yes|YES)
    sudo umount "$DATA_MOUNT" || true
    echo "Desmontado ${DATA_MOUNT}."
    ;;
  *)
    echo "Mantendo ${DATA_MOUNT} montado."
    ;;
esac

echo "✅ Pendrive pronto (UEFI + BIOS)."
