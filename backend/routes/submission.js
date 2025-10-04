const express = require('express');
const router = express.Router();
const db = require('../config/db');
const auth = require('../middleware/auth');

// Add submission with outcomes
router.post('/', auth, async (req, res) => {
  const { faculty_id, track_id, curriculum_id, year_id, outcomes } = req.body;

  const [result] = await db.query(
    'INSERT INTO submissions (user_id, faculty_id, track_id, curriculum_id, year_id) VALUES (?, ?, ?, ?, ?)',
    [req.user.id, faculty_id, track_id, curriculum_id, year_id]
  );

  const submissionId = result.insertId;

  for (const o of outcomes) {
    await db.query(
      'INSERT INTO outcomes (submission_id, level, verb, object_text, qualifier) VALUES (?, ?, ?, ?, ?)',
      [submissionId, o.level, o.verb, o.object, o.qualifier || null]
    );
  }

  res.json({ message: 'Submission added' });
});

module.exports = router;
