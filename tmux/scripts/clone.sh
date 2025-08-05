#!/bin/env bash

cd ~/code || exit 1

# Leer nombre del repo
read -rp "Repo name (e.g. user/repo): " repo_input

# Construir URL
repo_url="https://github.com/${repo_input}"

# Obtener el nombre del repo sin .git
repo_name=$(basename -s .git "$repo_input")

# Mostrar la URL
echo "Repo URL: $repo_url"

# Clonar
git clone "$repo_url" || exit 1

# Ejecutar el cambio de sesión fuera del popup usando el cliente original
tmux run-shell "tmux switch-client -t '$repo_name'"

# Cerrar la popup saliendo del script
exit 0

