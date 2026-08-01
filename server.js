
app.post('/api/tasks', (req, res) => {
  const { title } = req.body;
  if (!title) return res.status(400).json({ error: 'title es requerido' });
  const task = { id: nextId++, title, done: false, createdAt: new Date().toISOString() };
  tasks.push(task);
  res.status(201).json(task);
});

app.put('/api/tasks/:id', (req, res) => {
  const task = tasks.find(t => t.id === parseInt(req.params.id));
  if (!task) return res.status(404).json({ error: 'Tarea no encontrada' });
  Object.assign(task, req.body);
  res.json(task);
});
