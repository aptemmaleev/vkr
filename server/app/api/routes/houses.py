import asyncio
import traceback
import hashlib
import secrets
import logging

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
from app.utils.tables import *
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
    info: str = "",
    start_readings_day: int = 0,
    end_readings_day: int = 0
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
    if (info != ""): house.info = info
    if (start_readings_day != ""): house.start_readings_day = start_readings_day
    if (end_readings_day != ""): house.end_readings_day = end_readings_day
    await house.save()
    return JSONResponse(house.to_json(), status_code=200)


async def get_table(house_id, counter_type, year, month):
    house = await House.get_by_id(ObjectId(house_id))

    i = 1
    table = []

    # Get all apartments of the house
    apartments = await Apartment.get_list(house_id=ObjectId(house_id))
    # Form apartments ids list for query
    apartment_ids = [apartment._id for apartment in apartments]
    logging.info(f"Found {len(apartment_ids)} apartments")
    # Get counters
    cursor = MongoDB.db.counters.find({"apartment_id": {"$in": apartment_ids}, "type": counter_type})
    counters = [Counter(**data) async for data in cursor]
    logging.info(f"Found {len(counters)} counters")
    # Get new readings
    cursor = MongoDB.db.readings.find(
        {
            "year": year,
            "month": month,
            "counter_id": {"$in": [counter._id for counter in counters]}
        }
    )
    readings = [Reading(**data) async for data in cursor]
    logging.info(f"Found {len(readings)} readings this month")

    # Get prev readings
    prev_month = month - 1
    prev_year = year
    if prev_month == 0:
        prev_month = 12
        prev_year -= 1
    cursor = MongoDB.db.readings.find(
        {
            "year": prev_year,
            "month": prev_month,
            "counter_id": {"$in": [counter._id for counter in counters]}
        }
    )
    old_readings = [Reading(**data) async for data in cursor]
    logging.info(f"Found {len(old_readings)} readings previous month")
    
    # Prepare dicts for fast search
    apartment_to_counters = {}
    for counter in counters:
        if counter.apartment_id not in apartment_to_counters:
            apartment_to_counters[counter.apartment_id] = [counter]
        else:
            apartment_to_counters[counter.apartment_id].append(counter)
    counters_to_readings = {}
    for reading in readings:
        counters_to_readings[reading.counter_id] = reading
    counters_to_old_readings = {}
    for reading in old_readings:
        counters_to_old_readings[reading.counter_id] = reading

    # Form table
    i = 1
    for apartment in apartments:
        apartment_name = f"{house.address}, кв. {apartment.number}"
        # if apartment doesn't have counters
        if apartment._id not in apartment_to_counters:
            table.append([str(i), apartment_name, "нет приборов учета", "", "", "огульно"])
            i += 1
            continue
        # if apartment has counters
        firstRow = True
        for counter in apartment_to_counters[apartment._id]:
            prev_value = None
            new_value = None

            if counter._id in counters_to_old_readings:
                prev_value = counters_to_old_readings[counter._id].value
            if counter._id in counters_to_readings:
                new_value = counters_to_readings[counter._id].value
            
            if prev_value is not None and new_value is not None:
                table.append([str(i) if firstRow else "", apartment_name, counter.serial_number, prev_value, new_value, new_value - prev_value])
            elif prev_value is None and new_value is None:
                table.append([str(i) if firstRow else "", apartment_name, counter.serial_number, "", "", 0])
            elif prev_value is None:
                table.append([str(i) if firstRow else "", apartment_name, counter.serial_number, "", new_value, new_value])
            elif new_value is None:
                table.append([str(i) if firstRow else "", apartment_name, counter.serial_number, prev_value, "", 0])
            if firstRow: i += 1
            firstRow = False
        
    return table

@router.get("/form_table", tags=["Houses"], name="Form reading table")
async def form_table(
    current_user: Annotated[User, Depends(get_current_user)],
    house_id: str,
    year: int,
    month: int
) -> JSONResponse:
    house = await House.get_by_id(ObjectId(house_id))
    if current_user.role != "admin" and current_user._id not in house.managers:
        return JSONResponse({"error": "You are not admin or manager of this house"}, status_code=403)
    if month < 1 or month > 12:
        return JSONResponse({"error": "Invalid month"}, status_code=400)
    if year < 2020 or year > 2100:
        return JSONResponse({"error": "Invalid year"}, status_code=400)
    
    loop = asyncio.get_running_loop()

    # run tasks
    tasks = [
        loop.create_task(get_table(house_id, "electricity", year, month)),
        loop.create_task(get_table(house_id, "hot_water", year, month)),
        loop.create_task(get_table(house_id, "cold_water", year, month)),
    ]

    await asyncio.gather(*tasks)
    electricity_table = tasks[0].result()
    hot_water_table = tasks[1].result()
    cold_water_table = tasks[2].result()
    
    sa = get_service_account()
    sh = create_spreadsheet(house.address, year, month)
    print(sh.url)
    write_table(sh, house.address, "electricity", electricity_table)
    write_table(sh, house.address, "hot_water", hot_water_table)
    write_table(sh, house.address, "cold_water", cold_water_table)
    sh.del_worksheet(sh.worksheets()[0])

    return JSONResponse({"result": sh.url}, status_code=200)