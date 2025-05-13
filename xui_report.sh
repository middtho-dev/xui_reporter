#!/bin/sh

BOT_TOKEN="6602514727:AAF7d2iEQmH5YbynKSZH-lPA9-BDUNmjphY"
CHAT_ID="382094545"
INSTALL_DIR="/usr/local/bin"
SEND_SCRIPT="$INSTALL_DIR/send_xui_report.sh"

print_menu() {
  echo "======== X-UI REPORTER ========"
  echo "1. Установить"
  echo "2. Удалить"
  echo "3. Выйти"
  echo "==============================="
  read -p "Выберите: " action
  case "$action" in
    1) run_install_interactive ;;
    2) run_uninstall ;;
    3) exit 0 ;;
    *) echo "❌ Неверный выбор"; exit 1 ;;
  esac
}

run_install_interactive() {
  read -p "Название сервера (например, vln.kv9.ru): " SERVER_NAME
  read -p "Задержка перед отправкой (в секундах): " DELAY
  install_script "$SERVER_NAME" "$DELAY"
}

run_install_args() {
  SERVER_NAME="$1"
  DELAY="$2"
  install_script "$SERVER_NAME" "$DELAY"
}

install_script() {
  local SERVER_NAME="$1"
  local DELAY="$2"

  mkdir -p "$INSTALL_DIR"

  cat > "$SEND_SCRIPT" <<EOF
#!/bin/sh
sleep $DELAY

send_file() {
  FILE="\$1"
  TITLE="\$2"
  BASENAME=\$(basename "\$FILE")
  [ -f "\$FILE" ] || return

  CAPTION="\$TITLE
🖥️ Сервер: $SERVER_NAME
📁 Файл: \$BASENAME"

  curl -s -F chat_id=$CHAT_ID \
       -F document=@"\$FILE" \
       -F "caption=\$CAPTION" \
       -F parse_mode=Markdown \
       https://api.telegram.org/bot$BOT_TOKEN/sendDocument > /dev/null
}

send_file "/usr/local/x-ui/bin/config.json" "⚙️ Конфигурация"
send_file "/usr/local/x-ui/access.log" "📜 Access Log"
send_file "/usr/local/x-ui/error.log" "❗ Error Log"
send_file "/etc/x-ui/x-ui.db" "💾 База данных"
EOF

  chmod +x "$SEND_SCRIPT"

  (crontab -l 2>/dev/null; echo "0 * * * * $SEND_SCRIPT") | grep -v "^$" | sort -u | crontab -

  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    -d parse_mode=Markdown \
    --data-urlencode "text=✅ Установлен агент на *$SERVER_NAME*
🕒 Задержка: ${DELAY}s" > /dev/null

  sh "$SEND_SCRIPT"
  echo "✅ Установка завершена."
}

run_uninstall() {
  crontab -l 2>/dev/null | grep -v "$SEND_SCRIPT" | crontab -
  rm -f "$SEND_SCRIPT"
  curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    -d chat_id="$CHAT_ID" \
    --data-urlencode "text=🗑️ Агент X-UI удалён с сервера" > /dev/null
  echo "✅ Удаление завершено."
}

# Аргументы командной строки
if [ -n "$1" ] && [ -n "$2" ]; then
  run_install_args "$1" "$2"
else
  print_menu
fi
