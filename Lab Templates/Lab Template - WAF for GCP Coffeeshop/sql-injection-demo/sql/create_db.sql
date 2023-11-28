CREATE TABLE coffee (
  id SERIAL PRIMARY KEY,
  blend_name char(64),
  origin char(64),
  variety char(64),
  notes char(64),
  intensifier char(64),
  price float
);