use movie

GO

--DROP TABLE Logger
CREATE TABLE Logger
(cod_log INT PRIMARY KEY IDENTITY, --identity face sa se puna automat numele
TypeOperation VARCHAR(50), -- Insert, Select, Update, Delete 
TableOperation VARCHAR(50),
ExecutionDate DATETIME
);
GO


ALTER FUNCTION uf_lab3_sgbd_validate_critique (@titlu VARCHAR(200), @gen VARCHAR(50)) RETURNS VARCHAR(1000)
AS
BEGIN
DECLARE @colectoare VARCHAR(1000) = '';

	IF (LEN(@titlu) = 0)--void
		SET @colectoare = @colectoare + 'TITLUL NU TREBUIE SA GOL'+CHAR(13)+CHAR(10);

	IF (LEN(@gen) = 0)--void
		SET @colectoare = @colectoare + 'TIPUL NU TREBUIE SA GOL';
	ELSE
		BEGIN
		IF (@gen LIKE '%[^a-zA-Z0-9 \-]%')--non alpha-numeric
			SET @colectoare = @colectoare + 'GENUL POATE AVEA DOAR LITERE, CIFRE, SPATII SI CRATIMA';
		ELSE
			BEGIN
				IF (@gen NOT IN ('Actiune','Drama','Sci-Fi','Documentar','Comedie'))
					SET @colectoare = @colectoare + 'GENUL TREBUIE SA FIE O VALOARE DIN LISTA DATA';
			END;
		END;

	RETURN @colectoare;
END;


GO

ALTER PROCEDURE usp_lab3_sgbd_rollback (@titlu VARCHAR(200), @gen VARCHAR(50))
AS
BEGIN
	SET XACT_ABORT ON
	
	--===============================VALIDATION=======================================================
	DECLARE @colectoare VARCHAR(1000) = '';
	SELECT @colectoare = dbo.uf_lab3_sgbd_validate_critique(@titlu, @gen);

	IF ( LEN(@colectoare) > 0 )
		THROW 50003, @colectoare, 1;
	--===============================VALIDATION=======================================================

	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('SELECT', 'Filme', GETDATE());
	DECLARE @cod_film INT = -1;
	SELECT @cod_film = F.cod_film FROM Filme F WHERE F.titlu = @titlu;

	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('BEGIN TRAN', 'Genuri, Critica', GETDATE());
	BEGIN TRAN
	-- ANYTHING THAT BLOWS UP IN HERE, WILL BE UNDONE.
	-- IF THERE IS ANY ERROR IN THE EXECUTION, THE TRANSACTION WILL BE ABORTED.
	BEGIN TRY
		INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('INSERT', 'Genuri', GETDATE());
		INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen, 21);

		INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('INSERT', 'Genuri', GETDATE());
		INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen + '2', 18);

		INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('SELECT', 'Genuri', GETDATE());
		DECLARE @cod_gen INT = -1;
		SELECT @cod_gen = G.cod_gen FROM Genuri G WHERE G.tip = @gen;

		INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('SELECT', 'Genuri', GETDATE());
		DECLARE @cod_gen2 INT = -1;
		SELECT @cod_gen2 = G.cod_gen FROM Genuri G WHERE G.tip = @gen + '2';

		INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('INSERT', 'Critica', GETDATE());
		INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen, 2020)

		INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('INSERT', 'Critica', GETDATE());
		INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen2, 2020)

		INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('Commit TRAN', 'Genuri, Critica', GETDATE());
		COMMIT TRAN;
		SELECT 'Transaction committed';
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
	END CATCH

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




ALTER PROCEDURE usp_lab3_sgbd_checkpoint (@titlu VARCHAR(200), @gen VARCHAR(50))
AS
BEGIN
	--===============================VALIDATION=======================================================
	DECLARE @colectoare VARCHAR(1000) = '';
	SELECT @colectoare = dbo.uf_lab3_sgbd_validate_critique(@titlu, @gen);

	IF ( LEN(@colectoare) > 0 )
		THROW 50003, @colectoare, 1;
	--===============================VALIDATION=======================================================

	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('SELECT', 'Filme', GETDATE());
	DECLARE @cod_film INT = -1;
	SELECT @cod_film = F.cod_film FROM Filme F WHERE F.titlu = @titlu; -- throws exception when inserted -1 FK instead of existing FK
	print(@cod_film)

	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('BEGIN TRAN', 'Genuri, Critica', GETDATE());
	BEGIN TRAN
	
	BEGIN TRY
		INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('INSERT', 'Genuri', GETDATE());
		INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen, 21);
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN;
		SELECT 'Transaction rollbacked'
	END CATCH

	SAVE TRAN savepoint1;
	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('CHECKPOINT', 'Genuri', GETDATE());

	BEGIN TRY
	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen + "2", 18);', GETDATE(), 1);
	INSERT INTO Genuri (tip, varsta_minima) VALUES (@gen + '2', 18);
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN savepoint1;
		SELECT 'Transaction rollbacked';
	END CATCH

	SAVE TRAN savepoint2;
	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('CHECKPOINT', 'Genuri', GETDATE());
	-- FROM THIS POINT, THERE COULD APPEAR FOREIGN KEY CONFLICTS.
	-- THEREFORE, WHAT HAS BEEN DONE TILL NOW, WILL NOT BE ROLLED BACK.

	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('SELECT', 'Genuri', GETDATE());
	DECLARE @cod_gen INT = -1;
	SELECT @cod_gen = G.cod_gen FROM Genuri G WHERE G.tip = @gen;

	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('SELECT', 'Genuri', GETDATE());
	DECLARE @cod_gen2 INT = -1;
	SELECT @cod_gen2 = G.cod_gen FROM Genuri G WHERE G.tip = @gen + '2';

	BEGIN TRY
	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('INSERT', 'Critica', GETDATE());
	INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen, 2020);
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN savepoint2;
		SELECT 'Transaction rollbacked';
	END CATCH

	SAVE TRAN savepoint3
	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('CHECKPOINT', 'Genuri', GETDATE());

	BEGIN TRY
	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('INSERT', 'Critica', GETDATE());
	INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (@cod_film, @cod_gen2, 2020);
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN savepoint3;
		SELECT 'Transaction rollbacked';
	END CATCH

	--this part has to be here, because, after rollback, the execution is not finished and the transaction will commit.
	INSERT INTO Logger (TypeOperation, TableOperation, ExecutionDate) VALUES ('Commit TRAN', 'Genuri, Critica', GETDATE());
	COMMIT TRAN;
	SELECT 'Transaction committed';

END;







SELECT * FROM Logger;
DELETE FROM Logger;

-- efect similar - fail validation
EXEC usp_lab3_sgbd_rollback '','asdfgdhjg';
EXEC usp_lab3_sgbd_checkpoint '','asdfgdhjg';


-- efect diferit - validation ok + fail insert (because there are no films named that way and fk remains -1)
EXEC usp_lab3_sgbd_rollback 'Ion','Drama';
EXEC usp_lab3_sgbd_checkpoint 'Interstellar','Sci-Fi';


-- this will commit successfully.
EXEC usp_lab3_sgbd_rollback 'INCREDIBLES','Actiune';
EXEC usp_lab3_sgbd_checkpoint 'INCREDIBLES','Actiune';


INSERT INTO Critica (cod_film,cod_gen,last_update) VALUES (-1, 131, 2020);