from pydantic import SecretStr
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGODB_URL: SecretStr
    MONGODB_DB: SecretStr
    LOGGING_LEVEL: str
    API_PORT: int
    API_HOST: str
    
SETTINGS = Settings(_env_file=".env", _env_file_encoding="utf-8")