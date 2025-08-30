#!/usr/bin/env bash
set -euo pipefail

# ========= Config =========
USB_LABEL="XiboPlayer"
FILES_LIST="FilesToSync.txt"
ZIP_NAME="XiboInstall.zip"
# =========================

# Cores (opcional)
cyan(){ printf "\033[36m%s\033[0m\n" "$*"; }
green(){ printf "\033[32m%s\033[0m\n" "$*"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$*"; }
red(){ printf "\033[31m%s\033[0m\n" "$*"; }

# Diretório do script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FILES_LIST_PATH="${SCRIPT_DIR}/${FILES_LIST}"
ZIP_PATH="${SCRIPT_DIR}/${ZIP_NAME}"

# Verifica lista
cyan "Checking for ${FILES_LIST_PATH}..."
if [[ ! -f "${FILES_LIST_PATH}" ]]; then
  red "File not found: ${FILES_LIST_PATH}"
  exit 1
fi
green "Files to sync found."

# Lê lista (ignora linhas vazias e comentários)
mapfile -t FILES < <(grep -vE '^\s*($|#)' "${FILES_LIST_PATH}" || true)

# Cria ZIP preservando caminhos relativos
cyan "Creating ZIP file..."
rm -f "${ZIP_PATH}"

# Estratégia: entrar no SCRIPT_DIR e zipar os caminhos relativos que estão na lista
(
  cd "${SCRIPT_DIR}"
  # Valida cada item; avisa se não existir
  MISSING=0
  for f in "${FILES[@]}"; do
    if [[ ! -e "${f}" ]]; then
      yellow "File not found: ${f}"
      MISSING=1
    fi
  done

  # Zip -r preservando hierarquia a partir do SCRIPT_DIR
  # Usa xargs para lidar com espaços
  printf '%s\n' "${FILES[@]}" | zip -r -@ "${ZIP_PATH##*/}" >/dev/null
)
green "ZIP file created: ${ZIP_PATH}"

# Localiza ponto de montagem do USB pelo label
cyan "Looking for USB labeled '${USB_LABEL}'..."

# Tenta obter mountpoint via findmnt (mais robusto)
USB_MNT="$(findmnt -no TARGET -S "LABEL=${USB_LABEL}" 2>/dev/null || true)"

# Se não montado, tenta achar dispositivo e montar
if [[ -z "${USB_MNT}" ]]; then
  # Procura dispositivo por label via /dev/disk/by-label
  if [[ -L "/dev/disk/by-label/${USB_LABEL}" ]]; then
    DEV="$(readlink -f "/dev/disk/by-label/${USB_LABEL}")"
    MNT="/media/${USER:-root}/${USB_LABEL}"
    cyan "USB not mounted. Will try to mount ${DEV} at ${MNT} (requires sudo)."
    sudo mkdir -p "${MNT}"
    sudo mount "${DEV}" "${MNT}"
    USB_MNT="${MNT}"
  else
    # Plano B: tenta lsblk
    DEV="$(lsblk -rpno NAME,LABEL | awk -v L="${USB_LABEL}" '$2==L{print $1; exit}')"
    if [[ -n "${DEV}" ]]; then
      MNT="/media/${USER:-root}/${USB_LABEL}"
      cyan "USB not mounted. Will try to mount ${DEV} at ${MNT} (requires sudo)."
      sudo mkdir -p "${MNT}"
      sudo mount "${DEV}" "${MNT}"
      USB_MNT="${MNT}"
    fi
  fi
fi

if [[ -z "${USB_MNT}" ]]; then
  red "USB drive with label '${USB_LABEL}' not found!"
  exit 2
fi
green "USB found at: ${USB_MNT}"

# Copia o ZIP para o USB
ZIP_DST="${USB_MNT}/$(basename "${ZIP_PATH}")"
cyan "Copying ZIP to USB..."
cp -f "${ZIP_PATH}" "${ZIP_DST}"
green "ZIP file copied to: ${ZIP_DST}"

# Extrai no raiz do USB
cyan "Extracting ZIP to USB root..."
unzip -o "${ZIP_DST}" -d "${USB_MNT}" >/dev/null
green "ZIP extracted to: ${USB_MNT}"

cyan "Done."
