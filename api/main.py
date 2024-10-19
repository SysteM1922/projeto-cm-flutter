from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.database import create_db_and_tables
from controllers import user, bus, travel, stop, route, system

app = FastAPI()

origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://localhost:3000",
    "http://localhost:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

app.include_router(user.router)
app.include_router(bus.router)
app.include_router(travel.router)
app.include_router(stop.router)
app.include_router(route.router)
app.include_router(system.router)

@app.on_event("startup")
def on_startup():
    create_db_and_tables()
    

@app.get("/")
async def root():
    return JSONResponse(content={"message": "API Online"}, status_code=200)

