from flask import Flask, render_template, request, redirect, url_for, flash
import mysql.connector

app = Flask(__name__)
app.secret_key = 'your_secret_key'

db_config = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'tmdcarryu29082005',
    'database': 'hotel',
    'port': 3306
}

def get_available_rooms():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    cursor.execute("""
    SELECT r.roomid, t.typename, r.price
    FROM rooms r
    JOIN roomtypes t ON r.typeid = t.typeid
    WHERE r.status = 'available'
    """)
    rooms = cursor.fetchall()
    cursor.close()
    conn.close()
    return rooms

@app.route('/')
def index():
    rooms = get_available_rooms()
    return render_template('index.html', rooms=rooms)

@app.route('/booking', methods=['GET', 'POST'])
def booking():
    rooms = get_available_rooms()
    if request.method == 'POST':
        name = request.form['name']
        age = request.form['age']
        email = request.form['email']
        phonenumber = request.form['phonenumber']
        address = request.form['address']
        roomid = request.form['roomid']
        checkin = request.form['checkin']
        checkout = request.form['checkout']

        # Lấy thông tin phòng đã chọn
        selected_room = next((room for room in rooms if str(room['roomid']) == roomid), None)
        room_name = selected_room['typename'] if selected_room else 'N/A'
        total_cost = selected_room['price'] if selected_room else 0

        # Lưu vào bảng guests
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO guests (guestname, phonenumber, address, age, email) VALUES (%s, %s, %s, %s, %s)",
            (name, phonenumber, address, age, email)
        )
        guestid = cursor.lastrowid

        # Lưu vào bảng bookings
        cursor.execute(
            "INSERT INTO bookings (guestid, roomid, checkindate, checkoutdate) VALUES (%s, %s, %s, %s)",
            (guestid, roomid, checkin, checkout)
        )
        conn.commit()
        cursor.close()
        conn.close()

        return render_template('invoice.html',
                               name=name,
                               age=age,
                               email=email,
                               phonenumber=phonenumber,
                               address=address,
                               room=room_name,
                               checkin=checkin,
                               checkout=checkout,
                               total_cost=total_cost)
    return render_template('booking.html', rooms=rooms)




@app.route('/confirm', methods=['POST'])
def confirm():
    # Redirect to thank you page after invoice confirmation
    return redirect(url_for('thankyou'))

@app.route('/thankyou')
def thankyou():
    return render_template('thankyou.html')

@app.route('/about')
def about():
    return render_template('about.html')

@app.route('/contact')
def contact():
    return render_template('contact.html')

@app.route('/room')
def room():
    rooms = get_available_rooms()
    return render_template('room.html', rooms=rooms)

@app.route('/service')
def service():
    return render_template('service.html')

@app.route('/team')
def team():
    return render_template('team.html')

@app.route('/testimonial')
def testimonial():
    return render_template('testimonial.html')
@app.route('/report')
def report():
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)

    # 1. Tỷ lệ sử dụng phòng
    cursor.execute("""
        SELECT 
            CONCAT(ROUND(
                (SELECT COUNT(*) FROM bookings 
                 WHERE checkindate <= CURDATE() AND checkoutdate >= CURDATE())
                /
                (SELECT COUNT(*) FROM rooms) * 100, 2), '%'
            ) AS occupancy_rate
    """)
    occupancy = cursor.fetchone()

    # 2. Doanh thu theo tháng
    cursor.execute("""
        SELECT DATE_FORMAT(paymentdate, '%Y-%m') AS month, SUM(totalamount) AS total
        FROM invoices
        GROUP BY month
        ORDER BY month
    """)
    revenue = cursor.fetchall()

    # 3. Lịch sử khách hàng
    cursor.execute("""
        SELECT g.guestname, COUNT(b.bookingid) AS times_visited,
               MIN(b.checkindate) AS first_visit,
               MAX(b.checkoutdate) AS last_visit,
               SUM(i.totalamount) AS total_spent
        FROM guests g
        JOIN bookings b ON g.guestid = b.guestid
        LEFT JOIN invoices i ON i.guestid = g.guestid
        GROUP BY g.guestid
    """)
    guests = cursor.fetchall()

    cursor.close()
    conn.close()

    return render_template('report.html', occupancy=occupancy, revenue=revenue, guests=guests)


if __name__ == '__main__':
    app.run(debug=True)
