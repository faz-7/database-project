-- question 1
SELECT *
FROM rooms as r
WHERE r.RoomID NOT IN (
    SELECT res.RoomID
    FROM reservations res
);

-- *************************** --


-- question 2

-- حالت مداوم
SELECT 
    res.RoomID,
    res.HotelID,
    SUM(DATEDIFF(DAY, res.CheckInDate, res.CheckOutDate)) AS TotalConsecutiveDays
FROM 
    reservations res
JOIN 
    reservations next_res ON res.RoomID = next_res.RoomID AND res.HotelID = next_res.HotelID
WHERE 
    res.Status = 'Confirmed'
    AND DATEDIFF(DAY, next_res.CheckInDate, res.CheckOutDate) = 0  
GROUP BY 
    res.RoomID, res.HotelID;

-- حالت پیوسته
SELECT 
    r.RoomID,
    r.HotelID,
    SUM(DATEDIFF(DAY, res.CheckInDate, res.CheckOutDate)) AS TotalReservationDays
FROM 
    rooms r
JOIN 
    reservations res ON r.RoomID = res.RoomID AND r.HotelID = res.HotelID
WHERE 
    res.Status = 'Confirmed'
GROUP BY 
    r.RoomID, r.HotelID;

-- *************************** --


-- question 3
SELECT GuestID, AVG(DATEDIFF(DAY, CheckInDate, CheckOutDate)) AS AvgStayDays
FROM reservations
GROUP BY GuestID;

SELECT GuestID, HotelID, AVG(DATEDIFF(DAY, CheckInDate, CheckOutDate)) AS AvgStayDays
FROM reservations
GROUP BY GuestID, HotelID;

-- *************************** --


-- quesrtion 4
SELECT 
    r.RoomID,
    r.RoomNumber,
    r.RoomType,
    r.Price,
    h.HotelName,
    h.Location
FROM 
    rooms r
JOIN 
    hotels h ON r.HotelID = h.HotelID
WHERE 
    r.Price = (
        SELECT 
            MAX(r2.Price)
        FROM 
            rooms r2
        WHERE 
            r2.HotelID = r.HotelID
    )
ORDER BY 
    r.HotelID, r.Price DESC;

-- *************************** --


-- question 5
SELECT COUNT(*)
FROM booked_services
WHERE TotalPrice > (SELECT AVG(Price) FROM services);

SELECT COUNT(*)
FROM services
WHERE Price > (SELECT AVG(TotalPrice) FROM booked_services);

-- *************************** --


-- qusetion 6
WITH GuestPayments AS (
    SELECT 
        g.GuestID,
        g.FirstName,
        g.LastName,
        h.HotelID,
        h.HotelName,
        SUM(p.Amount) AS TotalPaid
    FROM 
        guests g
    JOIN 
        reservations r ON g.GuestID = r.GuestID
    JOIN 
        payments p ON r.ReservationID = p.ReservationID
    JOIN 
        hotels h ON r.HotelID = h.HotelID
    WHERE 
        h.HotelName = 'Hartman-Green'
    GROUP BY 
        g.GuestID, g.FirstName, g.LastName, h.HotelID, h.HotelName
)
SELECT 
    GuestID,
    FirstName,
    LastName,
    HotelName,
    TotalPaid
FROM 
    GuestPayments
WHERE 
    TotalPaid = (SELECT MAX(TotalPaid) FROM GuestPayments);

-- *************************** --


-- question 7
SELECT r.RoomID, h.HotelName, COUNT(res.ReservationID) AS NumberOfReservations
FROM rooms r
JOIN hotels h ON r.HotelID = h.HotelID
JOIN reservations res ON r.RoomID = res.RoomID AND r.HotelID = res.HotelID
GROUP BY r.RoomID, h.HotelName, r.HotelID
ORDER BY NumberOfReservations DESC;

-- *************************** --


-- question 8
SELECT 
    bs.BookedServiceID,
    s.ServiceName,
    bs.TotalPrice,
    h.HotelName
FROM 
    booked_services bs
JOIN 
    services s ON bs.ServiceID = s.ServiceID
JOIN 
    reservations r ON bs.ReservationID = r.ReservationID
JOIN 
    hotels h ON r.HotelID = h.HotelID
WHERE 
    h.HotelName = 'Cook PLC'
    AND bs.TotalPrice > (
        SELECT 
            AVG(bs2.TotalPrice)
        FROM 
            booked_services bs2
        JOIN 
            reservations r2 ON bs2.ReservationID = r2.ReservationID
        JOIN 
            hotels h2 ON r2.HotelID = h2.HotelID
        WHERE 
            h2.HotelName = 'Cook PLC'
    )
