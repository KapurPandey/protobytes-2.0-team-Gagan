
USE aaratico_nonet;


-- USERS TABLE
CREATE TABLE users (
  id INT(11) NOT NULL AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_username (username),
  UNIQUE KEY uq_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;


-- PENDING USERS TABLE
CREATE TABLE pending_user (
  id INT(11) NOT NULL AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  otp VARCHAR(16) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_pending_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;


-- PASSWORD RESET OTPs TABLE
CREATE TABLE password_reset_otps (
  id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  otp INT(11) NOT NULL,
  expires_at DATETIME NOT NULL,
  used TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_email (email),
  KEY idx_otp (otp),
  KEY idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


-- TRANSACTIONS TABLE
CREATE TABLE transactions (
  id INT(11) NOT NULL AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL,
  type ENUM('debit','credit','topup','fare','refund') NOT NULL,
  amount DECIMAL(18,2) NOT NULL,
  timestamp INT(11) DEFAULT CURRENT_TIMESTAMP,
  qr_hash VARCHAR(128) DEFAULT NULL,
  payment_status ENUM('pending','completed','failed') DEFAULT 'pending',
  remarks TEXT DEFAULT NULL,
  secondparty VARCHAR(64) DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_transactions_username (username),
  CONSTRAINT fk_transactions_user
    FOREIGN KEY (username) REFERENCES users(username)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;


-- USER INFO TABLE
CREATE TABLE user_info (
  id INT(11) NOT NULL AUTO_INCREMENT,
  username VARCHAR(64) NOT NULL,
  device_id VARCHAR(128) NOT NULL,
  name VARCHAR(128) DEFAULT NULL,
  public_key TEXT DEFAULT NULL,
  public_key_created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  balance DECIMAL(18,2) DEFAULT 100.00,
  PRIMARY KEY (id),
  UNIQUE KEY uq_user_device (username, device_id),
  CONSTRAINT fk_userinfo_user
    FOREIGN KEY (username) REFERENCES users(username)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
