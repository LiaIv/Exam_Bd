CREATE INDEX idx_attempts_covering ON Attempts(user_id, attempt_date, attempt_id, is_correct, flashcard_id, question_id);

CREATE INDEX idx_attempts_user_id ON Attempts(user_id);

-- Индексы для внешних ключей
CREATE INDEX idx_collections_user_id ON Collections(user_id);
CREATE INDEX idx_materials_collection_id ON Materials(collection_id);
CREATE INDEX idx_chunks_material_id ON Chunks(material_id);
CREATE INDEX idx_chunkconcepts_chunk_id ON ChunkConcepts(chunk_id);
CREATE INDEX idx_chunkconcepts_concept_id ON ChunkConcepts(concept_id);
CREATE INDEX idx_flashcards_chunk_id ON Flashcards(chunk_id);
CREATE INDEX idx_flashcards_concept_id ON Flashcards(concept_id);
CREATE INDEX idx_questions_chunk_id ON Questions(chunk_id);
CREATE INDEX idx_attempts_flashcard_id ON Attempts(flashcard_id);
CREATE INDEX idx_attempts_question_id ON Attempts(question_id);
CREATE INDEX idx_reviews_user_id ON Reviews(user_id);
CREATE INDEX idx_reviews_flashcard_id ON Reviews(flashcard_id);

CREATE INDEX idx_reviews_user_next_date ON Reviews(user_id, next_review_at);

CREATE INDEX idx_attempts_date ON Attempts(attempt_date);

VACUUM ANALYZE;