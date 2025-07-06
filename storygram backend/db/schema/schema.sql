-- Drop ENUM type if exists
DROP TYPE IF EXISTS story_status;

-- Create ENUM type
CREATE TYPE story_status AS ENUM (
  'draft',
  'published',
  'archived'
);

-- Create users table
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name VARCHAR NOT NULL,
  bio TEXT NOT NULL,
  profile_image VARCHAR NOT NULL DEFAULT '',
  location VARCHAR NOT NULL,
  website VARCHAR NOT NULL DEFAULT '',
  followers INTEGER NOT NULL DEFAULT 0,
  following INTEGER NOT NULL DEFAULT 0,
  email VARCHAR NOT NULL UNIQUE,
  stories_count INTEGER NOT NULL DEFAULT 0,
  is_verified BOOLEAN NOT NULL DEFAULT false
);
ALTER TABLE users ADD COLUMN password TEXT NOT NULL;
-- Alter the users table to make 'id' auto-incrementing
ALTER TABLE users
    ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);

-- Create stories table with user_id instead of author_id
CREATE TABLE stories (
  id INTEGER PRIMARY KEY,
  title VARCHAR NOT NULL,
  description TEXT,
  cover_image VARCHAR,
  user_id INTEGER NOT NULL,  -- changed from author_id to user_id
  likes INTEGER NOT NULL DEFAULT 0,
  views INTEGER NOT NULL DEFAULT 0,
  published_date TIMESTAMPTZ,
  last_edited TIMESTAMPTZ NOT NULL,
  story_type VARCHAR NOT NULL,
  status story_status NOT NULL,
  genres TEXT[]
);

-- Create chapters table
CREATE TABLE chapters (
    id SERIAL PRIMARY KEY,
    story_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    chapter_number INT NOT NULL,
    is_complete BOOLEAN NOT NULL,
    createdat TIMESTAMP DEFAULT NOW(),
    updatedat TIMESTAMP DEFAULT NOW(),
    FOREIGN KEY (story_id) REFERENCES stories(id),
    CONSTRAINT unique_chapter_number_per_story UNIQUE (story_id, chapter_number)
);




-- Create story_collaborators table
CREATE TABLE story_collaborators (
  story_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  PRIMARY KEY (story_id, user_id)
);








-- Foreign key constraints
ALTER TABLE stories
  ADD CONSTRAINT stories_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE chapters
  ADD CONSTRAINT chapters_story_id_fkey
  FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE;

ALTER TABLE story_collaborators
  ADD CONSTRAINT story_collaborators_story_id_fkey
  FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE;

ALTER TABLE story_collaborators
  ADD CONSTRAINT story_collaborators_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
