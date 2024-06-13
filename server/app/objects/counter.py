from bson import ObjectId

from typing import List
from datetime import datetime
from app.utils.mongo import MongoDB

class Reading:
    date: datetime
    value: float
    writer: ObjectId

    def __init__(
        self, 
        date: datetime,
        value: float,
        writer: ObjectId
    ) -> None:
        self.date = date
        self.value = value
        self.writer = writer

    def __dict__(self):
        return {
            'date': self.date,
            'value': self.value,
            'writer': self.writer
        }
    
    def to_json(self):
        return {
            'date': self.date.strftime("%Y-%m-%d"),
            'value': self.value,
            'writer': str(self.writer)
        }

class Counter:
    _id: ObjectId
    apartment_id: ObjectId
    active: bool
    name: str
    type: str
    serial_number: str
    readings: List[Reading]

    def __init__(
        self, 
        apartment_id: ObjectId,
        active: bool,
        name: str,
        type: str,
        serial_number: str,
        readings: List[dict] = [],
        _id: ObjectId = None
    ) -> None:
        self._id = _id
        self.apartment_id = apartment_id
        self.active = active
        self.name = name
        self.type = type
        self.serial_number = serial_number
        self.readings = [Reading(**reading) for reading in readings]

    def __dict__(self):
        return {
            'apartment_id': self.apartment_id,
            'active': self.active,
            'name': self.name,
            'type': self.type,
            'serial_number': self.serial_number,
            'readings': [reading.__dict__() for reading in self.readings]
        }
    
    def to_json(self):
        return {
            'id': str(self._id),
            'apartment_id': str(self.apartment_id),
            'active': self.active,
            'name': self.name,
            'type': self.type,
            'serial_number': self.serial_number
            # 'readings': self.readings
        }
    
    async def save(self):
        if self._id is None:
            inserted = await MongoDB.db.counters.insert_one(self.__dict__())
            self._id = inserted.inserted_id
        else:
            await MongoDB.db.counters.update_one(
                {'_id': self._id},
                {'$set': self.__dict__()}
            )

    @classmethod
    async def get_by_id(cls, _id: ObjectId):
        data = await MongoDB.db.counters.find_one({'_id': _id})
        if data is None:
            return None
        return cls(**data)
    
    @classmethod
    async def get_list(
        cls,
        apartment_id: ObjectId
    ) -> List:
        cursor = MongoDB.db.counters.find({'apartment_id': apartment_id})
        result = []
        async for data in cursor:
            result.append(cls(**data))
        return result