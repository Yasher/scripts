#!/usr/bin/env bash
set -euo pipefail

# Найдём exim/exim4
EXIM_BIN="$(command -v exim || command -v exim4 || true)"
if [[ -z "${EXIM_BIN}" ]]; then
  echo "Ошибка: exim/exim4 не найден в PATH" >&2
  exit 1
fi

# Временный список всех отправителей (одна строка — один адрес)
TMP_SENDERS="$(mktemp)"
trap 'rm -f "$TMP_SENDERS"' EXIT

# 1) Собираем (msgid, sender) из очереди
#   Формат главной строки: "<age> <size> <msgid> <sender>"
#   Берём предпоследнее поле как msgid и последнее — как sender.
mapfile -t LINES < <(
  "${EXIM_BIN}" -bp 2>/dev/null \
  | awk '/^[[:space:]]*[0-9]+[smhd]/{print $(NF-1) "\t" $NF}'
)

# Хелпер: извлечь реального отправителя из вложенных заголовков письма
get_real_sender() {
  local mid="$1"
  # Ищем внутри секции "Content-type: text/rfc822-headers"
  # сначала Return-path, потом Sender, потом From
  "${EXIM_BIN}" -Mvb "$mid" 2>/dev/null \
  | awk '
      BEGIN{inpart=0}
      /^Content-type:[[:space:]]*text\/rfc822-headers([;]|$)/{inpart=1; next}
      inpart && /^--/{inpart=0}        # вышли из части
      inpart {
        l=tolower($0)
        if (l ~ /^return-path:/) {print $0; exit}
        if (l ~ /^sender:/)       {print $0; exit}
        if (l ~ /^from:/)         {print $0; exit}
      }
    ' \
  | sed -E '
      s/^[^:]*:[[:space:]]*//;        # отрезать "Return-path:" / "From:" / "Sender:"
      s/.*<([^>]+)>.*/\1/; t          # вытащить адрес из <...> если есть
      s/^[[:space:]]+|[[:space:]]+$//g
    ' \
  | awk 'NF>0{print; exit}'
}

# 2) Проходимся по сообщениям: нормальные отправители — как есть,
#    у "<>" пытаемся достать реального автора
for line in "${LINES[@]}"; do
  msgid="${line%%$'\t'*}"
  sender="${line#*$'\t'}"

  # Уберём угловые скобки, если вдруг остались
  sender="${sender//</}"
  sender="${sender//>/}"

  if [[ -z "${sender}" || "${sender}" == "<>" || "${sender}" == "@" || "${sender}" == "MAILER-DAEMON" ]]; then
    real="$(get_real_sender "$msgid" || true)"
    if [[ -n "${real:-}" ]]; then
      echo "${real}" >> "$TMP_SENDERS"
    else
      echo "bounce (empty)" >> "$TMP_SENDERS"
    fi
  else
    echo "${sender}" >> "$TMP_SENDERS"
  fi
done

# 3) Группировка и сортировка
# (нормализуем регистр у доменов для красоты)
awk '
  {
    split($0, a, "@");
    if (length(a)==2) {
      localpart=a[1]; domain=tolower(a[2]);
      print localpart "@" domain
    } else {
      print $0
    }
  }
' "$TMP_SENDERS" \
| sort \
| uniq -c \
| sort -nr
