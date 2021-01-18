CREATE SCHEMA IF NOT EXISTS financedb;
USE financedb;


CREATE TABLE IF NOT EXISTS users (
  id INT NOT NULL AUTO_INCREMENT,
  fname VARCHAR(45) NOT NULL,
  lname VARCHAR(45) NOT NULL,
  username VARCHAR(45) NOT NULL,
  `password` VARCHAR(100) NOT NULL,
  email VARCHAR(45) NOT NULL,
  creation DATETIME NULL DEFAULT current_timestamp,
  actv TINYINT NULL DEFAULT '1',
  PRIMARY KEY (`id`));


CREATE TABLE IF NOT EXISTS useraccount (
  id INT NOT NULL,
  balance DECIMAL(11,2) NULL DEFAULT '0.00',
  PRIMARY KEY (id),
  CONSTRAINT FK_Useraccount_User
    FOREIGN KEY (id)
    REFERENCES users (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE);


CREATE TABLE IF NOT EXISTS customer (
  id INT NOT NULL,
  country VARCHAR(45) NOT NULL,
  city VARCHAR(45) NOT NULL,
  address VARCHAR(45) NOT NULL,
  zipcode VARCHAR(5) NOT NULL,
  telephone VARCHAR(13) NOT NULL,
  num_id VARCHAR(8) NOT NULL unique,
  vat VARCHAR(9) NOT NULL unique,
  PRIMARY KEY (id),
  CONSTRAINT FK_Customer_User
    FOREIGN KEY (id)
    REFERENCES users (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE);


CREATE TABLE IF NOT EXISTS orders (
  oid INT NOT NULL AUTO_INCREMENT,
  id INT NOT NULL,
  num_shares INT NOT NULL,
  symbol VARCHAR(6) NOT NULL,
  current_price DECIMAL(11,2) NOT NULL,
  timestmp DATETIME NULL DEFAULT current_timestamp,
  actv TINYINT(1) NULL DEFAULT '1',
  ordertype tinyint not null,
  commission DECIMAL(11,2) NULL DEFAULT '0.00',
  PRIMARY KEY (oid),
  CONSTRAINT FK_Orders_UserAccount
    FOREIGN KEY (id)
    REFERENCES useraccount (id)
	ON DELETE CASCADE
    ON UPDATE CASCADE);
    
    
    
CREATE TABLE IF NOT EXISTS portfolio (
  pid INT NOT NULL AUTO_INCREMENT,
  id INT NOT NULL,
  num_shares INT NOT NULL,
  symbol VARCHAR(6) NOT NULL,
  avg_price DECIMAL(11,2) NOT NULL,
  PRIMARY KEY (pid),
  CONSTRAINT FK_Portfolio_UserAccount
    FOREIGN KEY (id)
    REFERENCES useraccount (id));
    
    
    
    
    


CREATE TABLE IF NOT EXISTS roles (
  id INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(20) NOT NULL,
  PRIMARY KEY (id));
  

CREATE TABLE IF NOT EXISTS funding (
  fid INT NOT NULL AUTO_INCREMENT,
  id INT NOT NULL,
  fdate DATETIME NULL DEFAULT current_timestamp,
  deposit DECIMAL(11,2) NULL DEFAULT '0.00',
  withdrawal DECIMAL(11,2) NULL DEFAULT '0.00',
  PRIMARY KEY (fid),
  CONSTRAINT FK_Funding_Useraccount
    FOREIGN KEY (id)
    REFERENCES useraccount (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE);

CREATE TABLE IF NOT EXISTS user_roles (
  user_id INT NOT NULL,
  role_id INT NOT NULL,
  CONSTRAINT FK_UserRoleRole
    FOREIGN KEY (role_id)
    REFERENCES roles (id),
  CONSTRAINT FK_UserRolesUser
    FOREIGN KEY (user_id)
    REFERENCES users (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE);

CREATE TABLE IF NOT EXISTS userlogs (
  lid INT NOT NULL AUTO_INCREMENT,
  id INT NOT NULL,
  ulogs DATETIME NULL DEFAULT current_timestamp,
  PRIMARY KEY (lid),
  CONSTRAINT FK_UserLogsUser
    FOREIGN KEY (id)
    REFERENCES users (id)
    ON DELETE CASCADE
    ON UPDATE CASCADE);



-- TRIGGERS

-- CREATE ACCOUNT


-- Create Account if role === "user"
 delimiter |
   CREATE TRIGGER createAccount
   after insert ON user_roles
FOR EACH ROW
BEGIN
if new.role_id = 1
then
 insert into useraccount (id,balance) values (new.user_id,0);
 end if;
END;
| delimiter ;


-- UPDATE BALANCE ON DEPOSIT/WITHDRAWAL
delimiter |
CREATE TRIGGER updateBalanceOnDepositWithDraw
AFTER INSERT ON funding
FOR EACH ROW
BEGIN
      update useraccount set balance = balance + (new.deposit - new.withdrawal)
      where useraccount.id = new.id;
END;
| delimiter ;


-- CALCULATE COMMISION

delimiter |
CREATE TRIGGER calculateCommission
BEFORE INSERT ON orders
FOR EACH ROW
BEGIN
    IF (new.ordertype=0)
     THEN
        SET NEW.commission = (new.current_price * new.num_shares) * 0.01;
	 ELSE if (new.ordertype=1)
     then
        SET NEW.commission = 0;
        end if;
	END IF;
END;
| delimiter ;



-- UPDATE BALANCE ON ORDER

delimiter |
CREATE TRIGGER updateBalanceOnOrder
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
IF (new.ordertype=0)
 THEN
      UPDATE useraccount SET balance = balance - (new.num_shares*new.current_price + new.commission)
      WHERE useraccount.id = new.id;
      ELSE IF (new.ordertype=1)
      then
      UPDATE useraccount SET balance = balance + (new.num_shares*new.current_price)
      WHERE useraccount.id = new.id;
      end if;
 END IF;
END;
| delimiter ;


-- UPDATE PORTFOLIO ON BUY
delimiter |
CREATE TRIGGER updatePortfolioOnBuy
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
SET @variable = (select count(*) from portfolio where id=new.id and symbol=new.symbol);
if (@variable=0 AND new.ordertype=0)
then
     insert into portfolio (id,num_shares,symbol,avg_price)
     values (new.id,new.num_shares,new.symbol,new.current_price);
     else if(@variable>0 AND new.ordertype=0)
     then
     update portfolio set num_shares = (num_shares+new.num_shares),
	 avg_price = (((num_shares*avg_price)+(new.num_shares*new.current_price+new.commission))/(num_shares+new.num_shares)) where id = new.id and symbol=new.symbol;
     end if;
     end if;
END;
| delimiter ;


-- UPDATE PORTFOLIO ON SELL

delimiter |
CREATE TRIGGER updatePortfolioOnSell
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
SET @variable = (select count(*) from portfolio where id=new.id and symbol=new.symbol);
if (@variable>0 AND new.ordertype=1)
then
     update portfolio set num_shares = (num_shares-new.num_shares)
     where id = new.id and symbol=new.symbol;
     end if;
END;
| delimiter ;

 
 
 
 
 -- DUMMY DATA


SELECT * FROM USERS;
SELECT * FROM CUSTOMER;
SELECT * FROM USERACCOUNT;
SELECT * FROM ORDERS;
SELECT * FROM FUNDING;
SELECT * FROM USER_ROLES;
SELECT * FROM USERLOGS;
SELECT * FROM ROLES;
SELECT * FROM PORTFOLIO;


 -- ADMIN
insert into users (fname,lname,username,password,email) -- PASS 1234
values("KOSTAS","KOSTOPOULOS","admin","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","admin@admin.com");

-- USER DATA
insert into users (fname,lname,username,password,email) -- PASS 1234
values("Faye","Valiou","fayeval99","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","fif99@gmail.com"),
("Dimitris","Papadoloulos","dimPap","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","dimpap@yahoo.gr"),
("Cierra","Vega","cierrav88","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","vega@gmail.com"),
("Alexandra","Wilson","wilson1987","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","alex88@yahoo.com"),
("Cassie","Sherman","cassie21","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","shermanc@gmail.com"),
("Alberto","Harding","alberto99","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","albertoh@gmail.com"),
("Danny","Sherman","cassie21","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","shermanc@gmail.com"),
("Desiree","Sexton","cassiesx21","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","sexton88@gmail.com"),
("Cassie","Sherman","cassie21","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","shermanc@gmail.com"),
("Desiree","Lindsey","desira","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","desira@gmail.com"),
("Erick","Schmidt","erick1987","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","erickdt@gmail.com"),
("Sebastian","Savage","savageqw","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","savagek@gmail.com"),
("Mattie","Noble","noble99","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","noblm77@gmail.com"),
("Dax","Hickman","hickmanxxx","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","hickmanxxx@gmail.com"),
("Finnegan","Barber","barb22","$2a$10$exbqK7m5CCTHSSLubWwSOuuDlgCNWurIRgQLtawzHpERTuxN1BtmG","barberf@gmail.com");





-- CUSTOMER
insert into customer (country,city,address,zipcode,telephone,num_id,vat,id)
values ("Greece","Athens","Asklipiou 5","11343","+306999999999","AI787878","143303434",2),
("Greece","Thessaloniki","Koukou 5","18343","+306933333333","AI784498","155343434",3),
("Greece","Athens","Pouliou 5","11343","+306999977777","AI785578","149943434",4),
("Greece","Chania","Kritis 55","15643","+306999992222","AI323678","143349433",5),
("Greece","Volos","Tikou 65","15343","+306999999944","AI782222","233345534",6),
("Greece","Chania","Kritis 55","15643","+306999992222","AI323478","143349431",7),
("Greece","Heraklion","Papiou 55","13233","+306993392221","AI313278","145343434",8),
("Greece","Athens","Ithakis 125","11643","+306939992222","AI673872","173349434",9),
("Greece","Athens","Kritis 55","15643","+306999992222","AI323871","143349454",10),
("Greece","Chania","Ippokratous 155","15643","+306999992222","AI313878","143349434",11),
("Greece","Volos","Zakunthou 9","11743","+306949992222","AI323899","133349434",12),
("Greece","Chania","Iliou 99","14443","+306937892222","AI247878","126679434",13),
("Greece","Patra","Limnou 87","16442","+306955992121","AI655874","123546445",14),
("Greece","Thessaloniki","Thessalonikis 143","18643","+306935861112","AI523862","156364277",15),
("Greece","Thessaloniki","Manis 15","11663","+306978651349","AI225679","163357735",16);




-- ROLES ADMIN & USER
insert into roles (name) values ("ROLE_USER"),("ROLE_ADMIN");

-- USER ROLES
insert into user_roles (user_id,role_id) values (1,2);
insert into user_roles (user_id,role_id) values (2,1),(3,1),(4,1),(5,1),(6,1),(7,1),(8,1),(9,1),(10,1),(11,1),(12,1),(13,1),
(14,1),(15,1),(16,1);



-- TRANSACTIONS --> deposit
insert into funding (deposit,id)
values (1000,2),
(13000,2),(15000,2),(10000,3),(12200,4),(12500,5),(12200,6),(12100,7),(12140,8),
(11000,9),(12000,10),(21000,11),(24000,12),(25000,13),(21000,14),(11200,15),(11500,16);



-- WALLET TRANSACTIONS --> WITHDRAW
insert into funding (withdrawal,id)
values (100,2),(100,3),(50,4),(200,6),(200,7),(200,8),(200,9),(200,10),(400,11);





-- ORDER
insert into orders (num_shares,symbol,current_price,ordertype,id) 
values
(1,"AAPL",115,0,2),
(2,"TSLA",120,0,2),
(2,"AAPL",100,0,2),
(1,"TSLA",120,0,2),
(1,"AAPL",100,0,2),
(2,"TSLA",110,0,3),
(3,"TSLA",114,0,5),
(2,"AAPL",103,0,5),
(5,"TSLA",120,0,5),
(2,"TSLA",130,0,4),
(1,"TSLA",128,0,4),
(1,"AAPL",123,0,2),
(3,"AAPL",115,0,2),
(10,"AAPL",115,0,2),
(10,"AAPL",115,0,3),
(7,"AAPL",123,0,4),
(2,"AAPL",123,0,5),
(7,"TWTR",123,1,4),
(7,"FB",33,0,4),
(7,"MZFT",55,0,3),
(19,"F",9,0,2),
(2,"GOOGL",212,0,2),
(14,"GOOGL",217,0,2);






-- userlogs
insert into userlogs (ulogs,id)
values("2020-10-10",1),
("2020-11-10",1),
("2020-11-12",1),
("2020-11-11",1),
("2020-11-09",1),
("2020-11-11",2),
("2020-09-09",2),
("2020-09-10",2),
("2020-11-11",2),
("2020-10-10",2),
("2020-10-10",2),
("2020-09-09",2),
("2020-12-12",2);


