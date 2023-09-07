/*
	CLEANING OF HOUSING DATA
*/

-- Taking a preview of the data

SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing

-- Stanardizing the Sale Date column to obtain the correct date format
SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM PortfolioProjects.dbo.NashvilleHousing

--Updating the formated Sale Date cloumn
UPDATE NashvilleHousing 
SET SaleDate = CONVERT(Date, SaleDate)

--Alternatively,  the update can be done with ALTER TABLE AND THE UPDATE, if the first did'nt work properly
ALTER TABLE NashvilleHousing
ADD SaleDateFormatted Date

UPDATE NashvilleHousing 
SET SaleDateFormatted = CONVERT(Date, SaleDate) 


--Populating the PropertyAddress, assuming each parcelID has the same address and the uniqueIDs are indeed unique.

SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing
--where PropertyAddress IS NULL
ORDER BY ParcelID

--A self join was carried out on the NashvilleHousing Data so that missing property address can be populated by replacing nulls with the available parcelID adress using UPDATE

SELECT NashVilleNULL.ParcelID, 
	NashVilleNULL.PropertyAddress, 
	NashVilleNOTNULL.ParcelID, 
	NashVilleNOTNULL.PropertyAddress, 
	ISNULL(NashVilleNULL.PropertyAddress, 
	NashVilleNOTNULL.PropertyAddress) 
FROM PortfolioProjects.dbo.NashvilleHousing AS NashVilleNULL
JOIN PortfolioProjects.dbo.NashvilleHousing AS NashVilleNOTNULL
	ON NashVilleNULL.ParcelID = NashVilleNOTNULL.ParcelID
	AND NashVilleNULL.[UniqueID ] <> NashVilleNOTNULL.[UniqueID ]
WHERE NashVilleNULL.PropertyAddress IS NULL


--Populating the nulls in the property address column

UPDATE NashVilleNULL 
SET PropertyAddress = ISNULL(NashVilleNULL.PropertyAddress, 
	NashVilleNOTNULL.PropertyAddress)
FROM PortfolioProjects.dbo.NashvilleHousing AS NashVilleNULL
JOIN PortfolioProjects.dbo.NashvilleHousing AS NashVilleNOTNULL
	ON NashVilleNULL.ParcelID = NashVilleNOTNULL.ParcelID
	AND NashVilleNULL.[UniqueID ] <> NashVilleNOTNULL.[UniqueID ] 
WHERE NashVilleNULL.PropertyAddress IS NULL

--Checking to see if the property address was adequately populated

SELECT *
FROM PortfolioProjects.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL


-- Splitting the property address into individual columns

SELECT PropertyAddress
FROM PortfolioProjects.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

--Extracting the address from the property address column 

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address
FROM PortfolioProjects.dbo.NashvilleHousing

--Extracting the City from the property address
SELECT SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM PortfolioProjects.dbo.NashvilleHousing

--OR using the right Function (Both gives the same result)
SELECT RIGHT(PropertyAddress,LEN(PropertyAddress)-CHARINDEX(',', PropertyAddress)-1) AS City
FROM PortfolioProjects.dbo.NashvilleHousing

--Updating the NashvilleHousing data with the splitted property address and city as new columns
ALTER TABLE NashvilleHousing
ADD PptyAddress Nvarchar(255) -- pptyAddress = New Property Address 

UPDATE NashvilleHousing 
SET PptyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PptyCity Nvarchar(255) --PptyCity = Property City

UPDATE NashvilleHousing 
SET PptyCity = RIGHT(PropertyAddress,LEN(PropertyAddress)-CHARINDEX(',', PropertyAddress)-1) 

-- Changing the delimeter comma (,) to period (.) since Parsename() operates with period
SELECT REPLACE(OwnerAddress, ',','.')
FROM PortfolioProjects.dbo.NashvilleHousing

--Extracting the only the Owner's address from the Owner's address column 

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',','.'),3),
	PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
	PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
FROM PortfolioProjects.dbo.NashvilleHousing
--WHERE OwnerAddress IS NOT NULL

--Updating the NashvilleHousing data with the splitted owner's address, state, and city to establish new columns
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255)

UPDATE NashvilleHousing 
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255)

UPDATE NashvilleHousing 
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255)

UPDATE NashvilleHousing 
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

--Cleaning the sold as vacant column 

SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProjects.dbo.NashvilleHousing 
GROUP BY SoldAsVacant

--Using the Case statement to standrdize the Sold as vacant column

SELECT SoldAsVacant, COUNT(SoldAsVacant),
	CASE WHEN SoldAsVacant = 'N' THEN 'No'
		 WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 ELSE SoldAsVacant
		 END
FROM PortfolioProjects.dbo.NashvilleHousing 
GROUP BY SoldAsVacant

UPDATE NashvilleHousing 
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		ELSE SoldAsVacant
		END

--Removing duplicates in the data (This is a standalone copy of the Nashville Housing data
WITH Row_NumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 SaleDate,
					 SalePrice,
					 PropertyAddress,
					 LegalReference
					 ORDER BY
					 UniqueID
					   ) AS Row_Num
FROM PortfolioProjects.dbo.NashvilleHousing 
)
DELETE 
FROM Row_NumCTE
WHERE Row_Num >1

-- Deleting irrevalent data columns -- (The unsused columns were deleted sinces it's a standalone copy of a data)

ALTER TABLE NashvilleHousing 
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress, TaxDistrict


SELECT OwnerSplitCity, ROUND(AVG(SalePrice),1) AS AVGPrice
FROM PortfolioProjects.dbo.NashvilleHousing 
GROUP BY OwnerSplitCity
ORDER BY AVGPrice DESC
