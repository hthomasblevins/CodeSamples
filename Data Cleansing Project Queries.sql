/* Data Cleansing Queries -- Nashville Housing Data */

-- Select database to use
USE [HousingData]

-- Make a copy of the source table for cleansing
DROP TABLE IF EXISTS dbo.NashvilleHousingCleansed;
SELECT * INTO dbo.NashvilleHousingCleansed FROM dbo.NashvilleHousingSource

-- Change the data type for SaleDate to Date (was datetime) to enforce a standard display type
ALTER TABLE dbo.NashvilleHousingCleansed 
ALTER COLUMN SaleDate Date NOT NULL 
GO

-- Replace Null Property Address when there is a populated value for the same Parcel ID

--SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) as CorrectAddress
--	FROM dbo.NashvilleHousingCleansed a
--	INNER JOIN dbo.NashvilleHousingCleansed b
--	ON a.ParcelID = b.ParcelID
--		AND a.[UniqueID ] <> b.[UniqueID ]

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
	FROM dbo.NashvilleHousingCleansed a
	INNER JOIN dbo.NashvilleHousingCleansed b
	ON a.ParcelID = b.ParcelID
		AND a.[UniqueID ] <> b.[UniqueID ]


-- Split Property Address into Street and City

ALTER TABLE dbo.NashvilleHousingCleansed 
ADD PropertyStreetAddress nvarchar(255);
GO

UPDATE dbo.NashvilleHousingCleansed
SET PropertyStreetAddress = SUBSTRING (PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)
GO

ALTER TABLE dbo.NashvilleHousingCleansed 
ADD PropertyCity nvarchar(255);
GO

UPDATE dbo.NashvilleHousingCleansed
SET PropertyCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))
GO

-- Parse out the Owner Address to Street, City, State
ALTER TABLE dbo.NashvilleHousingCleansed 
ADD OwnerStreetAddress nvarchar(255);

ALTER TABLE dbo.NashvilleHousingCleansed 
ADD OwnerCity nvarchar(255);

ALTER TABLE dbo.NashvilleHousingCleansed 
ADD OwnerState nvarchar(255);
GO

UPDATE dbo.NashvilleHousingCleansed
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

UPDATE dbo.NashvilleHousingCleansed
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

UPDATE dbo.NashvilleHousingCleansed
SET OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)
GO


-- Cleanse the SoldAsVacant field to have consistent values

-- Determine current state of values
--SELECT DISTINCT(SoldasVacant), COUNT(SoldAsVacant)
--FROM dbo.NashvilleHousingCleansed
--GROUP BY SoldAsVacant
--ORDER BY COUNT(SoldAsVacant) desc

-- Use SQL code to normalize the values of SoldAsVacant
UPDATE dbo.NashvilleHousingCleansed
	SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
			When SoldAsVacant = 'N' THEN 'No'
			Else SoldAsVacant
			END
GO

-- Identify and remove duplicate records in the cleansed table
-- Use a Common Table Expression (CTE) to flag duplicate rows based on identical field values

WITH FindDupRowsCTE AS (
	Select *,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY
							UniqueID
						) Dup_Flag
	FROM dbo.NashvilleHousingCleansed
	)
DELETE 
FROM FindDupRowsCTE
WHERE Dup_Flag > 1 
GO

-- Validate that no duplicate rows remain
WITH FindDupRowsCTE AS (
	Select *,
		ROW_NUMBER() OVER (
			PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY
							UniqueID
						) Dup_Flag
	FROM dbo.NashvilleHousingCleansed
	)
SELECT * 
FROM FindDupRowsCTE
WHERE Dup_Flag > 1
ORDER BY PropertyAddress
GO

-- Remove redundant columns from the cleansed data table
ALTER TABLE dbo.NashvilleHousingCleansed
DROP COLUMN OwnerAddress,PropertyAddress

-- Review cleansed data
SELECT * FROM dbo.NashvilleHousingCleansed



