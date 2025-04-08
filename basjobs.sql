CREATE TABLE IF NOT EXISTS basjobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_label VARCHAR(255) NOT NULL,
    job_name VARCHAR(255) NOT NULL
);
CREATE TABLE basjob_ranks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(255) NOT NULL,
    job_label VARCHAR(255) NOT NULL,
    label VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    grade INT NOT NULL,
    salary INT NOT NULL
);
