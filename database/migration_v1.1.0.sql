-- Migration v1.1.0 — non destructive
-- Ajoute une colonne stock et un nouveau produit sans toucher aux données existantes.

-- Ajout de la colonne stock avec une valeur par défaut (les produits existants gardent 100)
ALTER TABLE products
  ADD COLUMN IF NOT EXISTS stock INTEGER NOT NULL DEFAULT 100 CHECK (stock >= 0);

-- Nouveau produit ajouté en v1.1.0
INSERT INTO products (name, description, price_cents, stock) VALUES
  ('Hub USB 7 ports', 'Hub USB 3.0 alimenté, 7 ports, compatible tous systèmes.', 2990, 50)
ON CONFLICT DO NOTHING;
