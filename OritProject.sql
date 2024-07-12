


Create Database OritProject
GO
Use OritProject
GO


 ---- Reference Tables Area

 CREATE TABLE Country  
(
	CountryID CHAR(2) PRIMARY KEY 
	,Country_Name VARCHAR(255) NOT NULL 
	,CONSTRAINT CHK_CountryID_Length CHECK (LEN(CountryID)=2)
);

CREATE TABLE City 
(
	CityID CHAR(3) Primary Key
	,City_Description VARCHAR(255) NOT NULL 
	,StateN VARCHAR(255)
	,CountryID CHAR(2) NOT NULL
	,UNLOCO CHAR(5) NOT NULL
	,Constraint FK_CountryID FOREIGN KEY (CountryID) References Country(CountryID)
	,Constraint CHK_CityID_Length CHECK(LEN(CityID)=3)
	,CONSTRAINT CHK_UNLOCO_Code_Format CHECK (LEN(UNLOCO) = 5 and UNLOCO = (CountryID + CityID))
	
);

---- Organization Area


CREATE TABLE Organization
(	ID INT IDENTITY(1,1) 
	,Company_Name VARCHAR(255) NOT NULL
    ,Org_Code AS (CAST(ID AS VARCHAR(7)) + LEFT(UPPER(Company_Name),5)) PERSISTED NOT NULL
	,Street_name VARCHAR(255) NOT NULL
	,CityID CHAR(3) NOT NULL
	,Postal_Code VARCHAR(25)  
	,CountryID CHAR(2) NOT NULL
	,Vat_Number VARCHAR(20) NOT NULL
	,Title VARCHAR(3)
	,FirstName VARCHAR(55) NOT NULL
	,LastName VARCHAR(100) NOT NULL
	,Possition VARCHAR(255)
	,Email VARCHAR(255) NOT NULL
	,Mobile VARCHAR(20) 
	,Birthday DATE --- minimum age for hiring 16
	,CONSTRAINT PK_Organization PRIMARY KEY (Org_Code)
	,CONSTRAINT FK_CityID_Org FOREIGN KEY (CityID) References City(CityID)
	,CONSTRAINT FK_CountryID_Org FOREIGN KEY (CountryID) References Country(CountryID)
	,CONSTRAINT CHK_Email CHECK (Email LIKE '%@%.%')
	,CONSTRAINT CHK_MinimumAge CHECK (DATEDIFF(YEAR,Birthday,GETDATE())>=16)
	);

--- Shipment Area

CREATE TABLE Package_Types
(
	Package_ID CHAR(3) PRIMARY KEY
	,Package_Name VARCHAR(155) NOT NULL
	,CONSTRAINT CHK_PackageID_Code CHECK (Package_ID IN ('CTN','PLT','BAG','COI','PKG')) 
);

CREATE TABLE Incoterms
(
	INCO_ID CHAR(3) Primary Key 
	,IncotermName varchar(55) 
	,CONSTRAINT CHK_INCOTermID_Code CHECK (INCO_ID IN ('EXW','FCA','FOB','CIF','DDU','DDP')) 
);

CREATE TABLE Event_Types
(
    Event_Code CHAR(3) PRIMARY KEY
    ,Event_Name VARCHAR(15) NOT NULL
    ,CONSTRAINT CHK_Event_Code CHECK (Event_Code IN ('OPN','BKC','PIC','DEP','ARV','DLV','DLY','CLS')) -- specific options
);


