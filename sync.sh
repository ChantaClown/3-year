if [[thatversion]] > [[thisversion]]; then
    git fecht && git pull
else [[ -n "$string" ]]; then
    echo "Origin version is older, no pulled files."
fi