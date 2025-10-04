const express = require('express');
const router = express.Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

// Get all faculties
router.get('/', auth, async (req, res) => {
  const [rows] = await db.query('SELECT * FROM faculties');
  res.json(rows);
});

// Get tracks by faculty
router.get('/:facultyId/tracks', auth, async (req, res) => {
  const { facultyId } = req.params;
  const [rows] = await db.query('SELECT * FROM tracks WHERE faculty_id = ?', [facultyId]);
  res.json(rows);
});

// Get curriculums by track
router.get('/track/:trackId/curriculums', auth, async (req, res) => {
  const { trackId } = req.params;
  const [rows] = await db.query('SELECT * FROM curriculums WHERE track_id = ?', [trackId]);
  res.json(rows);
});

// Get years
router.get('/years', auth, async (req, res) => {
  const [rows] = await db.query('SELECT * FROM years');
  res.json(rows);
});

module.exports = router;
