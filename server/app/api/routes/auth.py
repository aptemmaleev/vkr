import asyncio
import traceback
import hashlib
import secrets

from typing import Annotated
from datetime import datetime, timedelta
from uvicorn import Config, Server
from starlette.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

from fastapi import Depends, FastAPI, HTTPException, status, Request, APIRouter
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel

from app.settings import SETTINGS
from app.utils.security import verify_password, hash_password
from app.objects.user import User
from app.objects.session import Session
from app.api.schemas import RegisterData

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
router = APIRouter()

async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]) -> User:
    session: Session = await Session.get_by_token(token)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user: User = await User.get_by_id(session.user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    if session.expires_at < datetime.now():
        raise HTTPException(status_code=401, detail="Session expired")
    session.updated_at = datetime.now()
    session.expires_at = datetime.now() + timedelta(days=3)
    await session.save()
    return user

@router.post("/token")
async def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()], request: Request):
    user: User = await User.get_by_email(form_data.username)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect username or password")
    if not verify_password(form_data.password, user.password):
        raise HTTPException(status_code=400, detail="Incorrect username or password")
    session: Session = Session(
        user_id=user._id,
        ip=request.client.host,
        token=secrets.token_urlsafe(32),
        created_at=datetime.now(),
        expires_at=datetime.now() + timedelta(days=1),
    )
    await session.save()
    return {"access_token": session.token, "token_type": "bearer"}

@router.get("/users/me")
async def read_users_me(
    current_user: Annotated[User, Depends(get_current_user)]
):
    return JSONResponse(status_code=200, content=current_user.to_json())

@router.get("/users/me/update")
async def read_users_me(
    current_user: Annotated[User, Depends(get_current_user)],
    password: str = None,
    name: str = None,
    surname: str = None
):
    if (password != None): current_user.password = hash_password(password)
    if (name != None): current_user.name = name
    if (surname != None): current_user.surname = surname
    await current_user.save()
    return JSONResponse(status_code=200, content={"message": "User updated"})

@router.post("/register")
async def register(data: RegisterData):    
    if (await User.get_by_email(data.email)) is not None:
        return JSONResponse(status_code=200, content={"error": "Пользователь с таким адресом электронной почты уже существует"})
    print(data)
    user = User(
        name=data.name,
        surname=data.surname,
        email=data.email,
        password=hash_password(data.password),
        created_at=datetime.now(),
        updated_at=datetime.now()
    )
    print(user.to_json())
    await user.save()
    return JSONResponse(status_code=200, content={"message": "User created"})

