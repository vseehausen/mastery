-- Fix asin column length (was VARCHAR(20), some identifiers are longer)
ALTER TABLE sources ALTER COLUMN asin TYPE VARCHAR(50);
