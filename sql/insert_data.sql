-- =====================================================
-- Script d'insertion des données - Bibliothèque universitaire
-- Auteur: [Nom Étudiant]
-- Date: 06/06/2025
-- =====================================================

-- Nettoyage des données existantes (pour les tests)
DELETE FROM emprunt;
DELETE FROM livre;
DELETE FROM auteur;
DELETE FROM etudiant;

-- Reset des séquences
ALTER SEQUENCE auteur_id_seq RESTART WITH 1;
ALTER SEQUENCE etudiant_id_seq RESTART WITH 1;
ALTER SEQUENCE emprunt_id_seq RESTART WITH 1;

-- =====================================================
-- INSERTION DES AUTEURS (5 auteurs avec nationalités variées)
-- =====================================================

INSERT INTO auteur (nom, prenom, nationalite) VALUES
('Hugo', 'Victor', 'Française'),
('Orwell', 'George', 'Britannique'),
('García Márquez', 'Gabriel', 'Colombienne'),
('Murakami', 'Haruki', 'Japonaise'),
('Camus', 'Albert', 'Française');

-- =====================================================
-- INSERTION DES LIVRES (10 livres répartis entre les auteurs)
-- =====================================================

INSERT INTO livre (isbn, titre, id_auteur, annee_publication, genre, nb_exemplaires) VALUES
-- Livres de Victor Hugo
('978-2-07-036936-4', 'Les Misérables', 1, 1862, 'Roman historique', 3),
('978-2-07-040825-4', 'Notre-Dame de Paris', 1, 1831, 'Roman historique', 2),

-- Livres de George Orwell
('978-0-14-118776-1', '1984', 2, 1949, 'Science-fiction', 4),
('978-0-14-118765-5', 'Animal Farm', 2, 1945, 'Fable politique', 2),

-- Livres de Gabriel García Márquez
('978-84-376-0494-7', 'Cent ans de solitude', 3, 1967, 'Réalisme magique', 2),
('978-84-376-0495-4', 'L''Amour aux temps du choléra', 3, 1985, 'Romance', 3),

-- Livres de Haruki Murakami
('978-4-10-100101-5', 'Norwegian Wood', 4, 1987, 'Romance contemporaine', 2),
('978-4-10-100102-2', 'Kafka sur le rivage', 4, 2002, 'Fantastique', 1),

-- Livres d'Albert Camus
('978-2-07-036002-6', 'L''Étranger', 5, 1942, 'Roman philosophique', 3),
('978-2-07-036003-3', 'La Peste', 5, 1947, 'Roman philosophique', 0); -- Livre épuisé (0 exemplaire)

-- =====================================================
-- INSERTION DES ÉTUDIANTS (6 étudiants avec âges variés)
-- =====================================================

INSERT INTO etudiant (nom, prenom, date_naissance, email) VALUES
('Dupont', 'Marie', '2002-03-15', 'marie.dupont@univ.fr'),        -- 23 ans
('Martin', 'Pierre', '1999-07-22', 'pierre.martin@univ.fr'),       -- 25 ans
('Bernard', 'Julie', '2001-11-08', 'julie.bernard@univ.fr'),       -- 23 ans
('Leroy', 'Thomas', '2003-05-12', 'thomas.leroy@univ.fr'),         -- 22 ans
('Moreau', 'Sophie', '2000-09-30', 'sophie.moreau@univ.fr'),       -- 24 ans
('Petit', 'Lucas', '2004-01-18', 'lucas.petit@univ.fr');           -- 21 ans

-- =====================================================
-- INSERTION DES EMPRUNTS (12 emprunts avec cas spécifiques)
-- =====================================================

-- Emprunts en cours (non retournés) - 4 emprunts
INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) VALUES
(1, '978-2-07-036936-4', '2025-05-15', '2025-06-15'),  -- Marie - Les Misérables (en cours)
(2, '978-0-14-118776-1', '2025-05-20', '2025-06-20'),  -- Pierre - 1984 (en cours)
(3, '978-84-376-0494-7', '2025-05-25', '2025-06-25'),  -- Julie - Cent ans de solitude (en cours)
(4, '978-4-10-100101-5', '2025-06-01', '2025-07-01');  -- Thomas - Norwegian Wood (en cours)

