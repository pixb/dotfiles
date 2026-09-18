#!/bin/bash

# 等待 compositor 就绪
for i in $(seq 1 50); do
    if wlr-randr >/dev/null 2>&1; then
        break
    fi
    sleep 0.1
done

# 获取所有输出并设置镜像模式（相同分辨率，相同位置）
OUTPUTS=$(wlr-randr 2>/dev/null | grep -E "^[A-Z]" | awk '{print $1}')
if [ -n "$OUTPUTS" ]; then
    FIRST=$(echo "$OUTPUTS" | head -1)
    MODE=$(wlr-randr --output "$FIRST" 2>/dev/null | grep -E "^\s+[0-9]+x" | head -1 | awk '{print $1}')
    for output in $OUTPUTS; do
        wlr-randr --output "$output" --mode "$MODE" --pos 0,0 2>/dev/null
    done
fi

exec gtkgreet -s /etc/greetd/gtkgreet.css -b /etc/greetd/background.jpg
