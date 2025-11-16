-- Row-Level Security (RLS) Implementation Template
-- =================================================
-- For Fabric Warehouse and Semantic Models
-- Last Updated: 2024

-- ═══════════════════════════════════════════════════════
-- SECTION 1: SECURITY MAPPING TABLES
-- ═══════════════════════════════════════════════════════

-- Table to store user-to-region access mappings
CREATE TABLE Security.UserRegionAccess (
    UserEmail NVARCHAR(255) NOT NULL,
    AllowedRegion NVARCHAR(50) NOT NULL,
    AccessLevel NVARCHAR(20) NOT NULL DEFAULT 'Standard',
    EffectiveDate DATE NOT NULL DEFAULT GETDATE(),
    ExpirationDate DATE NULL,
    GrantedBy NVARCHAR(255) NOT NULL,
    GrantedDate DATETIME NOT NULL DEFAULT GETUTCDATE(),
    Notes NVARCHAR(500) NULL,

    CONSTRAINT PK_UserRegionAccess PRIMARY KEY (UserEmail, AllowedRegion),
    CONSTRAINT CK_AccessLevel CHECK (AccessLevel IN ('Standard', 'Admin', 'ReadOnly', 'Restricted'))
);

-- Table to store user-to-department access mappings
CREATE TABLE Security.UserDepartmentAccess (
    UserEmail NVARCHAR(255) NOT NULL,
    DepartmentCode NVARCHAR(20) NOT NULL,
    CanViewSensitive BIT NOT NULL DEFAULT 0,
    CanExport BIT NOT NULL DEFAULT 0,
    EffectiveDate DATE NOT NULL DEFAULT GETDATE(),
    ExpirationDate DATE NULL,

    CONSTRAINT PK_UserDepartmentAccess PRIMARY KEY (UserEmail, DepartmentCode)
);

-- Table to store hierarchy-based access (manager sees team data)
CREATE TABLE Security.UserHierarchy (
    UserEmail NVARCHAR(255) NOT NULL,
    ManagerEmail NVARCHAR(255) NULL,
    DepartmentCode NVARCHAR(20) NOT NULL,
    TeamCode NVARCHAR(20) NOT NULL,
    IsManager BIT NOT NULL DEFAULT 0,

    CONSTRAINT PK_UserHierarchy PRIMARY KEY (UserEmail)
);

-- ═══════════════════════════════════════════════════════
-- SECTION 2: SAMPLE DATA FOR TESTING
-- ═══════════════════════════════════════════════════════

-- Insert sample user access mappings
INSERT INTO Security.UserRegionAccess (UserEmail, AllowedRegion, AccessLevel, GrantedBy) VALUES
('alice@company.com', 'North America', 'Standard', 'admin@company.com'),
('bob@company.com', 'Europe', 'Standard', 'admin@company.com'),
('carol@company.com', 'Asia Pacific', 'Standard', 'admin@company.com'),
('david@company.com', 'North America', 'Admin', 'admin@company.com'),
('david@company.com', 'Europe', 'Admin', 'admin@company.com'),
('eve@company.com', 'GLOBAL', 'Admin', 'admin@company.com'),  -- Global access
('frank@company.com', 'North America', 'ReadOnly', 'admin@company.com');

-- Insert hierarchy data
INSERT INTO Security.UserHierarchy (UserEmail, ManagerEmail, DepartmentCode, TeamCode, IsManager) VALUES
('alice@company.com', 'manager1@company.com', 'SALES', 'TEAM_A', 0),
('bob@company.com', 'manager1@company.com', 'SALES', 'TEAM_A', 0),
('manager1@company.com', 'director@company.com', 'SALES', 'TEAM_A', 1),
('carol@company.com', 'manager2@company.com', 'MARKETING', 'TEAM_B', 0),
('manager2@company.com', 'director@company.com', 'MARKETING', 'TEAM_B', 1),
('director@company.com', NULL, 'EXEC', 'LEADERSHIP', 1);

-- ═══════════════════════════════════════════════════════
-- SECTION 3: RLS FILTER FUNCTIONS (FOR WAREHOUSE)
-- ═══════════════════════════════════════════════════════

