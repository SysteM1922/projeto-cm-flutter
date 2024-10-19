from fastapi import APIRouter
from fastapi.responses import JSONResponse
from fastapi import Depends
from uuid import UUID
from sqlalchemy.orm.session import Session
from app.database import get_session

from app.models import User, TravelHistory, Travel
from app.schemas import UserCreate

router = APIRouter(prefix="/user", tags=["User"])

@router.post("/create")
async def create_user(user_create: UserCreate, db: Session = Depends(get_session)):
    user = db.query(User).filter(User.firebase_uid == user_create.firebase_uid).first()
    if user is not None:
        return {"user_id": user.id, "card_id": user.card_number}
    
    new_user = User(username=user_create.username, email=user_create.email, firebase_uid=user_create.firebase_uid)

    try:
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
    except Exception:
        return JSONResponse(content={"message": "An error occurred"}, status_code=500)

    return {"user_id": new_user.id, "card_id": new_user.card_number}


@router.get("/{user_id}")
async def get_user(user_id: str, db: Session = Depends(get_session)):
    user = db.query(User).filter(User.firebase_uid == user_id).first()

    if user is None:
        return JSONResponse(content={"message": "User not found"}, status_code=404)

    return {"user_id": user.id, "card_id": user.card_number}

@router.get("/history/{user_id}")
async def get_user_history(user_id: UUID, db: Session = Depends(get_session)):
    travel_history = db.query(TravelHistory).filter(TravelHistory.user_id == user_id).first()

    if travel_history is None:
        return JSONResponse(content={"message": "User has no travel history"}, status_code=404)

    travels = db.query(Travel).filter(Travel.travel_history_id == travel_history.id).all()

    return [{"route_number": travel.route_number, "date": travel.date} for travel in travels]

@router.delete("/{user_id}")
async def delete_user(user_id: UUID, db: Session = Depends(get_session)):
    user = db.query(User).filter(User.id == user_id).first()

    if user is None:
        return JSONResponse(content={"message": "User not found"}, status_code=404)
    
    travel_history = db.query(TravelHistory).filter(TravelHistory.user_id == user_id).first()

    if travel_history is not None:
        for travel in db.query(Travel).filter(Travel.travel_history_id == travel_history.id).all():
            db.delete(travel)

        db.delete(travel_history)

    db.delete(user)
    db.commit()

    return {"message": "User deleted"}