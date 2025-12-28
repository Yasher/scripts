#!/bin/bash

#S3CFG="$HOME/.s3cfg"

S3CFG="${S3CMD_CONFIG:-/tmp/s3cfg-${USER}-$$}"
export S3CMD_CONFIG="$S3CFG"

get_access_key_from_cfg() {
    grep -E '^access_key\s*=' "$S3CFG" | awk -F= '{gsub(/ /,"",$2); print $2}'
}

login_s3() {
    if [[ -f "$S3CFG" ]]; then
        ACCESS_KEY=$(get_access_key_from_cfg)
        if [[ -z "$ACCESS_KEY" ]]; then
            echo "❌ Не удалось прочитать access_key из $S3CFG"
            exit 1
        fi
        return
    fi

    echo "🔐 s3cmd не настроен. Выполняется вход."

    printf "ACCESS_KEY: "
    read -r ACCESS_KEY

    printf "SECRET_KEY: "
    read -rs SECRET_KEY
    echo

    if [[ -z "$ACCESS_KEY" || -z "$SECRET_KEY" ]]; then
        echo "❌ ACCESS_KEY или SECRET_KEY пустые"
        exit 1
    fi

    s3cmd \
      --access_key="$ACCESS_KEY" \
      --secret_key="$SECRET_KEY" \
      --host=https://s3.hoztnode.net \
      --host-bucket="https://s3.hoztnode.net/%(bucket)" \
      --dump-config > "$S3CFG"

    chmod 600 "$S3CFG"

    echo "✅ Конфигурация s3cmd сохранена в $S3CFG"
}

# --- LOGIN ---
login_s3

# --- BUCKET from ACCESS_KEY ---

BUCKET_NAME="${ACCESS_KEY//_/-}"
BUCKET="s3://$BUCKET_NAME/$ACCESS_KEY"

print_with_size() {
    s3cmd -c "$S3CFG" ls "$BUCKET/" | awk '/DIR/ {print $2}' | while read -r dir; do
        total_size=$(s3cmd -c "$S3CFG" ls "$dir" 2>/dev/null | \
            awk '$4 ~ /\/F/ {sum += $3} END {printf "%.0f", sum}')

        if [ "$total_size" -gt 0 ]; then
            echo -n "$dir "
            numfmt --to=iec --suffix=B "$total_size"
        fi
    done
}

print_without_size_fast() {
    s3cmd -c "$S3CFG" ls -r "$BUCKET/" 2>/dev/null \
    | awk '$4 ~ /\/F/ {
        sub(/\/[^/]+$/, "/", $4)
        print $4
    }' | sort -u
}

delete_menu() {
    read -rp "Введите директорию для удаления (YYYY-MM-DD/): " START_DIR
    [[ -z "$START_DIR" ]] && return

    mapfile -t DIRS < <(
        s3cmd -c "$S3CFG" ls "$BUCKET/" | awk '/DIR/ {print $2}' | sed "s|$BUCKET/||" | sort
    )

    FOUND=false
    DELETE_DIRS=()

    for DIR in "${DIRS[@]}"; do
        [[ "$DIR" == "$START_DIR" ]] && FOUND=true
        $FOUND || continue

        FILES=$(s3cmd -c "$S3CFG" ls "$BUCKET/$DIR" 2>/dev/null | awk '{print $4}')

        HAS_I=$(echo "$FILES" | grep -q '/I' && echo yes || echo no)
        HAS_F=$(echo "$FILES" | grep -q '/F' && echo yes || echo no)

        if [[ "$DIR" == "$START_DIR" ]]; then
            if [[ "$HAS_I" == yes && "$HAS_F" == no ]]; then
                DELETE_DIRS+=("$DIR")
                break
            fi
            if [[ "$HAS_F" == yes ]]; then
                DELETE_DIRS+=("$DIR")
                continue
            fi
        else
            if [[ "$HAS_F" == yes ]]; then
                break
            fi
            if [[ "$HAS_I" == yes ]]; then
                DELETE_DIRS+=("$DIR")
            fi
        fi
    done

    if [[ ${#DELETE_DIRS[@]} -eq 0 ]]; then
        echo "Нечего удалять"
        return
    fi

    echo
    echo "⚠️ Будут удалены директории:"
    for d in "${DELETE_DIRS[@]}"; do
        echo "$BUCKET/$d"
    done

    echo
    read -rp "Подтвердите удаление (YES): " CONFIRM
    [[ "$CONFIRM" != "YES" ]] && echo "Отмена" && return

    echo
    for d in "${DELETE_DIRS[@]}"; do
        echo "Удаляется $BUCKET/$d"
        s3cmd -c "$S3CFG" del --recursive "$BUCKET/$d"
    done

    echo "✅ Удаление завершено"
}




print_dirs_with_type() {
    # Цвета
    if [[ -t 1 ]]; then
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        NC='\033[0m'
    else
        GREEN=''
        YELLOW=''
        NC=''
    fi

    s3cmd -c "$S3CFG" ls -r "$BUCKET/" 2>/dev/null | \
    awk -v GREEN="$GREEN" -v YELLOW="$YELLOW" -v NC="$NC" '
    {
        path = $4
        if (path !~ /\/[^\/]+$/) next

        # YYYY-MM-DD/
        sub(/\/[^\/]+$/, "/", path)

        if ($4 ~ /\/F/) hasF[path] = 1
        if ($4 ~ /\/I/) hasI[path] = 1
        dirs[path] = 1
    }
    END {
        for (d in dirs) {
            if (hasF[d]) {
                type="full"
                color=GREEN
                prefix=""
            } else if (hasI[d]) {
                type="diff"
                color=YELLOW
                prefix="\t"
            } else {
                continue
            }

            printf "%s%60s  -  %s%s%s\n", prefix, d, color, type, NC
        }
    }' | sort
}


while true; do
    echo
    echo "BUCKET: $BUCKET"
    echo
    echo "Выбери режим:"
    echo "1) Полные"
    echo "2) Все"
    echo "3) Полные (объем)"
    echo "4) Удаление"
    echo "5) Выход"
    read -rp "Введите номер: " choice

    case "$choice" in
        1) print_without_size_fast ;;
        2) print_dirs_with_type ;;
        3) print_with_size ;;
        4) delete_menu ;;
        5) exit 0 ;;
        *) echo "Неверный выбор" ;;
    esac
done
