USE SQLProjects;

----DATA CLEANING----
SELECT * FROM datacleaning;

--1 Standartize date format

SELECT
	SaleDate,
	CONVERT(date, SaleDate) AS SaleDateConverted
FROM DataCleaning;

UPDATE DataCleaning
SET SaleDate = CONVERT(DATE, SaleDate);

----IF ERROR----
--ALTER TABLE DataCleaning
--ADD SaleDateConverted DATE;

--UPDATE DataCleaning
--SET SaleDateConverted = CONVERT(DATE, SaleDate)

--SELECT SaleDateConverted FROM DataCleaning


----2 POPULATE PROPERTY ADDRESS WHEN IS NULL----
SELECT * FROM DataCleaning
WHERE PropertyAddress IS NULL;

--SELF JOIN
-- ID is always different, but Parcel ID Repeats

--Confirmation
SELECT
	t1.ParcelID,
	t1.PropertyAddress,
	t2.ParcelID,
	t2.PropertyAddress,
	ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM DataCleaning t1
JOIN DataCleaning t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress IS NULL;

--Updating the NULL fields
UPDATE t1
SET PropertyAddress = ISNULL(t1.PropertyAddress, t2.PropertyAddress)
FROM DataCleaning t1
JOIN DataCleaning t2
	ON t1.ParcelID = t2.ParcelID
	AND t1.UniqueID <> t2.UniqueID
WHERE t1.PropertyAddress IS NULL;


----3 BREAKING OUT INTO INDIVIDUAL COLUMNS (Address, City, State)----
--Testing Out
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1), --CHARINDEX (POSITION)
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS Address --CHARINDEX (POSITION)/LENGTH (NUMBER OF CHARACTERS)
FROM DataCleaning;

--Creating new columns
ALTER TABLE DataCleaning
ADD PropertySplitAddress Nvarchar(255);

UPDATE DataCleaning
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1);

ALTER TABLE DataCleaning
ADD PropertySplitCity Nvarchar(255);

UPDATE DataCleaning
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress));


----4 OWNERADDRESS breaking the column out

SELECT
PARSENAME(REPLACE(OwnerAddress,',', '.'), 3), --PARSENAME ONLY WORKS WITH '.', NOT 'COMMA'.
PARSENAME(REPLACE(OwnerAddress,',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress,',', '.'), 1)
FROM DataCleaning

ALTER TABLE DataCleaning
ADD OwnerSplitAddress Nvarchar(255);

UPDATE DataCleaning
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',', '.'), 3);

ALTER TABLE DataCleaning
ADD OwnerSplitCity Nvarchar(255);

UPDATE DataCleaning
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',', '.'), 2);

ALTER TABLE DataCleaning
ADD OwnerSplitState Nvarchar(255);

UPDATE DataCleaning
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',', '.'), 1);

SELECT * FROM datacleaning;

----5 STANDARDIZING TO YES OR NO, ACCORDING TO THE ORIGINAL DATABASE
--Testing out
SELECT
SoldAsVacant,
CASE WHEN SoldAsVacant = '1' THEN 'Yes'
	 WHEN SoldAsVacant = '0' THEN 'No'
	 ELSE NULL
	 END
FROM DataCleaning

--Changing the table
ALTER TABLE DataCleaning
ALTER COLUMN SoldAsVacant NVARCHAR(50);

UPDATE DataCleaning
SET SoldAsVacant =
CASE WHEN SoldAsVacant = '1' THEN 'Yes'
	 WHEN SoldAsVacant = '0' THEN 'No'
	 ELSE NULL
	 END

SELECT SoldAsVacant,
COUNT(SoldAsVacant)
FROM DataCleaning
GROUP BY SoldAsVacant;


----6 REMOVE DUPLICATES - IF CERTAIN----
--Selecting the duplicate data:
WITH duplicateCTE AS(
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference,
		OwnerName
	ORDER BY UniqueID) row_number
FROM DataCleaning
)
SELECT * FROM duplicateCTE
WHERE row_number > 1
ORDER BY ParcelID

--Deleting it
WITH duplicateCTE AS(
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY 
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference,
		OwnerName
	ORDER BY UniqueID) row_number
FROM DataCleaning
)
DELETE FROM duplicateCTE
WHERE row_number > 1;

----7 DELETE UNUSED COLUMN (Example)----
ALTER TABLE DataCleaning
DROP COLUMN PropertyAddress,
			SaleDateConverted,
			OwnerAddress;

SELECT * FROM DataCleaning;


