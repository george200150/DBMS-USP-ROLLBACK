use movie

GO

GO
CREATE TABLE Logger
(cod_log INT PRIMARY KEY IDENTITY, --identity face sa se puna automat numele
logged VARCHAR(1000),
StartAt DATETIME,
EndAt DATETIME,
isTemp INT --boolean value meaning if is currently in use
);
GO

ALTER PROCEDURE usp_lab3_sgbd_teardown
AS
BEGIN
	UPDATE Logger SET logged = logged + ' ABORTED', EndAt=GETDATE(), isTemp=0 WHERE isTemp = 1
	UPDATE Logger SET logged = logged + ' ROLLBACK', EndAt=GETDATE(), isTemp=0 WHERE isTemp = 2
END;


GO

ALTER PROCEDURE usp_lab3_sgbd_rollback (@titlu VARCHAR(100), @gen VARCHAR(50))
AS
BEGIN
	SET XACT_ABORT ON
	
	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('validation rollback', GETDATE(), 1);
	--===============================VALIDATION=======================================================
	DECLARE @colectoare VARCHAR(1000) = '';

	IF (LEN(@titlu) = 0)--void
		SET @colectoare = @colectoare + 'TITLUL NU TREBUIE SA GOL'+CHAR(13)+CHAR(10);

	IF (LEN(@gen) = 0)--void
		SET @colectoare = @colectoare + 'GENUL NU TREBUIE SA GOL';
	ELSE
		BEGIN
		IF (@gen LIKE '%[^a-zA-Z0-9 \-]%')--non alpha-numeric
			SET @colectoare = @colectoare + 'GENUL POATE AVEA DOAR LITERE, CIFRE, SPATII SI CRATIMA';
		END;

	IF ( LEN(@colectoare) > 0 )
		BEGIN
		UPDATE Logger SET logged = logged + ' FAILED VALIDATION', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
		THROW 50003, @colectoare, 1;
		END;
	--===============================VALIDATION=======================================================
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('find cod_film', GETDATE(), 1);
	DECLARE @cod_film INT = -1;
	SELECT @cod_film = F.cod_film FROM Filme F WHERE F.titlu = @titlu;
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('started-commited transaction rollback', GETDATE(), 2);
	BEGIN TRAN
	-- ANYTHING THAT BLOWS UP IN HERE, WILL BE UNDONE.
	-- IF THERE IS ANY ERROR IN THE EXECUTION, THE TRANSACTION WILL BE ABORTED.
	BEGIN TRY
		INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen, 21);', GETDATE(), 1);
		INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen, 21);
		UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

		INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen + "2", 18);', GETDATE(), 1);
		INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen + '2', 18);
		UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

		INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('find cod_gen', GETDATE(), 1);
		DECLARE @cod_gen INT = -1;
		SELECT @cod_gen = G.cod_gen FROM Genuri G WHERE G.tip = @gen;
		UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

		INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('find cod_gen2', GETDATE(), 1);
		DECLARE @cod_gen2 INT = -1;
		SELECT @cod_gen2 = G.cod_gen FROM Genuri G WHERE G.tip = @gen + '2';
		UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

		INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen, 2020)', GETDATE(), 1);
		INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen, 2020)
		UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

		INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen2, 2020)', GETDATE(), 1);
		INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen2, 2020)
		UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
	END TRY
	BEGIN CATCH
		--UPDATE Logger SET logged = logged + 'ABORTED', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 2;
		ROLLBACK TRAN;
	END CATCH

	COMMIT TRAN;
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 2;
END;

GO

SELECT * FROM Genuri;
DELETE FROM GENURI WHERE tip='';
DELETE FROM GENURI WHERE tip!='semaforu';
DELETE FROM GENURI WHERE varsta_minima IS NULL;
SELECT * FROM Critica;
DELETE FROM Critica;
DELETE FROM Critica WHERE
(SELECT COUNT(*) FROM Filme F INNER JOIN Critica C ON F.cod_film = C.cod_film 
INNER JOIN Genuri G ON G.cod_gen = C.cod_gen WHERE G.varsta_minima IS NULL) > 0;

GO




