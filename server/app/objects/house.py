from bson import ObjectId

from typing import List
from datetime import datetime
from app.utils.mongo import MongoDB

class House:
    _id: ObjectId
    address: str
    info: str
    start_readings_day: int
    end_readings_day: int
    managers: List[ObjectId]

    def __init__(
        self, 
        address: str,
        info: str,
        managers: List[ObjectId],
        start_readings_day: int = 1,
        end_readings_day: int = 30,
        _id: ObjectId = None
    ) -> None:
        self._id = _id
        self.address = address
        self.info = info
        self.start_readings_day = start_readings_day
        self.end_readings_day = end_readings_day
        self.managers = managers

    def __dict__(self):
        return {
            'address': self.address,
            'info': self.info,
            'start_readings_day': self.start_readings_day,
            'end_readings_day': self.end_readings_day,
            'managers': self.managers
        }
    
    def to_json(self):
        return {
            'id': str(self._id),
            'address': self.address,
            'info': self.info,
            'start_readings_day': self.start_readings_day,
            'end_readings_day': self.end_readings_day,
            'managers': list(map(str, self.managers))
        }
    
    async def save(self):
        if self._id is None:
            inserted = await MongoDB.db.houses.insert_one(self.__dict__())
            self._id = inserted.inserted_id
        else:
            await MongoDB.db.houses.update_one(
                {'_id': self._id},
                {'$set': self.__dict__()} 
            )

    @classmethod
    async def get_by_id(cls, _id: ObjectId):
        data = await MongoDB.db.houses.find_one({'_id': ObjectId(_id)})
        if data is None:
            return None
        return cls(**data)
    
    @classmethod
    async def get_list(
        cls,
        address: str = None,
        manager: ObjectId = None,
        skip: int = 0,
        limit: int = 20
    ) -> List:
        filter = {}
        if address is not None: filter['address'] = address
        if manager is not None: filter['managers'] = manager
        cursor = MongoDB.db.houses.find(filter, skip=skip, limit=limit) 
        result = []
        async for data in cursor:
            result.append(cls(**data))
        return result