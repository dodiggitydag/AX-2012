/* Fix table and field IDs to match AX model (code)
 *   This script fixes both Table and Field IDs in SqlDictionary (data db) to match the AX code (Model db).
 *   Useful for after a database has been restored and the table or field IDs do not match.  Instead of letting
 *   the database synchronization process drop and recreate the table, just run this!
 *
 * Before Running-
 *   Stop the AOS
 *   Always take the appropriate SQL backups before running this script
 *   Change database name <<AX2012DB>> to your own DB names (Ctrl + H)
 *
 * After Running-
 *   Add a reminder in your calendar to delete the table backups made: SQLDICTIONARY_BAK and SYSTEMSEQUENCES_BAK
 *   Start the AOS and try a dbsync within AX
 *
 * Notes
 *   To review what it will do, run the CTE separately before running the whole command.
 *   Objects that are new in AOT will get created in SQL dictionary when synchonisation happens
 *
 * History
 *   2018-05-18 Dag Calafell  Now it fixes the case where field ID is the same but name is different
 *   2018-05-18 Dag Calafell  Added step to remove duplicates in SqlDictionary
 *   2018-05-17 Dag Calafell  Initial code
 *           from http://abraaxapta.blogspot.com/2011/06/accessing-dynamics-ax-containers-from.html
 *           from http://daxjohan.blogspot.com.au/2015/01/ax-2012-r2-fix-sqldictionary.html
 */

USE AX2012DB
GO

-- Backup the existing SQL dictionary as precaution
SELECT *
INTO AX2012DB.dbo.SQLDICTIONARY_BAK
FROM AX2012DB.dbo.SQLDICTIONARY

SELECT *
INTO AX2012DB.dbo.SYSTEMSEQUENCES_BAK
FROM AX2012DB.dbo.SYSTEMSEQUENCES

----------------------------------------------------------------------------------------------
-- Step 1: Check and fix any duplicates in SqlDictionary.
----------------------------------------------------------------------------------------------
PRINT 'Step 1';

SELECT
    *,
    ROW_NUMBER() OVER(PARTITION BY Name, SQLName ORDER BY RecID) as RN
INTO #RecordsWithDuplicateTableIds
FROM AX2012DB.dbo.SQLDICTIONARY
WHERE SQLDICTIONARY.FIELDID = 0

-- Remove the non-duplicates from our list
DELETE #RecordsWithDuplicateTableIds
WHERE RN = 1

