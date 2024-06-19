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
    now = datetime.now().date()
    _counters = []
    for counter in counters:
        c = counter.to_json()
        c['has_reading'] = await MongoDB.db.readings.find_one({'year': now.year, 'month': now.month, 'counter_id': counter._id}) is not None
        _counters.append(c)

    return JSONResponse(_counters, status_code=200)

@router.get("/requests/resolve", tags=["Counters"], name="Resolve request")
async def add_counter(
    current_user: Annotated[User, Depends(get_current_user)],
    request_id: str,
    positive: bool
) -> JSONResponse:
    request = await MongoDB.db.requests.find_one({"_id": ObjectId(request_id)})
    if request is None:
        return JSONResponse({"error": "Заявка не найдена"}, status_code=200)
    if not positive:
        event = Event(
            request['user_id'],
            "notification",
            "Удаление счетчика" if request['type'] == 'delete' else "Добавление счетчика",
            f"Заявка по счетчику с серийным номером {request['counter_serial_number']} отклонена",
            False,
            ObjectId("65fca4b12b86fff7e3b1a5a3"),
            datetime.now(),
            request['house_id']
        )
        await event.save()
        counter = await Counter.get_by_id(request['counter_id'])
        if (request['type'] == 'delete'):
            counter.active = True
            await counter.save()
        else:
            await MongoDB.db.counters.delete_one({"_id": counter._id})
        await MongoDB.db.requests.delete_one({"_id": request["_id"]})
        return

    if request['type'] == 'delete':
        await MongoDB.db.counters.delete_one({"_id": ObjectId(request['counter_id'])})
        event = Event(
            request['user_id'],
            "notification",
            "Удаление счетчика",
            f"Счетчик с серийным номером {request['counter_serial_number']} удален",
            False,
            ObjectId("65fca4b12b86fff7e3b1a5a3"),
            datetime.now(),
            request['house_id']
        )
        await event.save()
    else:
        counter = await Counter.get_by_id(request['counter_id'])
        counter.active = True
        await counter.save()
        event = Event(
            request['user_id'],
            "notification",
            "Добавление счетчика",
            f"Счетчик с серийным номером {request['counter_serial_number']} добавлен",
            False,
            ObjectId("65fca4b12b86fff7e3b1a5a3"),
            datetime.now(),
            request['house_id']
        )
        await event.save()
    await MongoDB.db.requests.delete_one({"_id": request["_id"]})


@router.get("/add", tags=["Counters"], name="Add counter")
async def add_counter(
    current_user: Annotated[User, Depends(get_current_user)],
    apartment_id: str,
    serial_number: str,
    type: str,
    name: str,
    value: float
) -> JSONResponse:
    ''' Add counter 
    type: ["electricity", "hot_water", "cold_water", "gas"]
    '''
    # Check if type is valid
    if type not in ["electricity", "hot_water", "cold_water", "gas"]:
        return JSONResponse({"error": "Неверный тип"}, status_code=200)
    # Get apartment
    apartment = await Apartment.get_by_id(ObjectId(apartment_id))
    if apartment is None:
        return JSONResponse({"error": "Квартира не найдена"}, status_code=200)
    house = await House.get_by_id(ObjectId(apartment.house_id))    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers and current_user._id != apartment.owner_id:
        return JSONResponse({"error": "You are not admin, manager of this house or apartment owner"}, status_code=403)
    # Check if counter already exists
    counter = await MongoDB.db.counters.find_one({'serial_number': serial_number})
    if counter is not None:
        return JSONResponse({"error": "Counter already exists"}, status_code=400)
    # Check if there more then 3 counters of this type

    # Add counter
    counter = Counter(
        apartment_id=ObjectId(apartment_id),
        serial_number=serial_number,
        type=type,
        name=name,
        active=False
    )
    await counter.save()
    reading = Reading(
        value=round(value, 1),
        user_id=current_user._id,
        counter_id=counter._id,
        year=2024,
        month=1,
        created_at=datetime.now() - timedelta(days=60)
    )
    inserted = await MongoDB.db.readings.insert_one(reading.__dict__())

    request = {
        "counter_id": counter._id,
        "type": "add",
        "reason": "Новый счетчик",
        "counter_type": counter.type,
        "counter_serial_number": counter.serial_number,
        "apartment_number": apartment.number,
        "house_id": house._id,
        "user_id": current_user._id,
        "reviewed": False,
        "positive": False
    }
    await MongoDB.db.requests.insert_one(request)
    event = Event(
        current_user._id,
        "notification",
        "Добавление счетчика",
        f"Заявка на добавление счетчика с серийным номером {serial_number} принята",
        False,
        ObjectId("65fca4b12b86fff7e3b1a5a3"),
        datetime.now(),
        house._id
    )
    await event.save()

    return JSONResponse(counter.to_json(), status_code=200)

@router.get("/requests/list", tags=["Counters"], name="Remove counter")
async def remove_counter(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str
) -> JSONResponse:
    ''' Remove counter '''
    # Get counter
    house = await House.get_by_id(ObjectId(house_id))
    if house is None:
        return JSONResponse({"error": "Дом не найден"}, status_code=200)
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers:
        return JSONResponse({"error": "You are not admin or manager of this house"}, status_code=200)
    # Parse all requests
    cursor = MongoDB.db.requests.find({"house_id": ObjectId(house_id)})
    requests = []
    async for request in cursor:
        request['counter_id'] = str(request['counter_id'])
        request['_id'] = str(request['_id'])
        request['house_id'] = str(request['house_id'])
        request['user_id'] = str(request['user_id'])
        request['counter_id'] = str(request['counter_id'])
        requests.append(request)
    return JSONResponse(requests, status_code=200)
    

