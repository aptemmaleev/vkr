from bson import ObjectId

from typing import List
from datetime import datetime
from app.utils.mongo import MongoDB
from app.objects.user import User

class Apartment:
    _id: ObjectId
    house_id: ObjectId
    owner_id: ObjectId
    entrance: str
    floor: str
    number: str
    residents: List[ObjectId]

    def __init__(
        self, 
        house_id: ObjectId,
        owner_id: ObjectId,
        entrance: str,
        floor: str,
        number: str,
        residents: List[ObjectId] = [],
        _id: ObjectId = None
    ) -> None:
        self._id = _id
        self.house_id = house_id
        self.owner_id = owner_id
        self.entrance = entrance
        self.floor = floor
        self.number = number
        self.residents = residents

    def __dict__(self):
        return {
            'house_id': self.house_id,
            'owner_id': self.owner_id,
            'entrance': self.entrance,
            'floor': self.floor,
            'number': self.number,
            'residents': self.residents,
        }
    
    def to_json(self):
        return {
            'id': str(self._id),
            'house_id': str(self.house_id),
            'owner_id': str(self.owner_id),
            'entrance': str(self.entrance),
            'floor': self.floor,
            'number': self.number,
            'residents': list(map(str, self.residents)),
        }
    
    async def to_extended_json(self):
        return {
            'id': str(self._id),
            'house_id': str(self.house_id),
            'owner_id': str(self.owner_id),
            'entrance': self.entrance,
            'floor': self.floor,
            'number': self.number,
            'residents': [(await User.get_by_id(ObjectId(r))).to_json() for r in self.residents]
        }
    
    async def save(self):
        if self._id is None:
            inserted = await MongoDB.db.apartments.insert_one(self.__dict__())
            self._id = inserted.inserted_id
        else:
            await MongoDB.db.apartments.update_one(
                {'_id': self._id},
                {'$set': self.__dict__()}
            )
    
    @classmethod
    async def get_by_id(cls, _id: ObjectId):
        data = await MongoDB.db.apartments.find_one({'_id': _id})
        if data is None:
            return None
        return cls(**data)
    
    @classmethod
    async def get_list(
        cls, 
        house_id: ObjectId = None, 
        owner_id: ObjectId = None, 
        resident_id: ObjectId = None, 
        entrance: str = None,
        floor: str = None,
        number: str = None,
        skip: int = 0,
        limit: int = 20
    ) -> List:
        filter = {}
        if house_id is not None: filter['house_id'] = house_id
        if owner_id is not None: filter['owner_id'] = owner_id
        if resident_id is not None: filter['residents'] = resident_id
        if entrance is not None: filter['entrance'] = entrance
        if floor is not None: filter['floor'] = floor
        if number is not None: filter['number'] = number
        cursor = MongoDB.db.apartments.find(filter, skip=skip, limit=limit, sort=[("number", -1)])
        result = []
        async for data in cursor:
            result.append(cls(**data))
        return result