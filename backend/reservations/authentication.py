from dataclasses import dataclass

from rest_framework import authentication, exceptions, status

from supabase_client import SupabaseConfigurationError, get_supabase_client


class AuthenticationServiceUnavailable(exceptions.APIException):
    status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    default_detail = "Supabase authentication is not configured."
    default_code = "authentication_unavailable"


@dataclass(frozen=True)
class SupabaseUser:
    id: str
    email: str | None = None
    is_staff: bool = False
    raw: object | None = None

    @property
    def is_authenticated(self):
        return True

    @property
    def is_active(self):
        return True

    @property
    def is_superuser(self):
        return self.is_staff

    @property
    def pk(self):
        return self.id


class SupabaseAuthentication(authentication.BaseAuthentication):
    keyword = "Bearer"

    def authenticate(self, request):
        auth = authentication.get_authorization_header(request).split()

        if not auth:
            return None

        if auth[0].lower() != self.keyword.lower().encode():
            return None

        if len(auth) != 2:
            raise exceptions.AuthenticationFailed("Invalid Authorization header.")

        try:
            token = auth[1].decode("utf-8")
        except UnicodeError as exc:
            raise exceptions.AuthenticationFailed(
                "Invalid Authorization header."
            ) from exc

        supabase_user = self._get_supabase_user(token)
        user_id = self._get_value(supabase_user, "id")

        if not user_id:
            raise exceptions.AuthenticationFailed("Invalid Supabase user.")

        user = SupabaseUser(
            id=str(user_id),
            email=self._get_value(supabase_user, "email"),
            is_staff=self._is_admin(supabase_user),
            raw=supabase_user,
        )
        return user, token

    def authenticate_header(self, request):
        return self.keyword

    def _get_supabase_user(self, token):
        try:
            result = get_supabase_client().auth.get_user(token)
        except SupabaseConfigurationError as exc:
            raise AuthenticationServiceUnavailable(str(exc)) from exc
        except Exception as exc:
            raise exceptions.AuthenticationFailed(
                "Invalid Supabase access token."
            ) from exc

        user = self._get_value(result, "user")
        if not user:
            raise exceptions.AuthenticationFailed("Invalid Supabase access token.")
        return user

    @staticmethod
    def _get_value(source, key):
        if isinstance(source, dict):
            return source.get(key)
        return getattr(source, key, None)

    @classmethod
    def _is_admin(cls, supabase_user):
        app_metadata = cls._get_value(supabase_user, "app_metadata") or {}
        role = (
            app_metadata.get("role")
            if isinstance(app_metadata, dict)
            else cls._get_value(app_metadata, "role")
        )
        return role == "admin"
