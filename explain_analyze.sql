EXPLAIN ANALYZE
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

CREATE INDEX idx_attempts_covering ON Attempts(user_id, attempt_date, attempt_id, is_correct, flashcard_id, question_id);

SET work_mem = '64MB';

ANALYZE Attempts;
ANALYZE Users;


-- Запрос после оптимизации

EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
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

CREATE MATERIALIZED VIEW user_attempts_analytics AS
SELECT 
    u.user_id,
    u.name AS user_name,
    a.attempt_id,
    CASE 
        WHEN a.flashcard_id IS NOT NULL THEN 'Флешкарта'
        ELSE 'Вопрос'
    END AS attempt_type,
    a.is_correct,
    a.attempt_date,
    ROW_NUMBER() OVER(PARTITION BY u.user_id ORDER BY a.attempt_date, a.attempt_id) AS attempt_number,
    DENSE_RANK() OVER(PARTITION BY u.user_id ORDER BY a.attempt_date DESC) AS date_rank,
    ROUND(
        AVG(CASE WHEN a.is_correct THEN 1.0 ELSE 0.0 END) 
        OVER(PARTITION BY u.user_id ORDER BY a.attempt_date, a.attempt_id 
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100,
        2
    ) AS cumulative_success_rate
FROM Attempts a
JOIN Users u ON a.user_id = u.user_id;

CREATE INDEX idx_mv_user_attempts ON user_attempts_analytics(user_id, attempt_date);

REFRESH MATERIALIZED VIEW user_attempts_analytics;

SELECT * FROM user_attempts_analytics ORDER BY user_id, attempt_date;