-- Emprunts rendus en retard - 2 emprunts
INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue, date_retour_reelle) VALUES
(1, '978-2-07-040825-4', '2025-04-01', '2025-05-01', '2025-05-10'),  -- Marie - Notre-Dame (retard de 9 jours)
(2, '978-0-14-118765-5', '2025-04-10', '2025-05-10', '2025-05-20');  -- Pierre - Animal Farm (retard de 10 jours)

-- Emprunts rendus à temps - 2 emprunts
INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue, date_retour_reelle) VALUES
(3, '978-84-376-0495-4', '2025-04-15', '2025-05-15', '2025-05-12'),  -- Julie - L'Amour aux temps du choléra (à temps)
(5, '978-2-07-036002-6', '2025-04-20', '2025-05-20', '2025-05-18');  -- Sophie - L'Étranger (à temps)

-- Création d'un étudiant ayant 5 emprunts (limite atteinte) - Sophie
INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) VALUES
(5, '978-2-07-036936-4', '2025-06-02', '2025-07-02'),  -- Sophie - Les Misérables (2ème exemplaire)
(5, '978-0-14-118776-1', '2025-06-03', '2025-07-03'),  -- Sophie - 1984 (2ème exemplaire)
(5, '978-84-376-0495-4', '2025-06-04', '2025-07-04'),  -- Sophie - L'Amour aux temps du choléra (2ème exemplaire)
(5, '978-4-10-100102-2', '2025-06-05', '2025-07-05');  -- Sophie - Kafka sur le rivage (seul exemplaire)

-- Emprunt supplémentaire pour créer 12 emprunts au total
INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) VALUES
(6, '978-2-07-036002-6', '2025-06-06', '2025-07-06');  -- Lucas - L'Étranger

-- =====================================================
-- CAS SPÉCIFIQUES À TESTER (à exécuter séparément pour voir les erreurs)
-- =====================================================

-- Test 1: Tentative d'emprunt d'un livre épuisé (devrait échouer)
-- INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) VALUES
-- (6, '978-2-07-036003-3', '2025-06-06', '2025-07-06');  -- Lucas tente La Peste (0 exemplaire)

-- Test 2: Tentative d'un 6ème emprunt pour Sophie (devrait échouer)
-- INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) VALUES
-- (5, '978-0-14-118765-5', '2025-06-06', '2025-07-06');  -- Sophie tente un 6ème emprunt

-- Test 3: Tentative de double emprunt (devrait échouer)
-- INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue) VALUES
-- (1, '978-2-07-036936-4', '2025-06-06', '2025-07-06');  -- Marie tente de re-emprunter Les Misérables

-- =====================================================
-- VÉRIFICATIONS DES DONNÉES INSÉRÉES
-- =====================================================

-- Affichage des statistiques
SELECT 'AUTEURS' as table_name, COUNT(*) as nb_lignes FROM auteur
UNION ALL
SELECT 'LIVRES', COUNT(*) FROM livre
UNION ALL
SELECT 'ÉTUDIANTS', COUNT(*) FROM etudiant
UNION ALL
SELECT 'EMPRUNTS', COUNT(*) FROM emprunt;

-- Vérification des emprunts en cours
SELECT
    COUNT(*) as emprunts_en_cours,
    COUNT(CASE WHEN date_retour_prevue < CURRENT_DATE THEN 1 END) as emprunts_en_retard
FROM emprunt
WHERE date_retour_reelle IS NULL;

-- Vérification de l'étudiant ayant 5 emprunts
SELECT
    e.nom, e.prenom,
    COUNT(*) as nb_emprunts_actifs
FROM etudiant e
JOIN emprunt emp ON e.id = emp.id_etudiant
WHERE emp.date_retour_reelle IS NULL
GROUP BY e.id, e.nom, e.prenom
HAVING COUNT(*) = 5;