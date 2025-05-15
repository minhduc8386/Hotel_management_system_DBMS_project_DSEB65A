### Hotel Management System ###

import mysql.connector
from datetime import datetime

def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="tmdcarryu29082005",
        database="hotel"
    )

# ----------- Operational Modules -----------

def register_guest(guest_id, name, phone, address):
    conn = get_connection()
    cursor = conn.cursor()
    query = "INSERT INTO Guests (GuestID, GuestName, PhoneNumber, Address) VALUES (%s, %s, %s, %s)"
    cursor.execute(query, (guest_id, name, phone, address))
    conn.commit()
    conn.close()
    print("Guest registered successfully.")

def book_room(booking_id, guest_id, room_id, checkin_date, checkout_date):
    conn = get_connection()
    cursor = conn.cursor()
    # Check room availability
    cursor.execute("SELECT Status FROM Rooms WHERE RoomID = %s", (room_id,))
    status = cursor.fetchone()
    if not status or status[0] != 'Available':
        print("Room is not available.")
        return
    # Book the room
    query = "INSERT INTO Bookings (BookingID, GuestID, RoomID, CheckInDate, CheckOutDate) VALUES (%s, %s, %s, %s, %s)"
    cursor.execute(query, (booking_id, guest_id, room_id, checkin_date, checkout_date))
    # Update room status
    cursor.execute("UPDATE Rooms SET Status = 'Booked' WHERE RoomID = %s", (room_id,))
    conn.commit()
    conn.close()
    print("Room booked successfully.")

def check_out(room_id):
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("UPDATE Rooms SET Status = 'Available' WHERE RoomID = %s", (room_id,))
    conn.commit()
    conn.close()
    print("Checked out successfully.")

def generate_invoice(invoice_id, guest_id, amount):
    conn = get_connection()
    cursor = conn.cursor()
    today = datetime.today().strftime('%Y-%m-%d')
    query = "INSERT INTO Invoices (InvoiceID, GuestID, TotalAmount, PaymentDate) VALUES (%s, %s, %s, %s)"
    cursor.execute(query, (invoice_id, guest_id, amount, today))
    conn.commit()
    conn.close()
    print("Invoice generated successfully.")

# ----------- Report Modules -----------

def report_room_availability():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Rooms WHERE Status = 'Available'")
    rooms = cursor.fetchall()
    for room in rooms:
        print(room)
    conn.close()

def report_revenue():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT SUM(TotalAmount) FROM Invoices")
    total = cursor.fetchone()[0]
    print("Total Revenue:", total)
    conn.close()

def report_service_usage():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT GuestID, COUNT(*) FROM ServiceUsage GROUP BY GuestID")
    usage = cursor.fetchall()
    for row in usage:
        print("Guest:", row[0], "- Services Used:", row[1])
    conn.close()

# ----------- CLI Interface -----------

def main():
    while True:
        print("\n1. Register Guest")
        print("2. Book Room")
        print("3. Check Out")
        print("4. Generate Invoice")
        print("5. Report: Room Availability")
        print("6. Report: Revenue")
        print("7. Report: Service Usage")
        print("8. Exit")

        choice = input("Enter choice: ")

        if choice == '1':
            register_guest(input("Guest ID: "), input("Name: "), input("Phone: "), input("Address: "))
        elif choice == '2':
            book_room(input("Booking ID: "), input("Guest ID: "), input("Room ID: "), input("Check-in Date (YYYY-MM-DD): "), input("Check-out Date (YYYY-MM-DD): "))
        elif choice == '3':
            check_out(input("Room ID: "))
        elif choice == '4':
            generate_invoice(input("Invoice ID: "), input("Guest ID: "), float(input("Total Amount: ")))
        elif choice == '5':
            report_room_availability()
        elif choice == '6':
            report_revenue()
        elif choice == '7':
            report_service_usage()
        elif choice == '8':
            break
        else:
            print("Invalid choice")

if __name__ == "__main__":
    main()