ALTER PROCEDURE usp_lab3_sgbd_checkpoint (@titlu VARCHAR(100), @gen VARCHAR(50))
AS
BEGIN
	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('validation checkpoint', GETDATE(), 1);
	--===============================VALIDATION=======================================================
	DECLARE @colectoare VARCHAR(1000) = '';

	IF (LEN(@titlu) = 0)--void
		SET @colectoare = @colectoare + 'TITLUL NU TREBUIE SA GOL'+CHAR(13)+CHAR(10)

	IF (LEN(@gen) = 0)--void
		SET @colectoare = @colectoare + 'GENUL NU TREBUIE SA GOL'
	ELSE
		IF (@gen LIKE '%[^a-zA-Z0-9 \-]%')--non alpha-numeric
			SET @colectoare = @colectoare + 'GENUL POATE AVEA DOAR LITERE, CIFRE, SPATII SI CRATIMA'

	IF ( LEN(@colectoare) > 0 )
		BEGIN
		UPDATE Logger SET logged = logged + ' FAILED VALIDATION', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
		THROW 50003,@colectoare,1
		END;
	--===============================VALIDATION=======================================================
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('find cod_film', GETDATE(), 1);
	DECLARE @cod_film INT = -1;
	SELECT @cod_film = F.cod_film FROM Filme F WHERE F.titlu = @titlu;
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
	

	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('started-commited transaction checkpoint', GETDATE(), 2);
	BEGIN TRAN
	
	BEGIN TRY
		INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen, 21);', GETDATE(), 1);
		INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen, 21);
		UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		UPDATE Logger SET logged = logged + ' ABORT', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
	END CATCH

	SAVE TRAN savepoint1;
	INSERT INTO Logger (logged, StartAt, EndAt, isTemp) VALUES ('saved transaction checkpoint - savepoint1', GETDATE(), GETDATE(), 0);

	BEGIN TRY
	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen + "2", 18);', GETDATE(), 1);
	INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen + '2', 18);
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
	END TRY
	BEGIN CATCH
		--UPDATE Logger SET logged = logged + ' ABORT', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
		--UPDATE Logger SET logged = logged + ' ROLLBACK TO savepoint1', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 2;
		ROLLBACK TRAN savepoint1;
	END CATCH

	SAVE TRAN savepoint2;
	INSERT INTO Logger (logged, StartAt, EndAt, isTemp) VALUES ('saved transaction checkpoint - savepoint1', GETDATE(), GETDATE(), 0);
	-- FROM THIS POINT, THERE COULD APPEAR FOREIGN KEY CONFLICTS.
	-- THEREFORE, WHAT HAS BEEN DONE TILL NOW, WILL NOT BE ROLLED BACK.

	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('find cod_gen', GETDATE(), 1);
	DECLARE @cod_gen INT = -1;
	SELECT @cod_gen = G.cod_gen FROM Genuri G WHERE G.tip = @gen;
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('find cod_gen2', GETDATE(), 1);
	DECLARE @cod_gen2 INT = -1;
	SELECT @cod_gen2 = G.cod_gen FROM Genuri G WHERE G.tip = @gen + '2';
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;

	BEGIN TRY
	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen, 2020);', GETDATE(), 1);
	INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen, 2020);
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
	END TRY
	BEGIN CATCH
		--UPDATE Logger SET logged = logged + ' ABORT', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
		--UPDATE Logger SET logged = logged + ' ROLLBACK TO savepoint2', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 2;
		ROLLBACK TRAN savepoint2;
	END CATCH

	SAVE TRAN savepoint3
	INSERT INTO Logger (logged, StartAt, EndAt, isTemp) VALUES ('saved transaction checkpoint - savepoint1', GETDATE(), GETDATE(), 0);

	BEGIN TRY
	INSERT INTO Logger (logged, StartAt, isTemp) VALUES ('INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen2, 2020);', GETDATE(), 1);
	INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen2, 2020);
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
	END TRY
	BEGIN CATCH
		--UPDATE Logger SET logged = logged + ' ABORT', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 1;
		--UPDATE Logger SET logged = logged + ' ROLLBACK TO savepoint3', EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 2;
		ROLLBACK TRAN savepoint3;
	END CATCH

	COMMIT TRAN;
	UPDATE Logger SET EndAt=GETDATE(), isTemp = 0 WHERE isTemp = 2;
END;








DELETE FROM Logger;




