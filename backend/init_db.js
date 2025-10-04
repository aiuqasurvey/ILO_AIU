
const db = require('./db');

function run(sql, params=[]) {
  return new Promise((res, rej) => {
    db.run(sql, params, function(err) {
      if (err) rej(err); else res(this);
    });
  });
}

async function init() {
  try {
    // Users
    await run(`CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT DEFAULT 'user'
    );`);

    
    await run(`CREATE TABLE IF NOT EXISTS faculties (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE NOT NULL
    );`);

    await run(`CREATE TABLE IF NOT EXISTS tracks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      faculty_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      FOREIGN KEY(faculty_id) REFERENCES faculties(id)
    );`);

    await run(`CREATE TABLE IF NOT EXISTS curriculums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      track_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      FOREIGN KEY(track_id) REFERENCES tracks(id)
    );`);


    await run(`CREATE TABLE IF NOT EXISTS submissions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      professor TEXT,
      faculty TEXT,
      track TEXT,
      curriculum TEXT,
      year TEXT,
      outcomes TEXT, -- store JSON string array
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id)
    );`);

    // seed faculties/tracks/curriculums (example)
    const faculties = ['Pharmacy','Dentistry','Informatics and Communication Engineering','Civil Engineering','Architectural Engineering','Law','Business Administration','Arts'];
    for (const f of faculties) {
      await run(`INSERT OR IGNORE INTO faculties(name) VALUES(?)`, [f]);
    }

    // simple mapping example for tracks per faculty
    const facultyRows = await new Promise((res, rej) => db.all(`SELECT * FROM faculties`, [], (e,r)=> e? rej(e):res(r)));

    // Example tracks per faculty (you can edit)
    const mapping = {
      'Pharmacy': ['Clinical Pharmacy','Pharmaceutics'],
      'Dentistry': ['Orthodontics','Oral Surgery'],
      'Informatics and Communication Engineering': ['Software','Networks'],
      'Civil Engineering': ['Structural','Construction'],
      'Architectural Engineering': ['Design','History'],
      'Law': ['Private Law','Public Law'],
      'Business Administration': ['Accounting','Marketing'],
      'Arts': ['Fine Arts','Performing Arts']
    };

    for (const row of facultyRows) {
      const arr = mapping[row.name] || ['General'];
      for (const t of arr) {
        await run(`INSERT OR IGNORE INTO tracks(faculty_id, name) VALUES(?,?)`, [row.id, t]);
      }
    }

    // Example curriculums per track - simple seeds
    const tracks = await new Promise((res, rej) => db.all(`SELECT tracks.id as id, tracks.name as name, faculties.name as faculty FROM tracks JOIN faculties ON tracks.faculty_id = faculties.id`, [], (e,r)=> e? rej(e):res(r)));
    for (const tr of tracks) {
      // create 2 example curriculums per track
      await run(`INSERT OR IGNORE INTO curriculums(track_id, name) VALUES(?,?)`, [tr.id, `${tr.name} - Curriculum A`]);
      await run(`INSERT OR IGNORE INTO curriculums(track_id, name) VALUES(?,?)`, [tr.id, `${tr.name} - Curriculum B`]);
    }

    console.log('DB initialized.');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

init();
