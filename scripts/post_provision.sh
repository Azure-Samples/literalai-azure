 #!/bin/sh

. ./scripts/load_env.sh

# Echo the value of SERVICE_APP_URI
echo "Container app deployed at: $SERVICE_APP_URI"

if [ -z "$AZURE_USE_AUTHENTICATION" ]; then
  exit 0
fi

find_python() {
    if command -v python3 &>/dev/null; then
        echo "python3"
    elif command -v python &>/dev/null; then
        echo "python"
    else
        echo "Python is not installed" >&2
        exit 1
    fi
}

PYTHON=$(find_python)
$PYTHON ./scripts/post_provision.py