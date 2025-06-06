-- =====================================================
-- Fonctionnalités bonus - Bibliothèque universitaire
-- Auteur: IPSSI_WAYANS
-- Date: 06/06/2025
-- =====================================================

-- PARTIE 7.1 - FONCTION PERSONNALISÉE

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

-- PARTIE 7.2 - TRIGGER AFTER INSERT

DROP TRIGGER IF EXISTS trigger_after_emprunt_insert ON emprunt;
DROP FUNCTION IF EXISTS trigger_after_emprunt();

CREATE OR REPLACE FUNCTION trigger_after_emprunt()
RETURNS TRIGGER AS $$
DECLARE
    nb_emprunts_actifs INTEGER;
BEGIN
    UPDATE etudiant
    SET dernier_emprunt = NEW.date_emprunt
    WHERE id = NEW.id_etudiant;

    SELECT COUNT(*) INTO nb_emprunts_actifs
    FROM emprunt
    WHERE id_etudiant = NEW.id_etudiant
    AND date_retour_reelle IS NULL;

    IF nb_emprunts_actifs > 5 THEN
        DELETE FROM emprunt WHERE id = NEW.id;
        RAISE EXCEPTION 'Limite de 5 emprunts dépassée pour cet étudiant (ID: %)', NEW.id_etudiant;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_after_emprunt_insert
    AFTER INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION trigger_after_emprunt();

-- FONCTIONNALITÉS BONUS SUPPLÉMENTAIRES

