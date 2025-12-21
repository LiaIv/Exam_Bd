-- 1

WITH concept_errors AS (
    SELECT
        c.concept_id,
        c.term,
        COUNT(a.attempt_id) AS total_attempts,
        SUM(CASE WHEN a.is_correct = FALSE THEN 1 ELSE 0 END) AS error_count,
        ROUND(
            (SUM(CASE WHEN a.is_correct = FALSE THEN 1 ELSE 0 END)::NUMERIC / 
             NULLIF(COUNT(a.attempt_id), 0)) * 100, 
            2
        ) AS error_rate
    FROM Concepts c
    JOIN Flashcards f ON f.concept_id = c.concept_id
    JOIN Attempts a ON a.flashcard_id = f.flashcard_id
    GROUP BY c.concept_id, c.term
    HAVING COUNT(a.attempt_id) >= 5
)

SELECT 
    term AS "Концепт",
    total_attempts AS "Всего попыток",
    error_count AS "Ошибок",
    error_rate || '%' AS "Процент ошибок"
FROM concept_errors
ORDER BY error_rate DESC, error_count DESC
LIMIT 3;

-- 2

SELECT 
    u.user_id,
    u.name AS "Пользователь",
    u.email,
    c.name AS "Коллекция",
    m.title AS "Материал",
    m.material_type AS "Тип материала",
    COUNT(DISTINCT ch.chunk_id) AS "Количество нитей",
    COUNT(DISTINCT f.flashcard_id) AS "Создано флешкарт",
    COUNT(DISTINCT a.attempt_id) AS "Всего попыток",
    SUM(CASE WHEN a.is_correct = TRUE THEN 1 ELSE 0 END) AS "Правильных ответов"
FROM Users u
JOIN Collections c ON u.user_id = c.user_id
JOIN Materials m ON m.collection_id = c.collection_id
JOIN Chunks ch ON ch.material_id = m.material_id
LEFT JOIN Flashcards f ON f.chunk_id = ch.chunk_id
LEFT JOIN Attempts a ON a.flashcard_id = f.flashcard_id AND a.user_id = u.user_id
GROUP BY u.user_id, u.name, u.email, c.name, m.title, m.material_type
ORDER BY u.user_id, c.name;

-- 3

SELECT 
    u.user_id,
    u.name AS "Пользователь",
    a.attempt_id,
    CASE 
        WHEN a.flashcard_id IS NOT NULL THEN 'Флешкарта'
        ELSE 'Вопрос'
    END AS "Тип",
    a.is_correct AS "Правильно",
    a.attempt_date AS "Дата попытки",
    ROW_NUMBER() OVER(PARTITION BY u.user_id ORDER BY a.attempt_date, a.attempt_id) AS "Номер попытки",
    DENSE_RANK() OVER(PARTITION BY u.user_id ORDER BY a.attempt_date DESC) AS "Ранг по дате",
    ROUND(
        AVG(CASE WHEN a.is_correct THEN 1.0 ELSE 0.0 END) 
        OVER(PARTITION BY u.user_id ORDER BY a.attempt_date, a.attempt_id 
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100,
        2
    ) AS "Процент успеха (нарастающий)"
FROM Attempts a
JOIN Users u ON a.user_id = u.user_id
ORDER BY u.user_id, a.attempt_date, a.attempt_id;

-- 4

SELECT 
    u.name AS "Студент",
    col.name AS "Коллекция",
    m.title AS "Материал",
    con.term AS "Термин",
    f.question_text AS "Вопрос",
    r.next_review_at AS "Дата повторения",
    r.interval_days AS "Интервал (дней)",
    r.ease_factor AS "Коэффициент лёгкости"
FROM Reviews r
JOIN Users u ON r.user_id = u.user_id
JOIN Flashcards f ON r.flashcard_id = f.flashcard_id
JOIN Concepts con ON f.concept_id = con.concept_id
JOIN Chunks ch ON f.chunk_id = ch.chunk_id
JOIN Materials m ON ch.material_id = m.material_id
JOIN Collections col ON m.collection_id = col.collection_id
WHERE r.next_review_at <= CURRENT_DATE
ORDER BY r.next_review_at, u.name;

-- 5

SELECT 
    m.title AS "Материал",
    ch.chunk_id,
    LEFT(ch.content, 100) || '...' AS "Начало нити",
    COUNT(a.attempt_id) AS "Попыток",
    SUM(CASE WHEN a.is_correct = FALSE THEN 1 ELSE 0 END) AS "Ошибок",
    ROUND(
        (SUM(CASE WHEN a.is_correct = FALSE THEN 1 ELSE 0 END)::NUMERIC / 
         NULLIF(COUNT(a.attempt_id), 0)) * 100, 
        2
    ) AS "Процент ошибок"
FROM Chunks ch
JOIN Materials m ON ch.material_id = m.material_id
LEFT JOIN Flashcards f ON f.chunk_id = ch.chunk_id
LEFT JOIN Attempts a ON a.flashcard_id = f.flashcard_id
GROUP BY m.title, ch.chunk_id, ch.content
HAVING COUNT(a.attempt_id) > 0
ORDER BY "Процент ошибок" DESC, "Ошибок" DESC
LIMIT 10;