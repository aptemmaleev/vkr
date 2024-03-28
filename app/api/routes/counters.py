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

@router.get("/list", tags=["Counters"], name="Get counters list")
async def get_counters(
    current_user: Annotated[User, Depends(get_current_user)],
    apartment_id: str = None
) -> JSONResponse:
    ''' Get counters list '''
    # Get house
    apartment = await Apartment.get_by_id(ObjectId(apartment_id))
    if apartment is None:
        return JSONResponse({"error": "Apartment not found"}, status_code=404)
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers and current_user._id not in apartment.residents:
        return JSONResponse({"error": "You are not admin, manager of this house or resident of this apartment"}, status_code=403)
    # Get counters
    counters = await Counter.get_list(apartment_id=ObjectId(apartment_id))
    return JSONResponse([c.to_json() for c in counters], status_code=200)

@router.get("/add", tags=["Counters"], name="Add counter")
async def add_counter(
    current_user: Annotated[User, Depends(get_current_user)],
    apartment_id: str,
    serial_number: str,
    type: str,
    name: str
) -> JSONResponse:
    ''' Add counter 
    type: ["electricity", "hot_water", "cold_water", "gas"]
    '''
    # Check if type is valid
    if type not in ["electricity", "hot_water", "cold_water", "gas"]:
        return JSONResponse({"error": "Invalid type"}, status_code=400)
    # Get apartment
    apartment = await Apartment.get_by_id(ObjectId(apartment_id))
    if apartment is None:
        return JSONResponse({"error": "Apartment not found"}, status_code=404)
    house = await House.get_by_id(ObjectId(apartment.house_id))    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers and current_user._id != apartment.owner_id:
        return JSONResponse({"error": "You are not admin, manager of this house or apartment owner"}, status_code=403)
    # Check if counter already exists
    counter = await MongoDB.db.counters.find_one({'serial_number': serial_number})
    if counter is not None:
        return JSONResponse({"error": "Counter already exists"}, status_code=400)
    # Add counter
    counter = Counter(
        apartment_id=ObjectId(apartment_id),
        serial_number=serial_number,
        type=type,
        name=name,
        active=True
    )
    await counter.save()
    return JSONResponse(counter.to_json(), status_code=200)

@router.get("/remove", tags=["Counters"], name="Remove counter")
async def remove_counter(
    current_user: Annotated[User, Depends(get_current_user)],
    counter_id: str
) -> JSONResponse:
    ''' Remove counter '''
    # Get counter
    counter = await Counter.get_by_id(ObjectId(counter_id))
    if counter is None:
        return JSONResponse({"error": "Counter not found"}, status_code=404)
    apartment = await Apartment.get_by_id(ObjectId(counter.apartment_id))
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers and current_user._id != apartment.owner_id:
        return JSONResponse({"error": "You are not admin, manager of this house or apartment owner"}, status_code=403)
    # Remove counter
    await MongoDB.db.counters.delete_one({'_id': ObjectId(counter_id)})
    return JSONResponse({"message": "Counter removed"}, status_code=200)

@router.get("/readings/list", tags=["Counters"], name="Get readings list")
async def get_readings(
    current_user: Annotated[User, Depends(get_current_user)],
    counter_id: str = None,
    start_date: str = None,
    end_date: str = None,
    limit: int = 20,
    skip: int = 0
) -> JSONResponse:
    ''' Get readings list '''
    # Get counter
    counter: Counter = await Counter.get_by_id(ObjectId(counter_id))
    if counter is None:
        return JSONResponse({"error": "Counter not found"}, status_code=404)
    apartment = await Apartment.get_by_id(ObjectId(counter.apartment_id))
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and \
        current_user._id not in house.managers and \
        current_user._id not in apartment.residents:
        return JSONResponse({"error": "You are not admin, manager of this house or resident of this apartment"}, status_code=403)
    # Get readings
    start_date = datetime.strptime(start_date, '%Y-%m-%d') if start_date else None
    end_date = datetime.strptime(end_date, '%Y-%m-%d') if end_date else None
    result = []
    for reading in counter.readings:
        if start_date and reading.date < start_date:
            continue
        if end_date and reading.date > end_date:
            continue
        result.append(reading)
    result = [r.to_json() for r in result[skip:skip + limit]]
    return JSONResponse(result, status_code=200)

@router.get("/readings/add", tags=["Counters"], name="Add reading")
async def add_reading(
    current_user: Annotated[User, Depends(get_current_user)],
    counter_id: str,
    value: float
) -> JSONResponse:
    ''' Add reading '''
    # Get counter
    counter = await Counter.get_by_id(ObjectId(counter_id))
    if counter is None:
        return JSONResponse({"error": "Counter not found"}, status_code=404)
    apartment = await Apartment.get_by_id(ObjectId(counter.apartment_id))
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and \
        current_user._id not in house.managers and \
        current_user._id not in apartment.residents:
        return JSONResponse({"error": "You are not admin, manager of this house or resident of this apartment"}, status_code=403)
    # If there is reading in the same day
    for reading in counter.readings:
        if reading.date.date() == datetime.now().date():
            return JSONResponse({"error": "Reading in the same day already exists"}, status_code=400)
    # Add reading
    reading = Reading(
        date=datetime.now(),
        value=value,
        writer=current_user._id
    )
    counter.readings.append(reading)
    await counter.save()
    return JSONResponse(reading.to_json(), status_code=200)

@router.get("/readings/remove", tags=["Counters"], name="Remove reading")
async def remove_reading(
    current_user: Annotated[User, Depends(get_current_user)],
    counter_id: str,
    date: str
) -> JSONResponse:
    ''' Remove reading '''
    # Get counter
    counter = await Counter.get_by_id(ObjectId(counter_id))
    if counter is None:
        return JSONResponse({"error": "Counter not found"}, status_code=404)
    apartment = await Apartment.get_by_id(ObjectId(counter.apartment_id))
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and \
        current_user._id not in house.managers and \
        current_user._id not in apartment.residents:
        return JSONResponse({"error": "You are not admin, manager of this house or resident of this apartment"}, status_code=403)
    # Remove reading
    date = datetime.strptime(date, '%Y-%m-%d').date()
    removed = False
    for reading in counter.readings:
        if reading.date.date() == date:
            counter.readings.remove(reading)
            removed = True
            break
    if not removed:
        return JSONResponse({"error": "Reading not found"}, status_code=404)
    await counter.save()
    return JSONResponse({"message": "Reading removed"}, status_code=200)