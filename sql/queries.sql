-- =====================================================
-- Requêtes simples, jointures et recherches - Bibliothèque universitaire
-- Auteur: [Nom Étudiant]
-- Date: 06/06/2025
-- =====================================================

-- PARTIE 3.1 - REQUÊTES SIMPLES

-- Liste de tous les livres (titre, année, genre)
SELECT titre, annee_publication, genre
FROM livre
ORDER BY titre;

-- Étudiants nés après 2000
SELECT nom, prenom, date_naissance
FROM etudiant
WHERE date_naissance > '2000-12-31'
ORDER BY date_naissance;

-- Livres disponibles actuellement
SELECT l.isbn, l.titre, l.nb_exemplaires,
       (l.nb_exemplaires - COALESCE(emp_actifs.nb_emprunts, 0)) AS exemplaires_disponibles
FROM livre l
LEFT JOIN (
    SELECT isbn, COUNT(*) as nb_emprunts
    FROM emprunt
    WHERE date_retour_reelle IS NULL
    GROUP BY isbn
) emp_actifs ON l.isbn = emp_actifs.isbn
WHERE (l.nb_exemplaires - COALESCE(emp_actifs.nb_emprunts, 0)) > 0
ORDER BY l.titre;

-- Liste des emails des étudiants
SELECT email
FROM etudiant
ORDER BY email;

-- Liste des livres publiés après 2015
SELECT titre, annee_publication, genre
FROM livre
WHERE annee_publication > 2015
ORDER BY annee_publication DESC, titre;

-- PARTIE 3.2 - REQUÊTES AVEC JOINTURES

-- Liste des livres avec auteur complet
SELECT l.titre, l.annee_publication, l.genre,
       (a.prenom || ' ' || a.nom) AS auteur_complet
FROM livre l
JOIN auteur a ON l.id_auteur = a.id
ORDER BY l.titre;

-- Emprunts en cours (non retournés) avec nom de l'étudiant et titre du livre
SELECT (et.prenom || ' ' || et.nom) AS etudiant_complet,
       l.titre, e.date_emprunt, e.date_retour_prevue
FROM emprunt e
JOIN etudiant et ON e.id_etudiant = et.id
JOIN livre l ON e.isbn = l.isbn
WHERE e.date_retour_reelle IS NULL
ORDER BY e.date_emprunt;

-- Étudiants ayant emprunté un livre d'un auteur français
SELECT DISTINCT (et.prenom || ' ' || et.nom) AS etudiant_complet,
       et.email
FROM emprunt e
JOIN etudiant et ON e.id_etudiant = et.id
JOIN livre l ON e.isbn = l.isbn
JOIN auteur a ON l.id_auteur = a.id
WHERE a.nationalite = 'Française'
ORDER BY etudiant_complet;

-- Historique complet des emprunts d'un étudiant donné (id_etudiant = 1)
SELECT l.titre, e.date_emprunt, e.date_retour_prevue, e.date_retour_reelle,
       CASE
           WHEN e.date_retour_reelle IS NULL THEN 'En cours'
           WHEN e.date_retour_reelle > e.date_retour_prevue THEN 'Rendu en retard'
           ELSE 'Rendu à temps'
       END AS statut_retour
FROM emprunt e
JOIN livre l ON e.isbn = l.isbn
WHERE e.id_etudiant = 1
ORDER BY e.date_emprunt DESC;

-- Liste des livres empruntés par au moins 2 étudiants différents
SELECT l.titre, COUNT(DISTINCT e.id_etudiant) AS nb_etudiants_differents
FROM livre l
JOIN emprunt e ON l.isbn = e.isbn
GROUP BY l.isbn, l.titre
HAVING COUNT(DISTINCT e.id_etudiant) >= 2
ORDER BY nb_etudiants_differents DESC, l.titre;

-- PARTIE 4 - AGRÉGATS, REGROUPEMENTS ET STATISTIQUES

-- Nombre de livres par genre
SELECT genre, COUNT(*) AS nb_livres
FROM livre
GROUP BY genre
ORDER BY nb_livres DESC;

-- Moyenne d'âge des étudiants
SELECT ROUND(AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_naissance))), 1) AS age_moyen
FROM etudiant;

-- Nombre de livres empruntés par chaque étudiant
SELECT (et.prenom || ' ' || et.nom) AS etudiant_complet,
       COUNT(e.id) AS nb_emprunts_total
FROM etudiant et
LEFT JOIN emprunt e ON et.id = e.id_etudiant
GROUP BY et.id, et.prenom, et.nom
ORDER BY nb_emprunts_total DESC, etudiant_complet;

-- Nombre d'emprunts par nationalité d'auteur
SELECT a.nationalite, COUNT(e.id) AS nb_emprunts
FROM auteur a
JOIN livre l ON a.id = l.id_auteur
LEFT JOIN emprunt e ON l.isbn = e.isbn
GROUP BY a.nationalite
ORDER BY nb_emprunts DESC;

-- Nombre d'emprunts encore en retard
SELECT COUNT(*) AS emprunts_en_retard
FROM emprunt
WHERE date_retour_reelle IS NULL
AND date_retour_prevue < CURRENT_DATE;

-- Moyenne de jours de retard par étudiant
SELECT (et.prenom || ' ' || et.nom) AS etudiant_complet,
       ROUND(AVG(e.date_retour_reelle - e.date_retour_prevue), 1) AS moyenne_jours_retard
FROM etudiant et
JOIN emprunt e ON et.id = e.id_etudiant
WHERE e.date_retour_reelle IS NOT NULL
AND e.date_retour_reelle > e.date_retour_prevue
GROUP BY et.id, et.prenom, et.nom
ORDER BY moyenne_jours_retard DESC;

-- Top 3 des auteurs les plus empruntés
SELECT (a.prenom || ' ' || a.nom) AS auteur_complet,
       a.nationalite,
       COUNT(e.id) AS nb_emprunts
FROM auteur a
JOIN livre l ON a.id = l.id_auteur
LEFT JOIN emprunt e ON l.isbn = e.isbn
GROUP BY a.id, a.prenom, a.nom, a.nationalite
ORDER BY nb_emprunts DESC
LIMIT 3;