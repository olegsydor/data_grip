USE Blaze7_dev;

if DATENAME(WEEKDAY, getdate()) = N'Saturday'
    begin
        declare @current_date int = Convert(CHAR(8), GETDATE(), 112)

        delete
        from dbo.TOrder_EDW
        where date_id = @current_date;

        delete
        from dbo.TOrder_EDW
        where date_id = @current_date;

        delete
        from dbo.TOrderMisc1_EDW
        where date_id = @current_date;

        delete
        from dbo.TLegs_EDW
        where date_id = @current_date;

        delete
        from dbo.TReports_EDW
        where date_id = @current_date;

        delete
        from TPrices_EDW
        where date_id = @current_date;
    end;