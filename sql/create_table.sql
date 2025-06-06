-- =====================================================
-- Script de création des tables - Bibliothèque universitaire
-- Auteur: IPSSI_WAYANS
-- Date: 06/06/2025
-- =====================================================

DROP TABLE IF EXISTS emprunt CASCADE;
DROP TABLE IF EXISTS livre CASCADE;
DROP TABLE IF EXISTS auteur CASCADE;
DROP TABLE IF EXISTS etudiant CASCADE;

CREATE TABLE auteur (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    nationalite TEXT NOT NULL
);

CREATE TABLE livre (
    isbn TEXT PRIMARY KEY,
    titre TEXT NOT NULL,
    id_auteur INT NOT NULL REFERENCES auteur(id),
    annee_publication INT NOT NULL CHECK(annee_publication > 1800),
    genre TEXT NOT NULL,
    nb_exemplaires INT NOT NULL CHECK(nb_exemplaires >= 0)
);

CREATE TABLE etudiant (
    id SERIAL PRIMARY KEY,
    nom TEXT NOT NULL,
    prenom TEXT NOT NULL,
    date_naissance DATE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    dernier_emprunt DATE
);

CREATE TABLE emprunt (
    id SERIAL PRIMARY KEY,
    id_etudiant INT NOT NULL REFERENCES etudiant(id),
    isbn TEXT NOT NULL REFERENCES livre(isbn),
    date_emprunt DATE NOT NULL DEFAULT CURRENT_DATE,
    date_retour_prevue DATE NOT NULL,
    date_retour_reelle DATE,
    CONSTRAINT check_dates CHECK (date_retour_prevue >= date_emprunt),
    CONSTRAINT check_retour_date CHECK (date_retour_reelle IS NULL OR date_retour_reelle >= date_emprunt)
);

CREATE INDEX idx_livre_auteur ON livre(id_auteur);
CREATE INDEX idx_emprunt_etudiant ON emprunt(id_etudiant);
CREATE INDEX idx_emprunt_livre ON emprunt(isbn);
CREATE INDEX idx_emprunt_non_rendu ON emprunt(date_retour_reelle) WHERE date_retour_reelle IS NULL;

COMMENT ON TABLE auteur IS 'Table des auteurs de livres';
COMMENT ON TABLE livre IS 'Table des livres disponibles dans la bibliothèque';
COMMENT ON TABLE etudiant IS 'Table des étudiants utilisateurs de la bibliothèque';
COMMENT ON TABLE emprunt IS 'Table des emprunts de livres par les étudiants';

COMMENT ON COLUMN livre.nb_exemplaires IS 'Nombre total d''exemplaires disponibles';
COMMENT ON COLUMN emprunt.date_retour_reelle IS 'NULL si le livre n''est pas encore rendu';
COMMENT ON COLUMN etudiant.dernier_emprunt IS 'Date du dernier emprunt effectué par l''étudiant';