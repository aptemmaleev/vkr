import asyncio
import traceback
import hashlib
import secrets

from bson import ObjectId
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
from app.api.routes.auth import get_current_user

from app.objects import *
from app.utils.mongo import MongoDB

router = APIRouter()

@router.get("/my", tags=["Events"], name="Get my events")
async def get_my_events(
    current_user: Annotated[User, Depends(get_current_user)],
    read: bool = None,
    limit: int = 20,
    skip: int = 0
) -> JSONResponse:
    ''' Get my events '''
    result = await Event.get_user_events(
        user_id=current_user._id,
        read=read,
        limit=limit,
        skip=skip
    )
    return JSONResponse([n.to_json() for n in result], status_code=200)

@router.get("/mark", tags=["Events"], name="Get all events")
async def mark_events(
    current_user: Annotated[User, Depends(get_current_user)],
    event_id: str,
    read: bool = True
) -> JSONResponse:
    ''' Mark events as read '''
    event = await Event.get_by_id(ObjectId(event_id))
    if event is None:
        return JSONResponse(content={"error": "Notification not found"}, status_code=404)
    if event.user_id != current_user._id:
        return JSONResponse(content={"error": "Permission denied"}, status_code=403)
    event.readed = read
    await event.save()
    return JSONResponse(event.to_json(), status_code=200)

@router.get("/add", tags=["Events"], name="Add event")
async def add_event(
    current_user: Annotated[User, Depends(get_current_user)],
    type: str,
    title: str,
    details: str,
    house_id: str
) -> JSONResponse:
    ''' Add event 
    type: ["notification", "news", "system"]
    '''
    house = await House.get_by_id(house_id)
    if house is None:
        return JSONResponse({"error": "House not found"}, status_code=404)
    if current_user._id not in house.managers and current_user.role != "admin":
        return JSONResponse({"error": "You are not manager of this house"}, status_code=403)
    if type not in ["notification", "news", "system"]:
        return JSONResponse({"error": "Invalid event type"}, status_code=400)
    apartments = await Apartment.get_list(house_id=ObjectId(house_id))
    if len(apartments) == 0:
        return JSONResponse({"error": "House has no apartments"}, status_code=400)
    users = set()
    for apartment in apartments:
        for resident_id in apartment.residents:
            user = await User.get_by_id(resident_id)
            if user is not None:
                users.add(user._id)
    if len(users) == 0:
        return JSONResponse({"error": "No users found"}, status_code=400)
    for user_id in users:
        event = Event(
            user_id=user_id,
            type=type,
            title=title,
            details=details,
            house_id=house_id,
            manager_id=current_user._id
        )
        await event.save()
    return JSONResponse({"message": f"Event added to {len(users)} users"}, status_code=200)