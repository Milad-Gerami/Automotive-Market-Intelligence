CREATE DATABASE AutomotiveDashboard_DB;
GO

CREATE TABLE epa_vehicles (
    id               INT IDENTITY(1,1)  NOT NULL,
    make             NVARCHAR(50)       NULL,
    model            NVARCHAR(200)      NULL,
    year             INT                NULL,
    fuelType         NVARCHAR(50)       NULL,
    fuelType1        NVARCHAR(50)       NULL,
    atvType          NVARCHAR(50)       NULL,
    powertrain_group NVARCHAR(50)       NULL,
    city08           INT                NULL,
    highway08        INT                NULL,
    comb08           INT                NULL,
    co2TailpipeGpm   DECIMAL(8,2)       NULL,
    fuelCost08       INT                NULL,
    vclass           NVARCHAR(50)       NULL,
    vclass_group     NVARCHAR(50)       NULL,
    drive            NVARCHAR(50)       NULL,
    cylinders        INT                NULL,
    range            INT                NULL,
    trany            NVARCHAR(50)       NULL,
    trany_group      NVARCHAR(50)       NULL,
    feScore          INT                NULL,
    ghgScore         INT                NULL,
    youSaveSpend     INT                NULL,
    startStop        NCHAR(1)           NULL,
    phevCity         INT                NULL,
    phevHwy          INT                NULL,
    CONSTRAINT PK_epa_vehicles PRIMARY KEY (id)
);
GO

CREATE TABLE iea_ev_trends (
    id              INT IDENTITY(1,1)  NOT NULL,
    region_country  NVARCHAR(100)      NULL,
    category        NVARCHAR(50)       NULL,
    parameter       NVARCHAR(100)      NULL,
    mode            NVARCHAR(50)       NULL,
    powertrain      NVARCHAR(50)       NULL,
    year            INT                NULL,
    unit            NVARCHAR(50)       NULL,
    value           DECIMAL(18,4)      NULL,
    aggregate_group NVARCHAR(50)       NULL,
    CONSTRAINT PK_iea_ev_trends PRIMARY KEY (id)
);
GO