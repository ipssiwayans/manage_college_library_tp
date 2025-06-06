-- =====================================================
-- Gestion des rôles et sécurité - Bibliothèque universitaire
-- Auteur: IPSSI_WAYANS
-- Date: 06/06/2025
-- =====================================================

-- Suppression des rôles existants
DROP ROLE IF EXISTS bibliothecaire;
DROP ROLE IF EXISTS consultant;

-- PARTIE 6.1 - RÔLE BIBLIOTHECAIRE

CREATE ROLE bibliothecaire LOGIN PASSWORD 'biblio2025';

GRANT SELECT, INSERT, UPDATE, DELETE ON auteur TO bibliothecaire;
GRANT SELECT, INSERT, UPDATE, DELETE ON livre TO bibliothecaire;
GRANT SELECT, INSERT, UPDATE, DELETE ON etudiant TO bibliothecaire;
GRANT SELECT, INSERT, UPDATE, DELETE ON emprunt TO bibliothecaire;

GRANT USAGE ON SEQUENCE auteur_id_seq TO bibliothecaire;
GRANT USAGE ON SEQUENCE etudiant_id_seq TO bibliothecaire;
GRANT USAGE ON SEQUENCE emprunt_id_seq TO bibliothecaire;

GRANT SELECT ON v_livres_disponibles TO bibliothecaire;
GRANT SELECT ON v_emprunts_en_retard TO bibliothecaire;
GRANT SELECT ON v_emprunts_en_cours TO bibliothecaire;
GRANT SELECT ON v_statistiques_etudiant TO bibliothecaire;
GRANT SELECT ON v_emprunts_avec_retard TO bibliothecaire;

GRANT EXECUTE ON FUNCTION check_limite_emprunts() TO bibliothecaire;
GRANT EXECUTE ON FUNCTION check_disponibilite_livre() TO bibliothecaire;
GRANT EXECUTE ON FUNCTION check_double_emprunt() TO bibliothecaire;
GRANT EXECUTE ON FUNCTION update_dernier_emprunt() TO bibliothecaire;
GRANT EXECUTE ON FUNCTION nb_emprunts_etudiant(INTEGER) TO bibliothecaire;
GRANT EXECUTE ON FUNCTION jours_retard_emprunt(INTEGER) TO bibliothecaire;
GRANT EXECUTE ON FUNCTION tenter_emprunt(INTEGER, TEXT) TO bibliothecaire;
GRANT EXECUTE ON FUNCTION retourner_livre(INTEGER) TO bibliothecaire;
GRANT EXECUTE ON FUNCTION transferer_emprunt(INTEGER, INTEGER) TO bibliothecaire;

-- PARTIE 6.2 - RÔLE CONSULTANT

CREATE ROLE consultant LOGIN PASSWORD 'consult2025';

GRANT SELECT ON livre TO consultant;
GRANT SELECT ON auteur TO consultant;
GRANT SELECT ON v_livres_disponibles TO consultant;

GRANT EXECUTE ON FUNCTION nb_emprunts_etudiant(INTEGER) TO consultant;

-- Création d'une vue spéciale pour les consultants (sans données personnelles)
CREATE VIEW v_statistiques_publiques AS
SELECT
    l.genre,
    COUNT(e.id) as nb_emprunts_total,
    COUNT(DISTINCT e.id_etudiant) as nb_etudiants_differents,
    ROUND(AVG(CASE WHEN e.date_retour_reelle IS NOT NULL
                   THEN e.date_retour_reelle - e.date_emprunt END), 1) as duree_moyenne_emprunt
FROM livre l
LEFT JOIN emprunt e ON l.isbn = e.isbn
GROUP BY l.genre
ORDER BY nb_emprunts_total DESC;

GRANT SELECT ON v_statistiques_publiques TO consultant;

-- Vue des auteurs populaires pour les consultants
CREATE VIEW v_auteurs_populaires AS
SELECT
    (a.prenom || ' ' || a.nom) AS auteur_complet,
    a.nationalite,
    COUNT(l.isbn) as nb_livres_publies,
    COUNT(e.id) as nb_emprunts_total
FROM auteur a
LEFT JOIN livre l ON a.id = l.id_auteur
LEFT JOIN emprunt e ON l.isbn = e.isbn
GROUP BY a.id, a.prenom, a.nom, a.nationalite
ORDER BY nb_emprunts_total DESC;

GRANT SELECT ON v_auteurs_populaires TO consultant;

-- TESTS DES RÔLES

-- Test du rôle bibliothecaire
SET ROLE bibliothecaire;

SELECT 'Test bibliothecaire - SELECT sur etudiant' as test;
SELECT COUNT(*) FROM etudiant;

SELECT 'Test bibliothecaire - INSERT sur auteur' as test;
INSERT INTO auteur (nom, prenom, nationalite) VALUES ('Test', 'Auteur', 'Test');
DELETE FROM auteur WHERE nom = 'Test';

SELECT 'Test bibliothecaire - Utilisation des vues' as test;
SELECT COUNT(*) FROM v_emprunts_en_cours;

RESET ROLE;

-- Test du rôle consultant
SET ROLE consultant;

SELECT 'Test consultant - SELECT sur livre' as test;
SELECT COUNT(*) FROM livre;

SELECT 'Test consultant - SELECT sur auteur' as test;
SELECT COUNT(*) FROM auteur;

SELECT 'Test consultant - Accès aux vues publiques' as test;
SELECT COUNT(*) FROM v_statistiques_publiques;

RESET ROLE;

-- Tests d'accès refusé pour le consultant
SET ROLE consultant;

SELECT 'Test consultant - Tentative SELECT sur etudiant (doit échouer)' as test;

RESET ROLE;

-- Révocation de droits spécifiques
REVOKE INSERT ON auteur FROM bibliothecaire;
GRANT INSERT ON auteur TO bibliothecaire;

-- Création d'un rôle admin avec tous les droits
CREATE ROLE admin_biblio LOGIN PASSWORD 'admin2025';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_biblio;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_biblio;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO admin_biblio;

-- Rôle de lecture seule pour les rapports
CREATE ROLE lecteur_rapports LOGIN PASSWORD 'rapport2025';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lecteur_rapports;
GRANT SELECT ON ALL VIEWS IN SCHEMA public TO lecteur_rapports;

-- Politique de sécurité avancée : limitation par IP (exemple)
ALTER ROLE bibliothecaire SET log_statement = 'all';
ALTER ROLE consultant SET log_statement = 'mod';

-- Expiration des mots de passe
ALTER ROLE bibliothecaire VALID UNTIL '2026-06-06';
ALTER ROLE consultant VALID UNTIL '2026-06-06';