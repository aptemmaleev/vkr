import hashlib
import secrets

def hash_password(password: str, salt: str = None):
    if not salt: salt = secrets.token_urlsafe(8)
    password = hashlib.sha512(password.encode('utf-8')).hexdigest()
    password = hashlib.sha256(salt.encode('utf-8') + password.encode('utf-8')).hexdigest()
    return f"${salt}${password}"

def verify_password(password: str, hashed_password: str):
    salt, hash = hashed_password[1:].split('$')
    return hashed_password == hash_password(password, salt)

def generate_token() -> str:
    return secrets.token_urlsafe(128)