--Laboratoire 07 (TRIGGERS)
--Andr�e-Anne Roy

USE MASTER
GO

DROP DATABASE STORE
GO

--Step 01 - Creating a database.
CREATE DATABASE STORE
GO


--Step 02 - Using the database.
USE STORE
GO


--Step 03 - Creating a table.
CREATE TABLE ORDERS
(NO_ORDER	 INT CONSTRAINT PK_ORDER PRIMARY KEY,
NO_CLIENT	 INT,
DATE_ORDER	 DATE,
COST		 MONEY)
GO


--Step 04 - Creating a table ORDERSJOURNAL that contains transactions on table ORDERS.
CREATE TABLE ORDERSJOURNAL
(NO_ORDER			 INT,
NO_CLIENT			 INT,
DATE_ORDER			 DATE,
COST				 MONEY,
DATE_TRANSACTION	 DATE,
CODE_TRANSACTION	 VARCHAR(6) CHECK(CODE_TRANSACTION IN('INSERT','UPDATE','DELETE')),
CODE_USER			 VARCHAR(60))
GO


--Step 05 - Creating a trigger to log inserts on table ORDERS.
CREATE TRIGGER INS_JOURNAL_CMD
ON ORDERS
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON
	INSERT INTO ORDERSJOURNAL(NO_ORDER, NO_CLIENT, DATE_ORDER, COST, DATE_TRANSACTION, CODE_TRANSACTION, CODE_USER)
	SELECT NO_ORDER, NO_CLIENT, DATE_ORDER, COST, GETDATE(),'INSERT', SUSER_SNAME()
	FROM INSERTED
END
GO


--Step 06 - Creating a trigger to log updates on table ORDERS.
CREATE TRIGGER UPD_JOURNAL_CMD
ON ORDERS
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON
	INSERT INTO ORDERSJOURNAL(NO_ORDER, NO_CLIENT, DATE_ORDER, COST, DATE_TRANSACTION, CODE_TRANSACTION, CODE_USER)
	SELECT NO_ORDER, NO_CLIENT, DATE_ORDER, COST, GETDATE(),'UPDATE', SUSER_SNAME()
	FROM INSERTED
END
GO


--Step 07 - Creating a trigger to log deletions on table ORDERS.
CREATE TRIGGER DEL_JOURNAL_CMD
ON ORDERS
AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON
	INSERT INTO ORDERSJOURNAL(NO_ORDER, NO_CLIENT, DATE_ORDER, COST, DATE_TRANSACTION, CODE_TRANSACTION, CODE_USER)
	SELECT NO_ORDER, NO_CLIENT, DATE_ORDER, COST, GETDATE(),'DELETE', SUSER_SNAME()
	FROM DELETED
END
GO


--Step 08 - Adding data into the table ORDERS.
INSERT INTO ORDERS VALUES (1000, 10, '23 JANUARY 2017', 120.40),
						  (1001, 20, '12 MARCH 2017', 1200),
						  (1002, 10, '18 APRIL 2017', 89.43),
						  (1003, 30, '28 APRIL 2017', 4300)
GO

UPDATE ORDERS
SET COST = 1
WHERE NO_ORDER = 1000
GO

DELETE ORDERS
WHERE NO_ORDER = 1000

SELECT * FROM ORDERS
GO

SELECT * FROM ORDERSJOURNAL
GO


--Step 09 - Verifying the content of ORDERSJOURNAL.
SELECT * FROM ORDERSJOURNAL
GO


--Step 10 - Increasing the cost of order #1002 of 100$.
UPDATE ORDERS
SET COST = COST + 100
WHERE NO_ORDER = 1002
GO


--Step 11 - Verifying the content of ORDERSJOURNAL.
SELECT * FROM ORDERSJOURNAL
GO


--Step 12 - Deleting the order #1001.
DELETE ORDERS
WHERE NO_ORDER = 1001


--Step 13 - Verifying the content of ORDERSJOURNAL.
SELECT * FROM ORDERSJOURNAL
GO


--Step 14 - Deleting the 3 triggers.
DROP TRIGGER INS_JOURNAL_CMD
GO

DROP TRIGGER UPD_JOURNAL_CMD
GO

DROP TRIGGER DEL_JOURNAL_CMD
GO


--Step 15 - Creating a new trigger that will replace the 3 previous triggers.
CREATE TRIGGER JOURNAL_CMD
ON ORDERS
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON
	INSERT INTO ORDERSJOURNAL(NO_ORDER, NO_CLIENT, DATE_ORDER, COST, DATE_TRANSACTION, CODE_TRANSACTION, CODE_USER)
	SELECT NO_ORDER, NO_CLIENT, DATE_ORDER, COST, GETDATE(), 'INSERT', SUSER_NAME()
	FROM inserted
END

IF EXISTS(SELECT * FROM INSERTED) AND EXISTS (SELECT * FROM DELETED)
BEGIN
	SET NOCOUNT ON
	INSERT INTO ORDERSJOURNAL(NO_ORDER, NO_CLIENT, DATE_ORDER, COST, DATE_TRANSACTION, CODE_TRANSACTION, CODE_USER)
	SELECT NO_ORDER, NO_CLIENT, DATE_ORDER, COST, GETDATE(), 'UPDATE', SUSER_NAME()
	FROM INSERTED
END

IF EXISTS(SELECT * FROM DELETED) AND NOT EXISTS(SELECT * FROM INSERTED)
BEGIN
	SET NOCOUNT ON
	INSERT INTO ORDERSJOURNAL(NO_ORDER, NO_CLIENT, DATE_ORDER, COST, DATE_TRANSACTION, CODE_TRANSACTION, CODE_USER)
	SELECT NO_ORDER, NO_CLIENT, DATE_ORDER, COST, GETDATE(), 'DELETE', SUSER_NAME()
	FROM DELETED	
END
GO

--Step 16 - Testing the new trigger.
INSERT INTO ORDERS VALUES(3005,20,'31 JANUARY 2017', 300.40) 

--Step 17 - Creating a trigger that verifies before insertion that the date is >= to today's date, if not we reject the request.
CREATE TRIGGER AVANT_INS_CMD
ON ORDERS
INSTEAD OF INSERT
AS
BEGIN
	IF EXISTS (SELECT * FROM INSERTED WHERE DATE_ORDER > GETDATE())
		RAISERROR('Date order invalid', 16, 1)
	ELSE
		INSERT INTO ORDERS SELECT * FROM INSERTED
END
GO

--Step 18 - Testing the trigger.
INSERT INTO ORDERS VALUES(3001,10,'31 JANUARY 2017', 120.40) --VALID
INSERT INTO ORDERS VALUES(3000,10,'23 JUNE 2017', 120.40) --INVALID

SELECT *
FROM ORDERS