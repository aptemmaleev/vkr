from bson import ObjectId

from typing import List
from datetime import datetime
from app.utils.mongo import MongoDB

class Event:
    _id: ObjectId
    user_id: ObjectId
    type: str
    title: str
    details: str
    read: bool
    manager_id: ObjectId
    created_at: datetime
    house_id: ObjectId | None

    def __init__(
        self, 
        user_id: ObjectId,
        type: str,
        title: str,
        details: str,
        read: bool = False,
        manager_id: ObjectId = None,
        created_at: datetime = datetime.now(),
        house_id: ObjectId | None = None,
        _id: ObjectId = None
    ) -> None:
        self._id = _id
        self.user_id = user_id
        self.title = title
        self.details = details
        self.read = read
        self.manager_id = manager_id
        self.created_at = created_at
        self.house_id = house_id
        self.type = type

    def __dict__(self):
        return {
            'user_id': self.user_id,
            'type': self.type,
            'title': self.title,
            'details': self.details,
            'read': self.read,
            'manager_id': self.manager_id,
            'created_at': self.created_at,
            'house_id': self.house_id
        }
    
    def to_json(self):
        return {
            'id': str(self._id),
            'type': self.type,
            'user_id': str(self.user_id),
            'title': self.title,
            'details': self.details,
            'read': self.read,
            'manager_id': str(self.manager_id),
            'created_at': self.created_at.strftime('%Y-%m-%d'),
            'house_id': str(self.house_id)
        }
    
    async def save(self):
        if self._id is None:
            inserted = await MongoDB.db.events.insert_one(self.__dict__())
            self._id = inserted.inserted_id
        else:
            await MongoDB.db.events.update_one(
                {'_id': self._id},
                {'$set': self.__dict__()}
            )
    
    @classmethod
    async def get_by_id(cls, _id: ObjectId):
        data = await MongoDB.db.events.find_one({'_id': _id})
        if data is None:
            return None
        return cls(**data)
    
    @classmethod
    async def get_user_events(cls, user_id: ObjectId, limit: int = 20, skip: int = 0, read: bool = None):
        filter = {'user_id': user_id}
        if read is not None: filter['read'] = read
        cursor = MongoDB.db.events.find(filter, skip=skip, limit=limit)
        result = []
        async for data in cursor:
            result.append(cls(**data))
        return result