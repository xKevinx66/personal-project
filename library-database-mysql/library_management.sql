/* ============================================================
   期末作业 - MySQL 8.0 数据库系统实现
   题目：图书馆借阅管理系统
   Portfolio version: personal identifiers removed
   ============================================================ */

-- ============================================================
-- 0) 创建数据库
-- ============================================================
DROP DATABASE IF EXISTS library_portfolio;
CREATE DATABASE library_portfolio
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE library_portfolio;

SET NAMES utf8mb4;
SET sql_safe_updates = 0;

-- ============================================================
-- 1) 建表（DDL）—— 13 张业务表 + 1 张日志表（audit_log）
--    注：业务表数量 >= 10，audit_log 为日志表，不计入业务表数量。
-- ============================================================

/* 1.1 读者表 */
CREATE TABLE members (
  member_id     BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  card_no       VARCHAR(20)  NOT NULL COMMENT '借书证号/学号',
  name          VARCHAR(50)  NOT NULL COMMENT '姓名',
  gender        TINYINT      DEFAULT 0 COMMENT '0未知/1男/2女',
  phone         VARCHAR(20)  COMMENT '电话',
  email         VARCHAR(100) COMMENT '邮箱',
  id_card       VARCHAR(18)  COMMENT '证件号(可空)',
  register_date DATE         NOT NULL COMMENT '注册日期',
  status        TINYINT      DEFAULT 1 COMMENT '1正常/0停用',
  created_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_members_card_no (card_no),
  UNIQUE KEY uk_members_id_card (id_card)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.2 馆员表 */
CREATE TABLE librarians (
  librarian_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  employee_no  VARCHAR(20) NOT NULL COMMENT '工号',
  name         VARCHAR(50) NOT NULL COMMENT '姓名',
  phone        VARCHAR(20) COMMENT '电话',
  email        VARCHAR(100) COMMENT '邮箱',
  `role`         TINYINT     DEFAULT 1 COMMENT '1普通馆员/2管理员',
  status       TINYINT     DEFAULT 1 COMMENT '1在岗/0离岗',
  created_at   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP   DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_librarians_employee_no (employee_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.3 作者表 */
CREATE TABLE authors (
  author_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  full_name   VARCHAR(100) NOT NULL COMMENT '作者名',
  country     VARCHAR(50) COMMENT '国别',
  birth_year  SMALLINT COMMENT '出生年',
  death_year  SMALLINT COMMENT '去世年',
  bio         TEXT COMMENT '简介',
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.4 分类表（支持父子分类） */
CREATE TABLE categories (
  category_id  INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name         VARCHAR(50) NOT NULL COMMENT '分类名称',
  parent_id    INT UNSIGNED NULL COMMENT '父分类ID',
  description  VARCHAR(200) COMMENT '描述',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_categories_name (name),
  KEY idx_categories_parent (parent_id),
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_id) REFERENCES categories(category_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.5 书目表（ISBN 维度） */
CREATE TABLE books (
  book_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  isbn         CHAR(13) NOT NULL COMMENT 'ISBN-13',
  title        VARCHAR(200) NOT NULL COMMENT '书名',
  subtitle     VARCHAR(200) COMMENT '副标题',
  publisher    VARCHAR(120) COMMENT '出版社',
  publish_date DATE COMMENT '出版日期',
  language     VARCHAR(30) COMMENT '语言',
  edition      VARCHAR(30) COMMENT '版次',
  pages        INT UNSIGNED COMMENT '页数',
  summary      TEXT COMMENT '简介',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_books_isbn (isbn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.6 馆藏副本表（条码维度） */
CREATE TABLE book_copies (
  copy_id             BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  book_id             BIGINT UNSIGNED NOT NULL COMMENT '书目ID',
  barcode             VARCHAR(32) NOT NULL COMMENT '副本条码',
  shelf_location      VARCHAR(50) NOT NULL COMMENT '书架位置',
  acquisition_date    DATE COMMENT '入馆日期',
  price               DECIMAL(10,2) DEFAULT 0 COMMENT '购入价格',
  status              TINYINT DEFAULT 1 COMMENT '1在馆/2借出/3预约锁定/4丢失/5维修',
  condition_grade     TINYINT DEFAULT 2 COMMENT '1新/2良好/3磨损',
  last_inventory_date DATE COMMENT '最近盘点日期',
  remark              VARCHAR(200) COMMENT '备注',
  UNIQUE KEY uk_book_copies_barcode (barcode),
  KEY idx_book_copies_book_id (book_id),
  CONSTRAINT fk_book_copies_book
    FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.7 书目-作者关系表（多对多） */
CREATE TABLE book_authors (
  book_id       BIGINT UNSIGNED NOT NULL COMMENT '书目ID',
  author_id     BIGINT UNSIGNED NOT NULL COMMENT '作者ID',
  author_order  TINYINT UNSIGNED DEFAULT 1 COMMENT '作者顺序',
  `role`          VARCHAR(20) DEFAULT 'author' COMMENT 'author/translator/reviewer/editor',
  PRIMARY KEY (book_id, author_id),
  KEY idx_book_authors_author (author_id),
  CONSTRAINT fk_book_authors_book
    FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_book_authors_author
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.8 书目-分类关系表（多对多） */
CREATE TABLE book_categories (
  book_id     BIGINT UNSIGNED NOT NULL COMMENT '书目ID',
  category_id INT UNSIGNED NOT NULL COMMENT '分类ID',
  is_primary  BOOLEAN DEFAULT FALSE COMMENT '是否主分类',
  PRIMARY KEY (book_id, category_id),
  KEY idx_book_categories_category (category_id),
  CONSTRAINT fk_book_categories_book
    FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_book_categories_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.9 借阅单表 */
CREATE TABLE loans (
  loan_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  member_id    BIGINT UNSIGNED NOT NULL COMMENT '借阅人',
  librarian_id BIGINT UNSIGNED NOT NULL COMMENT '经办馆员',
  loan_time    DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '借出时间',
  due_date     DATE NOT NULL COMMENT '应还日期（整单）',
  return_time  DATETIME NULL COMMENT '全部归还时间',
  status       TINYINT DEFAULT 1 COMMENT '1进行中/2已关闭/3逾期/4取消',
  note         VARCHAR(200) COMMENT '备注',
  KEY idx_loans_member (member_id),
  KEY idx_loans_librarian (librarian_id),
  KEY idx_loans_loan_time (loan_time),
  CONSTRAINT fk_loans_member
    FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_loans_librarian
    FOREIGN KEY (librarian_id) REFERENCES librarians(librarian_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.10 借阅明细表（到副本级别） */
CREATE TABLE loan_items (
  loan_item_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  loan_id      BIGINT UNSIGNED NOT NULL COMMENT '借阅单ID',
  copy_id      BIGINT UNSIGNED NOT NULL COMMENT '副本ID',
  due_date     DATE NOT NULL COMMENT '单本应还日期',
  returned_at  DATETIME NULL COMMENT '归还时间',
  renew_count  TINYINT UNSIGNED DEFAULT 0 COMMENT '续借次数',
  item_status  TINYINT DEFAULT 1 COMMENT '1借出/2已还/3丢失',
  remark       VARCHAR(200) COMMENT '备注',
  UNIQUE KEY uk_loan_items_loan_copy (loan_id, copy_id),
  KEY idx_loan_items_copy (copy_id),
  KEY idx_loan_items_due (due_date),
  CONSTRAINT fk_loan_items_loan
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_loan_items_copy
    FOREIGN KEY (copy_id) REFERENCES book_copies(copy_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.11 预约表 */
CREATE TABLE reservations (
  reservation_id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  member_id      BIGINT UNSIGNED NOT NULL COMMENT '预约人',
  book_id        BIGINT UNSIGNED NOT NULL COMMENT '预约书目',
  request_time   DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '预约时间',
  expire_time    DATETIME NULL COMMENT '过期时间',
  status         TINYINT DEFAULT 1 COMMENT '1排队中/2已通知/3已取书/4取消/5过期',
  pickup_copy_id BIGINT UNSIGNED NULL COMMENT '分配副本(可空)',
  remark         VARCHAR(200) COMMENT '备注',
  KEY idx_reservations_book (book_id),
  KEY idx_reservations_member (member_id),
  KEY idx_reservations_status (status),
  CONSTRAINT fk_reservations_member
    FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_reservations_book
    FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_reservations_pickup_copy
    FOREIGN KEY (pickup_copy_id) REFERENCES book_copies(copy_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.12 罚款表 */
CREATE TABLE fines (
  fine_id      BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  member_id    BIGINT UNSIGNED NOT NULL COMMENT '读者ID',
  loan_item_id BIGINT UNSIGNED NOT NULL COMMENT '借阅明细ID',
  fine_type    TINYINT NOT NULL COMMENT '1逾期/2丢失/3损坏',
  amount       DECIMAL(10,2) NOT NULL COMMENT '罚款金额',
  assessed_at  DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '生成时间',
  status       TINYINT DEFAULT 1 COMMENT '1未缴/2已缴/3减免',
  note         VARCHAR(200) COMMENT '备注',
  KEY idx_fines_member (member_id),
  KEY idx_fines_status (status),
  CONSTRAINT fk_fines_member
    FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_fines_loan_item
    FOREIGN KEY (loan_item_id) REFERENCES loan_items(loan_item_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.13 罚款缴费流水表 */
CREATE TABLE fine_payments (
  payment_id   BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  fine_id      BIGINT UNSIGNED NOT NULL COMMENT '罚款ID',
  member_id    BIGINT UNSIGNED NOT NULL COMMENT '缴费人',
  librarian_id BIGINT UNSIGNED NOT NULL COMMENT '收款馆员',
  pay_amount   DECIMAL(10,2) NOT NULL COMMENT '支付金额',
  pay_method   TINYINT DEFAULT 3 COMMENT '1现金/2刷卡/3支付宝/4微信',
  pay_time     DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '支付时间',
  status       TINYINT DEFAULT 1 COMMENT '1成功/2已退款',
  KEY idx_fine_payments_fine (fine_id),
  KEY idx_fine_payments_member (member_id),
  KEY idx_fine_payments_pay_time (pay_time),
  CONSTRAINT fk_fine_payments_fine
    FOREIGN KEY (fine_id) REFERENCES fines(fine_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_fine_payments_member
    FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_fine_payments_librarian
    FOREIGN KEY (librarian_id) REFERENCES librarians(librarian_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* 1.14 日志表：审计日志（不计入业务表数量） */
CREATE TABLE audit_log (
  audit_id    BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  table_name  VARCHAR(64) NOT NULL COMMENT '来源表',
  action      VARCHAR(10) NOT NULL COMMENT 'INSERT/UPDATE/DELETE',
  pk_value    VARCHAR(255) NOT NULL COMMENT '主键值(可为复合键描述)',
  changed_at  DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '发生时间',
  detail_json JSON NULL COMMENT '简要数据(JSON)',
  KEY idx_audit_table_time (table_name, changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- 2) 插入测试数据（每表 ≥ 10 条）
-- ============================================================

/* 2.1 members（10条） */
INSERT INTO members (member_id, card_no, name, gender, phone, email, id_card, register_date, status)
VALUES
  (1,'M0001','张一',1,'13800000001','m0001@demo.com',NULL,'2025-01-02',1),
  (2,'M0002','李二',2,'13800000002','m0002@demo.com',NULL,'2025-01-03',1),
  (3,'M0003','王三',1,'13800000003','m0003@demo.com',NULL,'2025-01-05',1),
  (4,'M0004','赵四',2,'13800000004','m0004@demo.com',NULL,'2025-01-06',1),
  (5,'M0005','钱五',0,'13800000005','m0005@demo.com',NULL,'2025-01-08',1),
  (6,'M0006','孙六',1,'13800000006','m0006@demo.com',NULL,'2025-01-10',1),
  (7,'M0007','周七',2,'13800000007','m0007@demo.com',NULL,'2025-01-12',1),
  (8,'M0008','吴八',1,'13800000008','m0008@demo.com',NULL,'2025-01-15',1),
  (9,'M0009','郑九',2,'13800000009','m0009@demo.com',NULL,'2025-01-18',1),
  (10,'M0010','冯十',1,'13800000010','m0010@demo.com',NULL,'2025-01-20',1);

/* 2.2 librarians（10条） */
INSERT INTO librarians (librarian_id, employee_no, name, phone, email, `role`, status)
VALUES
  (1,'EMP0001','馆员甲','13900000001','emp0001@demo.com',2,1),
  (2,'EMP0002','馆员乙','13900000002','emp0002@demo.com',1,1),
  (3,'EMP0003','馆员丙','13900000003','emp0003@demo.com',1,1),
  (4,'EMP0004','馆员丁','13900000004','emp0004@demo.com',1,1),
  (5,'EMP0005','馆员戊','13900000005','emp0005@demo.com',1,1),
  (6,'EMP0006','馆员己','13900000006','emp0006@demo.com',1,1),
  (7,'EMP0007','馆员庚','13900000007','emp0007@demo.com',1,1),
  (8,'EMP0008','馆员辛','13900000008','emp0008@demo.com',1,1),
  (9,'EMP0009','馆员壬','13900000009','emp0009@demo.com',1,1),
  (10,'EMP0010','馆员癸','13900000010','emp0010@demo.com',1,1);

/* 2.3 authors（10条） */
INSERT INTO authors (author_id, full_name, country, birth_year, death_year, bio)
VALUES
  (1,'Robert C. Martin','USA',1952,NULL,'Software craftsmanship advocate.'),
  (2,'Donald E. Knuth','USA',1938,NULL,'Computer scientist, author of TAOCP.'),
  (3,'周志华','China',1973,NULL,'Machine learning researcher.'),
  (4,'J.K. Rowling','UK',1965,NULL,'Author of Harry Potter series.'),
  (5,'余华','China',1960,NULL,'Contemporary Chinese novelist.'),
  (6,'Yuval Noah Harari','Israel',1976,NULL,'Historian and philosopher.'),
  (7,'Adam Smith','UK',1723,1790,'Economist, author of The Wealth of Nations.'),
  (8,'Plato','Greece',-427,-347,'Ancient Greek philosopher.'),
  (9,'Walter Isaacson','USA',1952,NULL,'Biographer.'),
  (10,'Andrew Ng','USA',1976,NULL,'AI researcher and educator.');

/* 2.4 categories（10条，含父子关系） */
INSERT INTO categories (category_id, name, parent_id, description)
VALUES
  (1,'Technology',NULL,'General technology'),
  (2,'Computer Science',1,'CS and software'),
  (3,'Machine Learning',2,'ML and data mining'),
  (4,'Literature',NULL,'Novels and literature'),
  (5,'Chinese Literature',4,'Chinese novels'),
  (6,'World Literature',4,'World novels'),
  (7,'History',NULL,'World history'),
  (8,'Economics',NULL,'Economics and finance'),
  (9,'Philosophy',NULL,'Philosophy and thinking'),
  (10,'Biography',NULL,'Biographies');

/* 2.5 books（10条） */
INSERT INTO books (book_id, isbn, title, subtitle, publisher, publish_date, language, edition, pages, summary)
VALUES
  (1,'9780132350884','Clean Code','A Handbook of Agile Software Craftsmanship','Prentice Hall','2008-08-11','English','1st',464,'Coding best practices.'),
  (2,'9780201558029','The Art of Computer Programming','Volume 1: Fundamental Algorithms','Addison-Wesley','1997-01-01','English','3rd',672,'Classic algorithms series.'),
  (3,'9787302444545','机器学习','基础与实践','清华大学出版社','2016-01-01','Chinese','1st',425,'Machine learning textbook.'),
  (4,'9780747532743','Harry Potter and the Philosopher''s Stone',NULL,'Bloomsbury','1997-06-26','English','1st',223,'Fantasy novel.'),
  (5,'9787506365437','活着',NULL,'作家出版社','2012-05-01','Chinese','3rd',191,'A story of survival.'),
  (6,'9780062316097','Sapiens','A Brief History of Humankind','Harper','2015-02-10','English','1st',498,'Human history overview.'),
  (7,'9780140432082','The Wealth of Nations',NULL,'Penguin Classics','1999-03-01','English','1st',1264,'Economics classic.'),
  (8,'9780140455113','The Republic',NULL,'Penguin Classics','2007-01-30','English','2nd',416,'Philosophy classic.'),
  (9,'9781501127625','Steve Jobs',NULL,'Simon & Schuster','2011-10-24','English','1st',656,'Biography of Steve Jobs.'),
  (10,'9781617294433','Machine Learning Yearning',NULL,'Manning','2018-01-01','English','Draft',200,'Practical ML project guidance.');

/* 2.6 book_copies（15条 >= 10） */
INSERT INTO book_copies (copy_id, book_id, barcode, shelf_location, acquisition_date, price, status, condition_grade, last_inventory_date, remark)
VALUES
  (1,1,'BC000001','A1-01','2024-09-01',88.00,2,2,'2025-01-01','Borrowed'),
  (2,1,'BC000002','A1-01','2024-09-02',88.00,1,2,'2025-01-01','Available'),
  (3,2,'BC000003','A1-02','2024-09-05',199.00,2,2,'2025-01-01','Borrowed'),
  (4,2,'BC000004','A1-02','2024-09-06',199.00,1,2,'2025-01-01','Available'),
  (5,3,'BC000005','A2-01','2024-10-01',69.00,2,2,'2025-01-01','Borrowed'),
  (6,3,'BC000006','A2-01','2024-10-02',69.00,1,2,'2025-01-01','Available'),
  (7,4,'BC000007','B1-01','2024-11-01',59.00,2,2,'2025-01-01','Borrowed'),
  (8,5,'BC000008','B2-01','2024-11-05',39.00,2,3,'2025-01-01','Borrowed'),
  (9,6,'BC000009','C1-01','2024-12-01',79.00,2,2,'2025-01-01','Borrowed'),
  (10,7,'BC000010','C2-01','2024-12-05',99.00,2,2,'2025-01-01','Borrowed'),
  (11,8,'BC000011','D1-01','2024-12-10',45.00,1,2,'2025-01-01','Available'),
  (12,9,'BC000012','D2-01','2024-12-12',128.00,1,2,'2025-01-01','Available'),
  (13,10,'BC000013','A3-01','2024-12-20',0.00,1,2,'2025-01-01','Available'),
  (14,6,'BC000014','C1-01','2024-12-02',79.00,1,2,'2025-01-01','Available'),
  (15,4,'BC000015','B1-01','2024-11-02',59.00,1,2,'2025-01-01','Available');

/* 2.7 book_authors（12条 >= 10） */
INSERT INTO book_authors (book_id, author_id, author_order, `role`)
VALUES
  (1,1,1,'author'),
  (2,2,1,'author'),
  (3,3,1,'author'),
  (4,4,1,'author'),
  (5,5,1,'author'),
  (6,6,1,'author'),
  (7,7,1,'author'),
  (8,8,1,'author'),
  (9,9,1,'author'),
  (10,10,1,'author'),
  (10,3,2,'reviewer'),
  (6,9,2,'editor');

/* 2.8 book_categories（12条 >= 10） */
INSERT INTO book_categories (book_id, category_id, is_primary)
VALUES
  (1,2,TRUE),
  (2,2,TRUE),
  (3,3,TRUE),
  (10,3,TRUE),
  (4,6,TRUE),
  (5,5,TRUE),
  (6,7,TRUE),
  (7,8,TRUE),
  (8,9,TRUE),
  (9,10,TRUE),
  (6,10,FALSE),
  (1,1,FALSE);

/* 2.9 loans（10条） */
INSERT INTO loans (loan_id, member_id, librarian_id, loan_time, due_date, return_time, status, note)
VALUES
  (1,1,1,'2025-06-01 10:00:00','2025-06-15',NULL,1,'First loan'),
  (2,2,2,'2025-06-02 11:20:00','2025-06-16',NULL,1,NULL),
  (3,3,2,'2025-06-03 09:10:00','2025-06-17','2025-06-10 14:00:00',2,'Returned early'),
  (4,4,3,'2025-06-04 15:30:00','2025-06-18',NULL,1,NULL),
  (5,5,3,'2025-06-05 16:40:00','2025-06-19',NULL,1,NULL),
  (6,6,4,'2025-06-06 13:05:00','2025-06-20',NULL,1,NULL),
  (7,7,5,'2025-06-07 09:00:00','2025-06-21','2025-06-21 10:00:00',2,NULL),
  (8,8,6,'2025-06-08 10:30:00','2025-06-22',NULL,3,'Overdue risk'),
  (9,9,7,'2025-06-09 14:20:00','2025-06-23',NULL,1,NULL),
  (10,10,8,'2025-06-10 08:50:00','2025-06-24',NULL,1,NULL);

/* 2.10 loan_items（12条 >= 10） */
INSERT INTO loan_items (loan_item_id, loan_id, copy_id, due_date, returned_at, renew_count, item_status, remark)
VALUES
  (1,1,1,'2025-06-15',NULL,0,1,NULL),
  (2,2,3,'2025-06-16',NULL,0,1,NULL),
  (3,3,5,'2025-06-17','2025-06-10 14:00:00',0,2,'Returned'),
  (4,4,7,'2025-06-18',NULL,0,1,NULL),
  (5,5,8,'2025-06-19',NULL,1,1,'Renewed once'),
  (6,6,9,'2025-06-20',NULL,0,1,NULL),
  (7,7,10,'2025-06-21','2025-06-21 10:00:00',0,2,'Returned'),
  (8,8,2,'2025-06-22',NULL,0,1,NULL),
  (9,9,6,'2025-06-23',NULL,0,1,NULL),
  (10,10,4,'2025-06-24',NULL,0,1,NULL),
  (11,1,11,'2025-06-15',NULL,0,1,'Second item in same loan'),
  (12,2,12,'2025-06-16',NULL,0,1,'Second item in same loan');

/* 2.11 reservations（10条） */
INSERT INTO reservations (reservation_id, member_id, book_id, request_time, expire_time, status, pickup_copy_id, remark)
VALUES
  (1,3,1,'2025-06-01 12:00:00','2025-06-05 12:00:00',1,NULL,'Queueing'),
  (2,4,1,'2025-06-01 12:10:00','2025-06-05 12:10:00',1,NULL,'Queueing'),
  (3,5,4,'2025-06-02 09:00:00','2025-06-06 09:00:00',2,15,'Notified pickup'),
  (4,6,4,'2025-06-02 10:00:00','2025-06-06 10:00:00',1,NULL,'Queueing'),
  (5,7,6,'2025-06-03 08:00:00','2025-06-07 08:00:00',3,14,'Picked up'),
  (6,8,3,'2025-06-03 10:30:00','2025-06-07 10:30:00',1,NULL,'Queueing'),
  (7,9,2,'2025-06-04 14:00:00','2025-06-08 14:00:00',4,NULL,'Cancelled'),
  (8,10,9,'2025-06-05 16:00:00','2025-06-09 16:00:00',2,12,'Notified pickup'),
  (9,1,10,'2025-06-06 09:00:00','2025-06-10 09:00:00',1,13,'Assigned copy'),
  (10,2,8,'2025-06-06 09:05:00','2025-06-10 09:05:00',5,NULL,'Expired');

/* 2.12 fines（10条） */
INSERT INTO fines (fine_id, member_id, loan_item_id, fine_type, amount, assessed_at, status, note)
VALUES
  (1,1,1,1,5.00,'2025-06-16 09:00:00',1,'Overdue 1 day'),
  (2,2,2,1,10.00,'2025-06-17 09:00:00',2,'Paid'),
  (3,3,3,3,20.00,'2025-06-11 10:00:00',2,'Paid'),
  (4,4,4,1,8.00,'2025-06-19 09:00:00',1,'Overdue'),
  (5,5,5,1,6.00,'2025-06-20 09:00:00',1,'Overdue'),
  (6,6,6,2,79.00,'2025-06-21 09:00:00',1,'Lost copy'),
  (7,7,7,1,3.00,'2025-06-22 09:00:00',2,'Paid'),
  (8,8,8,1,12.00,'2025-06-23 09:00:00',1,'Overdue'),
  (9,9,9,1,4.00,'2025-06-24 09:00:00',1,'Overdue'),
  (10,10,10,1,7.00,'2025-06-25 09:00:00',2,'Paid');

/* 2.13 fine_payments（10条） */
INSERT INTO fine_payments (payment_id, fine_id, member_id, librarian_id, pay_amount, pay_method, pay_time, status)
VALUES
  (1,2,2,1,10.00,3,'2025-06-17 10:00:00',1),
  (2,3,3,2,20.00,4,'2025-06-11 10:20:00',1),
  (3,7,7,3,3.00,1,'2025-06-22 10:00:00',1),
  (4,10,10,4,7.00,2,'2025-06-25 10:00:00',1),
  (5,1,1,1,2.00,3,'2025-06-16 10:10:00',1),
  (6,1,1,2,3.00,4,'2025-06-16 11:00:00',1),
  (7,6,6,2,30.00,3,'2025-06-21 11:30:00',1),
  (8,6,6,2,49.00,3,'2025-06-21 12:00:00',1),
  (9,5,5,3,6.00,4,'2025-06-20 12:00:00',1),
  (10,4,4,3,8.00,1,'2025-06-19 12:00:00',1);

-- ============================================================
-- 3) 查询语句（≥10条；包含多表联接、子查询、分组统计、窗口函数）
-- ============================================================

/* Q1 多表联接：未归还借阅明细（成员+书名+条码+到期日） */
SELECT
  l.loan_id,
  m.name AS member_name,
  b.title,
  bc.barcode,
  li.due_date,
  li.returned_at
FROM loans l
JOIN members m      ON l.member_id = m.member_id
JOIN loan_items li  ON l.loan_id = li.loan_id
JOIN book_copies bc ON li.copy_id = bc.copy_id
JOIN books b        ON bc.book_id = b.book_id
WHERE li.returned_at IS NULL
ORDER BY li.due_date;

/* Q2 分组统计：按分类统计借阅次数 */
SELECT
  c.category_id,
  c.name AS category_name,
  COUNT(*) AS borrow_times
FROM loan_items li
JOIN book_copies bc      ON li.copy_id = bc.copy_id
JOIN book_categories bct ON bc.book_id = bct.book_id
JOIN categories c        ON bct.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY borrow_times DESC, c.category_id;

/* Q3 TopN：借阅次数最多的书目Top5 */
SELECT
  b.book_id,
  b.title,
  COUNT(*) AS borrow_times
FROM loan_items li
JOIN book_copies bc ON li.copy_id = bc.copy_id
JOIN books b        ON bc.book_id = b.book_id
GROUP BY b.book_id, b.title
ORDER BY borrow_times DESC, b.book_id
LIMIT 5;

/* Q4 子查询 + HAVING：借阅册数高于平均借阅册数的读者 */
SELECT
  m.member_id,
  m.name,
  COUNT(li.loan_item_id) AS borrow_items
FROM members m
JOIN loans l       ON m.member_id = l.member_id
JOIN loan_items li ON l.loan_id = li.loan_id
GROUP BY m.member_id, m.name
HAVING COUNT(li.loan_item_id) >
  (SELECT AVG(borrow_cnt)
   FROM (
     SELECT COUNT(li2.loan_item_id) AS borrow_cnt
     FROM loans l2
     JOIN loan_items li2 ON l2.loan_id = li2.loan_id
     GROUP BY l2.member_id
   ) t)
ORDER BY borrow_items DESC;

/* Q5 窗口函数：预约队列序号（仅排队中 status=1） */
SELECT
  r.book_id,
  b.title,
  r.reservation_id,
  m.name AS member_name,
  r.status,
  r.request_time,
  ROW_NUMBER() OVER (PARTITION BY r.book_id ORDER BY r.request_time) AS queue_no
FROM reservations r
JOIN books b   ON r.book_id = b.book_id
JOIN members m ON r.member_id = m.member_id
WHERE r.status = 1
ORDER BY r.book_id, queue_no;

/* Q6 EXISTS 子查询：至少有1本“在馆可借”副本的书目 */
SELECT
  b.book_id,
  b.title
FROM books b
WHERE EXISTS (
  SELECT 1
  FROM book_copies bc
  WHERE bc.book_id = b.book_id
    AND bc.status = 1
)
ORDER BY b.book_id;

/* Q7 统计：每位读者罚款总额、已缴金额、未缴金额 */
SELECT
  m.member_id,
  m.name,
  SUM(f.amount) AS total_fined,
  IFNULL(SUM(p.paid_amount), 0) AS total_paid,
  SUM(f.amount) - IFNULL(SUM(p.paid_amount), 0) AS outstanding
FROM members m
JOIN fines f ON m.member_id = f.member_id
LEFT JOIN (
  SELECT fine_id, SUM(pay_amount) AS paid_amount
  FROM fine_payments
  WHERE status = 1
  GROUP BY fine_id
) p ON f.fine_id = p.fine_id
GROUP BY m.member_id, m.name
ORDER BY outstanding DESC;

/* Q8 多表联接：按借书证号查询该读者罚款明细（含书名、条码） */
SELECT
  f.fine_id,
  m.name AS member_name,
  b.title,
  bc.barcode,
  f.fine_type,
  f.amount,
  f.status
FROM fines f
JOIN members m      ON f.member_id = m.member_id
JOIN loan_items li  ON f.loan_item_id = li.loan_item_id
JOIN book_copies bc ON li.copy_id = bc.copy_id
JOIN books b        ON bc.book_id = b.book_id
WHERE m.card_no = 'M0001'
ORDER BY f.fine_id;

/* Q9 业务查询：逾期未还的借阅明细 + 逾期天数 */
SELECT
  m.name AS member_name,
  b.title,
  bc.barcode,
  li.due_date,
  DATEDIFF(CURDATE(), li.due_date) AS overdue_days
FROM loan_items li
JOIN loans l        ON li.loan_id = l.loan_id
JOIN members m      ON l.member_id = m.member_id
JOIN book_copies bc ON li.copy_id = bc.copy_id
JOIN books b        ON bc.book_id = b.book_id
WHERE li.returned_at IS NULL
  AND li.due_date < CURDATE()
ORDER BY overdue_days DESC, li.loan_item_id;

/* Q10 分组统计：按月份统计借阅单数与借阅册数 */
SELECT
  DATE_FORMAT(l.loan_time, '%Y-%m') AS month,
  COUNT(DISTINCT l.loan_id) AS loan_count,
  COUNT(li.loan_item_id) AS borrowed_items
FROM loans l
JOIN loan_items li ON l.loan_id = li.loan_id
GROUP BY month
ORDER BY month;

-- ============================================================
-- 4) 性能优化（索引 + EXPLAIN 对比 + 统计直方图）
-- ============================================================

/* ------------------------------------------------------------
   4.1 索引优化：为每张表创建至少一个“额外的”非主键索引
       （部分表已在建表时包含索引，这里补充业务高频字段/组合索引）
   ------------------------------------------------------------ */

-- 4.1.1 EXPLAIN（创建索引前）—— 选择 3 条代表性查询进行对比

/* P1：loan_items 常用条件 returned_at IS NULL + ORDER BY due_date */
EXPLAIN
SELECT loan_item_id, due_date
FROM loan_items
WHERE returned_at IS NULL
ORDER BY due_date
LIMIT 20;

/* P2：reservations 常用查询 status + book_id + request_time 排序 */
EXPLAIN
SELECT reservation_id, book_id, request_time
FROM reservations
WHERE status = 1 AND book_id = 1
ORDER BY request_time
LIMIT 20;

/* P3：books 书名前缀检索 */
EXPLAIN
SELECT book_id, title
FROM books
WHERE title LIKE 'Machine%'
ORDER BY title;

-- 4.1.2 创建索引（每表至少 1 个新索引，并说明用途）

/* members：常用按状态+姓名检索/统计（例如停用用户、姓名模糊查询） */
CREATE INDEX idx_members_status_name ON members(status, name);

/* librarians：按在岗状态、角色统计/筛选 */
CREATE INDEX idx_librarians_status_role ON librarians(status, ``role``);

/* authors：按作者名检索 */
CREATE INDEX idx_authors_full_name ON authors(full_name);

/* categories：按创建时间做管理统计（示例用途） */
CREATE INDEX idx_categories_created_at ON categories(created_at);

/* books：书名检索（前缀索引减少索引体积，适用于 LIKE 'xxx%'） */
CREATE INDEX idx_books_title_prefix ON books(title(50));

/* book_copies：按副本状态筛选（在馆/借出/丢失等） */
CREATE INDEX idx_book_copies_status ON book_copies(status);

/* book_authors：按角色筛选（作者/译者/编辑等） */
CREATE INDEX idx_book_authors_role ON book_authors(`role`);

/* book_categories：主分类筛选（主分类展示） */
CREATE INDEX idx_book_categories_primary ON book_categories(is_primary);

/* loans：读者+状态+时间范围检索（高频：查某读者最近借阅、逾期单） */
CREATE INDEX idx_loans_member_status_time ON loans(member_id, status, loan_time);

/* loan_items：returned_at + due_date 复合索引，优化“未归还+按到期日排序/范围” */
CREATE INDEX idx_loan_items_returned_due ON loan_items(returned_at, due_date);

/* reservations：status + book_id + request_time 复合索引，优化排队队列查询 */
CREATE INDEX idx_reservations_status_book_time ON reservations(status, book_id, request_time);

/* fines：按罚款类型+状态筛选（逾期/丢失，未缴/已缴） */
CREATE INDEX idx_fines_type_status ON fines(fine_type, status);

/* fine_payments：按支付方式+时间统计（例如某渠道日统计） */
CREATE INDEX idx_fine_payments_method_time ON fine_payments(pay_method, pay_time);

/* audit_log：已在建表时建立 idx_audit_table_time，此处不重复 */

-- 4.1.3 EXPLAIN（创建索引后）—— 对比同样 3 条查询

EXPLAIN
SELECT loan_item_id, due_date
FROM loan_items
WHERE returned_at IS NULL
ORDER BY due_date
LIMIT 20;

EXPLAIN
SELECT reservation_id, book_id, request_time
FROM reservations
WHERE status = 1 AND book_id = 1
ORDER BY request_time
LIMIT 20;

EXPLAIN
SELECT book_id, title
FROM books
WHERE title LIKE 'Machine%'
ORDER BY title;

-- ------------------------------------------------------------
-- 4.2 统计直方图（Histogram）
--     目的：让优化器更准确估算选择性，改善执行计划选择
-- ------------------------------------------------------------

/* 4.2.1 创建直方图前：EXPLAIN (JSON) 查看 rows_estimation/选择性估算 */
EXPLAIN FORMAT=JSON
SELECT loan_item_id, due_date
FROM loan_items
WHERE returned_at IS NULL AND due_date <= '2025-06-20'
ORDER BY due_date
LIMIT 20;

EXPLAIN FORMAT=JSON
SELECT book_id, title
FROM books
WHERE language = 'Chinese';

/* 4.2.2 创建直方图 */
ANALYZE TABLE loan_items UPDATE HISTOGRAM ON returned_at WITH 32 BUCKETS;
ANALYZE TABLE books      UPDATE HISTOGRAM ON language    WITH 8  BUCKETS;

-- 查看直方图（MySQL 8.0）
SELECT
  SCHEMA_NAME, TABLE_NAME, COLUMN_NAME, JSON_PRETTY(HISTOGRAM) AS HISTOGRAM
FROM information_schema.COLUMN_STATISTICS
WHERE SCHEMA_NAME = 'library_portfolio'
  AND TABLE_NAME IN ('loan_items','books');

-- 4.2.3 创建直方图后：再次 EXPLAIN (JSON) 对比估算变化
EXPLAIN FORMAT=JSON
SELECT loan_item_id, due_date
FROM loan_items
WHERE returned_at IS NULL AND due_date <= '2025-06-20'
ORDER BY due_date
LIMIT 20;

EXPLAIN FORMAT=JSON
SELECT book_id, title
FROM books
WHERE language = 'Chinese';

-- ============================================================
-- 5) 数据库编程（5函数 + 5过程 + 5视图 + 每表触发器）
-- ============================================================

/* ------------------------------------------------------------
   5.1 存储函数（5个）：函数说明 + 创建语句 + 测试用例
   ------------------------------------------------------------ */
DROP FUNCTION IF EXISTS fn_available_copies;
DROP FUNCTION IF EXISTS fn_member_current_borrowed;
DROP FUNCTION IF EXISTS fn_overdue_days;
DROP FUNCTION IF EXISTS fn_member_outstanding_fine;
DROP FUNCTION IF EXISTS fn_book_borrow_times;

DELIMITER //

/* F1：返回某书目当前可借副本数（status=1） */
CREATE FUNCTION fn_available_copies(p_book_id BIGINT UNSIGNED)
RETURNS INT
READS SQL DATA
BEGIN
  DECLARE v_cnt INT;
  SELECT COUNT(*) INTO v_cnt
  FROM book_copies
  WHERE book_id = p_book_id AND status = 1;
  RETURN v_cnt;
END//

/* F2：返回某读者当前未归还册数（returned_at IS NULL） */
CREATE FUNCTION fn_member_current_borrowed(p_member_id BIGINT UNSIGNED)
RETURNS INT
READS SQL DATA
BEGIN
  DECLARE v_cnt INT;
  SELECT COUNT(*) INTO v_cnt
  FROM loans l
  JOIN loan_items li ON l.loan_id = li.loan_id
  WHERE l.member_id = p_member_id
    AND li.returned_at IS NULL;
  RETURN v_cnt;
END//

/* F3：计算逾期天数（已还=按归还日；未还=按指定as_of日期） */
CREATE FUNCTION fn_overdue_days(p_due_date DATE, p_returned_at DATETIME, p_as_of DATE)
RETURNS INT
NOT DETERMINISTIC
BEGIN
  DECLARE v_base_date DATE;
  IF p_due_date IS NULL THEN
    RETURN 0;
  END IF;

  IF p_returned_at IS NULL THEN
    SET v_base_date = p_as_of;
  ELSE
    SET v_base_date = DATE(p_returned_at);
  END IF;

  IF v_base_date <= p_due_date THEN
    RETURN 0;
  END IF;

  RETURN DATEDIFF(v_base_date, p_due_date);
END//

/* F4：返回某读者未缴罚款金额（总罚款 - 已缴流水） */
CREATE FUNCTION fn_member_outstanding_fine(p_member_id BIGINT UNSIGNED)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(10,2);
  DECLARE v_paid  DECIMAL(10,2);

  SELECT IFNULL(SUM(amount),0) INTO v_total
  FROM fines
  WHERE member_id = p_member_id;

  SELECT IFNULL(SUM(fp.pay_amount),0) INTO v_paid
  FROM fine_payments fp
  JOIN fines f ON fp.fine_id = f.fine_id
  WHERE f.member_id = p_member_id
    AND fp.status = 1;

  RETURN (v_total - v_paid);
END//

/* F5：返回某书目历史借阅次数（按借阅明细统计） */
CREATE FUNCTION fn_book_borrow_times(p_book_id BIGINT UNSIGNED)
RETURNS INT
READS SQL DATA
BEGIN
  DECLARE v_cnt INT;
  SELECT COUNT(*) INTO v_cnt
  FROM loan_items li
  JOIN book_copies bc ON li.copy_id = bc.copy_id
  WHERE bc.book_id = p_book_id;
  RETURN v_cnt;
END//

DELIMITER ;

-- 函数测试用例
SELECT fn_available_copies(1) AS available_copies_book_1;
SELECT fn_member_current_borrowed(1) AS member_1_current_borrowed;
SELECT fn_overdue_days('2025-06-15', NULL, CURDATE()) AS overdue_days_example;
SELECT fn_member_outstanding_fine(6) AS member_6_outstanding_fine;
SELECT fn_book_borrow_times(1) AS book_1_borrow_times;

/* ------------------------------------------------------------
   5.2 存储过程（5个）：过程说明 + 创建语句 + 测试用例
   ------------------------------------------------------------ */
DROP PROCEDURE IF EXISTS sp_create_loan;
DROP PROCEDURE IF EXISTS sp_add_loan_item;
DROP PROCEDURE IF EXISTS sp_return_loan_item;
DROP PROCEDURE IF EXISTS sp_renew_loan_item;
DROP PROCEDURE IF EXISTS sp_pay_fine;

DELIMITER //

/* P1：创建借阅单（仅建头），返回 loan_id */
CREATE PROCEDURE sp_create_loan(
  IN  p_member_id    BIGINT UNSIGNED,
  IN  p_librarian_id BIGINT UNSIGNED,
  IN  p_due_date     DATE,
  OUT o_loan_id      BIGINT UNSIGNED
)
BEGIN
  INSERT INTO loans(member_id, librarian_id, loan_time, due_date, status, note)
  VALUES(p_member_id, p_librarian_id, NOW(), p_due_date, 1, 'Created by sp_create_loan');

  SET o_loan_id = LAST_INSERT_ID();
END//

/* P2：向借阅单添加一本副本（检查副本状态=在馆可借），并将副本置为借出 */
CREATE PROCEDURE sp_add_loan_item(
  IN  p_loan_id  BIGINT UNSIGNED,
  IN  p_copy_id  BIGINT UNSIGNED,
  IN  p_due_date DATE,
  OUT o_ok       TINYINT,
  OUT o_msg      VARCHAR(200)
)
BEGIN
  DECLARE v_status TINYINT;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_status = NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET o_ok = 0;
    SET o_msg = 'SQL exception: rollback.';
  END;

  START TRANSACTION;

  SELECT status INTO v_status
  FROM book_copies
  WHERE copy_id = p_copy_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    ROLLBACK;
    SET o_ok = 0;
    SET o_msg = 'Copy not found.';
  ELSEIF v_status <> 1 THEN
    ROLLBACK;
    SET o_ok = 0;
    SET o_msg = 'Copy not available.';
  ELSE
    INSERT INTO loan_items(loan_id, copy_id, due_date, returned_at, renew_count, item_status, remark)
    VALUES(p_loan_id, p_copy_id, p_due_date, NULL, 0, 1, 'Added by sp_add_loan_item');

    UPDATE book_copies
    SET status = 2
    WHERE copy_id = p_copy_id;

    COMMIT;
    SET o_ok = 1;
    SET o_msg = 'OK';
  END IF;
END//

/* P3：归还一本副本（更新 loan_items + book_copies；若整单全部归还则关闭 loans） */
CREATE PROCEDURE sp_return_loan_item(
  IN  p_loan_item_id BIGINT UNSIGNED,
  OUT o_msg          VARCHAR(200)
)
BEGIN
  DECLARE v_copy_id BIGINT UNSIGNED;
  DECLARE v_loan_id BIGINT UNSIGNED;
  DECLARE v_left_cnt INT;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_copy_id = NULL, v_loan_id = NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET o_msg = 'SQL exception: rollback.';
  END;

  START TRANSACTION;

  SELECT copy_id, loan_id INTO v_copy_id, v_loan_id
  FROM loan_items
  WHERE loan_item_id = p_loan_item_id
  FOR UPDATE;

  IF v_copy_id IS NULL THEN
    ROLLBACK;
    SET o_msg = 'Loan item not found.';
  ELSE
    UPDATE loan_items
    SET returned_at = NOW(), item_status = 2
    WHERE loan_item_id = p_loan_item_id;

    UPDATE book_copies
    SET status = 1
    WHERE copy_id = v_copy_id;

    SELECT COUNT(*) INTO v_left_cnt
    FROM loan_items
    WHERE loan_id = v_loan_id AND returned_at IS NULL;

    IF v_left_cnt = 0 THEN
      UPDATE loans
      SET status = 2, return_time = NOW()
      WHERE loan_id = v_loan_id;
    END IF;

    COMMIT;
    SET o_msg = 'OK';
  END IF;
END//

/* P4：续借（限制续借次数<=2；更新 due_date 和 renew_count） */
CREATE PROCEDURE sp_renew_loan_item(
  IN  p_loan_item_id BIGINT UNSIGNED,
  IN  p_extra_days   INT,
  OUT o_msg          VARCHAR(200)
)
BEGIN
  DECLARE v_renew TINYINT UNSIGNED;
  DECLARE v_ret DATETIME;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_renew = NULL, v_ret = NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET o_msg = 'SQL exception: rollback.';
  END;

  START TRANSACTION;

  SELECT renew_count, returned_at INTO v_renew, v_ret
  FROM loan_items
  WHERE loan_item_id = p_loan_item_id
  FOR UPDATE;

  IF v_renew IS NULL THEN
    ROLLBACK;
    SET o_msg = 'Loan item not found.';
  ELSEIF v_ret IS NOT NULL THEN
    ROLLBACK;
    SET o_msg = 'Already returned.';
  ELSEIF v_renew >= 2 THEN
    ROLLBACK;
    SET o_msg = 'Renew limit reached.';
  ELSE
    UPDATE loan_items
    SET due_date = DATE_ADD(due_date, INTERVAL p_extra_days DAY),
        renew_count = renew_count + 1
    WHERE loan_item_id = p_loan_item_id;

    COMMIT;
    SET o_msg = 'OK';
  END IF;
END//

/* P5：缴纳罚款（写入缴费流水；若累计缴费>=罚款则将罚款标记为已缴） */
CREATE PROCEDURE sp_pay_fine(
  IN  p_fine_id      BIGINT UNSIGNED,
  IN  p_member_id    BIGINT UNSIGNED,
  IN  p_librarian_id BIGINT UNSIGNED,
  IN  p_amount       DECIMAL(10,2),
  IN  p_method       TINYINT,
  OUT o_remaining    DECIMAL(10,2),
  OUT o_msg          VARCHAR(200)
)
BEGIN
  DECLARE v_total DECIMAL(10,2);
  DECLARE v_paid  DECIMAL(10,2);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_total = NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET o_remaining = NULL;
    SET o_msg = 'SQL exception: rollback.';
  END;

  START TRANSACTION;

  SELECT amount INTO v_total
  FROM fines
  WHERE fine_id = p_fine_id AND member_id = p_member_id
  FOR UPDATE;

  IF v_total IS NULL THEN
    ROLLBACK;
    SET o_remaining = NULL;
    SET o_msg = 'Fine not found or member mismatch.';
  ELSE
    INSERT INTO fine_payments(fine_id, member_id, librarian_id, pay_amount, pay_method, pay_time, status)
    VALUES(p_fine_id, p_member_id, p_librarian_id, p_amount, p_method, NOW(), 1);

    SELECT IFNULL(SUM(pay_amount),0) INTO v_paid
    FROM fine_payments
    WHERE fine_id = p_fine_id AND status = 1;

    SET o_remaining = v_total - v_paid;

    IF o_remaining <= 0 THEN
      UPDATE fines SET status = 2 WHERE fine_id = p_fine_id;
      SET o_remaining = 0;
    END IF;

    COMMIT;
    SET o_msg = 'OK';
  END IF;
END//

DELIMITER ;

-- 过程测试用例
SET @new_loan_id = NULL;
CALL sp_create_loan(1, 1, '2025-07-01', @new_loan_id);
SELECT @new_loan_id AS created_loan_id;

SET @ok = 0; SET @msg = '';
CALL sp_add_loan_item(@new_loan_id, 13, '2025-07-01', @ok, @msg);
SELECT @ok AS add_item_ok, @msg AS add_item_msg;

SET @msg = '';
-- 归还刚刚插入的 loan_item（取最新一条）
SELECT MAX(loan_item_id) INTO @last_loan_item_id FROM loan_items;
CALL sp_return_loan_item(@last_loan_item_id, @msg);
SELECT @msg AS return_item_msg;

SET @msg = '';
CALL sp_renew_loan_item(5, 7, @msg); -- 对 loan_item_id=5 续借7天
SELECT @msg AS renew_msg;

SET @remaining = NULL; SET @msg = '';
CALL sp_pay_fine(1, 1, 1, 1.00, 3, @remaining, @msg);
SELECT @remaining AS remaining_after_pay, @msg AS pay_msg;

/* ------------------------------------------------------------
   5.3 视图（5个）：视图用途说明 + 创建语句 + 测试用例
   ------------------------------------------------------------ */
DROP VIEW IF EXISTS vw_current_loans;
DROP VIEW IF EXISTS vw_book_inventory;
DROP VIEW IF EXISTS vw_member_fine_summary;
DROP VIEW IF EXISTS vw_popular_books;
DROP VIEW IF EXISTS vw_reservation_queue;

-- V1：当前未归还借阅视图（便于前台展示/管理员催还）
CREATE VIEW vw_current_loans AS
SELECT
  m.member_id,
  m.name AS member_name,
  l.loan_id,
  l.loan_time,
  li.loan_item_id,
  li.due_date,
  bc.copy_id,
  bc.barcode,
  b.book_id,
  b.title
FROM loans l
JOIN members m      ON l.member_id = m.member_id
JOIN loan_items li  ON l.loan_id = li.loan_id
JOIN book_copies bc ON li.copy_id = bc.copy_id
JOIN books b        ON bc.book_id = b.book_id
WHERE li.returned_at IS NULL;

-- V2：书目库存视图（总册数/可借册数）
CREATE VIEW vw_book_inventory AS
SELECT
  b.book_id,
  b.isbn,
  b.title,
  COUNT(bc.copy_id) AS total_copies,
  SUM(CASE WHEN bc.status = 1 THEN 1 ELSE 0 END) AS available_copies
FROM books b
LEFT JOIN book_copies bc ON b.book_id = bc.book_id
GROUP BY b.book_id, b.isbn, b.title;

-- V3：读者罚款汇总视图（总罚款/已缴/未缴）
CREATE VIEW vw_member_fine_summary AS
SELECT
  m.member_id,
  m.name,
  IFNULL(SUM(f.amount), 0) AS total_fined,
  IFNULL(SUM(fp.pay_amount), 0) AS total_paid,
  IFNULL(SUM(f.amount), 0) - IFNULL(SUM(fp.pay_amount), 0) AS outstanding
FROM members m
LEFT JOIN fines f ON m.member_id = f.member_id
LEFT JOIN fine_payments fp ON f.fine_id = fp.fine_id AND fp.status = 1
GROUP BY m.member_id, m.name;

-- V4：热门书目视图（借阅次数排行）
CREATE VIEW vw_popular_books AS
SELECT
  b.book_id,
  b.title,
  COUNT(li.loan_item_id) AS borrow_times
FROM books b
LEFT JOIN book_copies bc ON b.book_id = bc.book_id
LEFT JOIN loan_items li ON bc.copy_id = li.copy_id
GROUP BY b.book_id, b.title;

-- V5：预约队列视图（带队列号）
CREATE VIEW vw_reservation_queue AS
SELECT
  r.book_id,
  b.title,
  r.reservation_id,
  r.member_id,
  m.name AS member_name,
  r.status,
  r.request_time,
  ROW_NUMBER() OVER (PARTITION BY r.book_id ORDER BY r.request_time) AS queue_no
FROM reservations r
JOIN books b   ON r.book_id = b.book_id
JOIN members m ON r.member_id = m.member_id;

-- 视图测试用例
SELECT * FROM vw_current_loans ORDER BY due_date LIMIT 10;
SELECT * FROM vw_book_inventory ORDER BY book_id LIMIT 10;
SELECT * FROM vw_member_fine_summary ORDER BY outstanding DESC LIMIT 10;
SELECT * FROM vw_popular_books ORDER BY borrow_times DESC, book_id LIMIT 10;
SELECT * FROM vw_reservation_queue WHERE status = 1 ORDER BY book_id, queue_no LIMIT 20;

/* ------------------------------------------------------------
   5.4 触发器（每表 ≥ 1 个）：用途说明 + 创建语句 + 测试用例
       统一审计策略：对每张业务表创建 AFTER INSERT 触发器，
       将新增记录写入 audit_log，方便审计与问题追踪。
       另外对 audit_log 自身创建“防删”触发器，保证日志不可随意删除。
   ------------------------------------------------------------ */
DROP TRIGGER IF EXISTS trg_members_ai;
DROP TRIGGER IF EXISTS trg_librarians_ai;
DROP TRIGGER IF EXISTS trg_authors_ai;
DROP TRIGGER IF EXISTS trg_categories_ai;
DROP TRIGGER IF EXISTS trg_books_ai;
DROP TRIGGER IF EXISTS trg_book_copies_ai;
DROP TRIGGER IF EXISTS trg_book_authors_ai;
DROP TRIGGER IF EXISTS trg_book_categories_ai;
DROP TRIGGER IF EXISTS trg_loans_ai;
DROP TRIGGER IF EXISTS trg_loan_items_ai;
DROP TRIGGER IF EXISTS trg_reservations_ai;
DROP TRIGGER IF EXISTS trg_fines_ai;
DROP TRIGGER IF EXISTS trg_fine_payments_ai;
DROP TRIGGER IF EXISTS trg_audit_log_bd;

DELIMITER //

/* members：新增读者写入审计日志 */
CREATE TRIGGER trg_members_ai
AFTER INSERT ON members
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('members', 'INSERT', CAST(NEW.member_id AS CHAR), NOW(),
         JSON_OBJECT('card_no', NEW.card_no, 'name', NEW.name, 'status', NEW.status));
END//

/* librarians：新增馆员写入审计日志 */
CREATE TRIGGER trg_librarians_ai
AFTER INSERT ON librarians
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('librarians', 'INSERT', CAST(NEW.librarian_id AS CHAR), NOW(),
         JSON_OBJECT('employee_no', NEW.employee_no, 'name', NEW.name, 'role', NEW.`role`));
END//

/* authors：新增作者写入审计日志 */
CREATE TRIGGER trg_authors_ai
AFTER INSERT ON authors
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('authors', 'INSERT', CAST(NEW.author_id AS CHAR), NOW(),
         JSON_OBJECT('full_name', NEW.full_name, 'country', NEW.country));
END//

/* categories：新增分类写入审计日志 */
CREATE TRIGGER trg_categories_ai
AFTER INSERT ON categories
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('categories', 'INSERT', CAST(NEW.category_id AS CHAR), NOW(),
         JSON_OBJECT('name', NEW.name, 'parent_id', NEW.parent_id));
END//

/* books：新增书目写入审计日志 */
CREATE TRIGGER trg_books_ai
AFTER INSERT ON books
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('books', 'INSERT', CAST(NEW.book_id AS CHAR), NOW(),
         JSON_OBJECT('isbn', NEW.isbn, 'title', NEW.title, 'language', NEW.language));
END//

/* book_copies：新增副本写入审计日志 */
CREATE TRIGGER trg_book_copies_ai
AFTER INSERT ON book_copies
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('book_copies', 'INSERT', CAST(NEW.copy_id AS CHAR), NOW(),
         JSON_OBJECT('book_id', NEW.book_id, 'barcode', NEW.barcode, 'status', NEW.status));
END//

/* book_authors：新增书目-作者关系写入审计日志（复合主键） */
CREATE TRIGGER trg_book_authors_ai
AFTER INSERT ON book_authors
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('book_authors', 'INSERT',
         CONCAT('book_id=', NEW.book_id, ',author_id=', NEW.author_id),
         NOW(),
         JSON_OBJECT('role', NEW.`role`, 'author_order', NEW.author_order));
END//

/* book_categories：新增书目-分类关系写入审计日志（复合主键） */
CREATE TRIGGER trg_book_categories_ai
AFTER INSERT ON book_categories
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('book_categories', 'INSERT',
         CONCAT('book_id=', NEW.book_id, ',category_id=', NEW.category_id),
         NOW(),
         JSON_OBJECT('is_primary', NEW.is_primary));
END//

/* loans：新增借阅单写入审计日志 */
CREATE TRIGGER trg_loans_ai
AFTER INSERT ON loans
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('loans', 'INSERT', CAST(NEW.loan_id AS CHAR), NOW(),
         JSON_OBJECT('member_id', NEW.member_id, 'librarian_id', NEW.librarian_id, 'status', NEW.status));
END//

/* loan_items：新增借阅明细写入审计日志 */
CREATE TRIGGER trg_loan_items_ai
AFTER INSERT ON loan_items
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('loan_items', 'INSERT', CAST(NEW.loan_item_id AS CHAR), NOW(),
         JSON_OBJECT('loan_id', NEW.loan_id, 'copy_id', NEW.copy_id, 'due_date', NEW.due_date));
END//

/* reservations：新增预约写入审计日志 */
CREATE TRIGGER trg_reservations_ai
AFTER INSERT ON reservations
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('reservations', 'INSERT', CAST(NEW.reservation_id AS CHAR), NOW(),
         JSON_OBJECT('member_id', NEW.member_id, 'book_id', NEW.book_id, 'status', NEW.status));
END//

/* fines：新增罚款写入审计日志 */
CREATE TRIGGER trg_fines_ai
AFTER INSERT ON fines
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('fines', 'INSERT', CAST(NEW.fine_id AS CHAR), NOW(),
         JSON_OBJECT('member_id', NEW.member_id, 'loan_item_id', NEW.loan_item_id, 'amount', NEW.amount, 'type', NEW.fine_type));
END//

/* fine_payments：新增缴费流水写入审计日志 */
CREATE TRIGGER trg_fine_payments_ai
AFTER INSERT ON fine_payments
FOR EACH ROW
BEGIN
  INSERT INTO audit_log(table_name, action, pk_value, changed_at, detail_json)
  VALUES('fine_payments', 'INSERT', CAST(NEW.payment_id AS CHAR), NOW(),
         JSON_OBJECT('fine_id', NEW.fine_id, 'member_id', NEW.member_id, 'amount', NEW.pay_amount, 'method', NEW.pay_method));
END//

/* audit_log：防止删除日志（保证审计数据不可随意清空） */
CREATE TRIGGER trg_audit_log_bd
BEFORE DELETE ON audit_log
FOR EACH ROW
BEGIN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'audit_log is immutable: DELETE is not allowed.';
END//

DELIMITER ;

-- 触发器测试用例：插入一条新作者，检查 audit_log 是否新增记录
INSERT INTO authors(full_name, country, birth_year, death_year, bio)
VALUES('Test Trigger Author', 'CN', 1990, NULL, 'Inserted for trigger test.');

SELECT *
FROM audit_log
WHERE table_name = 'authors'
ORDER BY audit_id DESC
LIMIT 5;

/* ============================================================
   脚本结束
   ============================================================ */

