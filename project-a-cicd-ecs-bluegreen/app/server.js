const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

app.get('/health', (req, res) => res.status(200).json({ ok: true }));
app.get('/', (req, res) => res.json({ message: 'Hello from ECS blue/green demo!' }));

app.listen(port, () => console.log(`Server listening on ${port}`));
