const express = require('express');
const router = express.Router();
const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');


router.post('/signup', async (req, res) => {
  const { username, password, name_ar, role = 'professor', email = '' } = req.body;

  if (!username || !password || !name_ar) {
    return res.status(400).json({ message: 'Missing required fields' });
  }

  const [existing] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
  if (existing.length) return res.status(400).json({ message: 'Username exists' });

  const hashed = await bcrypt.hash(password, 10);
  await db.query(
    'INSERT INTO users (username, password, name_ar, role, email) VALUES (?, ?, ?, ?, ?)',
    [username, hashed, name_ar, role, email]
  );

  res.json({ message: 'User created' });
});



router.post('/login', async (req, res) => {
  const { username, password } = req.body;
  const [rows] = await db.query('SELECT * FROM users WHERE username = ?', [username]);
  if (!rows.length) return res.status(400).json({ message: 'User not found' });

  const valid = await bcrypt.compare(password, rows[0].password);
  if (!valid) return res.status(400).json({ message: 'Wrong password' });

  const token = jwt.sign({ id: rows[0].id, username }, 'your_jwt_secret', { expiresIn: '1d' });
  res.json({ token });
});

module.exports = router;
