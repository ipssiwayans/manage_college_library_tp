-- =====================================================
-- Vues, sous-requêtes et fonctions - Bibliothèque universitaire
-- Auteur: IPSSI_WAYANS
-- Date: 06/06/2025
-- =====================================================

-- PARTIE 5.1 - CRÉATION DE VUES

DROP VIEW IF EXISTS v_emprunts_en_cours;
DROP VIEW IF EXISTS v_statistiques_etudiant;

CREATE VIEW v_emprunts_en_cours AS
SELECT e.id, (et.prenom || ' ' || et.nom) AS nom_prenom_etudiant,
       l.titre, e.date_emprunt
FROM emprunt e
JOIN etudiant et ON e.id_etudiant = et.id
JOIN livre l ON e.isbn = l.isbn
WHERE e.date_retour_reelle IS NULL
ORDER BY e.date_emprunt;

CREATE VIEW v_statistiques_etudiant AS
SELECT et.id, (et.prenom || ' ' || et.nom) AS nom_prenom_etudiant,
       COUNT(e.id) AS nb_emprunts_total,
       COUNT(CASE WHEN e.date_retour_reelle IS NOT NULL AND e.date_retour_reelle > e.date_retour_prevue THEN 1 END) AS nb_retards,
       MAX(e.date_emprunt) AS date_dernier_emprunt
FROM etudiant et
LEFT JOIN emprunt e ON et.id = e.id_etudiant
GROUP BY et.id, et.prenom, et.nom
ORDER BY et.nom, et.prenom;

-- PARTIE 5.2 - SOUS-REQUÊTES

-- Étudiants ayant emprunté plus de 3 livres
SELECT nom, prenom, email
FROM etudiant
WHERE id IN (
    SELECT id_etudiant
    FROM emprunt
    GROUP BY id_etudiant
    HAVING COUNT(*) > 3
)
ORDER BY nom, prenom;

-- Livres jamais empruntés
SELECT titre, (a.prenom || ' ' || a.nom) AS auteur_complet
FROM livre l
JOIN auteur a ON l.id_auteur = a.id
WHERE l.isbn NOT IN (
    SELECT DISTINCT isbn
    FROM emprunt
    WHERE isbn IS NOT NULL
)
ORDER BY titre;

-- Étudiants ayant toujours rendu leurs livres en retard
SELECT nom, prenom, email
FROM etudiant
WHERE id IN (
    SELECT id_etudiant
    FROM emprunt
    WHERE date_retour_reelle IS NOT NULL
    GROUP BY id_etudiant
    HAVING COUNT(*) > 0
    AND COUNT(CASE WHEN date_retour_reelle <= date_retour_prevue THEN 1 END) = 0
)
ORDER BY nom, prenom;

-- Auteurs dont aucun livre n'a été emprunté
SELECT nom, prenom, nationalite
FROM auteur
WHERE id NOT IN (
    SELECT DISTINCT l.id_auteur
    FROM livre l
    JOIN emprunt e ON l.isbn = e.isbn
    WHERE l.id_auteur IS NOT NULL
)
ORDER BY nom, prenom;

-- PARTIE 7 - BONUS

-- Fonction personnalisée : nb_emprunts_etudiant
DROP FUNCTION IF EXISTS nb_emprunts_etudiant(INTEGER);

CREATE OR REPLACE FUNCTION nb_emprunts_etudiant(id_etudiant_param INTEGER)
RETURNS INTEGER AS $$
DECLARE
    nb_total INTEGER;
BEGIN
    SELECT COUNT(*) INTO nb_total
    FROM emprunt
    WHERE id_etudiant = id_etudiant_param;

    RETURN nb_total;
END;
$$ LANGUAGE plpgsql;

-- Test de la fonction
SELECT nom, prenom, nb_emprunts_etudiant(id) AS nb_emprunts
FROM etudiant
ORDER BY nb_emprunts DESC, nom;

-- Fonction pour calculer les jours de retard d'un emprunt
DROP FUNCTION IF EXISTS jours_retard_emprunt(INTEGER);

CREATE OR REPLACE FUNCTION jours_retard_emprunt(id_emprunt INTEGER)
RETURNS INTEGER AS $$
DECLARE
    retard_jours INTEGER := 0;
    date_prevue DATE;
    date_reelle DATE;
BEGIN
    SELECT date_retour_prevue, date_retour_reelle
    INTO date_prevue, date_reelle
    FROM emprunt
    WHERE id = id_emprunt;

    IF date_reelle IS NOT NULL AND date_reelle > date_prevue THEN
        retard_jours := date_reelle - date_prevue;
    ELSIF date_reelle IS NULL AND CURRENT_DATE > date_prevue THEN
        retard_jours := CURRENT_DATE - date_prevue;
    END IF;

    RETURN retard_jours;
END;
$$ LANGUAGE plpgsql;

-- Vue utilisant la fonction de retard
DROP VIEW IF EXISTS v_emprunts_avec_retard;

CREATE VIEW v_emprunts_avec_retard AS
SELECT e.id, (et.prenom || ' ' || et.nom) AS etudiant_complet,
       l.titre, e.date_emprunt, e.date_retour_prevue, e.date_retour_reelle,
       jours_retard_emprunt(e.id) AS jours_retard,
       CASE
           WHEN e.date_retour_reelle IS NULL AND e.date_retour_prevue < CURRENT_DATE THEN 'En retard'
           WHEN e.date_retour_reelle IS NOT NULL AND e.date_retour_reelle > e.date_retour_prevue THEN 'Rendu en retard'
           WHEN e.date_retour_reelle IS NOT NULL THEN 'Rendu à temps'
           ELSE 'En cours'
       END AS statut
FROM emprunt e
JOIN etudiant et ON e.id_etudiant = et.id
JOIN livre l ON e.isbn = l.isbn
ORDER BY e.date_emprunt DESC;