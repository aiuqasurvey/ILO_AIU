CREATE DATABASE ilos_app;
USE ilos_app;

-- Users table
CREATE TABLE users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    username VARCHAR(32) UNIQUE NOT NULL,
    password VARCHAR(32) NOT NULL,
    name VARCHAR(64) NOT NULL,
    role VARCHAR(16) NOT NULL DEFAULT 'professor'
        CHECK (role IN ('admin', 'professor')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Faculties
CREATE TABLE faculties (
    faculty_id INT IDENTITY(1,1) PRIMARY KEY,
    faculty_name VARCHAR(64) UNIQUE NOT NULL
);

-- Tracks
CREATE TABLE tracks (
    track_id INT IDENTITY(1,1) PRIMARY KEY,
    faculty_id INT NOT NULL,
    track_name VARCHAR(64) NOT NULL,
    FOREIGN KEY (faculty_id) REFERENCES faculties(faculty_id) ON DELETE CASCADE
);

-- Curriculums
CREATE TABLE curriculums (
    curriculum_id INT IDENTITY(1,1) PRIMARY KEY,
    track_id INT NOT NULL,
    curr_name VARCHAR(64) NOT NULL,
    curriculum_code VARCHAR(16) UNIQUE NOT NULL,
    prerequisites VARCHAR(64),
    curr_period VARCHAR(16) NOT NULL DEFAULT 'semester'
        CHECK (curr_period IN ('annual','semester','trimester')),
    total_hours INT NOT NULL,
    lecture_hours INT NOT NULL,
    lab_hours INT NOT NULL,
    FOREIGN KEY (track_id) REFERENCES tracks(track_id) ON DELETE CASCADE
);

-- Years
CREATE TABLE years (
    year_id INT IDENTITY(1,1) PRIMARY KEY,
    year_range VARCHAR(16) UNIQUE NOT NULL
);

-- Bloom Levels 
CREATE TABLE bloom_levels (
    bloom_level_id INT IDENTITY(1,1) PRIMARY KEY,
    bloom_level_name VARCHAR(64) NOT NULL
);

-- Verbs 
CREATE TABLE verbs (
    verb_id INT IDENTITY(1,1) PRIMARY KEY,
    bloom_level_id INT NOT NULL,
    verb_name VARCHAR(64) NOT NULL,
    FOREIGN KEY (bloom_level_id) REFERENCES bloom_levels(bloom_level_id) ON DELETE CASCADE
);

-- Submissions
CREATE TABLE submissions (
    submission_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    faculty_id INT NOT NULL,
    track_id INT NOT NULL,
    curriculum_id INT NOT NULL,
    year_id INT NOT NULL,
    level INT NOT NULL CHECK (level BETWEEN 1 AND 10),  
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (faculty_id) REFERENCES faculties(faculty_id),
    FOREIGN KEY (track_id) REFERENCES tracks(track_id),
    FOREIGN KEY (curriculum_id) REFERENCES curriculums(curriculum_id),
    FOREIGN KEY (year_id) REFERENCES years(year_id)
);

-- Outcomes
CREATE TABLE outcomes (
    outcome_id INT IDENTITY(1,1) PRIMARY KEY,
    submission_id INT NOT NULL,
    bloom_level_id INT NOT NULL,   
    verb_id INT NOT NULL,
    object_text VARCHAR(255) NOT NULL,
    qualifier VARCHAR(255),
    FOREIGN KEY (submission_id) REFERENCES submissions(submission_id) ON DELETE CASCADE,
    FOREIGN KEY (bloom_level_id) REFERENCES bloom_levels(bloom_level_id),
    FOREIGN KEY (verb_id) REFERENCES verbs(verb_id)
);

 

-- data pre-filled

-- filling faculty

INSERT INTO faculties (faculty_id, faculty_name) values
    (1 , 'كلية الصيدلة'), 
    (2 ,'كلية طب الأسنان'),
    (3 , 'كلية الهندسة المعلوماتية والاتصالات'), 
    (4 , 'كلية الهندسة المدنية'), 
    (5 , 'كلية الهندسة المعمارية'), 
    (6 , 'كلية إدارة الأعمال'), 
    (7 , 'كلية الحقوق'), 
    (8 , 'كلية الفنون'); 



-- filling bloom levels

INSERT INTO bloom_levels (bloom_level_id, bloom_level_name) VALUES
  (1, ' المعرفة والفهم'),
  (2, 'التطبيق'),
  (3, 'التحليل'),
  (4,'التركيب'),
  (5, 'التقييم');


-- filling verbs per level

INSERT INTO verbs (verb_id, bloom_level_id, verb_name) VALUES
    (1, 1,  'اذكر'),
    (2, 1, ' سجل'),
    (3, 1,  'حدد'),
    (4, 1, 'وضح'),
    (5, 1,  'صف'),
    (6, 1,  'تعرف على'),
    (7, 1,  'ميز'),
    (8, 1,  'عدد'),
    (9, 1, 'اسرد'),
    (10, 1, 'ناقش'),
    (11, 1, 'استجب لـ'),
    (12, 1, 'كشف'),
    (13, 1, 'عرف'),
    (14, 1, 'سم'),
    (15, 1,  'عبر باختصار'),
    (16, 1,  'اشرح'),
    (17, 1,  'بين الأسباب'),
    (18, 1,  'لخص'),
    (19, 1,  'أشر إلى'),
    (20, 1, 'فسر'),
    (21, 2, 'طبق'),
    (22, 2,  'احصي'),
    (23, 2,  'حسب'),
    (24, 2,  'وصّف'),
    (25, 2,  'اكتشف'),
    (26, 2,  'عالج'),
    (27, 2,  'عدل'),
    (28, 2, 'نفذ'),
    (29, 2,  'تنبأ'),
    (30, 2, 'جهز'),
    (31, 2, 'أنتج'),
    (32, 2, 'ربط'),
    (33, 2, 'أظهر'),
    (34, 2,  'حل'),
    (35, 2, 'استخدم'),
    (36, 3, 'حلل'),
    (37, 3, 'قارن'),
    (38, 3,  'انتقد'),
    (39, 3,'افحص'),
    (40, 3,  'قدر'),
    (41, 3, 'جادل'),
    (42, 3, 'غاير'),
    (43, 3,'اسأل'),
    (44, 3, 'مايز '),
    (45, 4, 'رتب'),
    (46, 4,'صمم'),
    (47, 4, 'صغ'),
    (48, 4, 'أعد تعريف'),
    (49, 4, 'بادر'),
    (50, 4,'جمع'),
    (51, 4,  'جهز'),
    (52, 4, 'ابنِ'),
    (53, 4,'اقترح'),
    (54, 4,'ابدأ'),
    (55, 4, 'نظم'),
    (56, 4, 'طور'),
    (57, 4,  'أنتج'),
    (58, 4, 'ابتكر'),
    (59, 5,  'قيّم'),
    (60, 5,  'قيم'),
    (61, 5, 'احكم على'),
    (62, 5, 'قدر'),
    (63, 5,  'قيس'),
    (64, 5,  'أوصِ'),
    (65, 5,  'قَيّم'),
    (66, 5, 'انتقد'),
    (67, 5,'قارن'),
    (68, 5,  'دافع عن'),
    (69, 5,  'ميز'),
    (70, 5,  'دافع عن');
