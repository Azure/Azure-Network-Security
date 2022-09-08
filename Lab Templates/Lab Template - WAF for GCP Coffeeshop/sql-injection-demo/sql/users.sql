DROP TABLE IF EXISTS users;

/*NEVER store passwords in clear text as it's done here!!!*/
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  password TEXT NOT NULL,
  role ENUM('admin', 'consumer')
);

INSERT INTO users (name, email, password, role)
VALUES
('test', 'test@mail.ch', 'test', 'consumer'),
('admin', 'admin@mail.ch', 'admin', 'admin');
