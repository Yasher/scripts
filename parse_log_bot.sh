#!/bin/bash
        continue
    fi

    echo
    echo "Файлы в /var/www/*/data/logs (отсортированы):"
    for i in "${!sorted_files[@]}"; do
        printf "%3d) %s\n" "$i" "${sorted_files[$i]}"
    done

    echo -n "Введите номер файла для анализа: "
    read sub_choice

    if ! [[ "$sub_choice" =~ ^[0-9]+$ ]] || [ "$sub_choice" -lt 0 ] || [ "$sub_choice" -ge "${#sorted_files[@]}" ]; then
        echo "Неверный номер."
        continue
    fi

    selected_file="${sorted_files[$sub_choice]}"
else
    selected_file="$selected_main"
fi

echo "Вы выбрали файл: $selected_file"
echo

# Определяем, сжатый ли файл
if [[ "$selected_file" == *.gz ]]; then
    grep_cmd="zgrep"
else
    grep_cmd="grep"
fi

# Команда анализа
if [[ "$selected_file" == *.gz ]]; then
    cmd="zcat \"$selected_file\" | awk '
    !/\" (403|444|410|429) / {
        line=tolower(\$0)

        while (match(line, /[a-z0-9.\/;+_-]*(bot|meta|facebook)[a-z0-9.\/;+_-]*/)) {
            token=substr(line, RSTART, RLENGTH)
            cnt[token]++
            line=substr(line, RSTART+RLENGTH)
        }
    }
    END {
        for (i in cnt)
            print cnt[i], i
    }' | sort -nr | head -20"
else
    cmd="awk '
    !/\" (403|444|410|429) / {
        line=tolower(\$0)

        while (match(line, /[a-z0-9.\/;+_-]*(bot|meta|facebook)[a-z0-9.\/;+_-]*/)) {
            token=substr(line, RSTART, RLENGTH)
            cnt[token]++
            line=substr(line, RSTART+RLENGTH)
        }
    }
    END {
        for (i in cnt)
            print cnt[i], i
    }' \"$selected_file\" | sort -nr | head -20"
fi
#if [[ "$selected_file" == *.gz ]]; then
#    cmd="zcat \"$selected_file\" \
#    | awk '\$9 !~ /^(403|444|410|429)$/' \
#    | grep -oiE '\\b[a-zA-Z0-9./;+_-]*(bot|meta|facebook)[a-zA-Z0-9./;+_-]*\\b' \
#    | sort | uniq -c | sort -nr | head -n20"
#else
#    cmd="awk '\$9 !~ /^(403|444|410|429)$/' \"$selected_file\" \
#    | grep -oiE '\\b[a-zA-Z0-9./;+_-]*(bot|meta|facebook)[a-zA-Z0-9./;+_-]*\\b' \
#    | sort | uniq -c | sort -nr | head -n20"
#fi

#cmd="$grep_cmd -oiE '\"[^\"]+\"' \"$selected_file\" | $grep_cmd -oiE '\\b[a-zA-Z0-9./;+_-]*(bot|meta|facebook)[a-zA-Z0-9./;+_-]*\\b' | sort | uniq -c | sort -nr | head -n20"

echo "Будет выполнена команда:"
echo "$cmd"
echo
echo "Результат:"
echo

# Выполняем команду
eval "$cmd"

echo
read -p "Нажмите Enter для возврата в меню..."
clear
done
