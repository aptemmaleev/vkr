import asyncio

from fastapi import FastAPI
from uvicorn import Config, Server
from starlette.responses import JSONResponse

from app.settings import SETTINGS

from app.api.routes.auth import router as auth_router
from app.api.routes.houses import router as houses_router
from app.api.routes.counters import router as counters_router
from app.api.routes.apartments import router as apartments_router
from app.api.routes.events import router as events_router

app = FastAPI()
app.include_router(auth_router)
app.include_router(houses_router, prefix="/api/v1/houses")
app.include_router(counters_router, prefix="/api/v1/counters")
app.include_router(apartments_router, prefix="/api/v1/apartments")
app.include_router(events_router, prefix="/api/v1/events")

@app.get("/")
async def homepage_get(self):
    return JSONResponse({"Bober": "Rostislav"}, status_code=200)

def start_server(loop = None):
    if loop is None:
        loop = asyncio.get_running_loop()
    server_config = Config(
        app=app, 
        host=SETTINGS.API_HOST, 
        port=int(SETTINGS.API_PORT), 
        loop=loop
    )
    server = Server(config=server_config)
    loop.create_task(server.serve())