-- Fonction pour calculer les statistiques d'un livre
CREATE OR REPLACE FUNCTION stats_livre(isbn_param TEXT)
RETURNS TABLE(
    titre_livre TEXT,
    auteur_complet TEXT,
    nb_emprunts_total BIGINT,
    nb_etudiants_differents BIGINT,
    duree_moyenne_emprunt NUMERIC,
    nb_retards BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.titre,
        (a.prenom || ' ' || a.nom),
        COUNT(e.id),
        COUNT(DISTINCT e.id_etudiant),
        ROUND(AVG(CASE WHEN e.date_retour_reelle IS NOT NULL
                      THEN e.date_retour_reelle - e.date_emprunt END), 1),
        COUNT(CASE WHEN e.date_retour_reelle > e.date_retour_prevue THEN 1 END)
    FROM livre l
    JOIN auteur a ON l.id_auteur = a.id
    LEFT JOIN emprunt e ON l.isbn = e.isbn
    WHERE l.isbn = isbn_param
    GROUP BY l.isbn, l.titre, a.prenom, a.nom;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour obtenir les recommandations de livres
CREATE OR REPLACE FUNCTION recommandations_etudiant(id_etudiant_param INTEGER)
RETURNS TABLE(
    isbn_recommande TEXT,
    titre_recommande TEXT,
    auteur_recommande TEXT,
    score_recommandation BIGINT
) AS $$
BEGIN
    RETURN QUERY
    WITH genres_preferes AS (
        SELECT l.genre, COUNT(*) as nb_emprunts
        FROM emprunt e
        JOIN livre l ON e.isbn = l.isbn
        WHERE e.id_etudiant = id_etudiant_param
        GROUP BY l.genre
        ORDER BY nb_emprunts DESC
        LIMIT 3
    ),
    livres_non_empruntes AS (
        SELECT l.isbn, l.titre, (a.prenom || ' ' || a.nom) as auteur_nom, l.genre
        FROM livre l
        JOIN auteur a ON l.id_auteur = a.id
        WHERE l.isbn NOT IN (
            SELECT e.isbn
            FROM emprunt e
            WHERE e.id_etudiant = id_etudiant_param
        )
    )
    SELECT
        lne.isbn,
        lne.titre,
        lne.auteur_nom,
        COUNT(e.id) as score
    FROM livres_non_empruntes lne
    JOIN genres_preferes gp ON lne.genre = gp.genre
    LEFT JOIN emprunt e ON lne.isbn = e.isbn
    GROUP BY lne.isbn, lne.titre, lne.auteur_nom
    ORDER BY score DESC, lne.titre
    LIMIT 5;
END;
$$ LANGUAGE plpgsql;

-- Procédure pour générer un rapport mensuel
CREATE OR REPLACE FUNCTION rapport_mensuel(mois INTEGER, annee INTEGER)
RETURNS TABLE(
    metric_name TEXT,
    metric_value TEXT
) AS $$
DECLARE
    date_debut DATE;
    date_fin DATE;
    nb_nouveaux_emprunts INTEGER;
    nb_retours INTEGER;
    nb_retards INTEGER;
    livre_plus_emprunte TEXT;
    etudiant_plus_actif TEXT;
BEGIN
    date_debut := DATE(annee || '-' || mois || '-01');
    date_fin := date_debut + INTERVAL '1 month' - INTERVAL '1 day';

    SELECT COUNT(*) INTO nb_nouveaux_emprunts
    FROM emprunt
    WHERE date_emprunt BETWEEN date_debut AND date_fin;

    SELECT COUNT(*) INTO nb_retours
    FROM emprunt
    WHERE date_retour_reelle BETWEEN date_debut AND date_fin;

    SELECT COUNT(*) INTO nb_retards
    FROM emprunt
    WHERE date_retour_reelle BETWEEN date_debut AND date_fin
    AND date_retour_reelle > date_retour_prevue;

    SELECT l.titre INTO livre_plus_emprunte
    FROM livre l
    JOIN emprunt e ON l.isbn = e.isbn
    WHERE e.date_emprunt BETWEEN date_debut AND date_fin
    GROUP BY l.isbn, l.titre
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    SELECT (et.prenom || ' ' || et.nom) INTO etudiant_plus_actif
    FROM etudiant et
    JOIN emprunt e ON et.id = e.id_etudiant
    WHERE e.date_emprunt BETWEEN date_debut AND date_fin
    GROUP BY et.id, et.prenom, et.nom
    ORDER BY COUNT(*) DESC
    LIMIT 1;

    RETURN QUERY VALUES
        ('Période', date_debut::TEXT || ' au ' || date_fin::TEXT),
        ('Nouveaux emprunts', nb_nouveaux_emprunts::TEXT),
        ('Retours effectués', nb_retours::TEXT),
        ('Retours en retard', nb_retards::TEXT),
        ('Livre le plus emprunté', COALESCE(livre_plus_emprunte, 'Aucun')),
        ('Étudiant le plus actif', COALESCE(etudiant_plus_actif, 'Aucun'));
END;
$$ LANGUAGE plpgsql;

-- Trigger pour archiver les anciens emprunts
CREATE TABLE IF NOT EXISTS emprunt_archive (
    LIKE emprunt INCLUDING ALL,
    date_archivage TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION archiver_anciens_emprunts()
RETURNS INTEGER AS $$
DECLARE
    nb_archives INTEGER := 0;
BEGIN
    INSERT INTO emprunt_archive (id, id_etudiant, isbn, date_emprunt, date_retour_prevue, date_retour_reelle)
    SELECT id, id_etudiant, isbn, date_emprunt, date_retour_prevue, date_retour_reelle
    FROM emprunt
    WHERE date_retour_reelle IS NOT NULL
    AND date_retour_reelle < CURRENT_DATE - INTERVAL '1 year';

    GET DIAGNOSTICS nb_archives = ROW_COUNT;

    DELETE FROM emprunt
    WHERE date_retour_reelle IS NOT NULL
    AND date_retour_reelle < CURRENT_DATE - INTERVAL '1 year';

    RETURN nb_archives;
END;
$$ LANGUAGE plpgsql;

-- Tests des fonctions bonus
SELECT 'Test fonction stats_livre' as test;
SELECT * FROM stats_livre('978-2-07-036936-4');

SELECT 'Test fonction recommandations' as test;
SELECT * FROM recommandations_etudiant(1);

SELECT 'Test rapport mensuel' as test;
SELECT * FROM rapport_mensuel(6, 2025);