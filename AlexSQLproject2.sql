DROP TABLE if exists NashvilleHousing
CREATE TABLE NashvilleHousing(
    UniqueID 	int,
    ParcelID	varchar(50),
    LandUse varchar(50),
    PropertyAddress	varchar(50),
    SaleDate	date,
    SalePrice	varchar(50),
    LegalReference	varchar(50),
    SoldAsVacant	varchar(50),
    OwnerName	varchar(255),
    OwnerAddress	varchar(255),
    Acreage	varchar(255),
    TaxDistrict	varchar(50),
    LandValue	varchar(50),
    BuildingValue	varchar(50),
    TotalValue	varchar(50),
    YearBuilt	varchar(50),
    Bedrooms	int,
    FullBath	int,
    HalfBath    int
)

BULK INSERT NashvilleHousing from '/NashvilleHousingDataforDataCleaning.txt' with (fieldterminator = '\t', rowterminator = '0x0a', FIRSTROW= 2);

SELECT *
FROM NashvilleHousing

-- Remove quotes in text
UPDATE NashvilleHousing
SET PropertyAddress = REPLACE(PropertyAddress, '"', ''),
    OwnerName = REPLACE(OwnerName, '"', ''), 
    OwnerAddress = REPLACE(OwnerAddress, '"', '')

-- Populate Property Address data
SELECT *
FROM NashvilleHousing 
WHERE PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL

-- Breaking out propertyaddress into individual columns
SELECT 
    SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
    SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress VARCHAR(255), 
    PropertySplitCity VARCHAR(255)

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1), 
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) 

-- Breaking out owneraddress
SELECT OwnerAddress
FROM NashvilleHousing

SELECT
    PARSENAME(REPLACE(OwnerAddress,',','.'), 3)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress VARCHAR(255), 
    OwnerSplitCity VARCHAR(255),
    OwnerSplitState VARCHAR(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

-- Change Y and N to Yes and No

SELECT DISTINCT SoldAsVacant, COUNT(*)
FROM NashvilleHousing
GROUP BY SoldAsVacant

SELECT
    SoldAsVacant,
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = 
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
    END

-- Remove duplicates
WITH CTE AS(
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SaleDate, SalePrice, LegalReference
            ORDER BY UniqueID) AS row_num
    FROM NashvilleHousing
)
SELECT *
FROM CTE
WHERE row_num >1

DELETE 
FROM CTE
WHERE row_num >1

-- Delete unused columns

ALTER TABLE NashvilleHousing
DROP COLUMN TaxDistrict

SELECT *
FROM NashvilleHousing