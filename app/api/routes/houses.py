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

@router.get("/get", tags=["Houses"], name="Get house")
async def get_house(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str
) -> JSONResponse:
    ''' Get house by id '''
    house = await House.get_by_id(ObjectId(house_id))
    if house is None:
        return JSONResponse({"error": "House not found"}, status_code=404)
    return JSONResponse(house.to_json(), status_code=200)

@router.get("/list", tags=["Houses"], name="Get houses ")
async def get_houses(
    current_user: Annotated[User, Depends(get_current_user)],
    address: str = None,
    manager: str = None,
    skip: int = 0,
    limit: int = 20
) -> JSONResponse:
    ''' Get houses list '''
    houses = await House.get_list(
        address=address,
        manager=manager,
        skip=skip,
        limit=limit
    )
    return JSONResponse([h.to_json() for h in houses], status_code=200)

@router.get("/add", tags=["Houses"], name="Add house")
async def add_house(
    current_user: Annotated[User, Depends(get_current_user)],
    address: str,
    info: str = "",
) -> JSONResponse:
    ''' Add house '''
    # Check user role
    if current_user.role != "admin":
        return JSONResponse({"error": "You are not admin"}, status_code=403)
    # Check if house exists
    house = await House.get_list(address=address)
    if len(house) > 0:
        return JSONResponse({"error": "House already exists"}, status_code=409)
    # Create house and return it
    house = House(
        address=address,
        info=info,
        managers=[]
    )
    await house.save()
    return JSONResponse(house.to_json(), status_code=200)

@router.get("/remove", tags=["Houses"], name="Remove house")
async def remove_house(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str 
) -> JSONResponse:
    ''' Remove house '''
    # Check user role
    if current_user.role != "admin":
        return JSONResponse({"error": "You are not admin"}, status_code=403)
    # Check if house exists
    house = await House.get_by_id(ObjectId(house_id))
    if house is None:
        return JSONResponse({"error": "House not found"}, status_code=404)
    # Remove house and return it
    await MongoDB.db.houses.delete_one({'_id': ObjectId(house_id)})
    return JSONResponse({"message": f"House {house_id} removed"}, status_code=200)

@router.get("/managers/add", tags=["Houses"], name="Add manager to house")
async def add_manager_to_house(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str,
    manager_id: str
) -> JSONResponse:
    ''' Add manager to house '''
    # Check user role
    if current_user.role != "admin":
        return JSONResponse({"error": "You are not admin"}, status_code=403)
    # Check if house exists
    house = await House.get_by_id(ObjectId(house_id))
    if house is None:
        return JSONResponse({"error": "House not found"}, status_code=404)
    # Check if manager exists
    user = await User.get_by_id(ObjectId(manager_id))
    if user is None:
        return JSONResponse({"error": "Manager not found"}, status_code=404)
    # Check if manager already in house
    if manager_id in [str(x) for x in house.managers]:
        return JSONResponse({"error": "Manager already in house"}, status_code=409)
    # Add manager and return it
    house.managers.append(ObjectId(manager_id))
    await house.save()
    return JSONResponse(house.to_json(), status_code=200)

@router.get("/managers/remove", tags=["Houses"], name="Remove manager from house")
async def remove_manager_from_house(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str,
    manager_id: str
) -> JSONResponse:
    ''' Remove manager from house '''
    # Check user role
    if current_user.role != "admin":
        return JSONResponse({"error": "You are not admin"}, status_code=403)
    # Check if house exists
    house = await House.get_by_id(ObjectId(house_id))
    if house is None:
        return JSONResponse({"error": "House not found"}, status_code=404)
    # Check if manager exists
    user = await User.get_by_id(ObjectId(manager_id))
    if user is None:
        return JSONResponse({"error": "Manager not found"}, status_code=404)
    # Check if manager already in house
    if manager_id not in [str(x) for x in house.managers]:
        return JSONResponse({"error": "Manager not in house"}, status_code=409)
    # Remove manager and return it
    house.managers.remove(ObjectId(manager_id))
    await house.save()
    return JSONResponse(house.to_json(), status_code=200)

@router.get("/info/update", tags=["Houses"], name="Update house info")
async def set_info_house(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str,
    info: str
) -> JSONResponse:
    ''' Set house info '''
    # Check if house exists
    house = await House.get_by_id(ObjectId(house_id))
    if house is None:
        return JSONResponse({"error": "House not found"}, status_code=404)
    # Check user role
    if current_user.role != "admin" and current_user._id not in house.managers:
        return JSONResponse({"error": "You are not admin or manager of this house"}, status_code=403)
    # Set info and return it
    house.info = info
    await house.save()
    return JSONResponse(house.to_json(), status_code=200)