CREATE TABLE Shipment_Details
(
	Shipment_ID INT IDENTITY (1,1) Primary Key 
	,Job_Open DATE DEFAULT GETDATE() NOT NULL  
	,Incoterms CHAR(3) NOT NULL 
	,Shipper_ID VARCHAR(12) NOT NULL 
	,Consignee_ID VARCHAR(12) NOT NULL 
	,Paid_By VARCHAR(12)
	,Credit_Terms CHAR(7)
	,ValueOfGoods Money
	,FreightValue Money
	,PickupAddress TEXT NOT NULL
	,EstPickUp DATE 
	,FirstLoadPort CHAR(3) NOT NULL 
	,EstDepartureFirstPort DATE  
	,LastDischargePort CHAR(3) 
	,EstArrivalFinalPort DATE 
	,DeliveryAddress TEXT
	,EstDelivery DATE
	,Constraint FK_Shipper_ID Foreign Key (Shipper_ID) References Organization(Org_Code)
	,Constraint FK_Consignee_ID Foreign Key (Consignee_ID) References Organization(Org_Code)
	,Constraint FK_Paid_By Foreign Key (Paid_By) References Organization(Org_Code)
	,Constraint CHK_ShipperConsignee CHECK (Shipper_ID<>Consignee_ID)
    ,Constraint CHK_EstPickupSequance CHECK (EstPickUp>Job_Open)
    ,Constraint CHK_EstDepartureSequance CHECK (EstDepartureFirstPort > EstPickUp)
    ,Constraint CHK_EstArrivalSequance CHECK (EstArrivalFinalPort > EstDepartureFirstPort)
    ,Constraint CHK_EstDeliverySequance CHECK (EstDelivery > EstArrivalFinalPort)
	,Constraint FK_FirstLoadPort FOREIGN KEY (FirstLoadPort) REFERENCES City(CityID)
    ,Constraint FK_LastDischargePort FOREIGN KEY (LastDischargePort) REFERENCES City(CityID)
	,Constraint FK_Incoterms FOREIGN KEY (Incoterms) REFERENCES Incoterms(INCO_ID)
);

CREATE TABLE Cargo_Details
(
	Cargo_ID INT IDENTITY (1,1) Primary Key
	,Shipment_ID INT
	,ShortDescription VARCHAR(255) NOT NULL
	,Weight_KG DECIMAL(8,2) NOT NULL
	,Volume_CBM DECIMAL(8,2) NOT NULL 
	,Packages INT NOT NULL 
	,Package_Type CHAR(3) 
	,Container_Number VARCHAR(11)
	,Seal_Number VARCHAR(25) NOT NULL
	,Container_Type VARCHAR(4) NOT NULL 
	,AdditionalHandlingNotes TEXT 
	,CONSTRAINT FK_Shipment_ID Foreign Key (Shipment_ID) References Shipment_Details(Shipment_ID)
	,Constraint FK_Package_Type Foreign Key (Package_Type) References Package_Types(Package_ID)
	,CONSTRAINT CHK_Weight_Positive CHECK (Weight_KG > 0)
    ,CONSTRAINT CHK_Volume_Positive CHECK (Volume_CBM > 0)
    ,CONSTRAINT CHK_Packages_Positive CHECK (Packages > 0)
    ,CONSTRAINT CHK_Container_Number_Format CHECK (Container_Number LIKE '[A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][0-9][0-9][0-9]')
    ,CONSTRAINT CHK_Container_Type_Format CHECK (Container_Type IN ('20DV', '40DV', '20RF', '40RH', '20SP', '40SP'))
);


CREATE TABLE Shipment_Status
(
	EventID INT IDENTITY (1,1) NOT NULL PRIMARY KEY
	,Shipment_ID INT 
	,EventDate Date NOT NULL 
	,EventCode CHAR(3) 
	,Notes TEXT NOT NULL
	,CONSTRAINT CHK_EventDate_Valid CHECK (Eventdate <=GETDATE())
	,CONSTRAINT FK_Shipment_ID_Status Foreign Key (Shipment_ID) References Shipment_Details(Shipment_ID)
	,Constraint FK_EventCode FOREIGN KEY (EventCode) REFERENCES Event_Types(Event_Code)
);

INSERT INTO Incoterms (INCO_ID, IncotermName)
VALUES ('EXW', 'Ex Works'), ('FCA', 'Free Carrier'), ('FOB', 'Free on Board'), ('CIF', 'Cost, Insurance and Freight'), ('DDU', 'Delivered Duty Unpaid'), ('DDP', 'Delivered Duty Paid');

INSERT INTO Package_Types (Package_ID, Package_Name)
VALUES ('CTN', 'Carton'), ('PLT', 'Pallet'), ('BAG', 'Bag'), ('COI', 'Coil'), ('PKG', 'Package');

INSERT INTO Event_Types (Event_Code, Event_Name)
VALUES ('OPN', 'Open'), ('BKC', 'Booked'), ('PIC', 'Picked Up'), ('DEP', 'Departed'), ('ARV', 'Arrived'), ('DLV', 'Delivered'), ('DLY', 'Delayed'), ('CLS', 'Closed');