-- Delete the duplicate records for the tables, and the field records for those duplicated tables
DELETE AX2012DB.dbo.SQLDICTIONARY
WHERE TableId IN (SELECT TableId FROM #RecordsWithDuplicateTableIds)

DROP TABLE #RecordsWithDuplicateTableIds



USE AX2012DB_Model
GO

----------------------------------------------------------------------------------------------
-- Step 2 Find tables in SqlDictionary that have same name as in AOT but different ID and
--   update SystemSequences.TabID = TableID in Modelstore.  The SystemSequences table holds
--   the next available record ID block for each table.  The AOS actually consumes blocks of
--   RecId's, usually 256 at a time, and so the AOS must not be running.
----------------------------------------------------------------------------------------------
PRINT 'Step 2';

WITH t AS (
    SELECT
        m.ElementHandle,
        m.NAME AS mName,
        m.AxId,
        md.LegacyId,
        s.TABLEID,
        s.NAME AS sName,
        s.SQLNAME
    FROM ModelElementData md, ModelElement m
    LEFT OUTER JOIN AX2012DB..SQLDictionary s
        ON upper(m.NAME) collate Latin1_General_CI_AS = s.NAME
    WHERE m.ElementType = 44 -- UtilElementType::Table
        AND m.elementhandle = md.elementhandle
        AND s.ARRAY = 0
        AND s.FIELDID = 0
        AND s.TABLEID != m.AxId
)
UPDATE AX2012DB.dbo.SYSTEMSEQUENCES
SET TABID = t.axid
FROM t
JOIN AX2012DB.dbo.SYSTEMSEQUENCES x
    ON t.tableid = x.tabid
GO

----------------------------------------------------------------------------------------------
--Step 3 Find tables in SqlDictionary having the same name as in AOT but different ID and
--   update the ID to match the ModelstoreID in SqlDictionary for Table and fields records.
----------------------------------------------------------------------------------------------
PRINT 'Step 3';

WITH t AS (
    SELECT
        m.ElementHandle,
        m.NAME AS mName,
        m.AxId,
        md.LegacyId,
        s.TABLEID,
        s.NAME AS sName,
        s.SQLNAME
    FROM modelelementdata md,ModelElement m
    LEFT OUTER JOIN AX2012DB..SQLDictionary s
    ON upper(m.NAME) collate Latin1_General_CI_AS = s.NAME
    WHERE m.ElementType = 44 -- UtilElementType::Table
        AND m.elementhandle = md.elementhandle
        AND s.ARRAY = 0
        AND s.FIELDID = 0
        AND s.TABLEID != m.AxId
)
UPDATE AX2012DB.dbo.SQLDICTIONARY
SET TABLEID = (t.axid * -1)  -- Update to the correct number, but as a negative, just in case the destimation number is currently being used
FROM t
JOIN AX2012DB.dbo.SQLDICTIONARY s
ON t.tableid = s.tableid
GO


--verify SQLDICTIONARY that have negative IDs for change to positive
WITH t AS  (
    SELECT
        m.ElementHandle,
        m.NAME AS mName,
        m.AxId,
        md.LegacyId,
        s.TABLEID,
        s.NAME AS sName,
        s.SQLNAME
    FROM modelelementdata md, ModelElement m
    LEFT OUTER JOIN AX2012DB..SQLDictionary s
    ON (s.TABLEID * -1) = m.AxId
    WHERE m.ElementType = 44 -- UtilElementType::Table
        AND m.elementhandle = md.elementhandle
        AND s.ARRAY = 0
        AND s.FIELDID = 0
        AND upper(m.NAME) collate Latin1_General_CI_AS = s.NAME
)
UPDATE AX2012DB.dbo.SQLDICTIONARY
SET TABLEID = (TABLEID * -1) -- Update to positive
WHERE AX2012DB.dbo.SQLDICTIONARY.TABLEID < 0
GO


----------------------------------------------------------------------------------------------
-- Step 4 Fix the field ids in SQLDictionary which do not match
----------------------------------------------------------------------------------------------
PRINT 'Step 4';

WITH t AS (
    SELECT (
            SELECT m1.NAME
            FROM ModelElement m1
            WHERE m1.ElementHandle = m.ParentHandle
        ) AS [Table Name],
        m.NAME AS [mName],
        m.AXid,
        s.RECID,
        M.ParentId,
        s.TableId,
        s.FIELDID,
        S.NAME,
        s.SQLNAME
    FROM ModelElement m
    LEFT OUTER JOIN AX2012DB..SQLDICTIONARY s
        ON m.ParentId = s.TABLEID
        AND s.NAME =  upper(m.NAME) collate Latin1_General_CI_AS
    WHERE m.ElementType = 42 -- UtilElementType::TableField
        AND (s.ARRAY = 1 OR s.ARRAY IS NULL)
        AND (s.FIELDID > 0 OR s.FIELDID IS NULL)
        AND s.FIELDID != m.AxId
)
UPDATE AX2012DB.dbo.SQLDICTIONARY
SET FIELDID = (t.axid * -1) -- Set to a negative number but correct ID
FROM t join AX2012DB.dbo.SQLDICTIONARY s
ON upper(t.mName) collate Latin1_General_CI_AS = s.NAME
    AND s.FIELDID <> 0
    AND s.TABLEID = t.ParentId
GO

-- Reverse the negative to positive
UPDATE AX2012DB.dbo.SQLDICTIONARY
SET FIELDID = (FIELDID * -1)
WHERE FIELDID < 0
GO

----------------------------------------------------------------------------------------------
-- Step 5 Fix the field ids in SQLDictionary which do not match
-- There is a chance that the ID of a newly added field conflicts with an existing ID which is a field which is going away (not in the AX model)
-- This is not typical but has happened.
----------------------------------------------------------------------------------------------
PRINT 'Step 5';

WITH t AS (
    SELECT (
            SELECT m1.NAME
            FROM ModelElement m1
            WHERE m1.ElementHandle = m.ParentHandle
        ) AS [Table Name],
        m.NAME AS [mName],
        m.AXid,
        s.RECID,
        M.ParentId,
        s.TableId,
        s.FIELDID,
        S.NAME,
        s.SQLNAME,
        (
            SELECT MAX(FieldId)
            FROM AX2012DB..SQLDICTIONARY
            WHERE SQLDICTIONARY.TableId = s.TableId
        ) + 1 as [Next FieldId Would Be]
    FROM ModelElement m
    LEFT OUTER JOIN AX2012DB..SQLDICTIONARY s
        ON m.ParentId = s.TABLEID
        AND s.FIELDID = m.AxId
    WHERE m.ElementType = 42 -- UtilElementType::TableField
        AND (s.ARRAY = 1 OR s.ARRAY IS NULL)
        AND (s.FIELDID > 0 OR s.FIELDID IS NULL)
        AND s.NAME !=  upper(m.NAME) collate Latin1_General_CI_AS
)
UPDATE AX2012DB.dbo.SQLDICTIONARY
SET FieldID = [Next FieldId Would Be]
FROM t
JOIN AX2012DB.dbo.SQLDICTIONARY s
ON t.tableid = s.tableid
    AND t.FieldID = s.FieldID
GO
