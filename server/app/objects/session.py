from bson import ObjectId

from datetime import datetime
from app.utils.mongo import MongoDB

class Session:
    _id: ObjectId
    user_id: ObjectId

    ip: str
    token: str
    deviceInfo: dict

    created_at: datetime
    updated_at: datetime
    expires_at: datetime

    def __init__(
        self, 
        user_id: ObjectId,
        ip: str,
        token: str,
        deviceInfo: dict = {},
        created_at: datetime = datetime.now(),
        updated_at: datetime = datetime.now(),
        expires_at: datetime = datetime.now(),
        _id: ObjectId = None
    ) -> None:
        self._id = _id
        self.user_id = user_id
        self.ip = ip
        self.token = token
        self.deviceInfo = deviceInfo
        self.created_at = created_at
        self.updated_at = updated_at
        self.expires_at = expires_at

    def __dict__(self):
        return {
            'user_id': self.user_id,
            'ip': self.ip,
            'token': self.token,
            'deviceInfo': self.deviceInfo,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
            'expires_at': self.expires_at
        }
    
    def to_json(self):
        return {
            'id': str(self._id),
            'user_id': str(self.user_id),
            'ip': self.ip,
            'token': self.token,
            'deviceInfo': self.deviceInfo,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
            'expires_at': self.expires_at
        }

    async def save(self):
        if self._id is None:
            inserted = await MongoDB.db.sessions.insert_one(self.__dict__())
            self._id = inserted.inserted_id
        else:
            await MongoDB.db.sessions.update_one(
                {'_id': self._id},
                {'$set': self.__dict__()}
            )

    @classmethod
    async def get_by_id(cls, _id: ObjectId):
        data = await MongoDB.db.sessions.find_one({'_id': _id})
        if data is None:
            return None
        return cls(**data)
    
    @classmethod
    async def get_by_token(cls, token: str):
        data = await MongoDB.db.sessions.find_one({'token': token})
        if data is None:
            return None
        return cls(**data)
    
    @classmethod
    async def get_by_user_id(cls, user_id: ObjectId) -> list:
        cursor = MongoDB.db.sessions.find({'user_id': user_id})
        result = []
        async for data in cursor:
            result.append(cls(**data))
        return result