```bash
#!/usr/bin/env bash

# check and enable http/2
echo
if ! nginx -T 2>/dev/null |
    grep -v '^[[:space:]]*#' |
    grep -qP 'http2\s+on'; then

    read -r -p "Enable HTTP/2? [Y/n] " -n 1 REPLY
    echo

    if [[ ! $REPLY =~ ^([Nn]|т|Т)$ ]]; then

        # Try the modern syntax first: http2 on;
        grep -riIl '^[[:space:]]*#.*http2\s\+on' /etc/nginx/* 2>/dev/null |
            xargs -r sed -Ei 's/^[[:space:]]*#.*(http2\s+on)/\1/'

        sed -Ei 's/http2\s+off;/http2 on;/g' /etc/nginx/nginx.conf 2>/dev/null

        if ! grep -qP 'http2\s+on' /etc/nginx/nginx.conf 2>/dev/null; then
            sed -i '/^http\s*{/a \    http2 on;' /etc/nginx/nginx.conf 2>/dev/null
        fi

        if nginx -t 2>&1 | grep -q "emerg"; then
            echo "http2 on; failed, trying listen ... http2"

            sed -i '/^[[:space:]]*http2\s\+on;/d' /etc/nginx/nginx.conf

            grep -riIl 'listen\s\+[^;]*ssl' /etc/nginx/* 2>/dev/null |
                xargs -r sed -Ei '/http2/! s/(listen\s+[^;]*ssl)(\s*;)/\1 http2\2/'

            if nginx -t &>/dev/null; then
                systemctl restart nginx >/dev/null &&
                    echo "Result: OK (listen ... http2;)"
            else
                echo "Result: FAIL (nginx configuration test failed)"
            fi
        else
            if systemctl restart nginx >/dev/null; then
                echo "Result: OK (http2 on;)"
            else
                echo "Result: FAIL (nginx restart failed)"
            fi
        fi
    fi
fi


# check and disable tlsv1.3
echo
if nginx -T 2>/dev/null |
    grep -v '^[[:space:]]*#' |
    grep -qP 'ssl_protocols.*TLSv1\.3'; then

    read -r -p "Disable TLSv1.3? [Y/n] " -n 1 REPLY
    echo

    if [[ ! $REPLY =~ ^([Nn]|т|Т)$ ]]; then

        if nginx -t &>/dev/null; then
            if grep -riIl '^[[:space:]]*ssl_protocols.*TLSv1\.3' /etc/nginx/* 2>/dev/null |
                xargs -r sed -Ei '
                    /^[[:space:]]*#/! {
                        /TLSv1\.3/ {
                            h
                            s/^/#/
                            p
                            g
                            s/[[:space:]]*TLSv1\.3//g
                        }
                    }
                '; then

                if nginx -t &>/dev/null &&
                    systemctl restart nginx >/dev/null; then

                    echo -n "Result: "

                    if nginx -T 2>/dev/null |
                        grep -v '^[[:space:]]*#' |
                        grep -qP 'ssl_protocols.*TLSv1\.3'; then
                        echo "FAIL (TLSv1.3 still enabled)"
                    else
                        echo "OK (TLSv1.3 disabled)"
                    fi
                else
                    echo "Result: FAIL (nginx configuration test or restart failed)"
                fi
            fi
        fi
    fi
fi
```
