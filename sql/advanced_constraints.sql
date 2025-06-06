-- =====================================================
-- Contraintes métier avancées - Bibliothèque universitaire
-- Auteur: [Nom Étudiant]
-- Date: 06/06/2025
-- =====================================================

-- Fonction pour vérifier le nombre d'emprunts actifs d'un étudiant
CREATE OR REPLACE FUNCTION check_limite_emprunts()
RETURNS TRIGGER AS $
DECLARE
    nb_emprunts_actifs INT;
BEGIN
    -- Compter les emprunts non rendus de l'étudiant
    SELECT COUNT(*) INTO nb_emprunts_actifs
    FROM emprunt
    WHERE id_etudiant = NEW.id_etudiant
    AND date_retour_reelle IS NULL;

    -- Vérifier la limite de 5 emprunts
    IF nb_emprunts_actifs >= 5 THEN
        RAISE EXCEPTION 'Cet étudiant a déjà 5 emprunts en cours. Limite atteinte.';
    END IF;

    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Fonction pour vérifier la disponibilité d'un livre
CREATE OR REPLACE FUNCTION check_disponibilite_livre()
RETURNS TRIGGER AS $
DECLARE
    nb_exemplaires_total INT;
    nb_emprunts_actifs INT;
    nb_disponibles INT;
BEGIN
    -- Récupérer le nombre total d'exemplaires
    SELECT nb_exemplaires INTO nb_exemplaires_total
    FROM livre
    WHERE isbn = NEW.isbn;

    -- Compter les emprunts actifs de ce livre
    SELECT COUNT(*) INTO nb_emprunts_actifs
    FROM emprunt
    WHERE isbn = NEW.isbn
    AND date_retour_reelle IS NULL;

    -- Calculer la disponibilité
    nb_disponibles := nb_exemplaires_total - nb_emprunts_actifs;

    -- Vérifier qu'il reste des exemplaires
    IF nb_disponibles <= 0 THEN
        RAISE EXCEPTION 'Aucun exemplaire disponible pour ce livre (ISBN: %)', NEW.isbn;
    END IF;

    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Fonction pour vérifier qu'un étudiant n'emprunte pas deux fois le même livre
CREATE OR REPLACE FUNCTION check_double_emprunt()
RETURNS TRIGGER AS $
DECLARE
    nb_emprunts_actifs INT;
BEGIN
    -- Vérifier si l'étudiant a déjà ce livre en cours d'emprunt
    SELECT COUNT(*) INTO nb_emprunts_actifs
    FROM emprunt
    WHERE id_etudiant = NEW.id_etudiant
    AND isbn = NEW.isbn
    AND date_retour_reelle IS NULL;

    IF nb_emprunts_actifs > 0 THEN
        RAISE EXCEPTION 'Cet étudiant a déjà emprunté ce livre et ne l''a pas encore rendu';
    END IF;

    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Fonction pour mettre à jour la date de dernier emprunt
CREATE OR REPLACE FUNCTION update_dernier_emprunt()
RETURNS TRIGGER AS $
BEGIN
    -- Mettre à jour la date de dernier emprunt de l'étudiant
    UPDATE etudiant
    SET dernier_emprunt = NEW.date_emprunt
    WHERE id = NEW.id_etudiant;

    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Création des triggers
CREATE TRIGGER trigger_limite_emprunts
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_limite_emprunts();

CREATE TRIGGER trigger_disponibilite_livre
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_disponibilite_livre();

CREATE TRIGGER trigger_double_emprunt
    BEFORE INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION check_double_emprunt();

CREATE TRIGGER trigger_update_dernier_emprunt
    AFTER INSERT ON emprunt
    FOR EACH ROW
    EXECUTE FUNCTION update_dernier_emprunt();

-- Vue pour afficher les livres disponibles
CREATE VIEW v_livres_disponibles AS
SELECT
    l.isbn,
    l.titre,
    CONCAT(a.prenom, ' ', a.nom) AS auteur_complet,
    l.genre,
    l.annee_publication,
    l.nb_exemplaires,
    COUNT(e.id) as emprunts_actifs,
    (l.nb_exemplaires - COUNT(e.id)) as exemplaires_disponibles
FROM livre l
JOIN auteur a ON l.id_auteur = a.id
LEFT JOIN emprunt e ON l.isbn = e.isbn AND e.date_retour_reelle IS NULL
GROUP BY l.isbn, l.titre, a.prenom, a.nom, l.genre, l.annee_publication, l.nb_exemplaires
HAVING (l.nb_exemplaires - COUNT(e.id)) > 0
ORDER BY l.titre;

-- Vue pour les emprunts en retard
CREATE VIEW v_emprunts_en_retard AS
SELECT
    e.id,
    CONCAT(et.prenom, ' ', et.nom) AS etudiant_complet,
    et.email,
    l.titre,
    e.date_emprunt,
    e.date_retour_prevue,
    (CURRENT_DATE - e.date_retour_prevue) AS jours_retard
FROM emprunt e
JOIN etudiant et ON e.id_etudiant = et.id
JOIN livre l ON e.isbn = l.isbn
WHERE e.date_retour_reelle IS NULL
AND e.date_retour_prevue < CURRENT_DATE
ORDER BY jours_retard DESC;

-- Commentaires sur les fonctions
COMMENT ON FUNCTION check_limite_emprunts() IS 'Vérifie qu''un étudiant ne dépasse pas 5 emprunts simultanés';
COMMENT ON FUNCTION check_disponibilite_livre() IS 'Vérifie qu''il reste des exemplaires disponibles avant emprunt';
COMMENT ON FUNCTION check_double_emprunt() IS 'Empêche un étudiant d''emprunter deux fois le même livre';
COMMENT ON VIEW v_livres_disponibles IS 'Vue des livres ayant au moins un exemplaire disponible';
COMMENT ON VIEW v_emprunts_en_retard IS 'Vue des emprunts non rendus avec dépassement de la date prévue';