ORDER BY 
    bs.TotalPrice DESC;

-- *************************** --


-- question 9
SELECT 
    r.RoomID,
    h.HotelName,
    AVG(res.DurationDays) AS AvgStayDays
FROM 
    rooms r
JOIN 
    hotels h ON r.HotelID = h.HotelID
JOIN 
    (
        SELECT 
            RoomID,
            HotelID,
            DATEDIFF(DAY, CheckInDate, CheckOutDate) AS DurationDays
        FROM 
            reservations
    ) res ON r.RoomID = res.RoomID AND r.HotelID = res.HotelID
GROUP BY 
    r.RoomID, h.HotelID, h.HotelName
HAVING 
    AVG(res.DurationDays) > 
    (SELECT AVG(DATEDIFF(DAY, CheckInDate, CheckOutDate)) FROM reservations)
ORDER BY 
    AvgStayDays DESC;

-- *************************** --


-- question 10
SELECT 
    rv.ReviewID,
    g.GuestID,
    g.FirstName,
    g.LastName,
    rv.Comment,
    rv.Rating,
    rv.ReviewDate
FROM 
    guests g
JOIN 
    reservations r ON g.GuestID = r.GuestID
JOIN 
    reviews rv ON g.GuestID = rv.GuestID
WHERE 
    g.GuestID IN (
        SELECT 
            GuestID
        FROM 
            reservations
        GROUP BY 
            GuestID
        HAVING 
            COUNT(ReservationID) > 1
    )
ORDER BY 
    rv.ReviewDate DESC;

-- *************************** --


-- question 11
WITH MaxReservationDays AS (
    SELECT 
        HotelID,
        CheckInDate AS ReservationDate,
        COUNT(*) AS ReservationCount
    FROM 
        reservations
    WHERE 
        Status = 'Confirmed'
    GROUP BY 
        CheckInDate, HotelID
    HAVING 
        COUNT(*) = (
            SELECT MAX(Sub.ReservationCount)
            FROM (
                SELECT 
                    HotelID,
                    CheckInDate,
                    COUNT(*) AS ReservationCount
                FROM 
                    reservations
                WHERE 
                    Status = 'Confirmed'
                GROUP BY 
                    CheckInDate, HotelID
            ) AS Sub
            WHERE Sub.HotelID = reservations.HotelID
        )
),
PaymentTotals AS (
    SELECT 
        r.HotelID,
        p.PaymentDate,
        SUM(p.Amount) AS TotalPayment
    FROM 
        payments p
    JOIN 
        reservations r ON p.ReservationID = r.ReservationID
    GROUP BY 
        p.PaymentDate, r.HotelID
),
MaxPaymentDays AS (
    SELECT 
        pt.HotelID,
        pt.PaymentDate,
        pt.TotalPayment
    FROM 
        PaymentTotals pt
    WHERE 
        pt.TotalPayment = (
            SELECT 
                MAX(pt2.TotalPayment)
            FROM 
                PaymentTotals pt2
            WHERE 
                pt2.HotelID = pt.HotelID
        )
)

SELECT 
    r.HotelID,
    r.ReservationDate,
    r.ReservationCount,
    p.PaymentDate,
    p.TotalPayment
FROM 
    MaxReservationDays r
JOIN 
    MaxPaymentDays p
ON 
    r.HotelID = p.HotelID AND r.ReservationDate = p.PaymentDate;

-- *************************** --


-- question 12
WITH ServiceAvg AS (
    SELECT 
        AVG(s.Price) AS AvgPrice
    FROM 
        services s
    JOIN 
        booked_services bs ON s.ServiceID = bs.ServiceID
    JOIN 
        reservations r ON bs.ReservationID = r.ReservationID
    WHERE 
        r.HotelID = 4  
),
ServicesAboveAvg AS (
    SELECT 
        bs.ReservationID, 
        bs.ServiceID, 
        bs.Quantity
    FROM 
        booked_services bs
    JOIN 
        services s ON bs.ServiceID = s.ServiceID
    JOIN 
        reservations r ON bs.ReservationID = r.ReservationID
    CROSS JOIN 
        ServiceAvg sa
    WHERE 
        s.Price > sa.AvgPrice
        AND r.HotelID = 4
),
GuestServiceCount AS (
    SELECT 
        r.GuestID,
        COUNT(DISTINCT sa.ServiceID) AS ServiceCount
    FROM 
        ServicesAboveAvg sa
    JOIN 
        reservations r ON sa.ReservationID = r.ReservationID
    GROUP BY 
        r.GuestID
)
SELECT 
    g.GuestID,
    g.FirstName,
    g.LastName,
    g.Email,
    g.Phone,
    gsc.ServiceCount
