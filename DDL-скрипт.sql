-- Таблица пользователей
CREATE TABLE Users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE
);

-- Таблица коллекций
CREATE TABLE Collections (
    collection_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

-- Таблица материалов
CREATE TABLE Materials (
    material_id SERIAL PRIMARY KEY,
    collection_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    material_type VARCHAR(50) NOT NULL CHECK (material_type IN ('text', 'pdf', 'image')),
    CONSTRAINT fk_collection FOREIGN KEY (collection_id) REFERENCES Collections(collection_id)
);

-- Таблица нитей (фрагментов материалов)
CREATE TABLE Chunks (
    chunk_id SERIAL PRIMARY KEY,
    material_id INT NOT NULL,
    content TEXT NOT NULL,
    position INT NOT NULL CHECK (position > 0),
    CONSTRAINT fk_material FOREIGN KEY (material_id) REFERENCES Materials(material_id)
);

-- Таблица концептов (терминов и определений)
CREATE TABLE Concepts (
    concept_id SERIAL PRIMARY KEY,
    term VARCHAR(200) NOT NULL,
    definition TEXT NOT NULL
);

-- Таблица связи нитей и концептов (многие-ко-многим)
CREATE TABLE ChunkConcepts (
    chunk_id INT NOT NULL,
    concept_id INT NOT NULL,
    PRIMARY KEY (chunk_id, concept_id),
    CONSTRAINT fk_chunk FOREIGN KEY (chunk_id) REFERENCES Chunks(chunk_id),
    CONSTRAINT fk_concept FOREIGN KEY (concept_id) REFERENCES Concepts(concept_id)
);

-- Таблица флешкарт
CREATE TABLE Flashcards (
    flashcard_id SERIAL PRIMARY KEY,
    chunk_id INT NOT NULL,
    concept_id INT NOT NULL,
    question_text TEXT NOT NULL,
    answer_text TEXT NOT NULL,
    CONSTRAINT fk_flashcard_chunk FOREIGN KEY (chunk_id) REFERENCES Chunks(chunk_id),
    CONSTRAINT fk_flashcard_concept FOREIGN KEY (concept_id) REFERENCES Concepts(concept_id)
);

-- Таблица тестовых вопросов
CREATE TABLE Questions (
    question_id SERIAL PRIMARY KEY,
    chunk_id INT NOT NULL,
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN ('true_false', 'multiple_choice', 'short_answer')),
    correct_answer TEXT NOT NULL,
    options JSONB,
    CONSTRAINT fk_question_chunk FOREIGN KEY (chunk_id) REFERENCES Chunks(chunk_id)
);

-- Таблица попыток (ответов на флешкарты и вопросы)
CREATE TABLE Attempts (
    attempt_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    flashcard_id INT,
    question_id INT,
    user_answer TEXT,
    is_correct BOOLEAN NOT NULL,
    attempt_date DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT fk_attempt_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT fk_attempt_flashcard FOREIGN KEY (flashcard_id) REFERENCES Flashcards(flashcard_id),
    CONSTRAINT fk_attempt_question FOREIGN KEY (question_id) REFERENCES Questions(question_id),
    CONSTRAINT check_attempt_type CHECK (
        (flashcard_id IS NOT NULL AND question_id IS NULL) OR 
        (flashcard_id IS NULL AND question_id IS NOT NULL)
    )
);

-- Таблица расписания повторений
CREATE TABLE Reviews (
    review_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    flashcard_id INT NOT NULL,
    next_review_at DATE NOT NULL,
    interval_days INT NOT NULL DEFAULT 1 CHECK (interval_days > 0),
    ease_factor NUMERIC(3,2) NOT NULL DEFAULT 2.5 CHECK (ease_factor >= 1.3),
    CONSTRAINT fk_review_user FOREIGN KEY (user_id) REFERENCES Users(user_id),
    CONSTRAINT fk_review_flashcard FOREIGN KEY (flashcard_id) REFERENCES Flashcards(flashcard_id),
    CONSTRAINT unique_user_flashcard UNIQUE (user_id, flashcard_id)
);