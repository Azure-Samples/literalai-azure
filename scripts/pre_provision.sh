 #!/bin/sh

echo "Checking if authentication should be setup..."

. ./scripts/load_env.sh

if [ -z "$AZURE_USE_AUTHENTICATION" ]; then
  echo "AZURE_USE_AUTHENTICATION is not set, skipping authentication setup."
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
$PYTHON ./scripts/pre_provision.py