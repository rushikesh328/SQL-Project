use scube
go 

--down logic
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'p_get_freqs' AND ROUTINE_TYPE = 'PROCEDURE')
BEGIN
    DROP PROCEDURE p_get_freqs;
END;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'p_insert_user' AND ROUTINE_TYPE = 'PROCEDURE')
BEGIN
    DROP PROCEDURE p_insert_user;
END;

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'p_insert_live_analyses' AND ROUTINE_TYPE = 'PROCEDURE')
BEGIN
    DROP PROCEDURE p_insert_live_analyses;
END;

-- Drop existing procedures and triggers if they exist
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 't_before_insert_live_analysis')
BEGIN
    DROP TRIGGER t_before_insert_live_analysis;
END;

IF EXISTS (SELECT * FROM sys.triggers WHERE name = 't_after_insert_live_analysis')
BEGIN
    DROP TRIGGER t_after_insert_live_analysis;
END;

-- Other DROP PROCEDURE statements as needed
-- ...
-- Create a new INSTEAD OF INSERT Trigger with conditional logic
GO
CREATE TRIGGER t_before_insert_live_analysis
ON live_analyses
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowCount INT;
    SELECT @RowCount = COUNT(*) FROM live_analyses;

    -- Diagnostic message to check the row count
    PRINT 'Row count before insert: ' + CAST(@RowCount AS NVARCHAR(10));

    -- Check if the row count exceeds 10
    IF @RowCount >= 10
    BEGIN
        DELETE FROM live_analyses; -- Clear the table if more than 10 records

        -- Diagnostic message to confirm deletion
        PRINT 'Deleted existing records because row count exceeded 10';
    END

    -- Insert the new record
    INSERT INTO live_analyses (analysis_user_id, analysis_content_id, analysis_emotion_id, analysis_emotion, analysis_cube_sec)
    SELECT analysis_user_id, analysis_content_id, analysis_emotion_id, analysis_emotion, analysis_cube_sec
    FROM INSERTED; -- Insert new records from the inserted pseudo-table
END;
GO

drop table if exists results
go
create  TABLE results(
        analysis_emotion NVARCHAR(255),
        emotion_frequency INT,
    );
	go

CREATE PROCEDURE p_get_freqs

AS
BEGIN
    
	
    INSERT INTO results (analysis_emotion, emotion_frequency)
    SELECT
        analysis_emotion,
		COUNT(analysis_emotion) as emotion_frequency
    FROM
        live_analyses a
	GROUP BY
	analysis_emotion;

    SELECT * FROM results;
END;

go

-- Create AFTER INSERT Trigger to copy data from live_analyses to analyses
CREATE TRIGGER t_after_insert_live_analysis
ON live_analyses
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO analyses (analysis_user_id, analysis_content_id, analysis_emotion_id, analysis_emotion, analysis_cube_sec)
    SELECT analysis_user_id, analysis_content_id, analysis_emotion_id, analysis_emotion, analysis_cube_sec
    FROM INSERTED; -- Insert new records from the inserted pseudo-table into analyses
	DECLARE @user_id INT, @content_id INT;

	
    DECLARE @RowCount INT;
    SELECT @RowCount = COUNT(*) FROM live_analyses;

    -- Diagnostic message to check the row count
    PRINT 'Row count before insert: ' + CAST(@RowCount AS NVARCHAR(10));

    -- Check if the row count exceeds 10
    IF @RowCount = 10
    BEGIN
        
EXEC p_get_freqs;
	END;

    END
	go


CREATE PROCEDURE p_insert_live_analyses
    @analysis_user_id INT,
    @analysis_content_id INT,
    @analysis_emotion_id INT,
	@analysis_emotion VARCHAR (50),
    @analysis_cube_sec INT
AS
BEGIN
    INSERT INTO live_analyses (analysis_user_id, analysis_content_id, analysis_emotion_id, analysis_emotion, analysis_cube_sec)
    VALUES (@analysis_user_id, @analysis_content_id, @analysis_emotion_id, @analysis_emotion, @analysis_cube_sec)
END;
GO

CREATE PROCEDURE p_insert_user
	@Name NVARCHAR (250),
    @Email NVARCHAR(250),
    @Age INT,
    @Gender NVARCHAR(50),
    @Region INT,
	@Location NVARCHAR (50) 
AS
BEGIN
    INSERT INTO users (user_name, user_email, user_age, user_gender, user_region, user_location)
    VALUES (@Name, @Email, @Age, @Gender, @Region, @Location)
END
GO


