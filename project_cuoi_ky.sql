create database projectck;
use projectck;

-- bảng users
create table users (
    userid int primary key auto_increment,
    username varchar(50) unique,
    passwordhash varchar(255),
    role enum('receptionist', 'manager', 'accountant'),
    fullname varchar(100)
);

-- bảng guests
create table guests (
    guestid int primary key auto_increment,
    guestname varchar(100),
    phonenumber varchar(15),
    address varchar(255)
);

-- bảng roomtypes
create table roomtypes (
    typeid int primary key auto_increment,
    typename varchar(50),
    description text,
    baseprice decimal(10,2)
);

-- bảng rooms
create table rooms (
    roomid int primary key auto_increment,
    typeid int,
    status varchar(20),
    price decimal(10,2),
    foreign key (typeid) references roomtypes(typeid)
);

-- bảng services
create table services (
    serviceid int primary key auto_increment,
    servicename enum('rooms service', 'breakfast', 'spa', 'sports & gaming', 'event & party', 'gym & yoga'),
    description text,
    price decimal(10,2)
);

-- bảng bookings
create table bookings (
    bookingid int primary key auto_increment,
    guestid int,
    roomid int,
    checkindate date,
    checkoutdate date,
    foreign key (guestid) references guests(guestid),
    foreign key (roomid) references rooms(roomid)
);

-- bảng bookingservice
create table bookingservice (
    bookingid int,
    serviceid int,
    quantity int default 1,
    primary key (bookingid, serviceid),
    foreign key (bookingid) references bookings(bookingid),
    foreign key (serviceid) references services(serviceid)
);

-- bảng invoices
create table invoices (
    invoiceid int primary key auto_increment,
    guestid int,
    totalamount decimal(10,2),
    paymentdate date,
    foreign key (guestid) references guests(guestid)
);

-- bảng payments
create table payments (
    paymentid int primary key auto_increment,
    invoiceid int,
    amountpaid decimal(10,2),
    paymentdate date,
    paymentmethod varchar(50),
    foreign key (invoiceid) references invoices(invoiceid)
);

-- dữ liệu mẫu cho users
insert into users (username, passwordhash, role, fullname) values
('admin', '12345', 'manager', 'admin user'),
('reception1', 'abcdef', 'receptionist', 'receptionist one'),
('account1', 'password', 'accountant', 'accountant one');

-- dữ liệu mẫu cho guests
insert into guests (guestname, phonenumber, address) values
('nguyen van a', '0912345678', 'hanoi'),
('tran thi b', '0987654321', 'da nang'),
('le van c', '0977777777', 'ho chi minh'),
('pham thi d', '0912341234', 'hue'),
('do van e', '0973123456', 'can tho');

-- dữ liệu mẫu cho roomtypes
insert into roomtypes (typename, description, baseprice) values
('single', 'single room', 500000),
('double', 'double bed room', 1000000),
('suite', 'luxury suite', 1500000);

-- dữ liệu mẫu cho rooms
insert into rooms (typeid, status, price) values
(1, 'available', 500000),
(2, 'occupied', 1000000),
(3, 'maintenance', 1500000);

-- dữ liệu mẫu cho services
insert into services (servicename, description, price) values
('rooms service', 'in-room dining', 100000),
('breakfast', 'buffet breakfast', 80000),
('spa', 'relaxing massage', 300000),
('sports & gaming', 'entertaining with various sports and games', 100000),
('event & party', 'participating in exciting events and parties', 150000),
('gym & yoga', 'training and exercising in the gym', 50000);

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






