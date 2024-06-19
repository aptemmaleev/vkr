from bson import ObjectId

from typing import List
from datetime import datetime
from app.utils.mongo import MongoDB

class Reading:
    _id: ObjectId
    user_id: ObjectId
    value: float
    created_at: datetime
    counter_id: ObjectId
    year: int
    month: int

    def __init__(
        self, 
        user_id: ObjectId,
        value: float,
        created_at: datetime = datetime.now(),
        counter_id: ObjectId | None = None,
        year: int = datetime.now().year,
        month: int = datetime.now().month,
        _id: ObjectId = None
    ) -> None:
        self._id = ObjectId(_id)
        self.value = value
        self.user_id = ObjectId(user_id)
        self.created_at = created_at
        self.counter_id = ObjectId(counter_id)
        self.year = year
        self.month = month

    def __dict__(self):
        return {
            'user_id': self.user_id,
            'value': self.value,
            'created_at': self.created_at,
            'counter_id': self.counter_id,
            'year': self.year,
            'month': self.month
        }
    
    def to_json(self):
        return {
            'id': str(self._id),
            'value': self.value,
            'user_id': str(self.user_id),
            'created_at': self.created_at.strftime('%Y-%m-%d'),
            'counter_id': str(self.counter_id),
            'year': self.year,
            'month': self.month
        }
    
class Counter:
    _id: ObjectId
    apartment_id: ObjectId
    active: bool
    name: str
    type: str
    serial_number: str

    def __init__(
        self, 
        apartment_id: ObjectId,
        active: bool,
        name: str,
        type: str,
        serial_number: str,
        _id: ObjectId = None
    ) -> None:
        self._id = _id
        self.apartment_id = apartment_id
        self.active = active
        self.name = name
        self.type = type
        self.serial_number = serial_number

    def __dict__(self):
        return {
            'apartment_id': self.apartment_id,
            'active': self.active,
            'name': self.name,
            'type': self.type,
            'serial_number': self.serial_number,
        }
    
    def to_json(self):
        return {
            'id': str(self._id),
            'apartment_id': str(self.apartment_id),
            'active': self.active,
            'name': self.name,
            'type': self.type,
            'serial_number': self.serial_number
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
        apartment_id: ObjectId,
        type: str = None
    ) -> List:
        filter = {'apartment_id': apartment_id}
        if type is not None: filter['type'] = type
        cursor = MongoDB.db.counters.find(filter)
        result = []
        async for data in cursor:
            result.append(cls(**data))
        return result