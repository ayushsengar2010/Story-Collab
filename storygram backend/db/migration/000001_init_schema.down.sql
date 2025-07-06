-- name: DeleteLastInsertedAuthor :exec
DELETE FROM authors
WHERE id = (
    SELECT id FROM authors
    ORDER BY id DESC
    LIMIT 1
);

-- name: RestoreDeletedAuthor :exec
INSERT INTO authors (id, name, bio)
VALUES ($1, $2, $3);

-- Undo table creation
DROP TABLE IF EXISTS authors CASCADE;
