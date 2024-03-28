from bson import ObjectId

from datetime import datetime
from app.utils.mongo import MongoDB

class User:
    _id: ObjectId
    role: str
    email: str
    password: str
    name: str
    surname: str
    created_at: datetime
    updated_at: datetime

    def __init__(
            self, 
            name: str,
            surname: str,
            password: str, 
            email: str, 
            role: str = "user",
            created_at: datetime = datetime.now(),
            updated_at: datetime = datetime.now(),
            _id: ObjectId = None
        ) -> None:
        self._id = _id
        self.name = name
        self.surname = surname
        self.role = role
        self.email = email
        self.password = password
        self.created_at = created_at
        self.updated_at = updated_at
    
    def __dict__(self):
        return {
            'name': self.name,
            'surname': self.surname,
            'role': self.role,
            'email': self.email,
            'password': self.password,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
    
    def to_json(self):
        return {
            'id': str(self._id),
            'name': self.name,
            'surname': self.surname,
            'email': self.email,
            'role': self.role
            # 'password': self.password
        }
        
    async def save(self):
        if self._id is None:
            inserted = await MongoDB.db.users.insert_one(self.__dict__())
            self._id = inserted.inserted_id
        else:
            await MongoDB.db.users.update_one(
                {'_id': self._id},
                {'$set': self.__dict__()}
            )

    @classmethod
    async def get_by_email(cls, email: str):
        data = await MongoDB.db.users.find_one({'email': email})
        if data is None:
            return None
        return cls(**data)
        
    @classmethod
    async def get_by_id(cls, _id: ObjectId):
        data = await MongoDB.db.users.find_one({'_id': _id})
        if data is None:
            return None
        return cls(**data)