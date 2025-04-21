CREATE TABLE hotels (
HotelID int primary key,
HotelName varchar(50),
Location varchar(50),
Rating int,
Phone varchar(50),
Email varchar(100)
)


CREATE TABLE rooms(
RoomID int,
RoomNumber varchar(50),
RoomType varchar(50),
Price decimal,
Status varchar(50),
HotelID int,
primary key (RoomID, HotelID),
foreign key (HotelID) references hotels
)



CREATE TABLE guests(
GuestID int primary key,
FirstName varchar(50),
LastName varchar(50),
Phone varchar(50),
Email varchar(100)
)



CREATE TABLE reservations(
ReservationID int primary key,
CheckInDate date,
CheckOutDate date,
TotalAmount decimal,
Status varchar(50),
RoomID int,
GuestID int,
HotelID int,
foreign key (RoomID, HotelID) references rooms(RoomID,HotelID),
foreign key (GuestID) references guests
)

CREATE TABLE reviews(
ReviewID int primary key,
Rating int,
Comment varchar(500),
ReviewDate date,
HotelID int,
GuestID int,
foreign key (HotelID) references hotels,
foreign key (GuestID) references guests
)

CREATE TABLE services(
ServiceID int primary key,
ServiceName varchar(50),
Price decimal
)

CREATE TABLE booked_services(
BookedServiceID int primary key,
Quantity int,
TotalPrice decimal,
ReservationID int,
ServiceID int,
foreign key (ReservationID) references reservations,
foreign key (ServiceID) references services
)

CREATE TABLE payments(
PaymentID int primary key,
PaymentDate date,
Amount decimal,
PaymentMethod varchar(50),
ReservationID int,
foreign key (ReservationID) references reservations
)

UPDATE reservations
SET 
    CheckInDate = CheckOutDate,
    CheckOutDate = CheckInDate
WHERE 
    CheckOutDate < CheckInDate;