FROM 
    GuestServiceCount gsc
JOIN 
    guests g ON gsc.GuestID = g.GuestID
WHERE 
    gsc.ServiceCount = (SELECT MAX(ServiceCount) FROM GuestServiceCount);

-- *************************** --


-- question 13
WITH ReservationTotals AS (
    SELECT 
        res.RoomID,
        res.HotelID,
        COUNT(res.ReservationID) AS ReservationCount,
        SUM(res.TotalAmount) AS TotalReservationRevenue
    FROM 
        reservations res
    WHERE 
        res.Status = 'Confirmed'
    GROUP BY 
        res.RoomID, res.HotelID
),
ServiceTotals AS (
    SELECT 
        r.RoomID,
        r.HotelID,
        SUM(bs.TotalPrice) AS TotalServiceRevenue
    FROM 
        rooms r
    JOIN 
        (SELECT DISTINCT ReservationID, RoomID, HotelID 
         FROM reservations 
         WHERE Status = 'Confirmed') res
        ON r.RoomID = res.RoomID AND r.HotelID = res.HotelID
    JOIN 
        booked_services bs ON res.ReservationID = bs.ReservationID
    GROUP BY 
        r.RoomID, r.HotelID
),
CombinedTotals AS (
    SELECT 
        rt.RoomID,
        rt.HotelID,
        rt.ReservationCount,
        rt.TotalReservationRevenue,
        COALESCE(st.TotalServiceRevenue, 0) AS TotalServiceRevenue
    FROM 
        ReservationTotals rt
    LEFT JOIN 
        ServiceTotals st
    ON 
        rt.RoomID = st.RoomID AND rt.HotelID = st.HotelID
)
SELECT 
    ct.RoomID,
    ct.HotelID,
    ct.ReservationCount,
    ct.TotalReservationRevenue,
    ct.TotalServiceRevenue
FROM 
    CombinedTotals ct
WHERE 
    ct.ReservationCount = (
        SELECT MAX(ReservationCount)
        FROM ReservationTotals
    )
ORDER BY 
    ct.ReservationCount DESC, ct.TotalReservationRevenue DESC;

-- *************************** --


-- question 14
SELECT 
    r.HotelID,
    h.HotelName,
    r.GuestID,
    g.FirstName,
    g.LastName,
    AVG(DATEDIFF(DAY, r.CheckInDate, r.CheckOutDate)) AS AvgStayDays,
    AVG(bs.TotalPrice) AS AvgServiceCost
FROM 
    reservations r
LEFT JOIN guests g ON r.GuestID = g.GuestID
LEFT JOIN hotels h ON r.HotelID = h.HotelID
LEFT JOIN booked_services bs ON r.ReservationID = bs.ReservationID
GROUP BY 
    r.HotelID, h.HotelName, r.GuestID, g.FirstName, g.LastName
ORDER BY 
    r.HotelID, r.GuestID;

-- *************************** --


-- question 15
WITH PaymentTotals AS (
    SELECT 
        r.HotelID,
        p.PaymentDate,
        SUM(p.Amount) AS TotalPayment
    FROM 
        payments p
    JOIN 
        reservations r ON p.ReservationID = r.ReservationID
    GROUP BY 
        p.PaymentDate, r.HotelID
),
MaxPayments AS (
    SELECT 
        HotelID,
        PaymentDate,
        TotalPayment
    FROM 
        PaymentTotals
    WHERE 
        TotalPayment = (
            SELECT MAX(TotalPayment)
            FROM PaymentTotals pt
            WHERE pt.HotelID = PaymentTotals.HotelID
        )
),
ReservationTotals AS (
    SELECT 
        HotelID,
        CheckInDate AS ReservationDate,
        COUNT(ReservationID) AS ReservationCount
    FROM 
        reservations
    WHERE 
        Status = 'Confirmed'
    GROUP BY 
        HotelID, CheckInDate
),
MaxReservations AS (
    SELECT 
        HotelID,
        ReservationDate,
        ReservationCount
    FROM 
        ReservationTotals
    WHERE 
        ReservationCount = (
            SELECT MAX(ReservationCount)
            FROM ReservationTotals rt
            WHERE rt.HotelID = ReservationTotals.HotelID
        )
),
PositiveReviewTotals AS (
    SELECT 
        HotelID,
        ReviewDate,
        COUNT(ReviewID) AS PositiveReviewCount
    FROM 
        reviews
    WHERE 
        Rating IN (4, 5)
    GROUP BY 
        HotelID, ReviewDate
),
MaxPositiveReviews AS (
    SELECT 
        HotelID,
        ReviewDate,
        PositiveReviewCount
    FROM 
        PositiveReviewTotals
    WHERE 
        PositiveReviewCount = (
            SELECT MAX(PositiveReviewCount)
            FROM PositiveReviewTotals prt
            WHERE prt.HotelID = PositiveReviewTotals.HotelID
        )
)

