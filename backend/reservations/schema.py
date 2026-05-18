from drf_spectacular.extensions import OpenApiAuthenticationExtension


class SupabaseAuthenticationScheme(OpenApiAuthenticationExtension):
    target_class = "reservations.authentication.SupabaseAuthentication"
    name = "SupabaseBearer"

    def get_security_definition(self, auto_schema):
        return {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": (
                "Supabase access token. Obtain via Supabase Auth (frontend) "
                "or POST /api/login/."
            ),
        }