INSERT INTO Country(CountryID,Country_Name)
VALUES ('IL','Israel'),('PL','Poland'),('AR','Argentina'),('DE','Germany'),('FR','France'), ('CZ','Czech Republic'),('GR','Greece');

INSERT INTO City (CityID, City_Description, StateN, CountryID, UNLOCO)
VALUES 
    ('BUE', 'Buenos Aires', NULL, 'AR', 'ARBUE')
    ,('HFA', 'Haifa', NULL, 'IL', 'ILHFA')
   , ('WAW', 'Warszawa', NULL, 'PL', 'PLWAW')
   , ('ASH', 'Ashdod', NULL, 'IL', 'ILASH')
   , ('HAM', 'Hamburg', NULL, 'DE', 'DEHAM')
   , ('PIR', 'Piraeus', NULL, 'GR', 'GRPIR');


INSERT INTO Organization (Company_Name, Street_name, CityID, Postal_Code, CountryID, Vat_Number, Title, FirstName, LastName, Possition, Email, Mobile, Birthday)
VALUES 
('Yummiee Foods Ltd','30 SHMOTKIN ST', 'HFA', '456454', 'IL', '515454878', 'Mr', 'avi', 'saba', 'CEO', 'john@example.com', '123-456-7890', '1990-05-15'),
('Furde and Sons Milk','ENGLISCHE PLANKE 2','HAM','20459','DE','DE-78787', 'Ms', 'Jane', 'Henry', 'CFO', 'jane@example.com', '987-654-3210', '1974-10-20'),
('Nord springs','nothing street','HFA','54544','IL','515484878','Mrs', 'Eti', 'Shvili', 'COO', 'Eti@example.com', '054-456-7890', '1999-05-15'),
('EAT YOUR MEAT','FLORES NORTE','BUE','7300','AR','AR-7d548787', 'Mr', 'Jesus', 'Jorge', 'OPP', 'Jesus@example.com', '347-654-3210', '1984-11-20'),
('Poly Glue Sticks','no street for','ASH','848345','IL','545121887','Ms','Ditsa','Mollinger','CEO','Dit@example.com','058-545-6979','1974-07-24'),
('SVILANO','Efcharisto 289','PIR','454854','GR','GR2341676523','Mr', 'Panayoti','koukoulis','BRO','peter@stick.com','054-858-8878','1998-03-31');

INSERT INTO Shipment_Details
VALUES
('2024-02-28','DDU','5POLY','6SVILA','5POLY','PREPAID','151.2','15','no street for','2024-03-15','HFA','2024-03-18','PIR','2024-03-25','Efcharisto 289','2024-03-30'),
('2024-02-28','DDP','3NORD','2FURDE','3NORD','PREPAID','200','10','nothing street','2024-03-05','ASH','2024-03-08','HAM','2024-03-12','ENGLISCHE PLANKE 2','2024-03-17'),
('2024-02-28','EXW','4EAT Y','1YUMMI','1YUMMI','COLLECT','25000','2750','FLORES NORTE','2024-03-15','BUE','2024-03-18','ASH','2024-04-29','30 SHMOTKIN ST','2024-05-02');

INSERT INTO Cargo_Details (Shipment_ID, ShortDescription, Weight_KG, Volume_CBM, Packages, Package_Type, Container_Number, Seal_Number, Container_Type, AdditionalHandlingNotes)
VALUES
    (1, 'GLUE', 500.00, 12.5, 10, 'CTN', 'ZLCU1234567', 'SEAL123456', '20DV', 'IMO CLASS'),
    (2, 'POLYPROPILENE', 500.00, 17.2, 95, 'BAG', 'MLCU9876542', 'SEAL789012', '40DV', 'Non Stackable BigBags'),
	(3, 'FRESH MEAT', 21000.00, 55, 454, 'PLT', 'HLXU9865321', 'SEAL789012', '40RH', 'Temp Range: 1-3 degrees C');

INSERT INTO Shipment_Status (Shipment_ID, EventDate, EventCode, Notes)
VALUES
    (1, '2024-02-28', 'OPN', 'Opened'),
    (2, '2024-02-28', 'OPN', 'Opened'),
    (3, '2024-02-28', 'OPN', 'Opened');

