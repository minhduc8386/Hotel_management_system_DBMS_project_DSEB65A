
create database hotel;
use hotel;
drop table if exists bookingservices, invoices, payments, services, bookings, rooms, roomtypes, guests, users;

create table users (
    userid int primary key auto_increment,
    username varchar(50) unique,
    passwordhash varchar(255),
    role enum('receptionist', 'manager', 'accountant'),
    fullname varchar(100)
);

create table guests (
    guestid int primary key auto_increment,
    guestname varchar(100),
    phonenumber varchar(15),
    address varchar(255)
);

create table roomtypes (
    typeid int primary key auto_increment,
    typename varchar(50),
    description text,
    baseprice decimal(10,2)
);

create table rooms (
    roomid int primary key auto_increment,
    typeid int,
    status varchar(20),
    price decimal(10,2),
    foreign key (typeid) references roomtypes(typeid)
);

create table bookings (
    bookingid int primary key auto_increment,
    guestid int,
    roomid int,
    checkindate date,
    checkoutdate date,
    foreign key (guestid) references guests(guestid),
    foreign key (roomid) references rooms(roomid)
);

create table services (
    serviceid int primary key auto_increment,
    servicename varchar(100),
    description text,
    price decimal(10,2)
);

create table invoices (
    invoiceid int primary key auto_increment,
    guestid int,
    totalamount decimal(10,2),
    paymentdate date,
    foreign key (guestid) references guests(guestid)
);

create table payments (
    paymentid int primary key auto_increment,
    invoiceid int,
    amountpaid decimal(10,2),
    paymentdate date,
    paymentmethod varchar(50),
    foreign key (invoiceid) references invoices(invoiceid)
);

create table bookingservices (
    bookingid int,
    serviceid int,
    quantity int default 1,
    primary key (bookingid, serviceid),
    foreign key (bookingid) references bookings(bookingid),
    foreign key (serviceid) references services(serviceid)
);

insert into users (username, passwordhash, role, fullname) values
('recept01', 'hashedpass1', 'receptionist', 'receptionist a'),
('manager01', 'hashedpass2', 'manager', 'manager b'),
('acct01', 'hashedpass3', 'accountant', 'accountant c');

insert into guests (guestname, phonenumber, address) values
('nguyen van a', '0912345678', 'hanoi'),
('tran thi b', '0987654321', 'da nang'),
('le van c', '0909123456', 'ho chi minh'),
('pham thi d', '0934567890', 'hue'),
('do van e', '0978123456', 'can tho');

insert into roomtypes (typename, description, baseprice) values
('single', 'single bed room', 500000),
('double', 'double bed room', 800000),
('suite', 'luxury suite', 1500000);

insert into rooms (typeid, status, price) values
(1, 'available', 500000),
(2, 'occupied', 800000),
(3, 'available', 1500000),
(1, 'maintenance', 450000),
(2, 'available', 850000);

insert into services (servicename, description, price) values
('laundry', 'wash and fold clothes', 50000),
('room service', 'in-room dining', 100000),
('spa', 'relaxing massage', 300000),
('breakfast', 'buffet breakfast', 80000),
('airport pickup', 'pick-up by hotel car', 200000);

insert into bookings (guestid, roomid, checkindate, checkoutdate) values
(1, 1, '2025-05-01', '2025-05-03'),
(2, 2, '2025-05-01', '2025-05-04'),
(3, 3, '2025-05-02', '2025-05-05'),
(4, 5, '2025-05-01', '2025-05-02'),
(5, 4, '2025-05-03', '2025-05-05');

insert into bookingservices (bookingid, serviceid, quantity) values
(1, 1, 2),
(1, 2, 1),
(2, 3, 1),
(3, 1, 1),
(3, 4, 2),
(4, 5, 1);

insert into invoices (guestid, totalamount, paymentdate) values
(1, 1100000, '2025-05-03'),
(2, 2400000, '2025-05-04'),
(3, 3100000, '2025-05-05'),
(4, 850000, '2025-05-02'),
(5, 900000, '2025-05-05');

insert into payments (invoiceid, amountpaid, paymentdate, paymentmethod) values
(1, 1100000, '2025-05-03', 'cash'),
(2, 2400000, '2025-05-04', 'credit card'),
(3, 3100000, '2025-05-05', 'vnpay'),
(4, 850000, '2025-05-02', 'cash'),
(5, 900000, '2025-05-05', 'credit card');

create index idx_rooms_status on rooms(status);
create index idx_bookings_guest on bookings(guestid);
create index idx_bookings_room on bookings(roomid);

create or replace view currentoccupancy as
select 
    r.roomid,
    rt.typename as roomtype,
    g.guestname,
    b.checkindate,
    b.checkoutdate
from rooms r
join roomtypes rt on r.typeid = rt.typeid
join bookings b on r.roomid = b.roomid
join guests g on b.guestid = g.guestid
where curdate() between b.checkindate and b.checkoutdate;

create or replace view guesthistory as
select 
    g.guestname,
    b.bookingid,
    r.roomid,
    rt.typename,
    b.checkindate,
    b.checkoutdate
from guests g
join bookings b on g.guestid = b.guestid
join rooms r on b.roomid = r.roomid
join roomtypes rt on r.typeid = rt.typeid;

drop procedure if exists checkinroom;

delimiter //
create procedure checkinroom(in booking_id int)
begin
    update rooms
    set status = 'occupied'
    where roomid = (
        select roomid from bookings where bookingid = booking_id
    );
end //
delimiter ;

drop function if exists calculateroomcost;
delimiter //
create function calculateroomcost(booking_id int)
returns decimal(10,2)
deterministic
begin
    declare cost decimal(10,2);
    select r.price * datediff(b.checkoutdate, b.checkindate)
    into cost
    from bookings b
    join rooms r on b.roomid = r.roomid
    where b.bookingid = booking_id;
    return cost;
end //
delimiter ;

delimiter //
create trigger trg_updateroomstatus_onbookingdelete
after delete on bookings
for each row
begin
    update rooms
    set status = 'available'
    where roomid = old.roomid;
end //
delimiter ;

alter table invoices
add column userid int,
add constraint fk_invoices_user
foreign key (userid) references users(userid);

create user 'receptionist'@'localhost' identified by 'reception123';
create user 'manager'@'localhost' identified by 'manager123';
create user 'accountant'@'localhost' identified by 'account123';

grant select, insert, update on hotel.guests to 'receptionist'@'localhost';
grant select, insert, update on hotel.bookings to 'receptionist'@'localhost';
grant select on hotel.rooms to 'receptionist'@'localhost';
grant select on hotel.services to 'receptionist'@'localhost';

grant all privileges on hotel.* to 'manager'@'localhost';

grant select, insert on hotel.invoices to 'accountant'@'localhost';
grant select, insert on hotel.payments to 'accountant'@'localhost';

flush privileges;
-- ví dụ khi thêm khách
insert into guests (guestname, phonenumber, address)
values ('vo thi x', aes_encrypt('0911222333', 'mykey'), 'bien hoa');

-- và truy vấn khi hiển thị
select guestname, convert(aes_decrypt(phonenumber, 'mykey') using utf8) as phone, address from guests;