SELECT 
    mp.HotelID,
    mp.PaymentDate AS TargetDate,
    mp.TotalPayment,
    mr.ReservationCount,
    mpr.PositiveReviewCount
FROM 
    MaxPayments mp
JOIN 
    MaxReservations mr ON mp.HotelID = mr.HotelID AND mp.PaymentDate = mr.ReservationDate
JOIN 
    MaxPositiveReviews mpr ON mp.HotelID = mpr.HotelID AND mp.PaymentDate = mpr.ReviewDate;

-- *************************** --


-- question 16
SELECT 
    g.GuestID,
    g.FirstName,
    g.LastName,
    COUNT(bs.BookedServiceID) AS ServiceCount
FROM 
    guests g
JOIN 
    reservations r ON g.GuestID = r.GuestID
JOIN 
    booked_services bs ON r.ReservationID = bs.ReservationID
JOIN 
    reviews rev ON g.GuestID = rev.GuestID
WHERE 
    rev.Rating IN (4, 5)  
GROUP BY 
    g.GuestID, g.FirstName, g.LastName
HAVING 
    COUNT(bs.BookedServiceID) >= 3  

-- *************************** --


-- question 17
WITH CashPayments AS (
    SELECT 
        r.HotelID, 
        p.PaymentDate, 
        COUNT(p.PaymentID) AS CashPaymentCount
    FROM 
        payments p
    JOIN 
        reservations r ON p.ReservationID = r.ReservationID
    WHERE 
        p.PaymentMethod = 'Cash'
    GROUP BY 
        p.PaymentDate, r.HotelID
),
MaxCashPayments AS (
    SELECT 
        HotelID, 
        MAX(CashPaymentCount) AS MaxPayments
    FROM 
        CashPayments
    GROUP BY 
        HotelID
)
SELECT 
    cp.HotelID, 
    cp.PaymentDate, 
    cp.CashPaymentCount
FROM 
    CashPayments cp
JOIN 
    MaxCashPayments mcp ON cp.HotelID = mcp.HotelID
WHERE 
    cp.CashPaymentCount = mcp.MaxPayments;

-- *************************** --


-- question 18
WITH NegativeReviews AS (
    SELECT 
        r.GuestID,
        COUNT(*) AS NegativeReviewCount
    FROM 
        reviews r
    WHERE 
        r.Rating IN (1, 2)  
    GROUP BY 
        r.GuestID
),
MaxNegativeReviews AS (
    SELECT 
        MAX(NegativeReviewCount) AS MaxNegativeReviewCount
    FROM 
        NegativeReviews
),
TopNegativeGuests AS (
    SELECT 
        nr.GuestID
    FROM 
        NegativeReviews nr
    CROSS JOIN 
        MaxNegativeReviews mnr
    WHERE 
        nr.NegativeReviewCount = mnr.MaxNegativeReviewCount
)
SELECT 
    s.ServiceID,
    s.ServiceName,
    COUNT(bs.BookedServiceID) AS ServiceUsageCount
FROM 
    TopNegativeGuests tng
JOIN 
    reservations r ON tng.GuestID = r.GuestID
JOIN 
    booked_services bs ON r.ReservationID = bs.ReservationID
JOIN 
    services s ON bs.ServiceID = s.ServiceID
GROUP BY 
    s.ServiceID, s.ServiceName
ORDER BY 
    ServiceUsageCount DESC;

-- *************************** --



-- سوالات امتیازی --

-- question 1
WITH RoomReservations AS (
    SELECT 
        r.HotelID,
        r.RoomID,
        COUNT(res.ReservationID) AS ReservationCount
    FROM 
        rooms r
    JOIN 
        reservations res ON r.RoomID = res.RoomID AND r.HotelID = res.HotelID
    GROUP BY 
        r.RoomID, r.HotelID
),
RoomReviews AS (
    SELECT 
        r.HotelID,
        r.RoomID,
        AVG(rv.rating) AS AverageRating
    FROM 
        rooms r
    JOIN 
        reviews rv ON r.HotelID = rv.HotelID
    GROUP BY 
        r.RoomID, r.HotelID
),
CombinedData AS (
    SELECT 
        rr.HotelID,
        rr.RoomID,
        rr.ReservationCount,
        rv.AverageRating
    FROM 
        RoomReservations rr
    JOIN 
        RoomReviews rv ON rr.HotelID = rv.HotelID AND rr.RoomID = rv.RoomID
)
SELECT 
    h.HotelName,
    cd.RoomID,
    cd.ReservationCount,
    cd.AverageRating
