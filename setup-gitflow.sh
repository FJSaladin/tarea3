#!/usr/bin/env bash
# =========================================================================
# setup-gitflow.sh
# Automatiza: 5 ramas feature/hotfix, cada una con 3 PRs cerrados
# (-> develop, -> qa, -> main). Requiere: git, gh (autenticado), repo ya
# creado en GitHub, y ramas main/develop/qa ya existentes en el remoto.
# =========================================================================
set -e

# --------- 1. Define aquí tus 5 ramas y qué archivo tocan -----------------
declare -a BRANCHES=(
  "feature/login-form"
  "feature/create-task"
  "feature/update-task"
  "feature/delete-task"
  "hotfix/fix-date-format"
)

# --------- Función para hacer el cambio real de código por rama ----------
apply_change () {
  local branch="$1"
  case "$branch" in
    "feature/login-form")
      mkdir -p public
      cat > public/login.html <<'EOF'
<!DOCTYPE html>
<html lang="es">
<head><meta charset="UTF-8"><title>Login</title></head>
<body>
  <h1>Iniciar sesión</h1>
  <form id="loginForm">
    <input type="text" placeholder="Usuario" required>
    <input type="password" placeholder="Contraseña" required>
    <button type="submit">Entrar</button>
  </form>
</body>
</html>
EOF
      ;;
    "feature/create-task")
      cat >> server.js <<'EOF'

app.post('/api/tasks', (req, res) => {
  const { title } = req.body;
  if (!title) return res.status(400).json({ error: 'title es requerido' });
  const task = { id: nextId++, title, done: false, createdAt: new Date().toISOString() };
  tasks.push(task);
  res.status(201).json(task);
});
EOF
      ;;
    "feature/update-task")
      cat >> server.js <<'EOF'

app.put('/api/tasks/:id', (req, res) => {
  const task = tasks.find(t => t.id === parseInt(req.params.id));
  if (!task) return res.status(404).json({ error: 'Tarea no encontrada' });
  Object.assign(task, req.body);
  res.json(task);
});
EOF
      ;;
    "feature/delete-task")
      cat >> server.js <<'EOF'

app.delete('/api/tasks/:id', (req, res) => {
  const before = tasks.length;
  tasks = tasks.filter(t => t.id !== parseInt(req.params.id));
  if (tasks.length === before) return res.status(404).json({ error: 'Tarea no encontrada' });
  res.status(204).send();
});
EOF
      ;;
    "hotfix/fix-date-format")
      cat >> public/app.js <<'EOF'

// Hotfix: formatear fecha en formato local dd/mm/aaaa
function formatearFecha(isoString) {
  const d = new Date(isoString);
  return d.toLocaleDateString('es-DO');
}
EOF
      ;;
  esac
}

# --------- 2. Función que crea una rama y hace las 3 PRs -----------------
process_branch () {
  local branch="$1"

  echo ""
  echo "=== Procesando rama: $branch ==="

  git checkout develop
  git pull origin develop
  git checkout -b "$branch"

  apply_change "$branch"

  git add -A
  git commit -m "feat: cambios de $branch"
  git push -u origin "$branch"

  # --- PR hacia develop ---
  gh pr create --base develop --head "$branch" \
    --title "$branch -> develop" \
    --body "Integración de $branch en develop." || true
  gh pr merge "$branch" --merge --delete-branch=false --admin || \
    gh pr merge "$branch" --merge --delete-branch=false

  # --- PR hacia qa (misma rama, ya con el cambio integrado) ---
  git checkout "$branch"
  git push -u origin "$branch"
  gh pr create --base qa --head "$branch" \
    --title "$branch -> qa" \
    --body "Promoción de $branch a QA." || true
  gh pr merge "$branch" --merge --delete-branch=false --admin || \
    gh pr merge "$branch" --merge --delete-branch=false

  # --- PR hacia main ---
  gh pr create --base main --head "$branch" \
    --title "$branch -> main" \
    --body "Release de $branch a producción (main)." || true
  gh pr merge "$branch" --merge --delete-branch=false --admin || \
    gh pr merge "$branch" --merge --delete-branch=false

  echo "=== $branch: 3 PRs creados y cerrados ==="
}

# --------- 3. Ejecutar para las 5 ramas ------------------------------------
for b in "${BRANCHES[@]}"; do
  process_branch "$b"
done

echo ""
echo "LISTO. Revisa con: gh pr list --state merged --limit 30"
