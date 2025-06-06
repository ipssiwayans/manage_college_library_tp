# College Library Management System

This project is a database system for managing a college library. It allows librarians to keep track of books, authors, students, and loans.

## Database Schema

The database consists of the following tables:

### `auteur`

Stores information about authors.

- `id`: SERIAL PRIMARY KEY - Unique identifier for the author.
- `nom`: TEXT NOT NULL - Last name of the author.
- `prenom`: TEXT NOT NULL - First name of the author.
- `nationalite`: TEXT NOT NULL - Nationality of the author.

### `livre`

Stores information about books.

- `isbn`: TEXT PRIMARY KEY - ISBN of the book.
- `titre`: TEXT NOT NULL - Title of the book.
- `id_auteur`: INT NOT NULL REFERENCES auteur(id) - Foreign key referencing the author of the book.
- `annee_publication`: INT NOT NULL CHECK(annee_publication > 1800) - Year of publication.
- `genre`: TEXT NOT NULL - Genre of the book.
- `nb_exemplaires`: INT NOT NULL CHECK(nb_exemplaires >= 0) - Number of copies available.

### `etudiant`

Stores information about students.

- `id`: SERIAL PRIMARY KEY - Unique identifier for the student.
- `nom`: TEXT NOT NULL - Last name of the student.
- `prenom`: TEXT NOT NULL - First name of the student.
- `date_naissance`: DATE NOT NULL - Date of birth of the student.
- `email`: TEXT UNIQUE NOT NULL - Email address of the student.
- `dernier_emprunt`: DATE - Date of the last loan made by the student.

### `emprunt`

Stores information about book loans.

- `id`: SERIAL PRIMARY KEY - Unique identifier for the loan.
- `id_etudiant`: INT NOT NULL REFERENCES etudiant(id) - Foreign key referencing the student who borrowed the book.
- `isbn`: TEXT NOT NULL REFERENCES livre(isbn) - Foreign key referencing the borrowed book.
- `date_emprunt`: DATE NOT NULL DEFAULT CURRENT_DATE - Date when the book was borrowed.
- `date_retour_prevue`: DATE NOT NULL - Expected return date.
- `date_retour_reelle`: DATE - Actual return date (NULL if not yet returned).

**Relationships:**

- A book has one author (`livre.id_auteur` references `auteur.id`).
- An author can have multiple books.
- A student can make multiple loans (`emprunt.id_etudiant` references `etudiant.id`).
- A book can be part of multiple loans (`emprunt.isbn` references `livre.isbn`).

## SQL Scripts

The `sql/` directory contains the following scripts:

- `create_table.sql`: Defines and creates the database tables, including primary keys, foreign keys, and constraints.
- `insert_data.sql`: Populates the tables with initial sample data for testing and demonstration.
- `queries.sql`: Includes a variety of SELECT queries to retrieve information from the database (e.g., finding all books by an author, listing overdue books).
- `advanced_constraints.sql`: Implements more complex data integrity rules using triggers or advanced check constraints.
- `roles.sql`: Manages database user roles and their permissions to ensure secure access to the data.
- `transaction_test.sql`: Contains SQL statements to test transaction handling (e.g., ensuring atomicity of loan operations).
- `views_and_function.sql`: Creates database views for simplified querying and functions for reusable logic (e.g., a function to calculate overdue fines).
- `bonus_features.sql`: (If applicable) Contains scripts for any additional or bonus features implemented in the database.

## Schema Diagram

The `schema/` directory contains:

- `mcd_schema.xml`: An XML file that can be imported into tools like `diagrams.net` (formerly draw.io) to view the Conceptual Data Model (CDM) or a visual representation of the database schema. This helps in understanding the table structures and their relationships.

## How to Use

To set up and use the college library database:

1.  **Create the Database:**
    *   Ensure you have a PostgreSQL server running.
    *   Create a new database (e.g., `college_library`).
    *   Connect to your newly created database using a PostgreSQL client (like `psql` or a GUI tool).

2.  **Run the SQL Scripts:**
    Execute the scripts from the `sql/` directory in the following order:
    *   `create_table.sql`: This will create all the necessary tables and their structures.
    *   `insert_data.sql`: This will populate the tables with initial data.
    *   (Optional) `advanced_constraints.sql`: To add advanced integrity checks.
    *   (Optional) `roles.sql`: To set up specific user roles and permissions.
    *   (Optional) `views_and_function.sql`: To create helpful views and functions.

    You can run these scripts using a command like:
    ```bash
    psql -U your_username -d college_library -f path/to/script.sql
    ```
    Replace `your_username` with your PostgreSQL username and `path/to/script.sql` with the actual path to each SQL file.

3.  **Query the Database:**
    *   Use the queries in `queries.sql` as examples to retrieve data. You can run them directly in your PostgreSQL client or adapt them for your applications.
    *   For example, to find all books by a specific author:
        ```sql
        SELECT l.titre, l.annee_publication
        FROM livre l
        JOIN auteur a ON l.id_auteur = a.id
        WHERE a.nom = 'Rowling' AND a.prenom = 'J.K.';
        ```

4.  **Test Transactions (Optional):**
    *   The `transaction_test.sql` script can be used to verify how transactions are handled, for instance, when recording a new book loan to ensure data consistency.

This project provides a foundational database for a college library system. You can extend it further based on specific requirements.