@router.get("/remove", tags=["Counters"], name="Remove counter")
async def remove_counter(
    current_user: Annotated[User, Depends(get_current_user)],
    counter_id: str,
    reason: str = ""
) -> JSONResponse:
    ''' Remove counter '''
    # Get counter
    counter = await Counter.get_by_id(ObjectId(counter_id))
    if counter is None:
        return JSONResponse({"error": "Счетчик не найден"}, status_code=200)
    apartment = await Apartment.get_by_id(ObjectId(counter.apartment_id))
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and current_user._id not in house.managers and current_user._id != apartment.owner_id:
        return JSONResponse({"error": "You are not admin, manager of this house or apartment owner"}, status_code=403)
    # Remove counter
    request = {
        "counter_id": counter._id,
        "type": "delete",
        "reason": reason,
        "house_id": house._id,
        "counter_type": counter.type,
        "counter_serial_number": counter.serial_number,
        "apartment_number": apartment.number,
        "user_id": current_user._id,
        "reviewed": False,
        "positive": False
    }
    await MongoDB.db.requests.insert_one(request)

    event = Event(
        current_user._id,
        "notification",
        "Удаление счетчика",
        f"Заявка на удаление счетчика с серийным номером {counter.serial_number} принята",
        False,
        ObjectId("65fca4b12b86fff7e3b1a5a3"),
        datetime.now(),
        house._id
    )
    await event.save()

    counter.active = False
    await counter.save()
    # await MongoDB.db.counters.delete_one({'_id': ObjectId(counter_id)})
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
        return JSONResponse({"error": "Счетчик не найден"}, status_code=200)
    apartment = await Apartment.get_by_id(ObjectId(counter.apartment_id))
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and \
        current_user._id not in house.managers and \
        current_user._id not in apartment.residents:
        return JSONResponse({"error": "You are not admin, manager of this house or resident of this apartment"}, status_code=403)
    # Get readings
    start_date = datetime.strptime(start_date, '%Y-%m-%d') if start_date else datetime.strptime("2000-01-01", '%Y-%m-%d')
    end_date = datetime.strptime(end_date, '%Y-%m-%d') if end_date else datetime.strptime("2100-12-01", '%Y-%m-%d')

    print(start_date.year, start_date.month)
    print(end_date.year, end_date.month)

    cursor = MongoDB.db.readings.find({
        'counter_id': ObjectId(counter_id),
        'year': {
            '$gte': start_date.year,
            '$lte': end_date.year
        },
        'month': {
            '$gte': start_date.month,
            '$lte': end_date.month
        }
    }).skip(skip).limit(limit).sort([("year", -1), ("month", -1)])
    
    result = [Reading(**data) async for data in cursor]
    return JSONResponse([x.to_json() for x in result], status_code=200)

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
        return JSONResponse({"error": "Счетчик не найден"}, status_code=200)
    apartment = await Apartment.get_by_id(ObjectId(counter.apartment_id))
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and \
        current_user._id not in house.managers and \
        current_user._id not in apartment.residents:
        return JSONResponse({"error": "You are not admin, manager of this house or resident of this apartment"}, status_code=403)
    # Add reading
    reading = Reading(
        value=round(value, 1),
        user_id=current_user._id,
        counter_id=counter._id
    )

    if await MongoDB.db.readings.find_one({"value": {'counter_id': reading.counter_id,'$gte': value}}) is not None:
        return JSONResponse({"error": "Показания не могут быть меньше предыдущих"}, status_code=200)
    # current_reading = await MongoDB.db.readings.find_one({"year": reading.year, "month": reading.month, "counter_id": reading.counter_id})
    # if current_reading is not None:
    #     await MongoDB.db.readings.delete_one({"_id": current_reading._id})
    if await MongoDB.db.readings.find_one({"year": reading.year, "month": reading.month, "counter_id": reading.counter_id}) is not None:
        return JSONResponse({"error": "В этом месяце вы уже вносили показания"}, status_code=200)

    inserted = await MongoDB.db.readings.insert_one(reading.__dict__())
    reading._id = inserted.inserted_id

    return JSONResponse(reading.to_json(), status_code=200)

@router.get("/readings/remove", tags=["Counters"], name="Remove reading")
async def remove_reading(
    current_user: Annotated[User, Depends(get_current_user)],
    reading_id: str,
) -> JSONResponse:
    ''' Remove reading '''
    reading = await MongoDB.db.readings.find_one({"_id": ObjectId(reading_id)})
    if reading is None:
        return JSONResponse({"error": "Reading not found"}, status_code=404)
    counter = await Counter.get_by_id(ObjectId(reading['counter_id']))
    if counter is None:
        return JSONResponse({"error": "Counter not found"}, status_code=404)
    apartment = await Apartment.get_by_id(ObjectId(counter.apartment_id))
    house = await House.get_by_id(ObjectId(apartment.house_id))
    # Check user role
    if current_user.role not in ["admin"] and \
        current_user._id not in house.managers and \
        current_user._id not in apartment.residents:
        return JSONResponse({"error": "You are not admin, manager of this house or resident of this apartment"}, status_code=403)
    
    await MongoDB.db.readings.delete_one({"_id": ObjectId(reading_id)})
    return JSONResponse({"message": "Reading removed"}, status_code=200)