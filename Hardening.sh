#!/usr/bin/env bash

# ------------------------------------------------------------------
#     Hardening – Wrapper sencillo
#   • Da permisos +x a todos los *.sh
#   • Ejecuta o audita todos los scripts de cada bloque
#   • Registra resultados en Hardening.log
# ------------------------------------------------------------------
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${BASE_DIR}/Hardening.log"

# Colores opcionales
G="\e[32m"; R="\e[31m"; NC="\e[0m"; LIGHT_BLUE="\e[94m";

ensure_root() { [[ $EUID -eq 0 ]] || { echo -e "${R}Ejecutar como root${NC}"; exit 1; }; }

log_line() { echo "$*" | tee -a "$LOG_FILE"; }

chmod_all() {
  echo "→ Asignando permisos +x a todos los *.sh ..."
  find "$BASE_DIR" -type f -name '*.sh' -exec chmod +x {} +
}

run_all() {
  local mode="$1"            # exec  | audit
  local flag=""
  [[ $mode == "audit" ]] && flag="--dry-run"

  for bloque in "$BASE_DIR"/Bloque*/; do
    [[ -d $bloque ]] || continue
    local bname; bname="$(basename "$bloque")"

    for script in "$bloque"/*.sh; do
      [[ -e $script ]] || continue
      local sname; sname="$(basename "$script")"

      local out err
      out=$(mktemp); err=$(mktemp)
      if "$script" $flag >"$out" 2>"$err"; then
        log_line "${bname} | ${sname} | OK |"
        echo -e "${G}${bname}/${sname} OK${NC}"
      else
        local msg; msg=$(head -1 "$err")
        log_line "${bname} | ${sname} | FAIL | ${msg}"
        echo -e "${R}${bname}/${sname} FAIL${NC}"
      fi
      rm -f "$out" "$err"
    done
  done
}

ver_log_general() {
  echo -e "${LIGHT_BLUE}\n=== Mostrando log general: Hardening.log ===${NC}"
  if [[ -f "$LOG_FILE" ]]; then
    less "$LOG_FILE"
  else
    echo -e "${R}No se encontró el archivo de log general: $LOG_FILE${NC}"
  fi
}

ver_logs_por_bloque() {
  echo -e "${LIGHT_BLUE}\n=== Ver logs por bloque ===${NC}"

  local bloques=()
  for logdir in "$BASE_DIR"/Bloque*/Log; do
    [[ -d "$logdir" ]] && bloques+=("$(basename "$(dirname "$logdir")")")
  done

  if [[ ${#bloques[@]} -eq 0 ]]; then
    echo -e "${R}No se encontraron bloques con carpeta Log.${NC}"
    return
  fi

  PS3=$'\nSeleccione un bloque para ver sus logs (o 0 para volver): '
  select bloque in "${bloques[@]}"; do
    if [[ -z "$bloque" ]]; then
      echo "Volviendo..."
      return
    fi

    local log_dir="$BASE_DIR/$bloque/Log"
    local log_files=("$log_dir"/*.log)

    if [[ ! -e "${log_files[0]}" ]]; then
      echo -e "${R}No hay logs en ${log_dir}.${NC}"
      return
    fi

    echo -e "${LIGHT_BLUE}\nLogs disponibles en ${bloque}/Log:${NC}"
    PS3=$'\nSeleccione un log para ver (o 0 para volver): '
    select log_file in "${log_files[@]}"; do
      if [[ -z "$log_file" ]]; then
        echo "Volviendo..."
        return
      fi

      echo -e "${LIGHT_BLUE}\nMostrando: $log_file${NC}"
      less "$log_file"
      break
    done

    break
  done
}

welcome_screen() {
  clear
  echo -e "${LIGHT_BLUE}"
  cat << "EOF"
     ███████╗███╗   ███╗ ██╗ ██╗████████╗
     ██╔════╝████╗ ████║ ██║██╔╝╚══██╔══╝
     █████╗  ██╔████╔██║ █████╔╝   ██║
     ██╔══╝  ██║╚██╔╝██║ ██╔═██╗   ██║
     ██╗     ██║ ╚═╝ ██║ ██║  ██╗  ██║
     ╚═╝     ╚═╝     ╚═╝ ╚═╝  ╚═╝  ╚═╝

    F I D E L I T Y   M A R K E T I N G
                   2025

********************************************
* Authorized Access Only                   *
* All activity is monitored and logged.    *
* Disconnect immediately if unauthorized.  *
********************************************
EOF
  echo -e "${NC}"
}

### MAIN LOOP ###
ensure_root
chmod_all

while true; do
  welcome_screen
  echo -e "Hardening wrapper listo.\n"

  PS3=$'\nSeleccione una opción: '
  select opt in "Ejecutar" "Auditar" "Ver log general" "Ver logs por bloque" "Salir"; do
    case $REPLY in
      1)
        run_all "exec"
        echo -e "${R}\n### Reinicie el sistema de forma manual para impactar cambios ###${NC}"
        break ;;
      2)
        run_all "audit"
        break ;;
      3)
        ver_log_general
        break ;;
      4)
        ver_logs_por_bloque
        break ;;
      5)
        exit 0 ;;
      *)
        echo "Opción inválida" ;;
    esac
  done

  read -rp $'\nPresione Enter para volver al menú...'
done
