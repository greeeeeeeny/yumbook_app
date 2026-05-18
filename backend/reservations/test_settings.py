from django.conf import settings
from django.test import SimpleTestCase


class SettingsTests(SimpleTestCase):
    def test_required_apps_installed(self):
        for app in ("rest_framework", "corsheaders", "reservations"):
            self.assertIn(app, settings.INSTALLED_APPS)

    def test_cors_middleware_is_first(self):
        self.assertEqual(
            settings.MIDDLEWARE[0],
            "corsheaders.middleware.CorsMiddleware",
        )

    def test_supabase_is_default_authentication(self):
        
        self.assertEqual(
            settings.REST_FRAMEWORK["DEFAULT_AUTHENTICATION_CLASSES"],
            ["reservations.authentication.SupabaseAuthentication"],
        )

    def test_default_permission_requires_authentication(self):
        self.assertEqual(
            settings.REST_FRAMEWORK["DEFAULT_PERMISSION_CLASSES"],
            ["rest_framework.permissions.IsAuthenticated"],
        )

    def test_root_urlconf_points_to_project_urls(self):
        self.assertEqual(settings.ROOT_URLCONF, "yumbook_server.urls")

    def test_testserver_is_allowed_host(self):
        self.assertIn("testserver", settings.ALLOWED_HOSTS)

    def test_base_dir_contains_manage_py(self):
        self.assertTrue((settings.BASE_DIR / "manage.py").is_file())
