

CREATE TABLE IF NOT EXISTS cash_balance (
  steamid BIGINT UNSIGNED NOT NULL,
  name VARCHAR(128) NOT NULL,
  balance INT,
  first_seen DATETIME,
  PRIMARY KEY(steamid)
);
