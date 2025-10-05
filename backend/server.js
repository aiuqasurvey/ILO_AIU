require('dotenv').config();
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const bcrypt = require('bcrypt');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

if (!process.env.DB_PATH) {
  console.error(' DB_PATH is not defined in .env file');
  process.exit(1);
}

const whitelist = [
  'http://localhost:5173', 
  'http://127.0.0.1:5173',
  'https://ilo-aiu-web.onrender.com'
];

const corsOptions = {
  origin: function (origin, callback) {
    console.log('CORS check for origin:', origin);

    if (!origin || whitelist.includes(origin)) {
      callback(null, true);
    } else if (origin.startsWith('http://localhost:')) {
      // Allow any localhost port
      callback(null, true);
    } else {
      console.warn('CORS blocked:', origin);
      callback(null, false); // never crash
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};


app.use(cors(corsOptions));

// Handle preflight requests globally
app.options('*', cors(corsOptions), (req, res) => {
  res.sendStatus(200);
});


app.use(cors(corsOptions));
app.options('*', cors(corsOptions), (req, res) => {
  res.sendStatus(200);
});
app.use((req, res, next) => {
  console.log('Request origin:', req.headers.origin);
  next();
});

// -------------------- MIDDLEWARES -------------------- //
app.use(express.json());

app.use(cors({ origin: true, credentials: true }));


// -------------------- DATABASE -------------------- //
const dbPath = path.resolve(__dirname, process.env.DB_PATH);
console.log('DB_PATH from .env:', process.env.DB_PATH);

const db = new sqlite3.Database(dbPath, (err) => {
  if (err) console.error(' Failed to connect to database:', err.message);
  else console.log('Connected to SQLite database.');
});

// Helpers
function runAsync(query, params = []) {
  return new Promise((resolve, reject) => {
    db.run(query, params, function (err) {
      if (err) reject(err);
      else resolve({ lastID: this.lastID, changes: this.changes });
    });
  });
}

function allAsync(query, params = []) {
  return new Promise((resolve, reject) => {
    db.all(query, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
}

app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ error: err.message || 'Internal Server Error' });
});

// -------------------- ROUTES -------------------- //
// Example: test route
app.get('/api/test', (req, res) => {
  res.json({ message: 'CORS works!', origin: req.headers.origin });
});
// -------------------- GET ROUTES -------------------- //

// Get all faculties
app.get('/api/faculties', (req, res) => {
  db.all('SELECT * FROM faculties', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// Get tracks by faculty ID
app.get('/api/tracks/:facultyId', (req, res) => {
  const { facultyId } = req.params;
  db.all('SELECT * FROM tracks WHERE faculty_id = ?', [facultyId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});
app.get('/api/curriculums', async (req, res) => {
  try {
    const rows = await allAsync('SELECT * FROM curriculums');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


// Get curriculums by track ID
app.get('/api/curriculums/:trackId', (req, res) => {
  const { trackId } = req.params;
  db.all('SELECT * FROM curriculums WHERE track_id = ?', [trackId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// Add a curriculum 
app.post('/api/add-curriculum', (req, res) => {
  const {
    track_id,
    name,         
    curriculum_code,
    curr_period,
    total_hours,
    lecture_hours,
    lab_hours,
    prerequisites
  } = req.body;

  if (!track_id || !name || !curriculum_code || !curr_period || !total_hours) {
    return res.status(400).json({ error: 'حقل مطلوب مفقود' });
  }

  db.run(
    `INSERT INTO curriculums 
     (track_id, name, curriculum_code, curr_period, total_hours, lecture_hours, lab_hours, prerequisites)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      track_id,
      name,
      curriculum_code,
      curr_period,
      total_hours,
      lecture_hours || 0,
      lab_hours || 0,
      prerequisites || 'none'
    ],
    function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({ message: 'تم إضافة المقرر', curriculumId: this.lastID });
    }
  );
});


// Get all professors
app.get('/api/professors', (req, res) => {
  db.all('SELECT * FROM users WHERE role = "professor"', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// Get all users
app.get('/api/users', (req, res) => {
  db.all('SELECT * FROM users', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

// get all bloom levels
app.get('/api/bloom-levels', (req, res) => {
  console.log('GET /api/bloom-levels called from', req.ip, 'headers:', req.headers.origin);
  db.all(`SELECT bloom_level_id, bloom_level_name FROM bloom_levels`, [], (err, rows) => {
    if (err) {
      console.error('DB error getting bloom-levels:', err);
      return res.status(500).json({ error: err.message });
    }
    console.log('DB rows for bloom-levels:', rows);
    const mapped = rows.map(r => ({ bloom_level_id: r.bloom_level_id, name: r.bloom_level_name }));
    console.log('Mapped response:', mapped);
    res.json(mapped);
  });
});



// Get all verbs
app.get('/api/verbs', (req, res) => {
  db.all('SELECT verb_id, verb_name, bloom_level_id FROM verbs', [], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

app.get('/api/verbs/:bloomLevelId', (req, res) => {
  const { bloomLevelId } = req.params;
  db.all(
    `SELECT verb_id, verb_name FROM verbs WHERE bloom_level_id = ?`,
    [bloomLevelId],
    (err, rows) => {
      if (err) return res.status(500).json({ error: err.message });

      console.log("Raw rows from DB:", rows); 

      const mapped = rows.map(r => ({
        verb_id: r.verb_id,
        name: r.verb_name
      }));

      console.log("Mapped rows:", mapped);
      res.json(mapped);
    }
  );
});



// -------------------- AUTH -------------------- //

// Signup
app.post('/api/signup', async (req, res) => {
  const { username, password, professorName, email } = req.body;
  if (!username || !password || !professorName || !email) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  db.get('SELECT * FROM users WHERE username = ? OR email = ?', [username, email], async (err, user) => {
    if (user) return res.status(400).json({ error: 'Username or email exists' });

    const hashed = await bcrypt.hash(password, 10);
    db.run(
      'INSERT INTO users (username, name, email, password, role) VALUES (?, ?, ?, ?, ?)',
      [username, professorName, email, hashed, 'professor'],
      function(err) {
        if (err) return res.status(500).json({ error: err.message });

        // Link to professors table
        db.run(
          'INSERT INTO professors (name, users_id, users_name) VALUES (?, ?, ?)',
          [professorName, this.lastID.toString(), username],
          function(err2) {
            if (err2) return res.status(500).json({ error: err2.message });
            res.status(201).json({ message: 'User and professor registered', userId: this.lastID });
          }
        );
      }
    );
  });
});

//login
app.post('/api/login', (req, res) => {
  const { email, password } = req.body || {};

  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }

  db.get('SELECT * FROM users WHERE email = ?', [email], async (err, user) => {
    if (err) return res.status(500).json({ error: 'Database error' });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.status(401).json({ error: 'Invalid credentials' });

    res.json({ message: 'Login successful', userId: user.id, name: user.name, role: user.role });
  });
});




// -------------------- CURRICULUMS -------------------- //

app.post('/api/add-curriculum', (req, res) => {
  const {
    track_id,
    curr_name,
    curriculum_code,
    curr_period,
    total_hours,
    lecture_hours,
    lab_hours,
    prerequisites
  } = req.body;

  if (!track_id || !curr_name || !curriculum_code || !curr_period || !total_hours) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  db.run(
    `INSERT INTO curriculums 
     (track_id, curr_name, curriculum_code, curr_period, total_hours, lecture_hours, lab_hours, prerequisites)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
      track_id,
      curr_name,
      curriculum_code,
      curr_period,
      total_hours,
      lecture_hours || 0,
      lab_hours || 0,
      prerequisites || 'none' // if missing, default to 'none'
    ],
    function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({ message: 'Curriculum added', curriculumId: this.lastID });
    }
  );
});


app.get('/api/curriculums/professor/:professorId', (req, res) => {
  const { professorId } = req.params;
  const query = `
    SELECT c.curriculum_id AS id,
           c.name AS name,
           c.curriculum_code,
           c.total_hours,
           c.lecture_hours,
           c.lab_hours,
           c.curr_period,
           c.prerequisites
    FROM curriculums c
    INNER JOIN professor_curriculums pc
        ON c.curriculum_id = pc.curriculum_id
    WHERE pc.professor_id = ?
  `;
  db.all(query, [professorId], (err, rows) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(rows);
  });
});

//assign curriculum to professor
app.post('/api/curriculums/assign', (req, res) => {
  const { professorId, curriculumId } = req.body;
  if (!professorId || !curriculumId) return res.status(400).json({ error: 'professorId and curriculumId required' });

  db.run(
    'INSERT INTO submissions (user_id, faculty_id, track_id, curriculum_id, year_id, level) VALUES (?, 1, 1, ?, 1, 1)',
    [professorId, curriculumId],
    function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.status(200).json({ message: 'Curriculum assigned successfully' });
    }
  );
});

// -------------------- SUBMISSIONS -------------------- //
app.get('/api/submissions', async (req, res) => {
  try {
    const professorId = req.query.professorId;
    let query = `
      SELECT s.id AS submission_id,
             s.year,
             s.level,
             p.name AS professor_name,
             c.curriculum_id,
             c.name AS curriculum_name,
             c.curriculum_code,
             c.curr_period,
             c.total_hours,
             c.lecture_hours,
             c.lab_hours,
             c.prerequisites,
             f.faculty_name AS faculty_name,
             t.track_name AS track_name,
             o.bloom_level_id,
             b.bloom_level_name,
             v.verb_name,
             o.object,
             o.qualifier
      FROM submissions s
      LEFT JOIN professors p ON s.professor_id = p.id
      LEFT JOIN curriculums c ON s.curriculum_id = c.curriculum_id
      LEFT JOIN tracks t ON c.track_id = t.track_id
      LEFT JOIN faculties f ON t.faculty_id = f.faculty_id
      LEFT JOIN outcomes o ON s.id = o.submission_id
      LEFT JOIN bloom_levels b ON o.bloom_level_id = b.bloom_level_id
      LEFT JOIN verbs v ON o.verb_id = v.verb_id
    `;

    const params = [];
    if (professorId) {
      query += ' WHERE s.professor_id = ?';
      params.push(professorId);
    }
    query += ' ORDER BY s.id';

    const rows = await allAsync(query, params);

    const submissions = {};
for (const row of rows) {
  if (!submissions[row.submission_id]) {
    submissions[row.submission_id] = {
      id: row.submission_id,
      professor: row.professor_name,
      year: row.year,
      level: row.level,
      curriculum_id: row.curriculum_id, // <- must be here
      curriculum: {
        name: row.curriculum_name,
        code: row.curriculum_code,
        period: row.curr_period,
        total_hours: row.total_hours,
        lecture_hours: row.lecture_hours,
        lab_hours: row.lab_hours,
        prerequisites: row.prerequisites,
        faculty: row.faculty_name,
        track: row.track_name,
      },
      outcomes: [],
    };
  }

  if (row.bloom_level_id) {
    submissions[row.submission_id].outcomes.push({
      bloom_level_id: row.bloom_level_id, 
      verb_id: row.verb_id,
      bloom_level: row.bloom_level_name,
      verb: row.verb_name,
      object: row.object,
      qualifier: row.qualifier,
    });
  }
}

    res.json(Object.values(submissions));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});




// Create submission
app.post('/api/submissions', async (req, res) => {
  console.log("Incoming body:", req.body); // <- log everything
  if (!req.body) {
    return res.status(400).json({ error: "Request body is missing" });
  }

  const { professor_id, curriculum_id, level, year, outcomes } = req.body;

  if (!professor_id || !curriculum_id || !level || !year) {
    return res.status(400).json({ error: "Missing required submission fields" });
  }

  try {
    // Insert submission
    db.run(
      `INSERT INTO submissions (professor_id, curriculum_id, level, year)
       VALUES (?, ?, ?, ?)`,
      [professor_id, curriculum_id, level, year],
      function(err) {
        if (err) return res.status(500).json({ error: err.message });

        const submissionId = this.lastID;

        // Insert outcomes
        if (Array.isArray(outcomes)) {
          for (const o of outcomes) {
            db.run(
              `INSERT INTO outcomes (submission_id, professor_id, curriculum, bloom_level_id, verb_id, object, qualifier)
               VALUES (?, ?, ?, ?, ?, ?, ?)`,
              [submissionId, professor_id, curriculum_id, o.bloom_level_id, o.verb_id, o.object, o.qualifier],
              function(err2) {
                if (err2) console.error("Outcome insert error:", err2);
              }
            );
          }
        }

        res.status(201).json({ id: submissionId });
      }
    );
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});




// Update submission and its outcomes
app.put('/api/submissions/:id', async (req, res) => {
  try {
    const submissionId = req.params.id;
    const { professor_id, curriculum_id, level, year, outcomes } = req.body;

    if (!professor_id || !curriculum_id || !level || !year) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Update submission info
    await db.run(
      `UPDATE submissions
       SET professor_id = ?, curriculum_id = ?, level = ?, year = ?
       WHERE id = ?`,
      [professor_id, curriculum_id, level, year, submissionId]
    );

    // Process outcomes (update if has id, insert if new)
    if (Array.isArray(outcomes)) {
      for (const o of outcomes) {
        const {
          id, // existing outcome id if present
          bloom_level_id,
          verb_id,
          object = '',
          qualifier = '',
        } = o;

        if (id) {
          // 🔄 Update existing outcome
          await db.run(
            `UPDATE outcomes
             SET bloom_level_id = ?, verb_id = ?, object = ?, qualifier = ?
             WHERE id = ? AND submission_id = ?`,
            [bloom_level_id, verb_id, object, qualifier, id, submissionId]
          );
        } else {
          // ➕ Insert new outcome
          await db.run(
            `INSERT INTO outcomes
             (submission_id, professor_id, bloom_level_id, verb_id, object, qualifier)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [submissionId, professor_id, bloom_level_id, verb_id, object, qualifier]
          );
        }
      }
    }

    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: err.message });
  }
});



// Delete submission and its outcomes
app.delete('/api/submissions/:id', (req, res) => {
  const submissionId = req.params.id;
  db.serialize(() => {
    db.run(`DELETE FROM outcomes WHERE submission_id = ?`, [submissionId], err => {
      if (err) return res.status(500).json({ error: err.message });
      db.run(`DELETE FROM submissions WHERE id = ?`, [submissionId], err => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: 'Submission and outcomes deleted successfully' });
      });
    });
  });
});



// -------------------- BLOOM LEVELS & VERBS -------------------- //

// Add Bloom Level
app.post('/api/add-bloom', (req, res) => {
  const { level_en, level_ar } = req.body;
  if (!level_en) return res.status(400).json({ error: 'Bloom level name required' });

  db.run(
    'INSERT INTO bloom_levels (bloom_level_name) VALUES (?)',
    [level_en],
    function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({ message: 'Bloom level added', levelId: this.lastID });
    }
  );
});

// Add verb
app.post('/api/add-verb', (req, res) => {
  const { bloom_level_id, verb_en } = req.body;
  if (!bloom_level_id || !verb_en) return res.status(400).json({ error: 'Bloom level and verb required' });

  db.run(
    'INSERT INTO verbs (bloom_level_id, verb_name) VALUES (?, ?)',
    [bloom_level_id, verb_en],
    function(err) {
      if (err) return res.status(500).json({ error: err.message });
      res.status(201).json({ message: 'Verb added', verbId: this.lastID });
    }
  );
});


const flutterBuildPath = path.join(__dirname, '../build/web');
app.use(express.static(flutterBuildPath));

app.get(/^\/(?!api\/).*/, (req, res) => {
  res.sendFile(path.join(flutterBuildPath, 'index.html'));
});

// -------------------- START SERVER -------------------- //
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://0.0.0.0:${PORT}`);
});