-- Function to check if user has access to a region
CREATE FUNCTION Security.fn_UserHasRegionAccess(@Region NVARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS HasAccess
    WHERE EXISTS (
        SELECT 1
        FROM Security.UserRegionAccess
        WHERE UserEmail = SUSER_SNAME()
          AND (AllowedRegion = @Region OR AllowedRegion = 'GLOBAL')
          AND (ExpirationDate IS NULL OR ExpirationDate >= GETDATE())
          AND EffectiveDate <= GETDATE()
    );

-- Function to check department access with sensitivity level
CREATE FUNCTION Security.fn_UserDepartmentAccess(
    @DepartmentCode NVARCHAR(20),
    @IsSensitive BIT
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS HasAccess
    WHERE EXISTS (
        SELECT 1
        FROM Security.UserDepartmentAccess
        WHERE UserEmail = SUSER_SNAME()
          AND DepartmentCode = @DepartmentCode
          AND (ExpirationDate IS NULL OR ExpirationDate >= GETDATE())
          AND (@IsSensitive = 0 OR CanViewSensitive = 1)
    );

-- ═══════════════════════════════════════════════════════
-- SECTION 4: SECURITY PREDICATES (APPLY TO TABLES)
-- ═══════════════════════════════════════════════════════

-- Example: Apply RLS to Sales table
-- (Note: This is conceptual - Fabric Warehouse uses different syntax)

-- Create security policy for Fact_Sales
/*
CREATE SECURITY POLICY Security.SalesSecurityPolicy
ADD FILTER PREDICATE Security.fn_UserHasRegionAccess(Region) ON dbo.Fact_Sales
WITH (STATE = ON);
*/

-- ═══════════════════════════════════════════════════════
-- SECTION 5: DAX FILTERS FOR SEMANTIC MODEL
-- ═══════════════════════════════════════════════════════

/*
-- Role: Regional_Sales_Access
-- DAX Filter Expression (apply to Fact_Sales table):

VAR CurrentUser = USERPRINCIPALNAME()
VAR UserRegions =
    CALCULATETABLE(
        VALUES(UserRegionAccess[AllowedRegion]),
        UserRegionAccess[UserEmail] = CurrentUser,
        OR(
            ISBLANK(UserRegionAccess[ExpirationDate]),
            UserRegionAccess[ExpirationDate] >= TODAY()
        ),
        UserRegionAccess[EffectiveDate] <= TODAY()
    )
VAR HasGlobalAccess = "GLOBAL" IN UserRegions
RETURN
    HasGlobalAccess || [Region] IN UserRegions
*/

/*
-- Role: Department_Access
-- DAX Filter Expression (apply to Employee data):

VAR CurrentUser = USERPRINCIPALNAME()
VAR UserDepartments =
    CALCULATETABLE(
        VALUES(UserDepartmentAccess[DepartmentCode]),
        UserDepartmentAccess[UserEmail] = CurrentUser
    )
RETURN
    [DepartmentCode] IN UserDepartments
*/

/*
-- Role: Hierarchical_Access (Manager sees team data)
-- DAX Filter Expression:

VAR CurrentUser = USERPRINCIPALNAME()
VAR IsManagerRole =
    CALCULATE(
        MAX(UserHierarchy[IsManager]),
        UserHierarchy[UserEmail] = CurrentUser
    )
VAR CurrentUserTeam =
    CALCULATE(
        MAX(UserHierarchy[TeamCode]),
        UserHierarchy[UserEmail] = CurrentUser
    )
VAR TeamMembers =
    FILTER(
        UserHierarchy,
        UserHierarchy[TeamCode] = CurrentUserTeam
    )
RETURN
    IsManagerRole = TRUE() && [UserEmail] IN VALUES(TeamMembers[UserEmail])
    || [UserEmail] = CurrentUser  -- User can always see own data
*/

-- ═══════════════════════════════════════════════════════
-- SECTION 6: TESTING & VALIDATION
-- ═══════════════════════════════════════════════════════

-- Test RLS with different users
-- Execute these queries as different users to verify access

-- Test 1: Regional access for Alice (North America only)
/*
EXECUTE AS USER = 'alice@company.com';
SELECT Region, COUNT(*) as RecordCount
FROM dbo.Fact_Sales
GROUP BY Region;
REVERT;
-- Expected: Only North America data visible
*/

-- Test 2: Global access for Eve
/*
EXECUTE AS USER = 'eve@company.com';
SELECT Region, COUNT(*) as RecordCount
FROM dbo.Fact_Sales
GROUP BY Region;
REVERT;
-- Expected: All regions visible
*/

-- Test 3: Expired access (should show no data if expired)
/*
UPDATE Security.UserRegionAccess
SET ExpirationDate = DATEADD(DAY, -1, GETDATE())
WHERE UserEmail = 'test_user@company.com';

EXECUTE AS USER = 'test_user@company.com';
SELECT COUNT(*) FROM dbo.Fact_Sales;
REVERT;
-- Expected: 0 rows
*/

-- ═══════════════════════════════════════════════════════
-- SECTION 7: AUDIT & MONITORING
-- ═══════════════════════════════════════════════════════

-- Table to log RLS access attempts
CREATE TABLE Security.AccessAuditLog (
    AuditID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserEmail NVARCHAR(255) NOT NULL,
    ActionType NVARCHAR(50) NOT NULL,
    ObjectAccessed NVARCHAR(255) NOT NULL,
    AccessGranted BIT NOT NULL,
    Timestamp DATETIME NOT NULL DEFAULT GETUTCDATE(),
    Details NVARCHAR(MAX) NULL
);

-- Procedure to log access (call from application layer)
CREATE PROCEDURE Security.sp_LogAccess
    @UserEmail NVARCHAR(255),
    @ActionType NVARCHAR(50),
    @ObjectAccessed NVARCHAR(255),
    @AccessGranted BIT,
    @Details NVARCHAR(MAX) = NULL
AS
BEGIN
    INSERT INTO Security.AccessAuditLog (UserEmail, ActionType, ObjectAccessed, AccessGranted, Details)
    VALUES (@UserEmail, @ActionType, @ObjectAccessed, @AccessGranted, @Details);
END;

-- Query to analyze access patterns
CREATE VIEW Security.vw_AccessPatternAnalysis AS
SELECT
    UserEmail,
    ActionType,
    ObjectAccessed,
    COUNT(*) as AccessCount,
    SUM(CASE WHEN AccessGranted = 1 THEN 1 ELSE 0 END) as GrantedCount,
    SUM(CASE WHEN AccessGranted = 0 THEN 1 ELSE 0 END) as DeniedCount,
    MIN(Timestamp) as FirstAccess,
    MAX(Timestamp) as LastAccess
FROM Security.AccessAuditLog
GROUP BY UserEmail, ActionType, ObjectAccessed;

-- Alert on suspicious patterns
CREATE VIEW Security.vw_SuspiciousActivity AS
SELECT *
FROM Security.AccessAuditLog
WHERE
    -- Multiple denied accesses
    AccessGranted = 0
    OR
    -- Off-hours access (customize for your timezone)
    DATEPART(HOUR, Timestamp) NOT BETWEEN 7 AND 19
    OR
    -- Weekend access
    DATEPART(WEEKDAY, Timestamp) IN (1, 7);

-- ═══════════════════════════════════════════════════════
-- SECTION 8: MAINTENANCE PROCEDURES
-- ═══════════════════════════════════════════════════════

-- Procedure to grant access
CREATE PROCEDURE Security.sp_GrantRegionAccess
    @UserEmail NVARCHAR(255),
    @Region NVARCHAR(50),
    @AccessLevel NVARCHAR(20) = 'Standard',
    @ExpirationDate DATE = NULL,
    @GrantedBy NVARCHAR(255),
    @Notes NVARCHAR(500) = NULL
AS
BEGIN
    MERGE INTO Security.UserRegionAccess AS target
    USING (SELECT @UserEmail, @Region, @AccessLevel, @ExpirationDate, @GrantedBy, @Notes)
        AS source (UserEmail, AllowedRegion, AccessLevel, ExpirationDate, GrantedBy, Notes)
    ON target.UserEmail = source.UserEmail AND target.AllowedRegion = source.AllowedRegion
    WHEN MATCHED THEN
        UPDATE SET
            AccessLevel = source.AccessLevel,
            ExpirationDate = source.ExpirationDate,
            GrantedBy = source.GrantedBy,
            GrantedDate = GETUTCDATE(),
            Notes = source.Notes
    WHEN NOT MATCHED THEN
        INSERT (UserEmail, AllowedRegion, AccessLevel, ExpirationDate, GrantedBy, Notes)
        VALUES (source.UserEmail, source.AllowedRegion, source.AccessLevel, source.ExpirationDate, source.GrantedBy, source.Notes);

    -- Log the grant action
    EXEC Security.sp_LogAccess @UserEmail, 'ACCESS_GRANT', @Region, 1,
        @Notes = CONCAT('Granted by ', @GrantedBy, '. Level: ', @AccessLevel);
END;

-- Procedure to revoke access
CREATE PROCEDURE Security.sp_RevokeRegionAccess
    @UserEmail NVARCHAR(255),
    @Region NVARCHAR(50),
    @RevokedBy NVARCHAR(255),
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    DELETE FROM Security.UserRegionAccess
    WHERE UserEmail = @UserEmail AND AllowedRegion = @Region;

    -- Log the revocation
    EXEC Security.sp_LogAccess @UserEmail, 'ACCESS_REVOKE', @Region, 0,
        @Notes = CONCAT('Revoked by ', @RevokedBy, '. Reason: ', ISNULL(@Reason, 'Not specified'));
END;

-- Procedure to clean up expired access
CREATE PROCEDURE Security.sp_CleanupExpiredAccess
AS
BEGIN
    DECLARE @ExpiredCount INT;

    -- Archive expired entries
    INSERT INTO Security.UserRegionAccessArchive
    SELECT *, GETUTCDATE() as ArchivedDate
    FROM Security.UserRegionAccess
    WHERE ExpirationDate < GETDATE();

    SET @ExpiredCount = @@ROWCOUNT;

    -- Delete expired entries
    DELETE FROM Security.UserRegionAccess
    WHERE ExpirationDate < GETDATE();

    PRINT CONCAT('Cleaned up ', @ExpiredCount, ' expired access entries.');
END;

-- ═══════════════════════════════════════════════════════
-- SECTION 9: REPORTING
-- ═══════════════════════════════════════════════════════

-- Current access matrix
CREATE VIEW Security.vw_CurrentAccessMatrix AS
SELECT
    u.UserEmail,
    STRING_AGG(u.AllowedRegion, ', ') as AllowedRegions,
    u.AccessLevel,
    u.EffectiveDate,
    u.ExpirationDate,
    DATEDIFF(DAY, GETDATE(), ISNULL(u.ExpirationDate, '2099-12-31')) as DaysUntilExpiration
FROM Security.UserRegionAccess u
WHERE
    (u.ExpirationDate IS NULL OR u.ExpirationDate >= GETDATE())
    AND u.EffectiveDate <= GETDATE()
GROUP BY u.UserEmail, u.AccessLevel, u.EffectiveDate, u.ExpirationDate;

-- Access about to expire (next 30 days)
CREATE VIEW Security.vw_AccessExpiringSOON AS
SELECT *
FROM Security.UserRegionAccess
WHERE
    ExpirationDate IS NOT NULL
    AND ExpirationDate BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE())
ORDER BY ExpirationDate;

-- Users without any access (potential cleanup)
CREATE VIEW Security.vw_UsersWithoutAccess AS
SELECT DISTINCT h.UserEmail
FROM Security.UserHierarchy h
LEFT JOIN Security.UserRegionAccess r ON h.UserEmail = r.UserEmail
WHERE r.UserEmail IS NULL;

-- ═══════════════════════════════════════════════════════
-- SECTION 10: DOCUMENTATION
-- ═══════════════════════════════════════════════════════

/*
IMPLEMENTATION CHECKLIST:
-------------------------
[ ] 1. Create security mapping tables
[ ] 2. Populate with user access data
[ ] 3. Create DAX roles in semantic model
[ ] 4. Apply filter expressions to tables
[ ] 5. Test with multiple users
[ ] 6. Set up audit logging
[ ] 7. Configure monitoring alerts
[ ] 8. Document access policies
[ ] 9. Train administrators
[ ] 10. Schedule regular access reviews

BEST PRACTICES:
--------------
1. Use AAD groups instead of individual users when possible
2. Set expiration dates for temporary access
3. Regular access reviews (quarterly)
4. Audit all access changes
5. Test RLS before production deployment
6. Document all business rules
7. Monitor for security violations
8. Keep security tables optimized
*/

-- End of RLS Security Template