FROM 
    hotels h
JOIN 
    CombinedData cd ON h.HotelID = cd.HotelID
WHERE 
    cd.ReservationCount = (
        SELECT MAX(ReservationCount)
        FROM CombinedData
        WHERE HotelID = cd.HotelID
    )
    AND 
    cd.AverageRating = (
        SELECT MAX(AverageRating)
        FROM CombinedData
        WHERE HotelID = cd.HotelID
    );



-- question 2
SELECT 
    h.HotelName AS HotelName,
    r.RoomType AS RoomType,
    COUNT(bs.BookedServiceID) AS TotalServicesUsed,
    AVG(s.Price) AS AvgServiceCost
FROM 
    hotels h
JOIN rooms r ON h.HotelID = r.HotelID
JOIN reservations res ON res.RoomID = r.RoomID AND res.HotelID = r.HotelID
JOIN booked_services bs ON bs.ReservationID = res.ReservationID
JOIN services s ON bs.ServiceID = s.ServiceID
GROUP BY 
    h.HotelName, r.RoomType
ORDER BY 
    h.HotelName, r.RoomType;



-- question 3
WITH PositiveReviews AS (
    SELECT 
        HotelID,
        GuestID,
        COUNT(*) AS PositiveCount
    FROM 
        Reviews
    WHERE 
        Rating IN (4, 5) 
    GROUP BY 
        HotelID, GuestID
),
MaxReviewsPerHotel AS (
    SELECT 
        HotelID,
        MAX(PositiveCount) AS MaxPositiveCount
    FROM 
        PositiveReviews
    GROUP BY 
        HotelID
)
SELECT 
    PR.HotelID,
    PR.GuestID,
    PR.PositiveCount
FROM 
    PositiveReviews PR
JOIN 
    MaxReviewsPerHotel MR
ON 
    PR.HotelID = MR.HotelID AND PR.PositiveCount = MR.MaxPositiveCount;



-- question 4
WITH PaymentStats AS (
    SELECT 
        h.HotelID,
        h.HotelName,
        p.PaymentDate,
        SUM(p.Amount) AS TotalPayments
    FROM 
        hotels h
    JOIN 
        reservations r ON h.HotelID = r.HotelID
    JOIN 
        payments p ON r.ReservationID = p.ReservationID
    GROUP BY 
        h.HotelID, h.HotelName, p.PaymentDate
),
ReservationStats AS (
    SELECT 
        h.HotelID,
        r.CheckInDate AS ReservationDate,
        COUNT(r.ReservationID) AS TotalReservations
    FROM 
        hotels h
    JOIN 
        reservations r ON h.HotelID = r.HotelID
    GROUP BY 
        h.HotelID, r.CheckInDate
),
ServiceStats AS (
    SELECT 
        h.HotelID,
        r.CheckInDate AS ServiceDate,
        COUNT(bs.BookedServiceID) AS TotalServices
    FROM 
        hotels h
    JOIN 
        reservations r ON h.HotelID = r.HotelID
    JOIN 
        booked_services bs ON r.ReservationID = bs.ReservationID
    GROUP BY 
        h.HotelID, r.CheckInDate
),
CombinedStats AS (
    SELECT 
        p.HotelID,
        p.HotelName,
        p.PaymentDate AS EventDate,
        p.TotalPayments,
        rs.TotalReservations,
        ss.TotalServices
    FROM 
        PaymentStats p
    JOIN 
        ReservationStats rs ON p.HotelID = rs.HotelID AND p.PaymentDate = rs.ReservationDate
    JOIN 
        ServiceStats ss ON p.HotelID = ss.HotelID AND p.PaymentDate = ss.ServiceDate
)
SELECT 
    HotelName,
    EventDate,
    TotalPayments,
    TotalReservations,
    TotalServices
FROM 
    CombinedStats
WHERE 
    TotalPayments = (SELECT MAX(TotalPayments) FROM CombinedStats WHERE HotelID = CombinedStats.HotelID)
    AND 
    TotalReservations = (SELECT MAX(TotalReservations) FROM CombinedStats WHERE HotelID = CombinedStats.HotelID)
    AND 
    TotalServices = (SELECT MAX(TotalServices) FROM CombinedStats WHERE HotelID = CombinedStats.HotelID);



