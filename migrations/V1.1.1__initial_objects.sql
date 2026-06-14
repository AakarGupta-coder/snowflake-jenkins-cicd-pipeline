USE SCHEMA DATAOPS_DB.STAGING;

CREATE TABLE IF NOT EXISTS PATIENTS (
    PATIENT_ID INT AUTOINCREMENT START 1000 INCREMENT 1,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    DATE_OF_BIRTH DATE,
    GENDER VARCHAR(10),
    BLOOD_TYPE VARCHAR(5),
    PRIMARY_DIAGNOSIS VARCHAR(100),
    ADMISSION_DATE DATE DEFAULT CURRENT_DATE(),
    PRIMARY KEY (PATIENT_ID)
);

INSERT INTO PATIENTS (FIRST_NAME, LAST_NAME, DATE_OF_BIRTH, GENDER, BLOOD_TYPE, PRIMARY_DIAGNOSIS)
VALUES 
    ('Eleanor', 'Rigby', '1955-04-12', 'Female', 'O+', 'Type 2 Diabetes Mellitus'),
    ('Marcus', 'Aurelius', '1962-11-23', 'Male', 'A-', 'Hypertension'),
    ('Clara', 'Barton', '1988-07-09', 'Female', 'AB+', 'Asthma, Unspecified'),
    ('Alexander', 'Fleming', '1945-02-18', 'Male', 'B+', 'Coronary Artery Disease'),
    ('Florence', 'Nightingale', '1971-09-30', 'Female', 'O-', 'Rheumatoid Arthritis');
