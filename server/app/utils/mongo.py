import logging

from pymongo.database import Database
from motor.motor_asyncio import AsyncIOMotorClient

from app.settings import SETTINGS

class MongoDB:
    client: AsyncIOMotorClient # type: ignore
    db: Database

    @classmethod
    def setup(
            cls, 
            mongodb_url: str, 
            mongodb_db: str
        ) -> None:
        cls.client = AsyncIOMotorClient(mongodb_url) 
        cls.db = cls.client.get_database(mongodb_db)
        try:
            cls.client.admin.command('ping')
            logging.info('Connected to MongoDB')
        except Exception as e:
            logging.error(f'Exception while connecting to MongoDB: {e}')