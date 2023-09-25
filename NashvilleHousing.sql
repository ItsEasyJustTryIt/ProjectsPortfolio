/*

Portfolio Project: Cleaning Data using SQL Queries

*/


Select *
From PortfolioProjects.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

--1. Create column for converted date
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;
--2. Update new column with the converted date. "convert date" removes time portion of data
Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

--ALTER TABLE NashvilleHousing
--DROP COLUMN saleDateConverted

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data (29 Rows)

Select *
From PortfolioProjects.dbo.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID


--1. Self join to investigate null addresses where ParcelID is the same
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProjects.dbo.NashvilleHousing a
JOIN PortfolioProjects.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

--2. Update the PropertyAddress with missing values using UPDATE
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From PortfolioProjects.dbo.NashvilleHousing a
JOIN PortfolioProjects.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From PortfolioProjects.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

--1. Breakout streetname/number and city
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address --Streetname and number
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) as Address --City
From PortfolioProjects.dbo.NashvilleHousing

--2. Create columns
ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
Add PropertySplitAddress Nvarchar(255); --Address
-- Check if the table exists
-- Check permissions for the current user on the NashvilleHousing table


ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
Add PropertySplitCity Nvarchar(255); --City

--3. Update created columns with splits address and city info
Update PortfolioProjects.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

Update PortfolioProjects.dbo.NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))


--Lets take a look
Select *
From PortfolioProjects.dbo.NashvilleHousing



--1. Breakout streetname/number and city using PARSENAME REPLACE
Select OwnerAddress
From PortfolioProjects.dbo.NashvilleHousing

--REMEMBER PARSENAME looks for ".", replace all "," with "."
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From PortfolioProjects.dbo.NashvilleHousing


--2. Add columns and update each
--ALTER TABLE portfolioprojects.dbo.NashvilleHousing
--DROP COLUMN OwnerSplitAddress;
ALTER TABLE portfolioprojects.dbo.NashvilleHousing
Add OwnerSplitAddress Nvarchar(255),
    OwnerSplitCity Nvarchar(255),
    OwnerSplitState Nvarchar(255);

Update portfolioprojects.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);

--Check
Select *
From PortfolioProjects.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From PortfolioProjects.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

--Lets take a look after converting
Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From PortfolioProjects.dbo.NashvilleHousing

--Update table with above CASE statement
Update PortfolioProjects.dbo.NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
				   When SoldAsVacant = 'N' THEN 'No'
				   ELSE SoldAsVacant
				   END



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates, assuming UniqueID doesnt exist. PARTITION BY creates a unique row

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From PortfolioProjects.dbo.NashvilleHousing
--order by ParcelID
)
--DELETE
Select *
From RowNumCTE
Where row_num > 1
--Order by PropertyAddress



Select *
From PortfolioProjects.dbo.NashvilleHousing




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From PortfolioProjects.dbo.NashvilleHousing


ALTER TABLE PortfolioProjects.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate



-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProjects 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProjects;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProjects;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO


