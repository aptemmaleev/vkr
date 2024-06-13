import asyncio
import app.logger as logger

from app.settings import SETTINGS
from app.api.server import start_server
from app.utils.mongo import MongoDB

async def main():
    # Логирование
    logger.setup()
    # Подключаем БД
    MongoDB.setup(SETTINGS.MONGODB_URL.get_secret_value(), SETTINGS.MONGODB_DB.get_secret_value())
    # ЗАпускаем REST API
    server = start_server()
    
if __name__ == '__main__':
    loop = asyncio.new_event_loop() 
    loop.create_task(main())
    loop.run_forever()