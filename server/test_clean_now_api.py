"""End-to-end tests for the CleanNow REST workflow."""

from http.server import ThreadingHTTPServer
import json
import os
import tempfile
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from server import clean_now_api as api


class QuietHandler(api.Handler):
    def log_message(self, format, *args):
        pass


class CleanNowApiWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp_directory = tempfile.TemporaryDirectory(
            ignore_cleanup_errors=True,
        )
        api.DB_PATH = os.path.join(cls.temp_directory.name, "workflow.db")
        api.TURSO_DATABASE_URL = ""
        api.TURSO_AUTH_TOKEN = ""
        api.TOKEN_SECRET = "clean-now-test-secret"
        api.initialize()

        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), QuietHandler)
        cls.server.daemon_threads = True
        cls.server_thread = threading.Thread(
            target=cls.server.serve_forever,
            daemon=True,
        )
        cls.server_thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.server.server_port}/api"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.server_thread.join(timeout=5)
        cls.temp_directory.cleanup()

    def request(self, method, path, data=None, token=None):
        body = None if data is None else json.dumps(data).encode("utf-8")
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        request = Request(
            f"{self.base_url}{path}",
            data=body,
            headers=headers,
            method=method,
        )
        try:
            with urlopen(request, timeout=5) as response:
                payload = json.loads(response.read() or b"{}")
                return response.status, payload
        except HTTPError as error:
            try:
                payload = json.loads(error.read() or b"{}")
                return error.code, payload
            finally:
                error.close()

    def test_complete_customer_admin_cleaner_review_workflow(self):
        status, customer_auth = self.request(
            "POST",
            "/auth/register-customer",
            {
                "full_name": "Workflow Customer",
                "email": "workflow.customer@example.com",
                "phone": "+855 12 345 678",
                "password": "customer123",
            },
        )
        self.assertEqual(status, 201)
        customer = customer_auth["user"]
        customer_token = customer_auth["token"]

        status, admin_auth = self.request(
            "POST",
            "/auth/login",
            {"email": "admin@cleannow.demo", "password": "demo123"},
        )
        self.assertEqual(status, 200)
        admin_token = admin_auth["token"]

        status, application = self.request(
            "POST",
            "/admin/cleaners",
            {
                "full_name": "Workflow Cleaner",
                "email": "workflow.cleaner@example.com",
                "phone": "+855 98 765 432",
                "password": "cleaner123",
                "gender": "Prefer not to say",
                "address": "Phnom Penh",
                "work_experience": "Two years",
                "skills": "Home and office cleaning",
                "available_days": "Monday-Saturday",
                "available_time": "08:00-17:00",
            },
            admin_token,
        )
        self.assertEqual(status, 201)
        cleaner_id = application["user_id"]

        status, cleaner_auth = self.request(
            "POST",
            "/auth/login",
            {
                "email": "workflow.cleaner@example.com",
                "password": "cleaner123",
            },
        )
        self.assertEqual(status, 200)
        cleaner_token = cleaner_auth["token"]

        selected_extras = ["Inside fridge cleaning", "Window cleaning"]
        status, booking = self.request(
            "POST",
            "/bookings",
            {
                "user_id": customer["id"],
                "service_id": 2,
                "service_name": "Deep Cleaning",
                "customer_name": customer["full_name"],
                "phone": customer["phone"],
                "address": "123 Workflow Street, Phnom Penh",
                "property_type": "Apartment",
                "rooms": 3,
                "bathrooms": 2,
                "booking_date": "2027-01-15",
                "booking_time": "09:00 AM",
                "extra_services": selected_extras,
                "special_instruction": "Please call on arrival.",
                "payment_method": "Cash",
                "base_price": 50,
                "extra_price": 20,
                "total_price": 70,
                "estimated_duration": 305,
                "status": "Pending",
                "service_image": "https://example.com/deep-cleaning.jpg",
                "before_photos": [],
                "after_photos": [],
                "completion_notes": "",
            },
            customer_token,
        )
        self.assertEqual(status, 201)
        booking_id = booking["id"]
        self.assertEqual(json.loads(booking["extra_services"]), selected_extras)

        status, booking = self.request(
            "PATCH",
            f"/bookings/{booking_id}/status",
            {"status": "Accepted"},
            admin_token,
        )
        self.assertEqual((status, booking["status"]), (200, "Accepted"))

        status, booking = self.request(
            "PATCH",
            f"/bookings/{booking_id}/assign",
            {
                "cleaner_id": cleaner_id,
                "cleaner_name": "Workflow Cleaner",
                "cleaner_pay": 35,
            },
            admin_token,
        )
        self.assertEqual((status, booking["status"]), (200, "Cleaner Assigned"))

        for next_status in ("On the Way", "Arrived", "In Progress", "Completed"):
            status, booking = self.request(
                "PATCH",
                f"/bookings/{booking_id}/status",
                {"status": next_status},
                cleaner_token,
            )
            self.assertEqual((status, booking["status"]), (200, next_status))

        status, review = self.request(
            "POST",
            "/reviews",
            {
                "booking_id": booking_id,
                "service_id": 2,
                "user_id": customer["id"],
                "rating": 5,
                "comment": "Excellent service.",
            },
            customer_token,
        )
        self.assertEqual(status, 200)
        self.assertEqual(review["rating"], 5)

        status, saved_review = self.request(
            "GET",
            f"/reviews/booking/{booking_id}",
            token=customer_token,
        )
        self.assertEqual(status, 200)
        self.assertEqual(saved_review["comment"], "Excellent service.")

        status, notifications = self.request(
            "GET",
            f"/notifications?user_id={customer['id']}",
            token=customer_token,
        )
        self.assertEqual(status, 200)
        self.assertGreaterEqual(len(notifications), 1)

        status, second_customer_auth = self.request(
            "POST",
            "/auth/register-customer",
            {
                "full_name": "Other Customer",
                "email": "other.customer@example.com",
                "phone": "+855 10 000 001",
                "password": "customer123",
            },
        )
        self.assertEqual(status, 201)
        status, error = self.request(
            "GET",
            f"/notifications?user_id={customer['id']}",
            token=second_customer_auth["token"],
        )
        self.assertEqual(status, 403)
        self.assertEqual(error["error"], "Forbidden")


if __name__ == "__main__":
    unittest.main()
