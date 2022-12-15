-- Having a look on DATA 
SELECT * FROM nashville_housing_data_for_data_cleaning;



-- Standardize Date Format
ALTER TABLE nashville_housing_data_for_data_cleaning 
ADD COLUMN SoldDate DATE AFTER SaleDate;

UPDATE nashville_housing_data_for_data_cleaning 
SET SoldDate = STR_TO_DATE(SaleDate,'%d-%m-%Y') ;

ALTER TABLE nashville_housing_data_for_data_cleaning 
DROP COLUMN SaleDate;




-- Populate Property Address Data
SELECT * FROM nashville_housing_data_for_data_cleaning
GROUP BY ParcelID ;
SELECT COUNT(PropertyAddress) FROM nashville_housing_data_for_data_cleaning WHERE PropertyAddress IS NOT NULL;
-- No NULL values present


-- Separating Address of Property and Owner

-- Property Address Splitting
ALTER TABLE nashville_housing_data_for_data_cleaning 
ADD COLUMN PropertySplitAddress VARCHAR(255) AFTER PropertyAddress;

ALTER TABLE nashville_housing_data_for_data_cleaning 
ADD COLUMN PropertySplitCity VARCHAR(255) AFTER PropertySplitAddress;

-- SELECT instr(PropertyAddress,',') FROM nashville_housing_data_for_data_cleaning; 

UPDATE nashville_housing_data_for_data_cleaning SET
PropertySplitAddress = SUBSTR(PropertyAddress,1,INSTR(PropertyAddress,',')-1);

UPDATE nashville_housing_data_for_data_cleaning SET
PropertySplitCity = SUBSTR(PropertyAddress,INSTR(PropertyAddress,',')+1,LENGTH(PropertyAddress));

ALTER TABLE nashville_housing_data_for_data_cleaning DROP COLUMN PropertyAddress;


-- Owner Address Splitting

ALTER TABLE nashville_housing_data_for_data_cleaning 
ADD COLUMN OwnerSplitAddress VARCHAR(255) AFTER OwnerAddress;

ALTER TABLE nashville_housing_data_for_data_cleaning 
ADD COLUMN OwnerSplitCity VARCHAR(255) AFTER OwnerSplitAddress;

ALTER TABLE nashville_housing_data_for_data_cleaning 
ADD COLUMN OwnerSplitState VARCHAR(255) AFTER OwnerSplitCity;

-- SELECT SUBSTRING_INDEX(OwnerAddress,',',1) FROM nashville_housing_data_for_data_cleaning;
-- SELECT SUBSTRING_INDEX(OwnerAddress,',',2) FROM nashville_housing_data_for_data_cleaning; 

UPDATE nashville_housing_data_for_data_cleaning SET
OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress,',',1);

UPDATE nashville_housing_data_for_data_cleaning SET
OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',',2),',',-1);

UPDATE nashville_housing_data_for_data_cleaning SET
OwnerSplitState = SUBSTRING_INDEX(OwnerAddress,',',-1);

ALTER TABLE nashville_housing_data_for_data_cleaning DROP COLUMN OwnerAddress;


-- Fixing SalePrice DataType
SELECT SalePrice FROM nashville_housing_data_for_data_cleaning WHERE SalePrice LIKE '%,%' OR SalePrice LIKE '$%';

UPDATE nashville_housing_data_for_data_cleaning SET
SalePrice = CASE
	WHEN LENGTH(SalePrice) > 6 THEN 
	TRIM(LEADING '$' FROM CONCAT(SUBSTRING_INDEX(SalePrice,',',1),SUBSTRING_INDEX(SUBSTRING_INDEX(SalePrice,',',2),',',-1),SUBSTRING_INDEX(SalePrice,',',-1)))
	WHEN LENGTH(SalePrice) <= 6 THEN
	SUBSTRING(TRIM(LEADING '$' FROM CONCAT(SUBSTRING_INDEX(SalePrice,',',1),SUBSTRING_INDEX(SUBSTRING_INDEX(SalePrice,',',2),',',-1),SUBSTRING_INDEX(SalePrice,',',-1))),1,LENGTH(SalePrice)-1)
	END
	WHERE SalePrice LIKE '%,%' OR SalePrice LIKE '$%';

ALTER TABLE nashville_housing_data_for_data_cleaning 
ADD COLUMN SalesPrice INTEGER AFTER SalePrice; 

UPDATE nashville_housing_data_for_data_cleaning  SET
SalesPrice = CAST(SalePrice AS UNSIGNED);

ALTER TABLE nashville_housing_data_for_data_cleaning DROP COLUMN SalePrice;

	
	
	
-- Change Y and N in "SoldAsVacant" field
SELECT SoldAsVacant, COUNT(SoldAsVacant) FROM nashville_housing_data_for_data_cleaning
GROUP BY SoldAsVacant
ORDER BY 2; 

SELECT 
(CASE
	WHEN SoldAsVacant LIKE "Y%" THEN "Yes"
	WHEN SoldAsVacant LIKE "N%" THEN "No"
END) FROM nashville_housing_data_for_data_cleaning;


UPDATE nashville_housing_data_for_data_cleaning SET 
SoldAsVacant = CASE
				WHEN SoldAsVacant LIKE "Y%" THEN "Yes"
				WHEN SoldAsVacant LIKE "N%" THEN "No"
				END;
				
			
			
-- Remove Duplicates
WITH DuplicateRec AS(		
SELECT *,
	ROW_NUMBER() OVER 
	(PARTITION BY ParcelID,
				  PropertySplitAddress,
		          PropertySplitCity,
		          SalesPrice,
		          SoldDate,
		          LegalReference
		          ORDER BY UniqueID) R_num 
FROM nashville_housing_data_for_data_cleaning
)
DELETE FROM nashville_housing_data_for_data_cleaning WHERE UniqueID IN (SELECT UniqueID FROM DuplicateRec WHERE R_num>1);


-- Removing Irrelevant or useless Columns
SELECT * FROM nashville_housing_data_for_data_cleaning;
-- No Such Columns Found
		
	
	
	



