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

@router.get("/list", tags=["Apartments"], name="Get apartments list")
async def get_apartments(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str = None
) -> JSONResponse:
    ''' Get apartments list '''
    # Get house
    house = await House.get_by_id(ObjectId(house_id))
    if house is None:
        return JSONResponse({"error": "House not found"}, status_code=404)
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers:
        return JSONResponse({"error": "You are not admin or manager of this house"}, status_code=403)
    # Get apartments
    apartments = await Apartment.get_list(house_id=ObjectId(house_id))
    return JSONResponse([a.to_json() for a in apartments], status_code=200)

@router.get("/add", tags=["Apartments"], name="Add apartment")
async def add_apartment(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str,
    owner_id: str,
    entrance: str,
    number: str,
    floor: str
) -> JSONResponse:
    ''' Add apartment '''
    # Get house
    house = await House.get_by_id(ObjectId(house_id))
    if house is None:
        return JSONResponse({"error": "House not found"}, status_code=404)
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers:
        return JSONResponse({"error": "You are not admin or manager of this house"}, status_code=403)
    # Check if apartment already exists
    apartment_exists = await Apartment.get_list(
        house_id=ObjectId(house_id),
        number=number,
        entrance=entrance,
        floor=floor
    )
    if len(apartment_exists) > 0:
        return JSONResponse({"error": "Apartment already exists"}, status_code=400)
    # Add apartment
    apartment = Apartment(
        house_id=ObjectId(house_id),
        owner_id=ObjectId(owner_id),
        entrance=entrance,
        floor=floor,
        number=number,
        residents=[ObjectId(owner_id)]
    )
    await apartment.save()
    return JSONResponse(apartment.to_json(), status_code=200)

@router.get("/remove", tags=["Apartments"], name="Remove Apartment")
async def remove_apartment(
    current_user: Annotated[User, Depends(get_current_user)],
    apartment_id: str
) -> JSONResponse:
    ''' Remove apartment '''
    # Get apartment
    apartment = await Apartment.get_by_id(ObjectId(apartment_id))
    if apartment is None:
        return JSONResponse({"error": "Apartment not found"}, status_code=404)
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers:
        return JSONResponse({"error": "You are not admin or manager of this house"}, status_code=403)
    # Remove apartment
    await MongoDB.db.apartments.delete_one({'_id': ObjectId(apartment_id)})
    return JSONResponse({"message": "Apartment removed"}, status_code=200)

@router.get("/my", tags=["Apartments"], name="Get my apartments")
async def get_my_apartments(
    current_user: Annotated[User, Depends(get_current_user)]
) -> JSONResponse:
    ''' Get my apartments '''
    # Get my apartments
    my_apartments = await Apartment.get_list(resident_id=current_user._id)
    return JSONResponse([a.to_json() for a in my_apartments], status_code=200)

@router.get("/residents/add", tags=["Apartments"], name="Add resident to apartment")
async def add_resident_to_apartment(
    current_user: Annotated[User, Depends(get_current_user)],
    apartment_id: str,
    resident_id: str
) -> JSONResponse:
    ''' Add resident to apartment '''
    # Get apartment
    apartment = await Apartment.get_by_id(ObjectId(apartment_id))
    if apartment is None:
        return JSONResponse({"error": "Apartment not found"}, status_code=404)
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers and current_user._id != apartment.owner_id:
        return JSONResponse({"error": "You are not admin, manager of this house or apartment owner"}, status_code=403)
    # Check if resident already exists
    if resident_id in [str(x) for x in apartment.residents]:
        return JSONResponse({"error": "Resident already in apartment"}, status_code=409)
    # Add resident and return it
    apartment.residents.append(ObjectId(resident_id))
    await apartment.save()
    return JSONResponse(apartment.to_json(), status_code=200)

@router.get("/residents/remove", tags=["Apartments"], name="Remove resident from apartment")
async def remove_resident_from_apartment(
    current_user: Annotated[User, Depends(get_current_user)],
    apartment_id: str,
    resident_id: str
) -> JSONResponse:
    ''' Remove resident from apartment '''
    # Get apartment
    apartment = await Apartment.get_by_id(ObjectId(apartment_id))
    if apartment is None:
        return JSONResponse({"error": "Apartment not found"}, status_code=404)
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers and current_user._id != apartment.owner_id:
        return JSONResponse({"error": "You are not admin, manager of this house or apartment owner"}, status_code=403)
    # Check if resident not exists
    if resident_id not in [str(x) for x in apartment.residents]:
        return JSONResponse({"error": "Resident not in apartment"}, status_code=409)
    # Remove resident and return it
    apartment.residents.remove(ObjectId(resident_id))
    await apartment.save()
    return JSONResponse(apartment.to_json(), status_code=200)