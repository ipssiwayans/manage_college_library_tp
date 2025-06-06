-- =====================================================
-- Tests de transactions - Bibliothèque universitaire
-- Auteur: [Nom Étudiant]
-- Date: 06/06/2025
-- =====================================================

-- PARTIE 5.3 - TRANSACTION SIMULÉE

-- Version 1: Transaction simple avec vérification manuelle
DO $$
DECLARE
    nb_exemplaires_restants INTEGER;
    isbn_test TEXT := '978-2-07-036002-6';
    id_etudiant_test INTEGER := 6;
BEGIN
    BEGIN
        INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue)
        VALUES (id_etudiant_test, isbn_test, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');

        SELECT nb_exemplaires INTO nb_exemplaires_restants
        FROM livre
        WHERE isbn = isbn_test;

        SELECT COUNT(*) INTO nb_exemplaires_restants
        FROM emprunt
        WHERE isbn = isbn_test AND date_retour_reelle IS NULL;

        SELECT (l.nb_exemplaires - COUNT(e.id)) INTO nb_exemplaires_restants
        FROM livre l
        LEFT JOIN emprunt e ON l.isbn = e.isbn AND e.date_retour_reelle IS NULL
        WHERE l.isbn = isbn_test
        GROUP BY l.nb_exemplaires;

        IF nb_exemplaires_restants < 0 THEN
            RAISE EXCEPTION 'Plus d''exemplaires disponibles pour ce livre';
        END IF;

        RAISE NOTICE 'Emprunt réussi. Exemplaires restants: %', nb_exemplaires_restants;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Erreur lors de l''emprunt: %', SQLERRM;
            RAISE;
    END;
END;
$$;

-- Version 2: Transaction avec gestion d'exception complète
CREATE OR REPLACE FUNCTION tenter_emprunt(p_id_etudiant INTEGER, p_isbn TEXT)
RETURNS TEXT AS $$
DECLARE
    nb_disponibles INTEGER;
    resultat TEXT;
BEGIN
    BEGIN
        SELECT (l.nb_exemplaires - COALESCE(COUNT(e.id), 0))
        INTO nb_disponibles
        FROM livre l
        LEFT JOIN emprunt e ON l.isbn = e.isbn AND e.date_retour_reelle IS NULL
        WHERE l.isbn = p_isbn
        GROUP BY l.nb_exemplaires;

        IF nb_disponibles IS NULL THEN
            RETURN 'ERREUR: Livre introuvable';
        END IF;

        IF nb_disponibles <= 0 THEN
            RETURN 'ERREUR: Aucun exemplaire disponible';
        END IF;

        INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue)
        VALUES (p_id_etudiant, p_isbn, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');

        resultat := 'SUCCÈS: Emprunt enregistré. Exemplaires restants: ' || (nb_disponibles - 1);
        RETURN resultat;

    EXCEPTION
        WHEN unique_violation THEN
            RETURN 'ERREUR: Violation de contrainte d''unicité';
        WHEN foreign_key_violation THEN
            RETURN 'ERREUR: Étudiant ou livre inexistant';
        WHEN check_violation THEN
            RETURN 'ERREUR: Violation de contrainte de vérification';
        WHEN OTHERS THEN
            RETURN 'ERREUR: ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Tests de la fonction de transaction
SELECT tenter_emprunt(1, '978-2-07-036002-6') AS resultat_test_1;

SELECT tenter_emprunt(1, '978-2-07-036003-3') AS resultat_test_2;

SELECT tenter_emprunt(999, '978-2-07-036002-6') AS resultat_test_3;

-- Transaction complexe : retour de livre avec mise à jour des dates
CREATE OR REPLACE FUNCTION retourner_livre(p_id_emprunt INTEGER)
RETURNS TEXT AS $$
DECLARE
    date_retour_prevue_livre DATE;
    resultat TEXT;
BEGIN
    BEGIN
        SELECT date_retour_prevue INTO date_retour_prevue_livre
        FROM emprunt
        WHERE id = p_id_emprunt AND date_retour_reelle IS NULL;

        IF date_retour_prevue_livre IS NULL THEN
            RETURN 'ERREUR: Emprunt introuvable ou déjà retourné';
        END IF;

        UPDATE emprunt
        SET date_retour_reelle = CURRENT_DATE
        WHERE id = p_id_emprunt;

        IF CURRENT_DATE > date_retour_prevue_livre THEN
            resultat := 'SUCCÈS: Livre retourné avec ' || (CURRENT_DATE - date_retour_prevue_livre) || ' jour(s) de retard';
        ELSE
            resultat := 'SUCCÈS: Livre retourné à temps';
        END IF;

        RETURN resultat;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'ERREUR: ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;

-- Test de retour de livre
SELECT retourner_livre(1) AS resultat_retour;

-- Transaction de transfert d'emprunt (bonus)
CREATE OR REPLACE FUNCTION transferer_emprunt(p_id_emprunt INTEGER, p_nouvel_etudiant INTEGER)
RETURNS TEXT AS $$
DECLARE
    ancien_etudiant INTEGER;
    isbn_livre TEXT;
    resultat TEXT;
BEGIN
    BEGIN
        SELECT id_etudiant, isbn INTO ancien_etudiant, isbn_livre
        FROM emprunt
        WHERE id = p_id_emprunt AND date_retour_reelle IS NULL;

        IF ancien_etudiant IS NULL THEN
            RETURN 'ERREUR: Emprunt introuvable ou déjà retourné';
        END IF;

        UPDATE emprunt
        SET date_retour_reelle = CURRENT_DATE
        WHERE id = p_id_emprunt;

        INSERT INTO emprunt (id_etudiant, isbn, date_emprunt, date_retour_prevue)
        VALUES (p_nouvel_etudiant, isbn_livre, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 days');

        resultat := 'SUCCÈS: Emprunt transféré de l''étudiant ' || ancien_etudiant || ' vers l''étudiant ' || p_nouvel_etudiant;
        RETURN resultat;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'ERREUR: ' || SQLERRM;
    END;
END;
$$ LANGUAGE plpgsql;