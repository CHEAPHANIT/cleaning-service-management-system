"""CleanNow REST API backed by SQLite. Uses only Python's standard library."""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
import sqlite3
import hashlib
import secrets
import uuid
from urllib.request import urlopen
from datetime import datetime, timezone
from urllib.parse import parse_qs, urlparse

ROOT = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.getenv("CLEAN_NOW_DB", os.path.join(ROOT, "cleannow_server.db"))
HOST = os.getenv("CLEAN_NOW_HOST", "0.0.0.0")
PORT = int(os.getenv("CLEAN_NOW_PORT", "8080"))
OPENAPI_PATH = os.path.join(ROOT, "openapi.json")

SWAGGER_UI = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CleanNow API documentation</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    window.onload = () => SwaggerUIBundle({
      url: '/openapi.json',
      dom_id: '#swagger-ui',
      deepLinking: true,
      displayRequestDuration: true,
      persistAuthorization: true,
      tryItOutEnabled: true
    });
  </script>
</body>
</html>
"""


def now():
    return datetime.now(timezone.utc).isoformat()


def connect():
    db = sqlite3.connect(DB_PATH, timeout=10)
    db.row_factory = sqlite3.Row
    db.execute("PRAGMA journal_mode=WAL")
    db.execute("PRAGMA foreign_keys=ON")
    return db


def initialize():
    with connect() as db:
        db.executescript("""
        CREATE TABLE IF NOT EXISTS users(
          id INTEGER PRIMARY KEY AUTOINCREMENT, firebase_uid TEXT UNIQUE NOT NULL,
          full_name TEXT NOT NULL, email TEXT NOT NULL, phone TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'customer', address TEXT NOT NULL DEFAULT '',
          hourly_rate REAL NOT NULL DEFAULT 8, is_active INTEGER NOT NULL DEFAULT 1,
          availability_status TEXT NOT NULL DEFAULT 'Available',
          created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS bookings(
          id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL,
          service_id INTEGER NOT NULL, service_name TEXT NOT NULL,
          customer_name TEXT NOT NULL, phone TEXT NOT NULL, address TEXT NOT NULL,
          property_type TEXT NOT NULL, rooms INTEGER NOT NULL, bathrooms INTEGER NOT NULL,
          booking_date TEXT NOT NULL, booking_time TEXT NOT NULL,
          extra_services TEXT NOT NULL DEFAULT '[]', special_instruction TEXT NOT NULL DEFAULT '',
          payment_method TEXT NOT NULL, base_price REAL NOT NULL, extra_price REAL NOT NULL,
          total_price REAL NOT NULL, estimated_duration INTEGER NOT NULL,
          cleaner_id INTEGER, cleaner_name TEXT NOT NULL DEFAULT '', cleaner_pay REAL NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'Pending', service_image TEXT NOT NULL DEFAULT '',
          before_photos TEXT NOT NULL DEFAULT '[]', after_photos TEXT NOT NULL DEFAULT '[]',
          completion_notes TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL,
          title TEXT NOT NULL, message TEXT NOT NULL, is_read INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS services(
          id INTEGER PRIMARY KEY, name TEXT NOT NULL, category TEXT NOT NULL,
          description TEXT NOT NULL, base_price REAL NOT NULL,
          duration_minutes INTEGER NOT NULL, image_url TEXT NOT NULL,
          rating REAL NOT NULL DEFAULT 0, cleaners_required INTEGER NOT NULL DEFAULT 1,
          is_active INTEGER NOT NULL DEFAULT 1
        );
        CREATE TABLE IF NOT EXISTS favorites(
          id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL,
          service_id INTEGER NOT NULL, service_name TEXT NOT NULL,
          service_image TEXT NOT NULL, service_price REAL NOT NULL,
          created_at TEXT NOT NULL, UNIQUE(user_id, service_id)
        );
        CREATE TABLE IF NOT EXISTS reviews(
          id INTEGER PRIMARY KEY AUTOINCREMENT, booking_id INTEGER UNIQUE NOT NULL,
          service_id INTEGER NOT NULL, user_id INTEGER NOT NULL,
          rating INTEGER NOT NULL, comment TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS products(
          id INTEGER PRIMARY KEY AUTOINCREMENT, api_id INTEGER UNIQUE NOT NULL,
          title TEXT NOT NULL, description TEXT NOT NULL, price REAL NOT NULL,
          image_url TEXT NOT NULL, category TEXT NOT NULL, created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS addresses(
          id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL,
          title TEXT NOT NULL, address TEXT NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL
        );
        """)
        columns = {row["name"] for row in db.execute("PRAGMA table_info(users)")}
        if "password_hash" not in columns:
            db.execute("ALTER TABLE users ADD COLUMN password_hash TEXT NOT NULL DEFAULT ''")
        if "availability_status" not in columns:
            db.execute("ALTER TABLE users ADD COLUMN availability_status TEXT NOT NULL DEFAULT 'Available'")
            db.execute("UPDATE users SET availability_status='Off Duty' WHERE is_active=0")
        seeds = [
            ("demo-admin", "Admin Demo", "admin@cleannow.demo", "+855 123 456 789", "admin", 8),
            ("demo-cleaner", "Cleaner Demo", "cleaner@cleannow.demo", "+855 987 654 321", "cleaner", 9),
            ("demo-cleaner-sokha", "Sokha Chan", "sokha@cleannow.demo", "+855 111 222 333", "cleaner", 10),
        ]
        stamp = now()
        db.executemany("""
          INSERT INTO users(firebase_uid, full_name, email, phone, role, hourly_rate, created_at, updated_at, password_hash)
          VALUES(?,?,?,?,?,?,?,?,?) ON CONFLICT(firebase_uid) DO NOTHING
        """, [(*seed, stamp, stamp, hash_password("demo123")) for seed in seeds])
        for uid, *_ in seeds:
            db.execute(
                "UPDATE users SET password_hash=? WHERE firebase_uid=? AND password_hash=''",
                (hash_password("demo123"), uid),
            )
        services = [
            (1,"Basic Home Cleaning","Home Cleaning","Trusted cleaners refresh your living areas, kitchen, bathroom, floors, and surfaces.",25,120,"https://images.unsplash.com/photo-1581578731548-c64695cc6952",4.5,1,1),
            (2,"Deep Cleaning","Deep Cleaning","Detailed top-to-bottom cleaning for high-touch surfaces, stains, and hard-to-reach spaces.",50,240,"https://images.unsplash.com/photo-1527515637462-cff31c812dba",4.8,2,1),
            (3,"Office Cleaning","Office Cleaning","Workplace cleaning for desks, meeting rooms, shared areas, floors, and restrooms.",40,180,"https://images.unsplash.com/photo-1497366811353-6870744d04b2",4.6,2,1),
            (4,"Move-in Cleaning","Move-in Cleaning","Prepare a new home with cabinet wipe-downs, floor care, bathroom cleaning, and kitchen reset.",60,300,"https://images.unsplash.com/photo-1585421514738-01798e348b17",4.7,2,1),
            (5,"Sofa Cleaning","Sofa Cleaning","Fabric-safe sofa cleaning, surface treatment, vacuuming, and deodorizing.",20,90,"https://images.unsplash.com/photo-1555041469-a586c61ea9bc",4.4,1,1),
            (6,"Carpet Cleaning","Carpet Cleaning","Carpet refresh with vacuuming, stain focus, shampoo, and drying guidance.",30,120,"https://images.unsplash.com/photo-1556228453-efd6c1ff04f6",4.5,1,1),
        ]
        db.executemany("INSERT INTO services VALUES(?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO NOTHING", services)


def hash_password(password, salt=None):
    salt = salt or secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt.encode(), 120000).hex()
    return f"{salt}${digest}"


def verify_password(password, stored):
    if not stored or "$" not in stored:
        return False
    salt, _ = stored.split("$", 1)
    return secrets.compare_digest(hash_password(password, salt), stored)


def row_dict(row):
    return dict(row) if row else None


def user_dict(row):
    data = row_dict(row)
    if data:
        data.pop("password_hash", None)
    return data


def notify(db, user_id, title, message):
    db.execute(
        "INSERT INTO notifications(user_id,title,message,is_read,created_at) VALUES(?,?,?,?,?)",
        (user_id, title, message, 0, now()),
    )


def notify_admins(db, title, message):
    for row in db.execute("SELECT id FROM users WHERE role='admin' AND is_active=1"):
        notify(db, row["id"], title, message)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print("[CleanNow API]", fmt % args)

    def _cors(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,PATCH,DELETE,OPTIONS")

    def reply(self, status, body):
        data = json.dumps(body).encode("utf-8")
        self.reply_bytes(status, data, "application/json; charset=utf-8")

    def reply_bytes(self, status, data, content_type):
        self.send_response(status)
        self._cors()
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def body(self):
        size = int(self.headers.get("Content-Length", "0"))
        return json.loads(self.rfile.read(size) or b"{}")

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        if parsed.path in ("/docs", "/docs/", "/swagger", "/swagger/"):
            return self.reply_bytes(200, SWAGGER_UI.encode("utf-8"), "text/html; charset=utf-8")
        if parsed.path == "/openapi.json":
            try:
                with open(OPENAPI_PATH, "rb") as spec:
                    return self.reply_bytes(200, spec.read(), "application/json; charset=utf-8")
            except OSError:
                return self.reply(500, {"error": "OpenAPI specification is unavailable"})
        with connect() as db:
            if parsed.path == "/api/health":
                return self.reply(200, {"status": "ok", "database": DB_PATH})
            if parsed.path == "/api/users":
                rows = db.execute("SELECT * FROM users ORDER BY role, full_name").fetchall()
                return self.reply(200, [user_dict(row) for row in rows])
            if parsed.path == "/api/services":
                rows = db.execute("SELECT * FROM services ORDER BY id").fetchall()
                return self.reply(200, [row_dict(row) for row in rows])
            if parsed.path == "/api/bookings":
                sql, args = "SELECT * FROM bookings", []
                if "user_id" in query:
                    sql, args = sql + " WHERE user_id=?", [query["user_id"][0]]
                elif "cleaner_id" in query:
                    sql, args = sql + " WHERE cleaner_id=?", [query["cleaner_id"][0]]
                rows = db.execute(sql + " ORDER BY created_at DESC", args).fetchall()
                return self.reply(200, [row_dict(row) for row in rows])
            if parsed.path == "/api/notifications" and "user_id" in query:
                rows = db.execute(
                    "SELECT * FROM notifications WHERE user_id=? ORDER BY created_at DESC",
                    (query["user_id"][0],),
                ).fetchall()
                return self.reply(200, [row_dict(row) for row in rows])
            if parsed.path == "/api/favorites" and "user_id" in query:
                rows = db.execute(
                    "SELECT * FROM favorites WHERE user_id=? ORDER BY created_at DESC",
                    (query["user_id"][0],),
                ).fetchall()
                return self.reply(200, [row_dict(row) for row in rows])
            if parsed.path == "/api/addresses" and "user_id" in query:
                rows = db.execute(
                    "SELECT * FROM addresses WHERE user_id=? ORDER BY is_default DESC,id",
                    (query["user_id"][0],),
                ).fetchall()
                return self.reply(200, [row_dict(row) for row in rows])
            if parsed.path.startswith("/api/reviews/booking/"):
                try:
                    booking_id = int(parsed.path.rsplit("/", 1)[1])
                except ValueError:
                    return self.reply(400, {"error": "Invalid booking id"})
                row = db.execute("SELECT * FROM reviews WHERE booking_id=?", (booking_id,)).fetchone()
                return self.reply(200, row_dict(row)) if row else self.reply(404, {"error": "Review not found"})
            if parsed.path == "/api/products":
                rows = db.execute("SELECT * FROM products ORDER BY id").fetchall()
                if not rows:
                    try:
                        with urlopen("https://dummyjson.com/products?limit=30", timeout=5) as response:
                            products = json.load(response).get("products", [])
                        stamp = now()
                        db.executemany("""
                          INSERT INTO products(api_id,title,description,price,image_url,category,created_at)
                          VALUES(?,?,?,?,?,?,?) ON CONFLICT(api_id) DO UPDATE SET
                          title=excluded.title,description=excluded.description,price=excluded.price,
                          image_url=excluded.image_url,category=excluded.category
                        """, [(p["id"],p["title"],p.get("description",""),p["price"],p.get("thumbnail",""),p.get("category","Cleaning supplies"),stamp) for p in products])
                        rows = db.execute("SELECT * FROM products ORDER BY id").fetchall()
                    except Exception:
                        stamp = now()
                        fallback = [
                            (90001,"Microfiber Cleaning Cloths","Reusable lint-free cloth set",9.99,"https://images.unsplash.com/photo-1583947215259-38e31be8751f","cleaning-supplies",stamp),
                            (90002,"Multi-Surface Cleaner","Everyday cleaner for sealed surfaces",7.50,"https://images.unsplash.com/photo-1563453392212-326f5e854473","cleaning-supplies",stamp),
                            (90003,"Cleaning Brush Set","Detail brushes for kitchens and bathrooms",12.00,"https://images.unsplash.com/photo-1585421514738-01798e348b17","cleaning-supplies",stamp),
                        ]
                        db.executemany("INSERT INTO products(api_id,title,description,price,image_url,category,created_at) VALUES(?,?,?,?,?,?,?) ON CONFLICT(api_id) DO NOTHING", fallback)
                        rows = db.execute("SELECT * FROM products ORDER BY id").fetchall()
                return self.reply(200, [row_dict(row) for row in rows])
        self.reply(404, {"error": "Not found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        data = self.body()
        with connect() as db:
            if parsed.path == "/api/auth/register":
                email = data.get("email", "").strip().lower()
                if db.execute("SELECT id FROM users WHERE lower(email)=?", (email,)).fetchone():
                    return self.reply(409, {"error": "Email is already registered"})
                stamp = now()
                uid = f"api-{uuid.uuid4()}"
                cursor = db.execute("""
                  INSERT INTO users(firebase_uid,full_name,email,phone,role,address,hourly_rate,is_active,availability_status,created_at,updated_at,password_hash)
                  VALUES(?,?,?,?,?,?,?,?,?,?,?,?)
                """, (uid,data.get("full_name",""),email,data.get("phone",""),"customer","",8,1,"Available",stamp,stamp,hash_password(data.get("password",""))))
                row = db.execute("SELECT * FROM users WHERE id=?", (cursor.lastrowid,)).fetchone()
                return self.reply(201, user_dict(row))
            if parsed.path == "/api/auth/login":
                row = db.execute("SELECT * FROM users WHERE lower(email)=? AND is_active=1", (data.get("email","").strip().lower(),)).fetchone()
                if not row or not verify_password(data.get("password",""), row["password_hash"]):
                    return self.reply(401, {"error": "Invalid email or password"})
                return self.reply(200, user_dict(row))
            if parsed.path == "/api/auth/reset-password":
                exists = db.execute("SELECT id FROM users WHERE lower(email)=?", (data.get("email","").strip().lower(),)).fetchone()
                return self.reply(200, {"message": "Reset request accepted"}) if exists else self.reply(404, {"error": "Account not found"})
            if parsed.path == "/api/users/upsert":
                stamp = now()
                db.execute("""
                  INSERT INTO users(firebase_uid,full_name,email,phone,role,address,hourly_rate,is_active,availability_status,created_at,updated_at,password_hash)
                  VALUES(?,?,?,?,?,?,?,?,?,?,?,?)
                  ON CONFLICT(firebase_uid) DO UPDATE SET full_name=excluded.full_name,
                    email=excluded.email,phone=excluded.phone,role=excluded.role,address=excluded.address,
                    hourly_rate=excluded.hourly_rate,is_active=excluded.is_active,
                    availability_status=excluded.availability_status,updated_at=excluded.updated_at
                """, (
                    data["firebase_uid"], data.get("full_name", ""), data.get("email", ""),
                    data.get("phone", ""), data.get("role", "customer"), data.get("address", ""),
                    data.get("hourly_rate", 8), data.get("is_active", 1),
                    data.get("availability_status", "Available"), stamp, stamp,
                    hash_password(data.get("password", "demo123")),
                ))
                row = db.execute("SELECT * FROM users WHERE firebase_uid=?", (data["firebase_uid"],)).fetchone()
                return self.reply(200, user_dict(row))
            if parsed.path == "/api/services":
                service_id = int(data.get("id", 0))
                if service_id <= 0:
                    service_id = (db.execute("SELECT COALESCE(MAX(id),0)+1 next_id FROM services").fetchone()["next_id"])
                db.execute("""
                  INSERT INTO services(id,name,category,description,base_price,duration_minutes,image_url,rating,cleaners_required,is_active)
                  VALUES(?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET
                  name=excluded.name,category=excluded.category,description=excluded.description,
                  base_price=excluded.base_price,duration_minutes=excluded.duration_minutes,
                  image_url=excluded.image_url,rating=excluded.rating,
                  cleaners_required=excluded.cleaners_required,is_active=excluded.is_active
                """, (service_id,data["name"],data["category"],data["description"],data["base_price"],data["duration_minutes"],data["image_url"],data.get("rating",0),data.get("cleaners_required",1),data.get("is_active",1)))
                return self.reply(200, row_dict(db.execute("SELECT * FROM services WHERE id=?", (service_id,)).fetchone()))
            if parsed.path == "/api/favorites/toggle":
                existing = db.execute("SELECT id FROM favorites WHERE user_id=? AND service_id=?", (data["user_id"],data["service_id"])).fetchone()
                if existing:
                    db.execute("DELETE FROM favorites WHERE id=?", (existing["id"],))
                    return self.reply(200, {"favorite": False})
                db.execute("""INSERT INTO favorites(user_id,service_id,service_name,service_image,service_price,created_at) VALUES(?,?,?,?,?,?)""", (data["user_id"],data["service_id"],data["service_name"],data["service_image"],data["service_price"],now()))
                return self.reply(200, {"favorite": True})
            if parsed.path == "/api/addresses/replace":
                user_id = data["user_id"]
                db.execute("DELETE FROM addresses WHERE user_id=?", (user_id,))
                for item in data.get("addresses", []):
                    db.execute(
                        "INSERT INTO addresses(user_id,title,address,is_default,created_at) VALUES(?,?,?,?,?)",
                        (user_id,item.get("title",""),item.get("address",""),1 if item.get("is_default",item.get("isDefault",False)) else 0,now()),
                    )
                rows = db.execute("SELECT * FROM addresses WHERE user_id=? ORDER BY is_default DESC,id", (user_id,)).fetchall()
                return self.reply(200, [row_dict(row) for row in rows])
            if parsed.path == "/api/reviews":
                cursor = db.execute("""
                  INSERT INTO reviews(booking_id,service_id,user_id,rating,comment,created_at)
                  VALUES(?,?,?,?,?,?) ON CONFLICT(booking_id) DO UPDATE SET
                  rating=excluded.rating,comment=excluded.comment
                """, (data["booking_id"],data["service_id"],data["user_id"],data["rating"],data.get("comment",""),now()))
                row = db.execute("SELECT * FROM reviews WHERE booking_id=?", (data["booking_id"],)).fetchone()
                return self.reply(200, row_dict(row))
            if parsed.path == "/api/bookings":
                stamp = now()
                columns = [
                    "user_id","service_id","service_name","customer_name","phone","address",
                    "property_type","rooms","bathrooms","booking_date","booking_time","extra_services",
                    "special_instruction","payment_method","base_price","extra_price","total_price",
                    "estimated_duration","cleaner_id","cleaner_name","cleaner_pay","status","service_image",
                    "before_photos","after_photos","completion_notes","created_at","updated_at"
                ]
                values = []
                for column in columns[:-2]:
                    value = data.get(column)
                    if column in ("extra_services", "before_photos", "after_photos") and not isinstance(value, str):
                        value = json.dumps(value or [])
                    values.append(value)
                values += [stamp, stamp]
                cursor = db.execute(
                    f"INSERT INTO bookings({','.join(columns)}) VALUES({','.join('?' for _ in columns)})",
                    values,
                )
                booking_id = cursor.lastrowid
                notify(db, data["user_id"], "Booking created", f"{data['service_name']} is pending confirmation.")
                notify_admins(db, "New booking request", f"{data['customer_name']} booked {data['service_name']} for {data['booking_date']} at {data['booking_time']}.")
                row = db.execute("SELECT * FROM bookings WHERE id=?", (booking_id,)).fetchone()
                return self.reply(201, row_dict(row))
        self.reply(404, {"error": "Not found"})

    def do_PATCH(self):
        path = urlparse(self.path).path
        if path == "/api/notifications/read-all":
            data = self.body()
            with connect() as db:
                db.execute(
                    "UPDATE notifications SET is_read=1 WHERE user_id=?",
                    (data["user_id"],),
                )
            return self.reply(200, {"updated": True})
        parts = path.strip("/").split("/")
        if len(parts) != 4 or parts[0] != "api" or parts[1] != "bookings":
            return self.reply(404, {"error": "Not found"})
        try:
            booking_id = int(parts[2])
        except ValueError:
            return self.reply(400, {"error": "Invalid booking id"})
        action, data = parts[3], self.body()
        with connect() as db:
            booking = db.execute("SELECT * FROM bookings WHERE id=?", (booking_id,)).fetchone()
            if not booking:
                return self.reply(404, {"error": "Booking not found"})
            if action == "status":
                status = data["status"]
                allowed_transitions = {
                    "Pending": {"Accepted", "Cancelled", "Rejected"},
                    "Accepted": {"Cancelled", "Rejected"},
                    "Cleaner Assigned": {"On the Way", "Cancelled", "Rejected"},
                    "On the Way": {"Arrived", "Cancelled", "Rejected"},
                    "Arrived": {"In Progress", "Cancelled", "Rejected"},
                    "In Progress": {"Completed", "Cancelled", "Rejected"},
                }
                if status not in allowed_transitions.get(booking["status"], set()):
                    return self.reply(409, {
                        "error": f"Cannot change {booking['status']} to {status}"
                    })
                db.execute("UPDATE bookings SET status=?,updated_at=? WHERE id=?", (status, now(), booking_id))
                if booking["cleaner_id"] and status in ("Completed", "Cancelled", "Rejected"):
                    db.execute(
                        "UPDATE users SET is_active=1,availability_status='Available',updated_at=? WHERE id=?",
                        (now(), booking["cleaner_id"]),
                    )
                notify(db, booking["user_id"], "Booking status updated", f"{booking['service_name']} is now {status}.")
                notify_admins(db, "Booking status updated", f"{booking['service_name']} #{booking_id} is now {status}.")
            elif action == "documentation":
                db.execute("""UPDATE bookings SET before_photos=?,after_photos=?,completion_notes=?,updated_at=? WHERE id=?""", (
                    json.dumps(data.get("before_photos", [])), json.dumps(data.get("after_photos", [])),
                    data.get("completion_notes", ""), now(), booking_id,
                ))
            elif action == "assign":
                if booking["status"] != "Accepted" or booking["cleaner_id"] is not None:
                    return self.reply(409, {"error": "Only an unassigned accepted booking can be assigned"})
                cleaner = db.execute(
                    "SELECT is_active,availability_status FROM users WHERE id=? AND role='cleaner'",
                    (data["cleaner_id"],),
                ).fetchone()
                if not cleaner or not cleaner["is_active"] or cleaner["availability_status"] != "Available":
                    return self.reply(409, {"error": "Cleaner is not available"})
                active_job = db.execute("""
                  SELECT id FROM bookings
                  WHERE cleaner_id=? AND id<>?
                    AND status NOT IN ('Cancelled','Completed','Rejected')
                  LIMIT 1
                """, (data["cleaner_id"],booking_id)).fetchone()
                if active_job:
                    return self.reply(409, {"error": "Cleaner already has an active task"})
                db.execute("""UPDATE bookings SET cleaner_id=?,cleaner_name=?,cleaner_pay=?,status='Cleaner Assigned',updated_at=? WHERE id=?""", (
                    data["cleaner_id"], data["cleaner_name"], data.get("cleaner_pay", 0), now(), booking_id,
                ))
                db.execute(
                    "UPDATE users SET availability_status='Busy',updated_at=? WHERE id=?",
                    (now(), data["cleaner_id"]),
                )
                notify(db, data["cleaner_id"], "New job assigned", f"{booking['service_name']} for {booking['customer_name']} on {booking['booking_date']} at {booking['booking_time']}.")
                notify(db, booking["user_id"], "Cleaner assigned", f"{data['cleaner_name']} has been assigned to your booking.")
            else:
                return self.reply(404, {"error": "Unknown action"})
            updated = db.execute("SELECT * FROM bookings WHERE id=?", (booking_id,)).fetchone()
            return self.reply(200, row_dict(updated))

    def do_DELETE(self):
        parts = urlparse(self.path).path.strip("/").split("/")
        if len(parts) != 3 or parts[0] != "api":
            return self.reply(404, {"error": "Not found"})
        try:
            item_id = int(parts[2])
        except ValueError:
            return self.reply(400, {"error": "Invalid id"})
        with connect() as db:
            if parts[1] == "users":
                db.execute("UPDATE users SET is_active=0,updated_at=? WHERE id=?", (now(),item_id))
                return self.reply(200, {"deleted": True})
            if parts[1] == "services":
                db.execute("UPDATE services SET is_active=0 WHERE id=?", (item_id,))
                return self.reply(200, {"deleted": True})
        self.reply(404, {"error": "Not found"})


if __name__ == "__main__":
    initialize()
    print(f"CleanNow API listening on http://localhost:{PORT}/api")
    print(f"Swagger UI: http://localhost:{PORT}/docs")
    print(f"SQLite database: {DB_PATH}")
    ThreadingHTTPServer((HOST, PORT), Handler).serve_forever()
